# TP 0_0_sim : exécuter du code sur CALF en simulation

Le processeur CALF est simulé avec Verilator, à partir de ses sources
SystemVerilog (`src/main/sv`). Un programme C et assembleur, dans `sw/`, est
compilé, chargé dans la mémoire du processeur simulé et exécuté. La
simulation permet d'observer chaque signal du cœur, cycle par cycle, sans
carte.

Le but est d'écrire une fonction en assembleur RISC-V, puis d'observer son
exécution dans le cœur pour comprendre son fonctionnement.

## Mise en route

Prérequis : Verilator, le compilateur RISC-V `riscv64-unknown-elf-gcc` dans
le `PATH`, et GTKWave pour l'étape 3. Depuis la racine du dépôt :

```
python3 xp/0_0_sim/xp.py
```

Le script compile `sw/` (avec les fichiers communs de `sw/common`), construit
le simulateur dans `verilator/` au premier lancement, puis exécute le
programme jusqu'à la fin de `main()`. Il affiche ce que le programme envoie
sur l'UART, puis un bilan :

| Ligne | Signification |
|-------|---------------|
| `halt` | le programme s'est terminé (saut sur lui-même après `main()`) |
| `cycles` | cycles d'horloge exécutés |
| `instret` | instructions exécutées |
| `pc` | adresse de la dernière instruction |
| `a0` | registre `a0` à la fin : la valeur retournée par `main()` |

La compilation produit, dans `xp/0_0_sim/` : `elf/` (exécutable), `hex/`
(image mémoire) et surtout `lst/0_0_sim.lst`, le désassemblage complet du
programme, avec l'adresse de chaque instruction.

Fichiers du programme (`sw/main/`) :

| Fichier | Contenu |
|---------|---------|
| `main.c` | programme principal : appelle les fonctions et affiche les résultats |
| `main.h` | déclarations, `DATA_N` (taille du tableau) |
| `sum.S` | `asm_sum()`, à écrire (étape 2) |

## Avancement

Chaque partie à compléter est marquée par un commentaire `<TODO N>`, où `N`
est le numéro de l'étape : une fois la partie terminée, le remplacer par
`<DONE N>`, en gardant le numéro. La dernière ligne affichée par le script
donne l'avancement et la prochaine partie à faire, dans l'ordre des étapes ;
`python3 xp/0_0_sim/xp.py --progress` liste toutes les parties, faites ou non.

## Étapes

### Étape 1 : exécuter

Lancer la simulation sans rien modifier. `main()` remplit un tableau de 10
entiers (1 à 10), en calcule la somme en C avec `c_sum()`, l'affiche et la
retourne.

- Retrouver la valeur de `c_sum` dans le registre `a0` du bilan.
- Calculer le nombre moyen de cycles par instruction (CPI) :
  `cycles / instret`.
- Trouver `c_sum` dans `lst/0_0_sim.lst` (son nom commence par `c_sum`) et
  comparer avec le code C : où est passée la boucle ? Le programme est
  compilé avec `-O3` (`sw/common/build.py`).

**À valider :** `a0`, le CPI, et l'explication du code de `c_sum`.

### Étape 2 : écrire en assembleur

Écrire `asm_sum()` dans `sw/main/sum.S` : la même somme que `c_sum()`, en
assembleur RISC-V. Selon la convention d'appel, les arguments arrivent dans
`a0` (adresse du tableau) et `a1` (nombre d'éléments), et le résultat est
retourné dans `a0`. Les registres `t0` à `t6` sont libres.

**À valider :** `asm_sum = 55`, et le code de `asm_sum`.

### Étape 3 : observer le chronogramme

Relancer la simulation avec la trace des signaux et l'ouvrir dans GTKWave,
avec la sélection de signaux fournie (`sim/verilator/calf.gtkw`) :

```
python3 xp/0_0_sim/xp.py --wave
```

`-t` enregistre seulement la trace, dans `vcd/0_0_sim.vcd`, qui s'ouvre
ensuite avec `gtkwave xp/0_0_sim/vcd/0_0_sim.vcd sim/verilator/calf.gtkw`.

`fsm_r` est l'état du séquenceur du cœur (`calf_core_fsm.sv`) :

| `fsm_r` | État | Rôle |
|---------|------|------|
| 1 | `IF0` | demande de lecture de l'instruction à `pc` |
| 2 | `IF1` | réception de l'instruction |
| 3 | `ID` | décodage, lecture des registres |
| 4 | `ALU` | calcul |
| 5 | `BRU` | branchement : condition et adresse de destination |
| 6 | `AG` | calcul de l'adresse d'un accès mémoire |
| 7 | `MA0` | demande d'accès mémoire |
| 8 | `MA1` | fin de l'accès mémoire |
| 9 | `CSR` | accès à un registre CSR (`rdcycle`) |
| 10 | `WB` | écriture du résultat dans le registre destination |

Repérer dans `lst/0_0_sim.lst` les adresses des instructions de la boucle de
`asm_sum` (étape 2). Dans GTKWave, chercher ces valeurs de `pc_r` et relever,
cycle par cycle, la suite des états de `fsm_r` et les signaux du bus mémoire
(`mem_valid_o`, `mem_addr_o`, `mem_ready_i`) pour un `add` (ou `addi`), un
`lw` et un branchement.

**À valider :** la suite des états et le nombre de cycles de chacune de ces
instructions, et le lien avec le CPI de l'étape 1.

## Validation

En séance, faire valider chaque étape par l'enseignant. En autonomie, le
corrigé et les résultats attendus sont dans `xp/S0_0_sim/` sur la branche
principale du dépôt.

## Aide

- Une étiquette numérique (`1:`) peut être définie plusieurs fois :
  `1f` désigne la prochaine étiquette `1` (*forward*), `1b` la précédente
  (*backward*) : `j 1b` revient au début d'une boucle étiquetée `1:`.
- `lw t1, 0(a0)` lit le mot à l'adresse `a0`, `addi a0, a0, 4` passe au mot
  suivant.
- `python3 xp/0_0_sim/xp.py --help` donne les autres options (nombre maximal
  de cycles).
- Le programme n'appelle pas `uart_init()` : l'UART garde son débit de reset,
  celui du simulateur.
