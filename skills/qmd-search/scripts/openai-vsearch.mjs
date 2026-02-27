#!/usr/bin/env node
/**
 * Vector Search using OpenAI Embeddings
 * 
 * Searches qmd index using OpenAI embeddings for semantic similarity.
 * 
 * Usage: node openai-vsearch.mjs "query" [-n 5] [-c collection] [--json]
 */

import Database from 'better-sqlite3';
import { homedir } from 'os';
import { join } from 'path';
import { existsSync } from 'fs';

const QMD_DB = process.env.QMD_INDEX || join(homedir(), '.cache/qmd/index.sqlite');
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const EMBEDDING_MODEL = 'text-embedding-3-small';

// Parse args
const args = process.argv.slice(2);
let query = '';
let numResults = 5;
let collection = null;
let jsonOutput = false;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '-n' && args[i + 1]) {
    numResults = parseInt(args[i + 1]);
    i++;
  } else if ((args[i] === '-c' || args[i] === '--collection') && args[i + 1]) {
    collection = args[i + 1];
    i++;
  } else if (args[i] === '--json') {
    jsonOutput = true;
  } else if (!args[i].startsWith('-')) {
    query = args[i];
  }
}

if (!query) {
  console.error('Usage: openai-vsearch.mjs "query" [-n 5] [-c collection] [--json]');
  process.exit(1);
}

if (!OPENAI_API_KEY) {
  console.error('Error: OPENAI_API_KEY not set');
  process.exit(1);
}

if (!existsSync(QMD_DB)) {
  console.error(`Error: QMD database not found at ${QMD_DB}`);
  process.exit(1);
}

const db = new Database(QMD_DB);

// Check if we have OpenAI embeddings
const hasEmbeddings = db.prepare(`
  SELECT COUNT(*) as count FROM vectors_openai
`).get();

if (hasEmbeddings.count === 0) {
  console.error('No OpenAI embeddings found. Run openai-embed.mjs first.');
  db.close();
  process.exit(1);
}

// Get query embedding
async function getQueryEmbedding(text) {
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: EMBEDDING_MODEL,
      input: `task: search result | query: ${text}`
    })
  });
  
  if (!response.ok) {
    throw new Error(`OpenAI API error: ${response.status}`);
  }
  
  const data = await response.json();
  return data.data[0].embedding;
}

// Cosine similarity
function cosineSimilarity(a, b) {
  let dotProduct = 0;
  let normA = 0;
  let normB = 0;
  
  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

// Blob to Float32 array
function blobToEmbedding(blob) {
  return new Float32Array(blob.buffer, blob.byteOffset, blob.length / 4);
}

async function search() {
  // Get query embedding
  const queryEmb = await getQueryEmbedding(query);
  
  // Get all vectors (for small corpus, this is fine)
  let vectorQuery = `
    SELECT v.hash_seq, v.embedding, cv.hash, cv.content, cv.pos
    FROM vectors_openai v
    JOIN content_vectors_openai cv ON v.hash_seq = cv.hash || '_' || cv.seq
  `;
  
  const vectors = db.prepare(vectorQuery).all();
  
  // Calculate similarities
  const results = vectors.map(v => {
    const embedding = blobToEmbedding(v.embedding);
    const similarity = cosineSimilarity(queryEmb, embedding);
    return {
      hash: v.hash,
      content: v.content,
      pos: v.pos,
      score: similarity
    };
  });
  
  // Sort by similarity
  results.sort((a, b) => b.score - a.score);
  
  // Group by document, take best chunk per doc
  const seen = new Set();
  const deduped = results.filter(r => {
    if (seen.has(r.hash)) return false;
    seen.add(r.hash);
    return true;
  });
  
  // Get document info
  const docInfo = db.prepare(`
    SELECT d.hash, d.title, d.path as filepath, d.collection
    FROM documents d
    WHERE d.active = 1 ${collection ? 'AND d.collection = ?' : ''}
  `);
  
  const docs = collection 
    ? docInfo.all(collection)
    : docInfo.all();
  
  const docMap = new Map(docs.map(d => [d.hash, d]));
  
  // Filter by collection and limit
  const filtered = deduped
    .filter(r => docMap.has(r.hash))
    .slice(0, numResults)
    .map(r => {
      const doc = docMap.get(r.hash);
      return {
        ...r,
        title: doc.title,
        filepath: doc.filepath,
        collection: doc.collection
      };
    });
  
  return filtered;
}

// Run search
search().then(results => {
  if (jsonOutput) {
    console.log(JSON.stringify(results, null, 2));
  } else {
    if (results.length === 0) {
      console.log('No results found.');
      return;
    }
    
    for (const r of results) {
      const score = Math.round(r.score * 100);
      console.log(`\n${r.collection}/${r.filepath} #${r.hash.slice(0, 6)}`);
      console.log(`Title: ${r.title}`);
      console.log(`Score: ${score}%`);
      console.log('');
      // Show snippet (first 200 chars of matched chunk)
      const snippet = r.content.replace(/^title: [^|]+ \| text: /, '').slice(0, 200);
      console.log(snippet + (r.content.length > 200 ? '...' : ''));
    }
  }
  
  db.close();
}).catch(e => {
  console.error('Error:', e.message);
  db.close();
  process.exit(1);
});
