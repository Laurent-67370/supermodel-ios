# Supermodel pour iPhone et iPad (expérimental)

Version iOS de [Supermodel](https://github.com/trzy/supermodel), l'émulateur
Sega Model 3 de « The Supermodel Team » (GPL 3) : Virtua Fighter 3, Scud
Race, Daytona USA 2, Sega Rally 2, Star Wars Trilogy, etc.

**État : Model 3, Model 2 et Model 1 marchent sur iPad.** Sur un iPad Pro M5
sous iOS 27 (LiveContainer, sans JIT), un bêta-testeur joue **Virtua Fighter 3**
à pleine vitesse (57,5 images/s, la fréquence de la borne), **Virtua Racing**
(Model 1) et **Sonic Championship** (Model 2) « parfaitement », à la manette ;
les jeux de course gardent leurs réglages du menu de service d'une partie à
l'autre. Les corrections propres à iOS : l'écran est un framebuffer de SDL
(0.1.2), SDL n'est plus arrêté entre la liste et le jeu (0.1.3), le
*renderbuffer* de l'écran est remis actif avant chaque image (0.1.5), le rendu
Model 1/2 est passé à OpenGL ES 3.0 (0.1.6), le Model 2 prépare des triangles
et la mémoire des jeux est enregistrée quand l'app passe en arrière-plan
(0.1.7). Les **bêta-testeurs** sont les bienvenus :
[issue #3](https://github.com/Laurent-67370/supermodel-ios/issues/3).

> **In English, for beta testers:** an experimental and unsigned iOS build of
> Supermodel (iOS 16.3+, arm64). On an iPad Pro M5 (iOS 27, no JIT), Virtua
> Fighter 3 runs at full speed (57.5 fps); Virtua Racing (Model 1) and Sonic
> Championship (Model 2) run perfectly, and games keep their settings (NVRAM)
> when the app is closed (build 0.1.7).
> Download
> [supermodel.ipa](https://github.com/Laurent-67370/supermodel-ios/releases/download/supermodel-ios/supermodel.ipa),
> sideload it (SideStore, AltStore, LiveContainer), put your games (`.zip`
> sets, as for the desktop Supermodel) in the app's `ROMs` folder (Files →
> On My iPhone/iPad → Supermodel → ROMs), launch the app and pick a game in
> its list. A **game controller** is needed to play (no touch controls yet).
> Please report your device, iOS version, which games start, how fast they run
> and `Supermodel.log` (in the same folder) in
> [issue #3](https://github.com/Laurent-67370/supermodel-ios/issues/3).

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
   commandes tactiles. Pour revenir à la liste, fermer l'app et la relancer
   (depuis la 0.1.7, les réglages faits dans le menu de service du jeu sont
   gardés).
   Pour remplir tout l'écran, cocher **Stretch** dans l'onglet **Video** du
   menu (l'image est alors un peu étirée) ; avec **ShowFrameRate**, le nombre
   d'images par seconde est écrit dans `Supermodel.log` toutes les 5 secondes
   (iOS n'affiche pas le titre de la fenêtre, où il apparaît sur ordinateur).

Les réglages sont dans `Config/Supermodel.ini` et le journal dans
`Supermodel.log`, dans le même dossier de l'app.

## Ce qui marche, ce qui manque

| | |
|---|---|
| Jeux Model 3 | **Virtua Fighter 3 : parfait, 57,5 images/s** (pleine vitesse ; iPad Pro M5, sans JIT) |
| Réglages des jeux (NVRAM) | gardés : enregistrés quand l'app passe en arrière-plan (0.1.7, vérifié) |
| Rendu 3D | OpenGL ES 3.0, en triangles (le rendu en quadrilatères demande des geometry shaders, absents d'iOS) |
| Son | oui (vérifié sur iPad) |
| Manettes | oui (vérifié sur iPad) |
| Commandes tactiles | pas encore |
| Jeux Model 1 / Model 2 | **Virtua Racing (Model 1) et Sonic Championship (Model 2) : parfaits** (0.1.7) ; en triangles (sans geometry shaders) |
| Jeux au pistolet | à essayer à la souris (axes de visée réglés sur la souris par défaut ; viseur : **Crosshairs** dans l'onglet Video) ; le test de « ligne de mire » du Model 3 lit la profondeur, ce qu'OpenGL ES ne permet pas |
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
    l'écran, et les dossiers de l'app ;
  - l'écran d'iOS : le « framebuffer 0 » que Supermodel utilise pour l'écran
    est remplacé par celui que SDL crée pour la vue de l'app ;
  - les erreurs de compilation des shaders écrites dans `Supermodel.log`, et un
    menu 1,5 fois plus grand sur iOS ;
  - sur iOS, SDL n'est plus arrêté entre la liste des jeux et le jeu, et tout
    est en plein écran ; `Supermodel.log` dit, après les premières images, la
    taille de la fenêtre et de l'image, le framebuffer et les erreurs d'OpenGL ;
  - pendant les 300 premières images, chaque erreur d'OpenGL est écrite dans
    `Supermodel.log` avec l'appel et la ligne de Supermodel qui l'a faite, et
    un programme de shaders qui ne se lie pas, avec la raison ;
  - avant chaque image montrée, le *renderbuffer* de l'écran remis actif :
    SDL, sous iOS, présente celui qui est actif ;
  - le rendu Model 1/2 : ses *texture buffers* deviennent des textures 2D
    d'entiers de 256 de large (lues ainsi par les shaders traduits), ses pixels
    BGRA sont envoyés en RGBA avec rouge et bleu échangés à la lecture
    (*swizzle*), `findMSB` (GLSL ES 3.10) est réécrit, et ses quadrilatères
    (geometry shaders) laissent la place aux triangles, que le Model 2 prépare
    alors lui-même ;
  - sur iOS, la NVRAM (réglages du menu de service, scores) est enregistrée
    chaque fois que l'app passe en arrière-plan : une app iOS est fermée depuis
    le sélecteur d'apps, jamais quittée.
- [`ios/`](ios) : l'`Info.plist` et la préparation des dossiers dans
  Documents (`Config/`, `ROMs/`, `NVRAM/`, `Saves/`, `Assets/`).
- [`android/`](android) : la même préparation pour Android ; le patch et la
  compilation sont communs avec la version Android,
  [supermodel-android](https://github.com/Laurent-67370/supermodel-android),
  qui les reprend d'ici.
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
