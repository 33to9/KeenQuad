<p align="center">
<img src="../img/keenquad-header.png" alt="KeenQuad" width="800">
</p>
<h3 align="center">Des définitions HiDPI nettes pour votre écran, en un clic depuis la barre des menus</h3>
<p align="center">
<a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/v/release/33to9/KeenQuad?style=flat" alt="Dernière version"></a> <a href="https://github.com/33to9/KeenQuad/releases"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/total?style=flat" alt="Téléchargements au total"></a> <a href="https://github.com/33to9/KeenQuad/releases/latest"><img src="https://img.shields.io/github/downloads/33to9/KeenQuad/latest/total?style=flat" alt="Téléchargements de la dernière version"></a> <a href="https://github.com/33to9/KeenQuad/blob/main/LICENSE"><img src="https://img.shields.io/github/license/33to9/KeenQuad?style=flat" alt="Licence"></a>
</p>
<p align="center">
<a href="../README.md">English</a> · <a href="README.zh-Hans.md">简体中文</a> · <a href="README.zh-Hant.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.de.md">Deutsch</a> · <a href="README.ko.md">한국어</a> · <b>Français</b> · <a href="README.es.md">Español</a>
</p>

> **KeenQuad** est une petite app de la barre des menus qui fait passer votre écran d’une définition HiDPI à une autre, y compris celles, bien nettes, que Réglages Système n’affiche pas.
> Sur beaucoup d’écrans externes, une définition comme 1600 × 1000 n’apparaît dans Réglages Système qu’en version 1x, et elle paraît floue. macOS en possède aussi une version HiDPI, bien nette, mais seules les apps qui lisent la liste complète des modes d’affichage peuvent y passer. C’est exactement ce que fait KeenQuad, et rien de plus.

## Pourquoi la même définition peut être floue ou nette

Chaque taille figure généralement deux fois dans la liste des modes d’affichage de macOS. Sur une dalle 2560 × 1600, pour 1600 × 1000 :

| Version | Comment macOS la dessine | Rendu |
|---|---|---|
| 1x | Calcule 1600 × 1000 pixels, puis les étire sur la dalle | Flou |
| HiDPI | Calcule 3200 × 2000 pixels, puis les réduit sur la dalle | Net |

Réglages Système › Moniteurs ne propose que les modes de l’interface publique, qui masque de nombreuses versions HiDPI. Si vous y choisissez 1600 × 1000, vous obtenez la version 1x. Lorsque le mode actuel est un mode HiDPI réglé par KeenQuad, Réglages Système affiche le nom identique comme sélectionné ; cliquer à nouveau dessus vous fait passer à la version floue.

Pour savoir ce que vous utilisez, exécutez `system_profiler SPDisplaysDataType` : en HiDPI, **Resolution** vaut le double de **UI Looks like**.

## Fonctionnalités

- Affiche toutes les définitions HiDPI de chaque écran, y compris les cachées, et indique la définition actuelle et la taille pixel pour pixel de la dalle
- Un clic pour changer. Si vous ne confirmez pas une nouvelle définition dans les 15 secondes, elle est rétablie toute seule : un écran noir se corrige de lui-même
- Sur une définition 1x floue, le menu propose **Passer à la version nette**, avec la même taille de bureau
- Les définitions conservées restent après avoir quitté l’app, fermé la session ou redémarré ; macOS les enregistre, rien ne tourne en arrière-plan
- Ouverture à la connexion et **Rechercher les mises à jour…**
- English, 简体中文, 繁體中文, 日本語, Deutsch, 한국어, Français et Español ; suit la langue du système, ou choisissez-en une dans le menu

## Configuration requise

- Un Mac avec puce Apple
- macOS 14 ou version ultérieure

## Installation

### Option 1 : installation en une ligne (recommandée, sans alerte Gatekeeper)

Ouvrez Terminal, collez cette ligne et appuyez sur Retour :

```bash
curl -fsSL https://raw.githubusercontent.com/33to9/KeenQuad/main/install.sh | bash
```

Le script télécharge la dernière version depuis GitHub, vérifie son SHA-256, l’installe dans Applications et l’ouvre. Les fichiers téléchargés avec curl ne portent pas d’attribut de quarantaine : macOS ne bloque donc pas la première ouverture. Si KeenQuad est déjà installé, il est mis à jour sur place et conserve son réglage d’ouverture à la connexion. Le script est court, n’hésitez pas à le [lire](../install.sh) d’abord.

### Option 2 : ZIP

