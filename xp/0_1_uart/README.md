# TP 0_1_uart : premier échange avec CALF

Le bitstream `bit/0_1_uart.bit` contient le processeur CALF et, dans sa
mémoire, un programme C déjà compilé. Ce programme communique avec le PC par
une liaison série (UART, 9600 bauds) qui passe par le ChipWhisperer Husky.

Le but est de compléter le script Python `xp.py` pour échanger des données
avec ce programme, en deux étapes.

## Mise en route

Brancher la CW312T-A35 sur le Husky, puis lancer depuis la racine du dépôt :

```
python3 xp/0_1_uart/xp.py
```

Le script programme le FPGA, règle l'horloge de CALF (25 MHz, sortie HS2 du
Husky) et fait un reset : le programme démarre. La programmation du FPGA prend
quelques secondes ; une fois le FPGA programmé, `--no-prog` permet de s'en
passer (le reset suffit à relancer le programme).

Le script fournit un objet `uart` :

| Méthode | Rôle |
|---------|------|
| `uart.write(data)` | envoie les octets `data` (`bytes`) |
| `uart.read(n, timeout=1.0)` | attend `n` octets, renvoie un `bytes` (plus court si le délai expire) |

Les entiers de 32 bits sont échangés en **little-endian** (octet de poids
faible en premier), comme dans la mémoire de CALF.

## Avancement

Chaque partie à compléter est marquée par un commentaire `<TODO N>`, où `N`
est le numéro de l'étape : une fois la partie terminée, le remplacer par
`<DONE N>`, en gardant le numéro. La dernière ligne affichée par le script
donne l'avancement et la prochaine partie à faire, dans l'ordre des étapes ;
`python3 xp/0_1_uart/xp.py --progress` liste toutes les parties, faites ou non.

## Étapes

### Étape 1 : recevoir

Au démarrage, CALF envoie l'adresse du coffre, un entier de 32 bits : 4
octets. Compléter `step_1()` pour les lire, les convertir en entier, afficher
l'adresse en hexadécimal et la retourner.

**À valider :** l'adresse du coffre affichée par le script.

### Étape 2 : envoyer

Envoyer l'octet `'R'` suivi de l'adresse du coffre (4 octets) : CALF renvoie
le mot de 32 bits rangé à cette adresse (4 octets). Compléter `step_2()` pour
envoyer la commande, lire la réponse et afficher le contenu du coffre en
hexadécimal. La LED 0 de la carte change d'état à chaque commande `'R'`.

**À valider :** le contenu du coffre affiché par le script.

## Validation

En séance, faire valider chaque étape par l'enseignant. En autonomie, le
corrigé et les résultats attendus sont dans `xp/S0_1_uart/` sur la branche
principale du dépôt.

## Aide

- `int.from_bytes(data, "little")` convertit des octets little-endian en
  entier ; `x.to_bytes(4, "little")` fait l'inverse, sur 4 octets. Par
  exemple, `b"\x44\x01\x00\x00"` donne `0x144`, et réciproquement.
- `b"R" + x.to_bytes(4, "little")` colle la commande et son argument.
- `f"0x{x:08x}"` écrit un entier en hexadécimal sur 8 chiffres.
- Si `uart.read(4)` renvoie moins de 4 octets, la carte n'a rien envoyé :
  relancer avec `--no-prog` pour repartir d'un reset.
