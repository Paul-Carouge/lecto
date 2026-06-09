#!/usr/bin/env python3
"""Release Lecto APK to GitHub"""
import json, urllib.request, os, sys

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

body = ('## Lecto v1.3.0\n\n'
        '### Nouveau : Recherche multi-sources\n\n'
        '- **OpenLibrary + BnF** combines en parallele pour des resultats maximaux\n'
        '- **BnF (Bibliotheque nationale de France)** : 16 millions de notices,\n'
        '  incluant des livres rares, anciens et editions francaises introuvables ailleurs\n'
        '- **Pas de restriction de langue** : livres en francais ET en anglais\n'
        '- **Deduplication automatique** : pas de doublons entre les sources\n'
        '- Les resultats OpenLibrary apparaissent en premier, completes par la BnF\n\n'
        '### Comment ca marche\n\n'
        '1. OpenLibrary cherche (40M+ livres, rapide)\n'
        '2. BnF cherche en parallele (livres francais, catalogue national)\n'
        '3. Les resultats sont fusionnes sans doublons\n'
        '4. Vous voyez jusqu\'a 40 resultats par recherche\n\n'
        '### Fonctionnalites existantes\n\n'
        '- Bibliotheque, sessions chrono, statistiques, objectifs\n'
        '- Recommandations, Wrapped mensuel, mode sombre\n'
        '- 100% local, aucune donnee envoyee')

data = json.dumps({'tag_name': 'v1.3.0', 'name': 'Lecto v1.3.0 - Recherche multi-sources', 'body': body, 'draft': False, 'prerelease': False}).encode()
req = urllib.request.Request('https://api.github.com/repos/Paul-Carouge/lecto/releases', data=data, headers=h)
with urllib.request.urlopen(req) as r:
    rid = json.loads(r.read())['id']
    print(f'Release: {rid}')

apk = open(os.path.expanduser('~/lecto/build/app/outputs/flutter-apk/app-release.apk'), 'rb').read()
url = f'https://uploads.github.com/repos/Paul-Carouge/lecto/releases/{rid}/assets?name=lecto-v1.3.0.apk'
rh = {'Authorization': f'token {token}', 'Content-Type': 'application/octet-stream', 'Content-Length': str(len(apk))}
req = urllib.request.Request(url, data=apk, headers=rh, method='POST')
with urllib.request.urlopen(req) as r:
    d = json.loads(r.read())
    print(f'Uploaded: {d["name"]} - {d["size"]} bytes')