Téléchargez le dernier `KeenQuad_vX.Y.Z_macOS.zip` depuis [Releases](https://github.com/33to9/KeenQuad/releases/latest), décompressez-le et placez KeenQuad dans le dossier Applications.

L’app n’est pas notariée par Apple, macOS bloque donc la première ouverture une fois :
- **macOS 15 et versions ultérieures** : double-cliquez (une alerte s’affiche), puis ouvrez **Réglages Système → Confidentialité et sécurité**, faites défiler vers le bas et cliquez sur **Ouvrir quand même**
- **macOS 14** : cliquez sur l’app avec le bouton droit → **Ouvrir**

### Mise à jour

Choisissez **Rechercher les mises à jour…** dans le menu de KeenQuad. S’il existe une nouvelle version, KeenQuad affiche les nouveautés et ouvre la page de téléchargement. Pour mettre à jour sans alerte Gatekeeper, relancez l’installation en une ligne.

## Utiliser KeenQuad

Cliquez sur l’icône de KeenQuad dans la barre des menus :

- Cliquez sur une définition pour en changer. Pour une nouvelle définition, KeenQuad demande **Conserver cette définition ?** : appuyez sur Retour pour la conserver, sur Échap pour revenir en arrière, ou attendez 15 secondes et elle est rétablie toute seule. Les définitions déjà conservées s’appliquent immédiatement.
- **Passer à la version nette** apparaît lorsque la définition actuelle est une définition 1x floue qui a une version HiDPI.
- **Autres formats** contient les tailles HiDPI dont les proportions ne correspondent pas à la dalle.
- **Langue** et **Ouvrir à la connexion** se trouvent en bas du menu.

## Autorisations

Aucune. Changer de mode d’affichage ne nécessite ni l’enregistrement de l’écran, ni l’accessibilité, ni aucune autre autorisation. Si macOS vous demande d’autoriser l’élément d’ouverture, KeenQuad ouvre la bonne page de Réglages Système.

## Confidentialité

KeenQuad ne collecte rien et n’envoie aucune statistique. Il ne se connecte à Internet que lorsque vous cliquez sur **Rechercher les mises à jour…** : une seule requête à l’API GitHub pour connaître la dernière version, sans aucune information vous concernant. Vos réglages restent dans `~/Library/Preferences/com.keenquad.app.plist`.

## Désinstallation

1. Dans le menu de KeenQuad, désactivez **Ouvrir à la connexion**, puis choisissez **Quitter KeenQuad**.
2. Supprimez `/Applications/KeenQuad.app`.
3. Facultatif : exécutez `defaults delete com.keenquad.app`.

La définition utilisée reste en place ; changez-la dans Réglages Système si vous le souhaitez.

## Fonctionnement

KeenQuad lit et change les modes d’affichage à l’aide de fonctions privées de CoreGraphics (`CGSGetNumberOfDisplayModes`, `CGSGetDisplayModeDescriptionOfLength`, `CGSConfigureDisplayMode`), les mêmes que celles de l’outil open source `displayplacer`. Il ne crée pas de définitions, n’installe pas de fichiers de remplacement d’écran et ne demande pas de mot de passe administrateur ; il passe seulement à des modes que macOS possède déjà. Une nouvelle définition ne s’applique d’abord que tant que l’app tourne : si KeenQuad est forcé à quitter, macOS la rétablit. Elle n’est enregistrée durablement que lorsque vous la conservez.

Comme il utilise des fonctions privées, une future mise à jour de macOS pourrait les modifier. Si le menu reste un jour vide, merci d’[ouvrir une issue](https://github.com/33to9/KeenQuad/issues).

## Compiler depuis les sources

Prérequis : outils en ligne de commande Xcode (Xcode n’est pas nécessaire).

```bash
git clone https://github.com/33to9/KeenQuad.git
cd KeenQuad/tray
./build.sh --install        # compiler et installer dans /Applications
./Tests/run-selftest.sh     # tests des règles en lecture seule, ne change rien
```

`./build.sh --package` crée `dist/KeenQuad_vX.Y.Z_macOS.zip` pour une publication. Les notes de développement (en chinois) se trouvent dans [`tray/README.md`](../tray/README.md), et les spécifications dans `KeenQuad_Tray_v0_*.md`.

## Licence

Ce projet est distribué sous licence **GPL-3.0-only** (voir [LICENSE](../LICENSE)). Le nom KeenQuad et ses icônes ne sont pas couverts par la licence ; voir [TRADEMARK.md](../TRADEMARK.md).

Copyright © 2026 [33to9](https://github.com/33to9)
