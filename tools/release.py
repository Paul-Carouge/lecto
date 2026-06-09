#!/usr/bin/env python3
"""Release Lecto APK to GitHub"""
import json, urllib.request, os, sys

# Read token
token = ''
for line in open('/home/atlas/.hermes/.env'):
    line = line.strip()
    if line.startswith('GITHUB_TOKEN='):
        var = line.split('=', 1)[1].strip().strip("'\"")
        token = var
        break

if not token:
    sys.exit(1)

h = {'Authorization': f'token {token}', 'Content-Type': 'application/json'}

body = ('## Lecto v1.2.1\n\n'
        '### Correction\n\n'
        '- **Permission INTERNET ajoutee au manifest release**\n'
        '  L erreur Failed host lookup etait causee par l absence de permission.\n\n'
        '### Fonctionnalites\n\n'
        '- Recherche livres OpenLibrary (titre, ISBN)\n'
        '- Couvertures, auteur, pages, editeur, categories\n'
        '- Sessions chrono, stats, objectifs, recommandations\n'
        '- Wrapped mensuel, mode sombre, 100% local')

data = json.dumps({'tag_name': 'v1.2.1', 'name': 'Lecto v1.2.1 - Permission INTERNET', 'body': body, 'draft': False, 'prerelease': False}).encode()
req = urllib.request.Request('https://api.github.com/repos/Paul-Carouge/lecto/releases', data=data, headers=h)
with urllib.request.urlopen(req) as r:
    rid = json.loads(r.read())['id']
    print(f'Release: {rid}')

apk = open(os.path.expanduser('~/lecto/build/app/outputs/flutter-apk/app-release.apk'), 'rb').read()
url = f'https://uploads.github.com/repos/Paul-Carouge/lecto/releases/{rid}/assets?name=lecto-v1.2.1.apk'
rh = {'Authorization': f'token {token}', 'Content-Type': 'application/octet-stream', 'Content-Length': str(len(apk))}
req = urllib.request.Request(url, data=apk, headers=rh, method='POST')
with urllib.request.urlopen(req) as r:
    d = json.loads(r.read())
    print(f'Uploaded: {d["name"]} - {d["size"]} bytes')
