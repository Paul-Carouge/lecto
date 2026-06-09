#!/usr/bin/env bash
set -e
cd /home/atlas/lecto

# Read GITHUB_TOKEN from .env
source /home/atlas/.hermes/.env 2>/dev/null || true
TOKEN=$(grep -oP "GITHUB_TOKEN='\K[^']+" /home/atlas/.hermes/.env 2>/dev/null || \
        grep -oP 'GITHUB_TOKEN="\K[^"]+' /home/atlas/.hermes/.env 2>/dev/null || \
        grep -oP "GITHUB_TOKEN=\K[^'\"]+" /home/atlas/.hermes/.env 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "ERROR: GITHUB_TOKEN not found"
  exit 1
fi

# Create release
echo "Creating release..."
RELEASE=$(curl -s -X POST "https://api.github.com/repos/Paul-Carouge/lecto/releases" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tag_name": "v1.2.1",
    "name": "Lecto v1.2.1 - Permission INTERNET",
    "body": "## Lecto v1.2.1\n\n### Correction\n\n- **Permission INTERNET ajoutee au manifest release**\n  L erreur Failed host lookup: openlibrary.org etait causee par\n  l absence de la permission INTERNET dans le manifest Android de release.\n\n### Fonctionnalites\n\n- Recherche de livres via OpenLibrary (titre, ISBN)\n- Couvertures, auteur, pages, editeur, categories\n- Sessions de lecture avec chronometre\n- Statistiques, objectifs, recommandations, Wrapped\n- 100% local, mode sombre",
    "draft": false,
    "prerelease": false
  }')

RELEASE_ID=$(echo "$RELEASE" | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])")
echo "Release ID: $RELEASE_ID"

# Upload APK
echo "Uploading APK..."
curl -s -X POST "https://uploads.github.com/repos/Paul-Carouge/lecto/releases/$RELEASE_ID/assets?name=lecto-v1.2.1.apk" \
  -H "Authorization: token $TOKEN" \
  -H "Content-Type: application/vnd.android.package-archive" \
  --data-binary @build/app/outputs/flutter-apk/app-release.apk | \
  python3 -c "import json,sys;d=json.load(sys.stdin);print(f'Uploaded: {d[\"name\"]} - {d[\"size\"]} bytes')"

echo "Done!"
