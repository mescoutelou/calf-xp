# Expérimentations CALF

Travaux pratiques sur le processeur CALF, en simulation (Verilator) ou
implémenté sur la carte ChipWhisperer CW312T-A35 (Artix-7 35T) et piloté par
un ChipWhisperer Husky.

Les premiers TP sont une prise en main, chacun avec son objectif :

| TP | Objectif |
|----|----------|
| [0_0_sim](0_0_sim/README.md) | Simulation : exécuter du C et de l'assembleur, visualiser l'exécution d'une instruction étape par étape |
| [0_1_uart](0_1_uart/README.md) | Carte : échanger des données entre un script Python et le programme C de CALF par l'UART |
| [0_2_boot](0_2_boot/README.md) | Carte : changer le programme par le bootloader, sans regénérer le bitstream |
| [0_3_dump](0_3_dump/README.md) | Sécurité : lire la mémoire par le bootloader, retrouver une clé dans le code et une clé matérielle dans la pile, voir la rémanence de la RAM, puis lire la clé matérielle par `DUMP` et par injection de code |

## Organisation

Un TP `<n>_<m>_<nom>` a deux répertoires : le répertoire étudiant
`<n>_<m>_<nom>` et le répertoire de corrigé `S<n>_<m>_<nom>`, qui sert aussi
à régénérer les fichiers du répertoire étudiant. Les fichiers logiciels
communs sont dans `sw/common`, le dialogue avec la carte dans
`implem/xilinx/src/cw312_a7_35t.py`.

```
xp/
  gen.py              enseignant : régénère les fichiers fournis (programme, bitstream)
  branch.py           enseignant : construit la branche étudiante (sans les corrigés)
  progress.py         avancement d'un TP : marqueurs <TODO N> et <DONE N> (N : étape)
  0_0_sim/            répertoire étudiant
    README.md         sujet
    xp.py             lanceur : compile sw/, simule (verilator/), trace (vcd/)
    sw/               programme C et assembleur à compléter
  S0_0_sim/           corrigé (absent de la branche étudiante)
    README.md         résultats attendus, expliqués
    xp.py             lanceur du corrigé
    sw/               programme complet
    gen.yaml          options : pas de bitstream (TP simulé)
  0_1_uart/           répertoire étudiant
    README.md         sujet
    xp.py             script Python à compléter
    bit/0_1_uart.bit  bitstream fourni : design + programme dans l'image RAM
  S0_1_uart/          corrigé et régénération (absent de la branche étudiante)
    README.md         résultats attendus, expliqués
    xp.py             corrigé de 0_1_uart/xp.py
    sw/               programme C qui tourne sur CALF (compilé par gen.py)
    gen.yaml          options du bitstream : programme dans l'image RAM
    xpr/              projet Vivado créé par gen.py (non versionné)
  0_2_boot/           répertoire étudiant
    README.md         sujet
    xp.py             chargement par le bootloader, à compléter
    sw/               programme C à modifier, chargé par xp.py
    bit/0_2_boot.bit  bitstream fourni : design + bootloader, RAM vide
  S0_2_boot/          corrigé et régénération (absent de la branche étudiante)
    README.md         résultats attendus, expliqués
    xp.py             corrigé de 0_2_boot/xp.py
    sw/               programme complet
    gen.yaml          options du bitstream : bootloader, RAM vide
  0_3_dump/           répertoire étudiant
    README.md         sujet
    xp.py             dump de la mémoire et clés trouvées, à compléter
    sw/example/main.c programme d'exemple à analyser (--example, étape 1)
    sw/inject/main.c  programme à injecter par le bootloader, à compléter (--direct, étape 5)
    bit/0_3_dump.bit  bitstream fourni : design, bootloader, programme dans l'image RAM, clé matérielle
  S0_3_dump/          corrigé et régénération (absent de la branche étudiante)
    README.md         résultats attendus, expliqués
    xp.py             corrigé de 0_3_dump/xp.py
    sw/main/          programme du bitstream (jamais fourni)
    sw/example/       copie du programme d'exemple
    sw/inject/        programme injecté complet
    gen.yaml          options du bitstream : bootloader, programme dans l'image RAM, clé
sw/common/
  build.py            compilation RISC-V d'un programme (<dir>/src, <xp>/sw)
  script.ld           édition de liens (RAM 16 Ko)
  src/start.S         démarrage : gp, sp, appel de main
  src/hw.h            fréquence, RAM, registres GPIO A, UART 0 et KEY 0
  src/isa.h           instructions sans équivalent C (compteur de cycles)
  src/gpio.h          bits des LED et du trigger
  src/uart.h          débit et fonctions UART (scrutation)
sim/
  sim.py              simulation Verilator : construction du simulateur, exécution
  verilator/src/      top de simulation (.sv) et banc de test (.cpp)
  verilator/calf.gtkw sélection des signaux du cœur pour GTKWave
implem/xilinx/src/
  cw312_a7_35t.py     côté PC : programmation FPGA, horloge HS2, reset, Uart
  cw312_a7_35t.*      top (.sv), contraintes (.xdc) et flot Vivado (.tcl) de la carte
```

