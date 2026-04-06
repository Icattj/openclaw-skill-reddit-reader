---
name: reddit-reader
description: Read Reddit posts, comments, and subreddits via the JSON API. No API key needed. Use when asked to read a Reddit thread, browse a subreddit, search Reddit for topics, or gather community opinions. Works by appending .json to Reddit URLs.
---

# Reddit Reader

Read Reddit content via the public JSON API (no authentication required).

## Quick Start

```bash
# Read a subreddit's hot posts
scripts/reddit.sh programming

# Read a specific thread with comments
scripts/reddit.sh "https://www.reddit.com/r/programming/comments/abc123/title/"

# Specify limit
scripts/reddit.sh technology 20
```

## Manual Commands

### Browse subreddit
```bash
curl -sH "User-Agent: Mozilla/5.0" \
  "https://www.reddit.com/r/SUBREDDIT/hot.json?limit=10" | \
  python3 -c "
import json,sys; d=json.load(sys.stdin)
for p in d['data']['children']:
    x=p['data']
    print(f\"[{x['score']}] {x['title']}\")
    print(f\"  u/{x['author']} | {x['num_comments']} comments | {x['url']}\")
    print()
"
```

### Read specific post + comments
```bash
curl -sH "User-Agent: Mozilla/5.0" "https://www.reddit.com/r/sub/comments/ID/.json" | \
  python3 -c "
import json,sys; data=json.load(sys.stdin)
post=data[0]['data']['children'][0]['data']
print(f\"# {post['title']}\nby u/{post['author']} | {post['score']} pts\n\")
if post.get('selftext'): print(post['selftext'][:2000])
print('\n--- Comments ---')
for c in data[1]['data']['children'][:15]:
    if c['kind']!='more':
        d=c['data']
        print(f\"\nu/{d.get('author','?')} [{d.get('score','?')} pts]:\")
        print(d.get('body','')[:500])
"
```

### Search Reddit
```bash
curl -sH "User-Agent: Mozilla/5.0" \
  "https://www.reddit.com/search.json?q=QUERY&limit=10&sort=relevance"
```

## Sorting Options

Append to subreddit URL: `/hot`, `/new`, `/top`, `/rising`
For `/top`, add `?t=hour|day|week|month|year|all`

## VPS Note

Reddit may block some VPS IP ranges. If requests fail with 403/429:
- Add a delay between requests (2-3 seconds)
- Use `web_fetch` tool as fallback
- Try via Jina Reader: `curl -s "https://r.jina.ai/https://reddit.com/r/sub"`
