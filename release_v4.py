import json, os, subprocess, sys

# Check if GH_TOKEN exists
token = os.environ.get('GH_TOKEN') or os.environ.get('GITHUB_TOKEN')
if not token:
    # Try to get from gh CLI
    try:
        token = subprocess.check_output(['gh', 'auth', 'token'], text=True).strip()
    except:
        print("No GitHub token found. Trying unauthenticated...")
        token = None

repo = "Paul-Carouge/lecto"
tag = "v4.0.0"
apk_path = "/home/atlas/lecto/lecto-v4.0.0.apk"

# Release body
body = """## Lecto v4.0.0 — Refonte complète

### ✨ Nouveautés

- **BottomNavigationBar** — Navigation par onglets : Accueil, Bibliothèque, Recherche, Statistiques, Paramètres
- **Nouveau flux de session** — Lancez une session depuis le détail du livre, entrez le nombre de pages lues à la fin, obtention automatique de la moyenne pages/min
- **Suivi des pages restantes** — Les pages lues sont déduites du nombre total de pages du livre
- **Streak de lecture** — Nombre de jours consécutifs de lecture affiché sur l'accueil
- **Profil utilisateur** — Configurez votre nom dans les paramètres
- **Note par étoiles** — Notez tous vos livres, pas seulement les terminés
- **Sessions persistantes** — Reprenez une session interrompue depuis le détail du livre

### 🎨 Design

- Interface aérée et spacieuse
- Statistiques pleine largeur sur l'accueil
- Streak avec icône 🔥
- Pas de texte tronqué, tout est lisible
- Nouveau design pour l'écran de session active

### 🔧 Technique

- Architecture BottomNavigationBar + IndexedStack (préservation des états)
- Providers refactorés pour le calcul des pages restantes
- Nouvelle méthode `finishSession()` dans le session provider
- `updateSessionPages()` pour la saisie manuelle des pages

### 📱 APK

- Taille : ~61 MB
- API minimale : Android 5.0+"""

# Create release
import urllib.request

headers = {
    'Accept': 'application/vnd.github+json',
    'Content-Type': 'application/json',
}
if token:
    headers['Authorization'] = f'Bearer {token}'

# First check if release already exists and delete it
req = urllib.request.Request(
    f'https://api.github.com/repos/{repo}/releases/tags/{tag}',
    headers=headers,
    method='GET'
)
try:
    resp = urllib.request.urlopen(req)
    existing = json.loads(resp.read())
    print(f"Release already exists: {existing['id']}, deleting...")
    del_req = urllib.request.Request(
        f'https://api.github.com/repos/{repo}/releases/{existing["id"]}',
        headers=headers,
        method='DELETE'
    )
    urllib.request.urlopen(del_req)
    print("Deleted old release")
except urllib.error.HTTPError as e:
    if e.code != 404:
        print(f"Error checking release: {e.code} {e.read()}")
        sys.exit(1)

# Create new release
data = json.dumps({
    'tag_name': tag,
    'name': f'Lecto v4.0.0 — Refonte complète',
    'body': body,
    'draft': False,
    'prerelease': False,
}).encode()

req = urllib.request.Request(
    f'https://api.github.com/repos/{repo}/releases',
    data=data,
    headers=headers,
    method='POST'
)
resp = urllib.request.urlopen(req)
release = json.loads(resp.read())
release_id = release['id']
print(f"Release created: {release['html_url']}")

# Upload APK
import mimetypes
file_size = os.path.getsize(apk_path)
print(f"Uploading APK ({file_size} bytes)...")

with open(apk_path, 'rb') as f:
    apk_data = f.read()

upload_headers = {
    'Accept': 'application/vnd.github+json',
    'Content-Type': 'application/vnd.android.package-archive',
    'Content-Length': str(file_size),
}
if token:
    upload_headers['Authorization'] = f'Bearer {token}'

upload_url = f'https://uploads.github.com/repos/{repo}/releases/{release_id}/assets?name=lecto-v4.0.0.apk'
req = urllib.request.Request(upload_url, data=apk_data, headers=upload_headers, method='POST')
resp = urllib.request.urlopen(req)
asset = json.loads(resp.read())
print(f"APK uploaded: {asset['browser_download_url']}")
print("Done!")
