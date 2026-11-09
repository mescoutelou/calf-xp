# TP 0_3_dump : lire la mémoire par le bootloader

Première expérience orientée sécurité. Le bitstream `bit/0_3_dump.bit`
contient un programme, dans sa mémoire, qui vérifie deux clés secrètes. Le
code source n'est pas fourni. Mais le bootloader est resté actif : comme
dans 0_2_boot, sa commande `DUMP` permet de relire toute la mémoire.

Le but est de retrouver les deux clés à partir de la mémoire :

1. une clé écrite dans le code du programme ;
2. une clé matérielle, que le programme copie dans sa pile.

puis de constater que la RAM garde ces secrets d'une exécution à l'autre
(rémanence), et de lire la clé matérielle directement, sans passer par le
programme.

## Mise en route

Prérequis : ceux de 0_2_boot (paquet `chipwhisperer`, Husky et carte
CW312T-A35, compilateur RISC-V `riscv64-unknown-elf-gcc` et
`riscv64-unknown-elf-objdump` dans le `PATH`, pour l'exemple, le
désassemblage et l'étape 5). Depuis la racine du dépôt :

```
python3 xp/0_3_dump/xp.py
```

Le script programme le FPGA et fait un reset : le bootloader attend ses
commandes. Il enchaîne ensuite :

1. le dump du début de la mémoire (code et données), dans `dump/code.*` ;
2. le démarrage du programme, puis la commande `K` avec `SECRET_KEY` ;
3. la commande `H` avec `HW_KEY` ;
4. un reset, qui relance le bootloader, puis le dump du haut de la mémoire
   (pile), dans `dump/stack.*` ;
5. le redémarrage du programme, puis de nouveau la commande `H`.

Chaque dump est écrit en trois fichiers : `.bin` (octets bruts), `.txt`
(adresse, valeurs hexadécimales et caractères ASCII, 16 octets par ligne)
et `.lst` (désassemblage : chaque mot est affiché comme une instruction,
même s'il s'agit de données).

## Le programme

Le programme répond à deux commandes, une fois démarré (9600 bauds) :

| Envoi | Réponse |
|-------|---------|
| `K` puis une valeur (4 octets, little-endian) | `secret_key: OK` si c'est la clé du code, sinon `secret_key: KO` |
| `H` puis une valeur (4 octets, little-endian) | `hw_key: OK` si c'est la clé matérielle, sinon `hw_key: KO` |

La clé matérielle est la valeur du registre en lecture seule `KEY_0_DATA`, à
l'adresse `0x10000300` (`sw/common/src/hw.h`) : elle est fixée à la
génération du bitstream et n'est pas dans le code.

## Avancement

Chaque partie à compléter est marquée par un commentaire `<TODO N>`, où `N`
est le numéro de l'étape : une fois la partie terminée, le remplacer par
`<DONE N>`, en gardant le numéro. La dernière ligne affichée par le script
donne l'avancement et la prochaine partie à faire, dans l'ordre des étapes ;
`python3 xp/0_3_dump/xp.py --progress` liste toutes les parties, faites ou non.

## Étapes

### Étape 1 : comprendre l'organisation de la mémoire

Avant d'attaquer le programme inconnu, on étudie un programme dont on a la
source : `sw/example/main.c`. Il met en jeu les mêmes éléments qu'un
programme réel : une chaîne de caractères, une constante de 32 bits comparée
à une valeur reçue, et une valeur copiée dans une variable locale.

Le compiler et regarder où le compilateur range chacun :

```
python3 xp/0_3_dump/xp.py --example
```

- `lst/example.lst` est le désassemblage, **avec les noms** (le
  listing d'un dump brut n'en aura pas). Y repérer :
  - `key_check` : la constante `EXAMPLE_KEY` (`0x12345678`), construite par
    `lui` puis `addi`, et comparée par `beq`/`bne` ;
  - `stack_copy` : la valeur rangée dans la pile par `sw ..., N(x2)`, après
    `addi x2, x2, -M` (le registre `x2` est `sp`) ;
  - `MESSAGE` : la chaîne, dont on lit l'adresse.
- `example.txt` est l'image mémoire en hexadécimal : y retrouver les
  octets de la chaîne et leur adresse.

**À valider :** pour l'exemple, l'adresse de `MESSAGE`, la valeur de
`EXAMPLE_KEY` reconstruite à partir de `lui`/`addi`, et l'adresse où
`stack_copy` écrit dans la pile.

### Étape 2 : la clé du code

On applique la même lecture au programme inconnu. Compléter d'abord `dump()`
dans `xp.py` : envoyer `NUM = 1`, puis `DUMP` avec l'adresse et la taille, et
retourner la réponse. Le bootloader rend ensuite la main au processeur.

Retrouver ensuite la clé dans le dump, comme `EXAMPLE_KEY` à l'étape 1 :

- dans `dump/code.txt`, trouver la chaîne `secret_key` et son adresse ;
- dans `dump/code.lst`, trouver l'instruction qui utilise cette adresse ;
- juste à côté, trouver la constante à laquelle la valeur reçue est
  comparée, et l'écrire dans `SECRET_KEY`.

**À valider :** l'adresse de la chaîne, les instructions qui l'utilisent et
qui construisent la constante, la valeur de la clé et la réponse
`secret_key: OK`.

### Étape 3 : la clé de la pile

Comme `stack_copy` à l'étape 1, la commande `H` lit le registre `KEY_0_DATA`
et en garde une copie dans la pile. Après le reset, le bootloader relit le
haut de la mémoire dans `dump/stack.txt` : la mémoire n'est pas effacée par
un reset.

- Dans `dump/code.lst`, trouver la lecture de `0x10000300` et l'instruction
  qui range la valeur lue dans la pile (`sw ..., <décalage>(x2)`).
- En déduire l'adresse de la copie : `sp` vaut `0x4000` au démarrage
  (`sw/common/src/start.S`), puis chaque fonction le diminue de la taille de
  sa pile (`addi x2, x2, -N`).
- Lire la valeur à cette adresse dans `dump/stack.txt`, et l'écrire dans
  `HW_KEY`.

**À valider :** l'adresse de la copie, la valeur de la clé et la réponse
`hw_key: OK`.

### Étape 4 : la rémanence de la mémoire

Si la copie de l'étape 3 est encore lisible après le reset, c'est que le
reset **n'efface pas** la RAM : c'est la *rémanence*. Un secret écrit par une
exécution reste en mémoire pour la suivante. Un produit qui se contente d'un
reset entre deux utilisateurs laisse donc fuir les secrets du précédent.

On le met en évidence avec `--residue`. Compléter d'abord `HW_COPY_ADDR` avec
l'adresse de la copie trouvée à l'étape 3, puis :

```
python3 xp/0_3_dump/xp.py --residue
```

Le script, juste après avoir programmé le FPGA :

1. lit la pile par `DUMP` (la copie est absente) ;
2. démarre le programme et envoie `H` : il copie la clé dans la pile ;
3. fait un reset, puis relit la pile : la copie est toujours là.

La lecture se fait par le bootloader (`DUMP`), pas par un programme : un
programme injecté aurait sa propre pile tout en haut de la RAM et écraserait
justement la copie. Ce qui efface la RAM, c'est la **reprogrammation** du
FPGA, qui la recharge depuis le bitstream (copie absente), pas le reset.

**À valider :** les deux valeurs (copie absente après la programmation,
présente après un run et un reset), et l'explication : pourquoi le reset ne
suffit-il pas à effacer un secret ? Dans quels cas la rémanence est-elle un
problème pour un vrai produit ? (Les contre-mesures — effacement de la pile,
RAM vidée au reset — sont vues dans une autre partie du cours.)

### Étape 5 : lire la clé matérielle sans le programme

Les étapes 2 et 3 suivent ce que fait le programme. Mais le bootloader n'est
pas limité à la RAM : il accède au même bus que le processeur, donc à tous
les périphériques, et il charge n'importe quel programme. Deux accès plus
directs à la clé matérielle :

1. **`DUMP` du registre** : compléter `key_dump()` dans `xp.py`, qui lit les
   `KEY_SIZE` octets à l'adresse `KEY_ADDR` (`0x10000300`) avec `dump()` et
   les convertit en entier.
2. **Injection de code** : compléter `sw/inject/main.c`, un programme qui
   envoie `KEY_0_DATA` sur l'UART (4 octets) à chaque octet reçu, puis
   `inject()` dans `xp.py`, qui le charge à l'adresse 0 comme dans 0_2_boot :
   `NUM = 2`, `INIT`, puis `PING`, dont la réponse arrive une fois toute
   l'image reçue.

```
python3 xp/0_3_dump/xp.py --no-prog --direct
```

Le script compile `sw/inject`, fait le `DUMP` du registre, puis un reset,
l'injection et la lecture de la clé envoyée par le programme injecté.

Le programme injecté remplace celui du bitstream dans la RAM : pour refaire
les étapes 2 à 4, relancer le script sans `--no-prog` (voir 0_2_boot,
étape 4).

**À valider :** la clé lue par les deux méthodes, le nombre de lignes de C
écrites pour l'injection, et pour chacune des quatre attaques (clé du code,
copie dans la pile, `DUMP` du registre, injection) une protection qui
l'empêche. Laquelle les empêche toutes ? Une clé que le logiciel ne peut
pas lire peut-elle quand même servir ?

## Validation

En séance, faire valider chaque étape par l'enseignant. En autonomie, le
corrigé et les résultats attendus sont dans `xp/S0_3_dump/` sur la branche
principale du dépôt.

## Aide

- `lui xN, A` met `A << 12` dans `xN`, puis `addi xN, xN, B` ajoute `B` :
  la constante vaut `(A << 12) + B`. `B` est signé sur 12 bits.
- Le désassemblage écrit les valeurs immédiates en décimal : une adresse
  peut apparaître sous la forme `li x13, 536`, soit `0x218`.
- Dans `dump/*.txt`, les octets sont dans l'ordre de la mémoire : en
  little-endian, le mot `0x12345678` apparaît `78 56 34 12`.
