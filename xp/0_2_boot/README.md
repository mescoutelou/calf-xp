# TP 0_2_boot : changer le programme de la carte

Le bitstream `bit/0_2_boot.bit` contient le processeur CALF et son
*bootloader* : à chaque reset, avant le processeur, le bootloader écoute
l'UART et écrit en mémoire le programme que lui envoie le PC. Changer de
programme ne demande donc pas de regénérer le bitstream (plusieurs minutes
avec Vivado) : il suffit de le recompiler et de le recharger.

Le but est d'écrire, en Python, le chargement d'un programme par le
bootloader, puis de modifier ce programme en C.

## Mise en route

Prérequis : ceux de 0_1_uart (paquet `chipwhisperer`, Husky et carte
CW312T-A35), et le compilateur RISC-V `riscv64-unknown-elf-gcc` dans le
`PATH`. Depuis la racine du dépôt :

```
python3 xp/0_2_boot/xp.py
```

Le script compile le programme de `sw/`, programme le FPGA, fait un reset,
puis appelle `boot_load()` pour charger le programme. Il passe ensuite au
débit du programme et lui envoie la ligne `hello calf` : le programme la
renvoie en écho. La LED 0 change d'état à chaque octet reçu.

Options :

| Option | Rôle |
|--------|------|
| `--no-prog` | ne reprogramme pas le FPGA (déjà programmé) |
| `--no-load` | ne charge pas de programme : démarre celui qui est en mémoire (étape 4) |
| `--progress` | affiche l'avancement |

## Le bootloader

Le bootloader communique à 4800 bauds (`uart.baud`), le programme à 9600
bauds une fois `uart_init()` appelé. Les champs de plusieurs octets sont en
little-endian.

| Envoi | Contenu | Réponse |
|-------|---------|---------|
| `NUM` | 1 octet : nombre de commandes qui suivent ; 0 démarre le processeur | |
| `INIT` | `0x01`, `ADDR` (4 octets), `SIZE` (4 octets), puis `SIZE` octets à écrire en mémoire à partir de `ADDR` | |
| `DUMP` | `0x03`, `ADDR` (4 octets), `SIZE` (4 octets) | `SIZE` octets lus en mémoire |
| `PING` | `0x02` | `0xaa` |

Après la dernière des `NUM` commandes, le bootloader rend la main au
processeur, qui démarre à l'adresse 0. Pendant qu'il répond (`DUMP`,
`PING`), le bootloader ignore ce qu'il reçoit : attendre la fin de la
réponse avant d'envoyer la commande suivante.

## Avancement

Chaque partie à compléter est marquée par un commentaire `<TODO N>`, où `N`
est le numéro de l'étape : une fois la partie terminée, le remplacer par
`<DONE N>`, en gardant le numéro. La dernière ligne affichée par le script
donne l'avancement et la prochaine partie à faire, dans l'ordre des étapes ;
`python3 xp/0_2_boot/xp.py --progress` liste toutes les parties, faites ou non.

## Étapes

### Étape 1 : charger

Compléter `boot_load()` dans `xp.py` : envoyer `NUM = 2`, puis `INIT` avec
l'image du programme à l'adresse 0, puis `PING`. Lire la réponse de `PING`
et vérifier qu'elle vaut `0xaa`.

**À valider :** la réponse de `PING` et l'écho de `hello calf`.

### Étape 2 : vérifier

Ajouter `DUMP` entre `INIT` et `PING` (`NUM = 3`) pour relire la mémoire,
et comparer la réponse avec l'image envoyée. Le délai de lecture doit
couvrir l'envoi de l'image et la réponse : 10 bits par octet à 4800 bauds.

**À valider :** le nombre d'octets relus et le nombre d'octets différents de
l'image.

### Étape 3 : modifier le programme

Modifier `sw/main/main.c` pour que le programme renvoie les lettres en
majuscules, puis relancer le script : il recompile et recharge le programme,
sans toucher au bitstream (`--no-prog` évite même de reprogrammer le FPGA).

**À valider :** l'écho `HELLO CALF`.

### Étape 4 : redémarrer sans recharger

Compléter `boot_skip()` : envoyer `NUM = 0` pour démarrer le processeur sur
le programme déjà en mémoire. Essayer :

```
python3 xp/0_2_boot/xp.py --no-prog --no-load
python3 xp/0_2_boot/xp.py --no-load
```

**À valider :** le résultat des deux commandes, et son explication : que
devient la mémoire lors d'un reset, et lors de la programmation du FPGA ?

## Validation

En séance, faire valider chaque étape par l'enseignant. En autonomie, le
corrigé et les résultats attendus sont dans `xp/S0_2_boot/` sur la branche
principale du dépôt.

## Aide

- `(0).to_bytes(4, "little")` et `len(image).to_bytes(4, "little")` donnent
  `ADDR` et `SIZE` ; `bytes([2, CMD_INIT])` donne `NUM` et la commande.
- `uart.read(n, timeout)` attend `n` octets pendant `timeout` secondes, et
  renvoie moins d'octets si le délai expire.
- `sum(a != b for a, b in zip(x, y))` compte les octets différents de deux
  `bytes` de même taille.