La branche étudiante garde tout `sw/` et `implem/` : certains TP font
modifier le logiciel, voire le matériel.

Dans un TP, `sw/` contient le logiciel (C, compilé avec `sw/common`) et
`hw/` le matériel : ses fichiers `.sv` et `.xdc` remplacent ceux de même nom
de `src/main/sv` et `implem/xilinx/src`, les autres s'y ajoutent. Le projet
Vivado d'un TP est dans son propre `xpr/`.

Dans les fichiers étudiants, chaque partie à compléter est marquée par un
commentaire `<TODO N>`, `N` étant le numéro de l'étape du sujet, que
l'étudiant remplace par `<DONE N>` une fois la partie terminée ; le corrigé
marque les mêmes endroits par `<DONE N>`, avec le même numéro. Chaque `xp.py`
affiche l'avancement à la fin de son exécution, avec la prochaine partie à
faire dans l'ordre des étapes, et le détail avec `--progress`
(`xp/progress.py`, qui donne aussi l'avancement de tous les TP :
`python3 xp/progress.py`). Un marqueur sans numéro (`<TODO>`, `<DONE>`) est
signalé par un avertissement.

Chaque TP se lance par son `xp.py`, qui utilise les bibliothèques communes :
`sw/common/build.py` (compilation), `sim/sim.py` (simulation) et
`implem/xilinx/src/cw312_a7_35t.py` (carte). Un TP simulé a son propre
simulateur, dans `verilator/`, construit avec son `hw/` s'il en a un.

## Prérequis (étudiants)

Simulation (0_0_sim) :

- Verilator (testé avec la 5.048), GTKWave.
- Le compilateur RISC-V `riscv64-unknown-elf-gcc` dans le `PATH`.

Carte (0_1_uart, 0_2_boot, 0_3_dump) :

- Python 3 avec le paquet `chipwhisperer` (testé avec la 6.0.0) :
  `pip install chipwhisperer "setuptools<81"`. Sans `setuptools` (absent par
  défaut depuis Python 3.12), `scope.default_setup()` échoue sur
  `'NoneType' object has no attribute '_set_enabled'`.
- Un ChipWhisperer Husky avec la carte CW312T-A35 branchée.

Pour un TP à bitstream fourni, Vivado n'est pas nécessaire. Pour 0_1_uart,
le compilateur RISC-V non plus : le bitstream contient déjà le programme.
Pour 0_2_boot, il faut le compilateur RISC-V : le programme est compilé puis
chargé par le bootloader. Pour 0_3_dump, il faut `riscv64-unknown-elf-objdump`
pour désassembler la mémoire lue, et le compilateur pour l'exemple et le
programme injecté (étapes 1 et 5).

## Validation

Chaque TP est découpé en étapes ; le sujet indique pour chacune ce qui est à
faire valider (une valeur affichée, un comportement de la carte).

- En séance, l'enseignant valide chaque étape.
- En autonomie, le corrigé est dans le répertoire `S<n>_<m>_<nom>` de la
  branche principale du dépôt : `README.md` donne et explique les résultats
  attendus, `sw/` et `xp.py` sont le programme et le script complets.

