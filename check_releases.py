import json, os, urllib.request

# Get token from git-credentials
token = None
cred_path = os.path.expanduser("~/.git-credentials")
if os.path.exists(cred_path):
    with open(cred_path) as f:
        line = f.read().strip()
        if '://' in line:
            parts = line.split(':', 2)
            if len(parts) >= 3:
                token = parts[2].split('@')[0]

if not token:
    print("No token found")
    exit(1)

auth = "Bearer " + token
req = urllib.request.Request(
    "https://api.github.com/repos/Paul-Carouge/lecto/releases?per_page=5",
    headers={"Authorization": auth, "Accept": "application/vnd.github.v3+json"}
)
resp = urllib.request.urlopen(req)
data = json.loads(resp.read())

for r in data:
    print(r['tag_name'], '| draft:', r['draft'], '| prerelease:', r.get('prerelease'))
    for a in r.get('assets', []):
        print('  ->', a['name'], '| url:', a['browser_download_url'][:70] if a['browser_download_url'] else 'NONE')
