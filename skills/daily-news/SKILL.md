# Daily NYC/NJ News Briefing

An adaptive morning briefing that learns and evolves based on current events and feedback.

## How It Works

1. **Reads context** from `memory/news-context.md` for current focus topics
2. **Searches** for news across culture, industry, sports, and focus topics
3. **Delivers briefing** with top stories
4. **Updates context** with new trending topics and follow-ups
5. **Learns** from feedback to improve over time

## Context File

`memory/news-context.md` tracks:
- **Focus Topics**: Major ongoing events (Olympics, playoffs, elections, etc.)
- **Local Interests**: NYC/JC specific topics
- **Teams**: Sports teams to monitor
- **Preferences**: What Arxa wants more/less of
- **Briefing Notes**: Follow-up items from previous briefings

## Giving Feedback

Just tell me:
- "More Olympics coverage" → adds to focus
- "Skip crypto news" → adds to skip list
- "Track the Rangers playoff push" → adds specific follow-up

The briefing adapts based on your input.

## Schedule

Runs daily at 9AM ET via cron. Can also be triggered manually.

## Evolution

After each briefing, I update the context with:
- New trending topics discovered
- Stories worth following up
- Adjustments based on what's relevant

This means the briefing gets smarter over time, not just a static news dump.
