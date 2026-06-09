#!/usr/bin/env python3
"""Create GitHub release and upload APK for Lecto"""
import os, json, urllib.request, sys

token = os.environ.get('GITHUB_TOKEN', '')
if not token:
    print("ERROR: Set GITHUB_TOKEN env var", file=sys.stderr)
    sys.exit(1)

headers = {
    'Authorization': f'token {token}',
    'Content-Type': 'application/json',
}

version = 'v1.2.0'

body = (
    '## Lecto v1.2.0\n\n'
    '### Changements majeurs\n\n'
    '- **OpenLibrary remplace Google Books** - Google Books avait un quota epuise.\n'
    '  OpenLibrary est gratuit, sans cle API, parfait pour les livres francais.\n'
    '- **Recherche de livres fonctionnelle** - Ajoutez des livres par titre ou ISBN,\n'
    '  avec couverture, auteur, pages, editeur et categories.\n\n'
    '### Fonctionnalites\n\n'
    '- Bibliotheque avec recherche et filtres\n'
    '- Sessions de lecture avec chronometre\n'
    '- Statistiques avec graphiques mensuels\n'
    '- Objectifs annuels et mensuels\n'
    '- Recommandations basees sur vos genres favoris\n'
    '- Wrapped mensuel automatique\n'
    '- Mode sombre integre\n'
    '- 100% local\n\n'
    '### Technique\n\n'
    '- Flutter 3.44 + Riverpod + SQLite\n'
    '- OpenLibrary API + covers.openlibrary.org'
)

release_data = json.dumps({
    'tag_name': version,
    'name': 'Lecto v1.2.0 - OpenLibrary, application fonctionnelle',
    'body': body,
    'draft': False,
    'prerelease': False,
}).encode()

req = urllib.request.Request(
    'https://api.github.com/repos/Paul-Carouge/lecto/releases',
    data=release_data, headers=headers,
)

with urllib.request.urlopen(req) as resp:
    release_id = json.loads(resp.read())['id']
    print(f'Release created: {release_id}')

# Upload APK
apk_path = os.path.expanduser('~/lecto/build/app/outputs/flutter-apk/app-release.apk')
with open(apk_path, 'rb') as f:
    apk_data = f.read()

upload_url = f'https://uploads.github.com/repos/Paul-Carouge/lecto/releases/{release_id}/assets?name=lecto-{version}.apk'
upload_headers = {
    'Authorization': f'token {token}',
    'Content-Type': 'application/vnd.android.package-archive',
    'Content-Length': str(len(apk_data)),
}

req = urllib.request.Request(upload_url, data=apk_data, headers=upload_headers, method='POST')
with urllib.request.urlopen(req) as resp:
    r = json.loads(resp.read())
    print(f'Uploaded: {r["name"]} - {r["size"]} bytes')
