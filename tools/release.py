#!/usr/bin/env python3
"""Create GitHub release and upload APK for Lecto v1.1.0"""
import os, json, urllib.request

# Get token from environment
token = os.environ.get('GITHUB_TOKEN', '')
if not token:
    env_path = '/home/atlas/.hermes/.env'
    if os.path.exists(env_path):
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith('GITHUB_TOKEN='):
                    token = line.split('=', 1)[1].strip().strip("'\"")

assert token, "GITHUB_TOKEN not found"

headers = {
    'Authorization': f'token {token}',
    'Content-Type': 'application/json',
}

# Create release
body = '## Lecto v1.1.0\n\n### Ameliorations\n\n- **Livres francais prioritaires** - L API Google Books cherche desormais en francais (langRestrict=fr)\n- **Recherche optimisee** - Resultats tries par pertinence avec couvertures, titres et toutes les infos\n- **Interface traduite** - Toute l interface est maintenant en francais\n- **Cartes redesignees** - Tailles fixes pour les couvertures, plus de debordement de texte\n- **Grille 2 colonnes** - Les livres sont plus lisibles\n\n### Corrections\n\n- Correction du debordement de texte dans les cartes de livres\n- Layout stabilise : plus d erreur Expanded inside Column\n- Badges de statut en francais avec couleurs adaptees'

release_data = json.dumps({
    'tag_name': 'v1.1.0',
    'name': 'Lecto v1.1.0 - Livres francais, UI robuste',
    'body': body,
    'draft': False,
    'prerelease': False,
}).encode()

req = urllib.request.Request(
    'https://api.github.com/repos/Paul-Carouge/lecto/releases',
    data=release_data,
    headers=headers,
)

with urllib.request.urlopen(req) as resp:
    release = json.loads(resp.read())
    release_id = release['id']
    print(f'Release created: {release_id}')

# Upload APK
apk_path = '/home/atlas/lecto/build/app/outputs/flutter-apk/app-release.apk'
with open(apk_path, 'rb') as f:
    apk_data = f.read()

upload_url = f'https://uploads.github.com/repos/Paul-Carouge/lecto/releases/{release_id}/assets?name=lecto-v1.1.0.apk'
upload_headers = {
    'Authorization': f'token {token}',
    'Content-Type': 'application/vnd.android.package-archive',
    'Content-Length': str(len(apk_data)),
}

upload_req = urllib.request.Request(upload_url, data=apk_data, headers=upload_headers, method='POST')
with urllib.request.urlopen(upload_req) as resp:
    result = json.loads(resp.read())
    print(f'Uploaded: {result["name"]} - {result["size"]} bytes')
