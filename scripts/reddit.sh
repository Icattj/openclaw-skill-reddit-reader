#!/usr/bin/env bash
# Read Reddit posts/comments via JSON API
# Usage: reddit.sh <subreddit-or-url> [limit]
set -euo pipefail

INPUT="${1:?Usage: reddit.sh <subreddit-or-url> [limit]}"
LIMIT="${2:-10}"
UA="User-Agent: Mozilla/5.0 (compatible; AgentBot/1.0)"

# Determine if input is a full URL or just a subreddit name
if [[ "$INPUT" == http* ]]; then
    # Full URL — ensure it ends with .json
    URL="${INPUT%.json}.json"
else
    # Subreddit name
    URL="https://www.reddit.com/r/${INPUT}/hot.json?limit=${LIMIT}"
fi

echo "Fetching: $URL"
echo ""

RESPONSE=$(curl -s -H "$UA" "$URL" 2>/dev/null) || {
    echo "❌ Failed to fetch. Reddit may be blocking this IP."
    echo "Fallback: try web_fetch or Jina Reader"
    exit 1
}

python3 -c "
import json, sys

data = json.loads('''$( echo "$RESPONSE" | python3 -c "import sys; print(sys.stdin.read().replace(\"'''\", \"___\"))" )'''.replace('___', \"'''\"))

# Handle both listing (subreddit) and thread (post+comments) formats
if isinstance(data, list):
    # Thread format: [post, comments]
    post = data[0]['data']['children'][0]['data']
    print(f\"# {post['title']}\")
    print(f\"by u/{post['author']} | {post['score']} pts | {post['num_comments']} comments\")
    print(f\"Sub: r/{post['subreddit']}\")
    if post.get('selftext'):
        print(f\"\n{post['selftext'][:3000]}\")
    print('\n--- Top Comments ---')
    for c in data[1]['data']['children'][:15]:
        if c['kind'] != 'more':
            d = c['data']
            print(f\"\nu/{d.get('author','?')} [{d.get('score','?')} pts]:\")
            body = d.get('body','')[:500]
            print(body)
elif isinstance(data, dict) and 'data' in data:
    # Listing format (subreddit)
    for p in data['data']['children']:
        x = p['data']
        print(f\"[{x.get('score',0):>5}] {x['title']}\")
        print(f\"        u/{x['author']} | {x.get('num_comments',0)} comments\")
        if x.get('url'): print(f\"        {x['url']}\")
        print()
else:
    print('Unexpected response format')
    print(json.dumps(data, indent=2)[:2000])
" 2>/dev/null || {
    echo "❌ Failed to parse response. Raw output (first 1000 chars):"
    echo "$RESPONSE" | head -c 1000
}
