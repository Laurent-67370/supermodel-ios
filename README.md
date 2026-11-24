# Supermodel pour iPhone et iPad (expérimental)

Version iOS de [Supermodel](https://github.com/trzy/supermodel), l'émulateur
Sega Model 3 de « The Supermodel Team » (GPL 3) : Virtua Fighter 3, Scud
Race, Daytona USA 2, Sega Rally 2, Star Wars Trilogy, etc.

**État : premier essai, pas encore testé sur un appareil.** L'app se compile
et le rendu a été vérifié sur un ordinateur, avec la même version d'OpenGL
qu'iOS (OpenGL ES 3.0). Il reste à savoir si les jeux tournent, et à quelle
vitesse, sur un vrai iPhone ou iPad. Les **bêta-testeurs** sont les bienvenus :
[les issues de ce dépôt](https://github.com/Laurent-67370/supermodel-ios/issues).

> **In English, for beta testers:** a first, experimental and unsigned iOS
> build of Supermodel (iOS 16.3+, arm64), not yet tried on a device.
> Download
> [supermodel.ipa](https://github.com/Laurent-67370/supermodel-ios/releases/download/supermodel-ios/supermodel.ipa),
> sideload it (SideStore, AltStore, LiveContainer), put your games (`.zip`
> sets, as for the desktop Supermodel) in the app's `ROMs` folder (Files →
> On My iPhone/iPad → Supermodel → ROMs), launch the app and pick a game in
> its list. A **game controller** is needed to play (no touch controls yet).
> Please report your device, iOS version, which games start, how fast they run
> and `Supermodel.log` (in the same folder) in
> [this repository's issues](https://github.com/Laurent-67370/supermodel-ios/issues).

## Télécharger

[supermodel.ipa](https://github.com/Laurent-67370/supermodel-ios/releases/download/supermodel-ios/supermodel.ipa)
(publication [`supermodel-ios`](https://github.com/Laurent-67370/supermodel-ios/releases/tag/supermodel-ios),
reconstruite à chaque modification de l'app). L'`.ipa` n'est pas signé : on
l'installe soi-même avec SideStore, AltStore ou LiveContainer.

## Utilisation

1. Installer `supermodel.ipa`, puis lancer l'app une première fois : elle crée
   ses dossiers.
2. Mettre les jeux (fichiers `.zip`, les mêmes que pour Supermodel sur
   ordinateur) dans le dossier **ROMs** de l'app : app **Fichiers** → **Sur mon
   iPhone/iPad** → **Supermodel** → **ROMs** (avec LiveContainer, dans son
   propre dossier).
3. Relancer l'app : la liste montre les jeux trouvés ; toucher un jeu, puis
   **Load game**.
4. Jouer avec une **manette** (Xbox, PlayStation, MFi) : il n'y a pas encore de
   commandes tactiles. Pour revenir à la liste, fermer l'app et la relancer.

Les réglages sont dans `Config/Supermodel.ini` et le journal dans
`Supermodel.log`, dans le même dossier de l'app.

## Ce qui marche, ce qui manque

| | |
|---|---|
| Jeux Model 3 | à tester (Step 1.0 à 2.1) |
| Rendu 3D | OpenGL ES 3.0, en triangles (le rendu en quadrilatères demande des geometry shaders, absents d'iOS) |
| Son | oui (SDL2) |
| Manettes | oui (SDL2) |
| Commandes tactiles | pas encore |
| Jeux Model 1 / Model 2 | non (leur rendu demande des geometry shaders et des texture buffers) |
| Jeux au pistolet | visée à vérifier (lecture de profondeur absente d'OpenGL ES) |
| Réseau entre bornes | non testé |

**Vitesse :** le processeur PowerPC du Model 3 est émulé par un interpréteur,
sans JIT. Les jeux Step 1.x (66 MHz : Virtua Fighter 3, Scud Race) ont le plus
de chances de tourner à pleine vitesse sur un appareil récent ; les Step 2.x
(166 MHz : Daytona USA 2, Star Wars Trilogy...) risquent d'être trop lents.

## Comment c'est fait

- [`supermodel.version`](supermodel.version) : le commit de Supermodel utilisé.
- [`patches/0001-ios.patch`](patches/0001-ios.patch) : les changements apportés
  à Supermodel :
  - `Src/OSD/GLES/` remplace GLEW : OpenGL ES 3.0, et les shaders (GLSL 4.10)
    traduits en GLSL ES 3.00 au moment où ils sont donnés à OpenGL ;
  - deux corrections dans les shaders du rendu 3D (conversions explicites, et
    accès aux deux pages de textures par des indices constants), valables aussi
    sur ordinateur ;
  - le contexte OpenGL ES 3.0, le rendu en triangles, la fenêtre à la taille de
    l'écran, et les dossiers de l'app.
- [`ios/`](ios) : l'`Info.plist` et la préparation des dossiers dans
  Documents (`Config/`, `ROMs/`, `NVRAM/`, `Saves/`, `Assets/`).
- [`CMakeLists.txt`](CMakeLists.txt) : la compilation, d'après la liste des
  fichiers du Makefile de Supermodel ; elle marche aussi sous Linux (OpenGL ES
  de Mesa) pour essayer sans appareil.
- [`.github/workflows/ios.yml`](.github/workflows/ios.yml) : l'`.ipa`, compilé
  sur un Mac de GitHub, avec SDL2 et SDL2_net compilés depuis leurs sources.

Pour compiler sous Linux (paquets `libsdl2-dev`, `libsdl2-net-dev`, `libgles-dev`) :

```sh
./fetch-supermodel.sh
cmake -S . -B build -G Ninja && ninja -C build
```

## Licence

GPL 3 ou ultérieure, comme Supermodel. Aucun jeu ni fichier de Sega n'est
fourni : il faut posséder ses propres jeux.