## Enseignant

Régénérer les fichiers fournis d'un TP à bitstream fourni (programme de la
solution, bitstream), avec Vivado, le compilateur RISC-V et le paquet Python
`pyyaml` (`pip install pyyaml`, pour `gen.yaml`) :

```
source /opt/xilinx/Vivado/2024.1/settings64.sh
export PATH=/opt/toolchain-man/build/custom/bin:$PATH
python3 xp/gen.py 0_1_uart         # --no-bit : programme seul, sans Vivado
python3 xp/S0_1_uart/xp.py         # corrigé, sur la carte
```

- `gen.py` compile `xp/S0_1_uart/sw` (sorties dans `xp/S0_1_uart/{obj,elf,
  hex,lst,log}`), puis écrit le bitstream dans `xp/0_1_uart/bit`.
- Les options sont dans `xp/S<n>_<m>_<nom>/gen.yaml`, présent dans chaque
  corrigé. Toutes sont obligatoires, avec leur valeur par défaut quand elle
  s'applique : `gen.py` lit le fichier avant de compiler et s'arrête s'il
  manque, s'il manque une option ou si une valeur est invalide.

  | Option | Valeur | Rôle | Argument du `.tcl` |
  |--------|--------|------|--------------------|
  | `bit` | `true` / `false` | bitstream ; `false` pour un TP simulé : `gen.py` compile seulement le programme | |
  | `boot` | `true` / `false` | bootloader UART | `-boot 1` / `-boot 0` |
  | `ram` | `true` / `false` | programme de `sw/main` dans l'image RAM | `-ram <image>` |
  | `key` | `"<hexadécimal>"`, entre guillemets (défaut `"00000000"`) | valeur du registre `KEY_0_DATA` | `-key <clé>` |

  | TP | `bit` | `boot` | `ram` | `key` |
  |----|-------|--------|-------|-------|
  | 0_0_sim | `false` | `false` | `true` | `"00000000"` |
  | 0_1_uart | `true` | `false` | `true` | `"00000000"` |
  | 0_2_boot | `true` | `true` | `false` (l'étudiant charge son programme) | `"00000000"` |
  | 0_3_dump | `true` | `true` | `true` | secrète |

  Pour 0_0_sim, `boot`, `ram` et `key` sont ceux de la simulation (RAM
  préchargée, sans bootloader, clé par défaut), pour mémoire : `sim/sim.py`
  ne les lit pas. La clé de 0_3_dump n'est jamais dans le répertoire
  étudiant ; `gen.py` ne l'affiche pas, mais le journal de Vivado
  (`xpr/vivado.log` du corrigé) la contient.
- Le flot Vivado est `implem/xilinx/src/cw312_a7_35t.tcl -tclargs -boot 0
  -key 00000000 -ram <image> -xpr xp/S0_1_uart/xpr [-hw xp/S0_1_uart/hw]` : chaque TP a son
  projet, plusieurs `gen.py` peuvent tourner en même temps.
- Si le corrigé a un répertoire `hw/`, le bitstream contient le matériel
  corrigé : il reste dans `xp/S<n>_<m>_<nom>/bit` et n'est pas fourni.
- Après une modification du programme, vérifier les résultats attendus du
  `README.md` du corrigé (adresses, valeurs) : ils dépendent du programme.

Branche étudiante : `python3 xp/branch.py` construit, depuis le commit
courant, la branche `xp` sans les répertoires de corrigé (voir `--help`).

Ajouter un TP `<n>_<m>_<nom>` : créer `xp/S<n>_<m>_<nom>/` avec le programme
`sw/` (et `hw/` si besoin), le lanceur corrigé `xp.py` et le `README.md` des
résultats attendus, puis `xp/<n>_<m>_<nom>/` avec le sujet `README.md`, le
lanceur `xp.py` et les fichiers à compléter (marqués `<TODO N>`, et `<DONE N>`
dans le corrigé), et `gen.yaml` dans le corrigé. Pour un TP à bitstream
fourni, lancer ensuite `gen.py <n>_<m>_<nom>`. Un TP en simulation n'a rien à
générer : son `xp.py` compile son `sw/`.
