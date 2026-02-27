#!/usr/bin/env node
/**
 * OpenAI Embeddings for QMD
 * 
 * Generates embeddings using OpenAI API and stores them in qmd's sqlite-vec format.
 * This enables vector search without local llama.cpp.
 * 
 * Usage: node openai-embed.mjs [--force]
 */

import Database from 'better-sqlite3';
import { readFileSync, existsSync } from 'fs';
import { homedir } from 'os';
import { join } from 'path';

const QMD_DB = process.env.QMD_INDEX || join(homedir(), '.cache/qmd/index.sqlite');
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const EMBEDDING_MODEL = 'text-embedding-3-small';
const EMBEDDING_DIM = 1536;
const CHUNK_SIZE = 800; // tokens (conservative estimate: ~4 chars/token)
const CHUNK_OVERLAP = 0.15;

if (!OPENAI_API_KEY) {
  console.error('Error: OPENAI_API_KEY not set');
  process.exit(1);
}

if (!existsSync(QMD_DB)) {
  console.error(`Error: QMD database not found at ${QMD_DB}`);
  console.error('Run "qmd collection add" first to create the index.');
  process.exit(1);
}

const forceReembed = process.argv.includes('--force') || process.argv.includes('-f');

// Initialize database
const db = new Database(QMD_DB);

// Ensure sqlite-vec extension and tables exist
try {
  db.exec(`
    CREATE TABLE IF NOT EXISTS content_vectors_openai (
      hash TEXT NOT NULL,
      seq INTEGER NOT NULL,
      pos INTEGER NOT NULL,
      content TEXT NOT NULL,
      PRIMARY KEY (hash, seq)
    );
    
    CREATE TABLE IF NOT EXISTS vectors_openai (
      hash_seq TEXT PRIMARY KEY,
      embedding BLOB NOT NULL
    );
  `);
} catch (e) {
  // Tables may already exist
}

// Get documents that need embedding
const docs = db.prepare(`
  SELECT d.hash, c.doc as content, d.title, d.path as filepath
  FROM documents d
  JOIN content c ON d.hash = c.hash
  LEFT JOIN content_vectors_openai cv ON d.hash = cv.hash
  WHERE d.active = 1 AND (cv.hash IS NULL ${forceReembed ? 'OR 1=1' : ''})
  GROUP BY d.hash
`).all();

if (docs.length === 0) {
  console.log('All documents already have OpenAI embeddings.');
  process.exit(0);
}

console.log(`Embedding ${docs.length} documents with OpenAI ${EMBEDDING_MODEL}...`);

// Simple chunking (by character count, ~4 chars per token)
function chunkText(text, title) {
  const charLimit = CHUNK_SIZE * 4;
  const overlapChars = Math.floor(charLimit * CHUNK_OVERLAP);
  const chunks = [];
  let pos = 0;
  
  while (pos < text.length) {
    const end = Math.min(pos + charLimit, text.length);
    let chunkEnd = end;
    
    // Try to break at paragraph or sentence
    if (end < text.length) {
      const lastPara = text.lastIndexOf('\n\n', end);
      const lastSentence = text.lastIndexOf('. ', end);
      if (lastPara > pos + charLimit * 0.5) chunkEnd = lastPara + 2;
      else if (lastSentence > pos + charLimit * 0.5) chunkEnd = lastSentence + 2;
    }
    
    const chunk = text.slice(pos, chunkEnd).trim();
    if (chunk) {
      chunks.push({
        content: `title: ${title || 'none'} | text: ${chunk}`,
        pos: pos
      });
    }
    
    pos = chunkEnd - overlapChars;
    if (pos <= chunks[chunks.length - 1]?.pos) pos = chunkEnd; // Prevent infinite loop
  }
  
  return chunks;
}

// Call OpenAI embeddings API
async function getEmbeddings(texts) {
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: EMBEDDING_MODEL,
      input: texts
    })
  });
  
  if (!response.ok) {
    const err = await response.text();
    throw new Error(`OpenAI API error: ${response.status} ${err}`);
  }
  
  const data = await response.json();
  return data.data.map(d => d.embedding);
}

// Float32 array to blob
function embeddingToBlob(embedding) {
  return Buffer.from(new Float32Array(embedding).buffer);
}

// Process documents
const insertChunk = db.prepare(`
  INSERT OR REPLACE INTO content_vectors_openai (hash, seq, pos, content)
  VALUES (?, ?, ?, ?)
`);

const insertVector = db.prepare(`
  INSERT OR REPLACE INTO vectors_openai (hash_seq, embedding)
  VALUES (?, ?)
`);

let totalChunks = 0;
const batchSize = 50; // OpenAI supports up to 2048 inputs

for (let i = 0; i < docs.length; i++) {
  const doc = docs[i];
  const chunks = chunkText(doc.content, doc.title);
  
  console.log(`  [${i + 1}/${docs.length}] ${doc.filepath} (${chunks.length} chunks)`);
  
  // Process in batches
  for (let j = 0; j < chunks.length; j += batchSize) {
    const batch = chunks.slice(j, j + batchSize);
    const texts = batch.map(c => c.content);
    
    try {
      const embeddings = await getEmbeddings(texts);
      
      const transaction = db.transaction(() => {
        for (let k = 0; k < batch.length; k++) {
          const seq = j + k;
          const chunk = batch[k];
          const embedding = embeddings[k];
          
          insertChunk.run(doc.hash, seq, chunk.pos, chunk.content);
          insertVector.run(`${doc.hash}_${seq}`, embeddingToBlob(embedding));
        }
      });
      
      transaction();
      totalChunks += batch.length;
    } catch (e) {
      console.error(`    Error embedding batch: ${e.message}`);
    }
  }
}

console.log(`\nDone! Embedded ${totalChunks} chunks from ${docs.length} documents.`);

// Show stats
const stats = db.prepare(`
  SELECT 
    (SELECT COUNT(DISTINCT hash) FROM content_vectors_openai) as docs,
    (SELECT COUNT(*) FROM vectors_openai) as vectors
`).get();

console.log(`Total: ${stats.docs} documents, ${stats.vectors} vectors`);

db.close();
