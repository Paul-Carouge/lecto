import json, os, urllib.request

# Get token
token = None
cred_path = os.path.expanduser("~/.git-credentials")
if os.path.exists(cred_path):
    with open(cred_path) as f:
        line = f.read().strip()
        if '://' in line:
            parts = line.split(':', 2)
            if len(parts) >= 3:
                token = parts[2].split('@')[0]

auth = "Bearer " + token if token else ""

# Make repo public
data = json.dumps({"private": False}).encode()
req = urllib.request.Request(
    "https://api.github.com/repos/Paul-Carouge/lecto",
    data=data,
    headers={"Authorization": auth, "Accept": "application/vnd.github.v3+json", "Content-Type": "application/json"},
    method="PATCH"
)
resp = urllib.request.urlopen(req)
repo = json.loads(resp.read())
print("private:", repo.get("private"), "| visibility:", repo.get("visibility"))
print("Repo is now PUBLIC!")
