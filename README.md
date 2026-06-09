# 📚 Lecto

**Lecto** est une application de suivi de lecture **100% locale**, élégante et professionnelle. Inspirée par Lexu mais sans fonctionnalités sociales — vos données restent sur votre appareil.

> *"Le Strava des livres, en local."*

## ✨ Fonctionnalités

| Fonctionnalité | Description |
|----------------|-------------|
| **📖 Bibliothèque** | Ajoutez vos livres par recherche Google Books, scan ISBN ou saisie manuelle |
| **⏱ Sessions** | Chronomètre intégré avec suivi des pages et durée |
| **📊 Statistiques** | Tableau de bord avec graphiques mensuels (pages, temps de lecture) |
| **🎯 Objectifs** | Fixez des objectifs annuels (livres) ou mensuels (pages, minutes) |
| **🤖 Recommandations** | Moteur local qui analyse vos genres préférés et suggère des livres similaires |
| **📋 Wrapped mensuel** | Récapitulatif automatique de vos lectures chaque mois |
| **🌙 Mode sombre** | Thème clair/sombre adaptatif |
| **🔒 100% local** | Aucun compte requis, aucune donnée personnelle envoyée |

## 🖼 Aperçu

- **Bibliothèque** — Grille élégante avec filtres par statut (À lire, En cours, Terminé)
- **Détail d'un livre** — Couverture, progression, sessions, notes
- **Session active** — Interface minimaliste et immersive pour le chrono
- **Statistiques** — Graphiques mensuels pages/temps, genres favoris, streaks
- **Recommandations** — Suggestions personnalisées basées sur vos lectures

## 🛠 Stack technique

- **Flutter** 3.44 — Framework cross-platform
- **Riverpod** — State management
- **SQLite** — Base de données locale
- **Google Books API** — Recherche et métadonnées de livres
- **Google Fonts** (Outfit + Inter) — Typographie soignée
- **fl_chart** — Graphiques de statistiques

## 📦 Installation

### Android
1. Téléchargez le dernier APK depuis la [page des releases](https://github.com/Paul-Carouge/lecto/releases)
2. Ouvrez le fichier sur votre appareil Android
3. Autorisez l'installation depuis des sources inconnues si nécessaire

### iOS
Construisez le projet avec Xcode sur macOS.

### Web
Lecto supporte également le déploiement web via `flutter build web`.

## 🔧 Développement

```bash
# Cloner le dépôt
git clone https://github.com/Paul-Carouge/lecto.git
cd lecto

# Installer les dépendances
flutter pub get

# Générer les fichiers .g.dart (riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# Lancer l'application
flutter run

# Build APK release
flutter build apk --release
```

## 📄 Licence

Projet privé — © 2026 Paul Carouge
