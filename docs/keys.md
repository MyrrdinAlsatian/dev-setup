# Configuration des clés SSH et GPG

Ce guide explique comment utiliser le script `setup-keys.sh` pour générer et configurer vos clés SSH et GPG pour GitHub et GitLab.

## Vue d'ensemble

Le script `setup-keys.sh` automatise la génération et la configuration de:
- **Clés SSH**: pour l'authentification Git via SSH
- **Clés GPG**: pour signer vos commits Git

## Prérequis

Le script vérifie automatiquement la présence des outils nécessaires:
- `ssh-keygen` (génération de clés SSH)
- `ssh-agent` et `ssh-add` (gestion de l'agent SSH)
- `gpg` (génération de clés GPG)
- `git` (configuration Git)

Si des dépendances sont manquantes, le script affichera des instructions d'installation adaptées à votre système d'exploitation.

## Utilisation

### Mode interactif (recommandé)

Le mode interactif vous guide à travers chaque étape:

```bash
cd dev-setup
./scripts/setup-keys.sh
```

Le script vous demandera:
1. Votre adresse e-mail
2. Votre nom complet (pour GPG)
3. Le type de clé SSH (ed25519 par défaut, ou RSA)
4. Le chemin de sauvegarde de la clé SSH
5. Si vous souhaitez ajouter une entrée dans `~/.ssh/config`
6. Si vous souhaitez configurer Git pour signer les commits

### Mode non-interactif

Pour une utilisation en scripts ou CI/CD, vous pouvez passer tous les paramètres en ligne de commande:

```bash
./scripts/setup-keys.sh \
    --email "votre.email@example.com" \
    --name "Votre Nom" \
    --ssh-type ed25519
```

## Options disponibles

| Option | Description | Défaut |
|--------|-------------|--------|
| `--email EMAIL` | Adresse e-mail (pour SSH et GPG) | Demandé interactivement |
| `--name NAME` | Nom complet (pour GPG et Git) | Demandé interactivement |
| `--ssh-path PATH` | Chemin de la clé SSH | `~/.ssh/id_ed25519` ou `~/.ssh/id_rsa` |
| `--ssh-type TYPE` | Type de clé SSH: `ed25519` ou `rsa` | `ed25519` |
| `--no-ssh` | Ne pas générer de clé SSH | - |
| `--no-gpg` | Ne pas générer de clé GPG | - |
| `--help` | Afficher l'aide | - |

## Types de clés SSH

### Ed25519 (recommandé par défaut)

Ed25519 est le type de clé par défaut car il offre:
- **Sécurité élevée**: équivalent à RSA 4096 bits
- **Performance**: plus rapide que RSA
- **Taille réduite**: clés plus courtes et plus faciles à gérer

```bash
./scripts/setup-keys.sh --ssh-type ed25519
```

### RSA 4096

Pour une compatibilité maximale ou des exigences spécifiques:

```bash
./scripts/setup-keys.sh --ssh-type rsa
```

Cela génère une clé RSA de 4096 bits, offrant un excellent niveau de sécurité.

## Exemples d'utilisation

### Générer uniquement une clé SSH

```bash
./scripts/setup-keys.sh --no-gpg --email "dev@example.com"
```

### Générer uniquement une clé GPG

```bash
./scripts/setup-keys.sh --no-ssh \
    --email "dev@example.com" \
    --name "Jean Dupont"
```

### Configuration complète avec RSA

```bash
./scripts/setup-keys.sh \
    --email "dev@example.com" \
    --name "Jean Dupont" \
    --ssh-type rsa \
    --ssh-path "~/.ssh/id_rsa_github"
```

### Mode automatique pour CI/CD

```bash
./scripts/setup-keys.sh \
    --email "$USER_EMAIL" \
    --name "$USER_NAME" \
    --ssh-type ed25519 \
    --no-gpg
```

## Ajouter les clés sur GitHub

### Clé SSH

1. Le script affichera votre clé publique SSH
2. Copiez la clé complète (elle commence par `ssh-ed25519` ou `ssh-rsa`)
3. Allez sur https://github.com/settings/keys
4. Cliquez sur **"New SSH key"**
5. Donnez un titre à votre clé (ex: "Laptop perso")
6. Collez votre clé publique
7. Cliquez sur **"Add SSH key"**

### Clé GPG

1. Le script affichera votre clé publique GPG
2. Copiez toute la clé (de `-----BEGIN PGP PUBLIC KEY BLOCK-----` à `-----END PGP PUBLIC KEY BLOCK-----`)
3. Allez sur https://github.com/settings/keys
4. Cliquez sur **"New GPG key"**
5. Collez votre clé publique
6. Cliquez sur **"Add GPG key"**

### Tester la connexion SSH

```bash
ssh -T git@github.com
```

Vous devriez voir un message de bienvenue de GitHub.

## Ajouter les clés sur GitLab

### Clé SSH

1. Le script affichera votre clé publique SSH
2. Copiez la clé complète
3. Allez sur https://gitlab.com/-/profile/keys
4. Collez votre clé publique dans le champ "Key"
5. Donnez un titre à votre clé
6. Cliquez sur **"Add key"**

### Clé GPG

1. Le script affichera votre clé publique GPG
2. Copiez toute la clé
3. Allez sur https://gitlab.com/-/profile/gpg_keys
4. Collez votre clé publique
5. Cliquez sur **"Add key"**

### Tester la connexion SSH

```bash
ssh -T git@gitlab.com
```

Vous devriez voir un message de bienvenue de GitLab.

## Configuration Git

Le script configure automatiquement Git pour:
- Définir `user.name` et `user.email` s'ils ne sont pas configurés
- Configurer `user.signingkey` avec votre clé GPG
- Activer la signature automatique des commits (`commit.gpgsign true`)

Vous pouvez vérifier votre configuration avec:

```bash
git config --global --list
```

## Sécurité

Le script applique les meilleures pratiques de sécurité:

### Permissions des fichiers

- **Répertoire `~/.ssh/`**: permissions `700` (rwx------)
- **Clés privées**: permissions `600` (rw-------)
- **Clés publiques**: permissions `644` (rw-r--r--)

### Validation des entrées

- Les adresses e-mail sont validées avec une regex
- Les entrées utilisateur sont "sanitisées" pour éviter l'injection de commandes
- Les chemins de fichiers sont nettoyés

### Agent SSH

Le script ajoute automatiquement votre clé à l'agent SSH, vous évitant de retaper votre passphrase à chaque utilisation.

### Configuration `~/.ssh/config`

Le script peut ajouter des entrées dans votre fichier `~/.ssh/config` pour GitHub et GitLab:

```
# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

Cela garantit que la bonne clé est utilisée pour chaque service.

## Gestion des clés existantes

Si vous avez déjà des clés SSH ou GPG:

- **Mode interactif**: le script vous demandera si vous souhaitez les remplacer
- **Mode non-interactif**: le script utilisera les clés existantes sans les remplacer

## Dépannage

### L'agent SSH ne démarre pas

Si vous recevez une erreur concernant l'agent SSH:

```bash
# Démarrer l'agent manuellement
eval "$(ssh-agent -s)"

# Ajouter votre clé
ssh-add ~/.ssh/id_ed25519
```

### La clé GPG n'est pas reconnue par Git

Vérifiez que la clé est bien configurée:

```bash
# Lister vos clés GPG
gpg --list-secret-keys --keyid-format LONG

# Vérifier la configuration Git
git config --global user.signingkey
```

### Erreur "Permission denied" lors du test SSH

Vérifiez que:
1. Votre clé publique est bien ajoutée sur GitHub/GitLab
2. Les permissions de votre clé privée sont correctes (`600`)
3. L'agent SSH a bien chargé votre clé (`ssh-add -l`)

### La clé GPG n'apparaît pas comme vérifiée sur GitHub

Assurez-vous que:
1. L'adresse e-mail de votre clé GPG correspond à celle de votre compte GitHub
2. L'adresse e-mail est vérifiée dans les paramètres de votre compte GitHub
3. Vous avez bien signé vos commits (`git commit -S`)

## Commandes utiles

### Lister vos clés SSH

```bash
ls -la ~/.ssh/
```

### Afficher votre clé publique SSH

```bash
cat ~/.ssh/id_ed25519.pub
```

### Lister vos clés GPG

```bash
gpg --list-keys
gpg --list-secret-keys
```

### Exporter votre clé publique GPG

```bash
gpg --armor --export votre.email@example.com
```

### Vérifier les clés chargées dans l'agent SSH

```bash
ssh-add -l
```

### Signer un commit manuellement

```bash
git commit -S -m "Votre message de commit"
```

## Ressources supplémentaires

- [Documentation GitHub - Connecting to GitHub with SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Documentation GitHub - Signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification)
- [Documentation GitLab - SSH Keys](https://docs.gitlab.com/ee/user/ssh.html)
- [Documentation GitLab - Signing commits with GPG](https://docs.gitlab.com/ee/user/project/repository/gpg_signed_commits/)

## Support

Pour toute question ou problème, veuillez [ouvrir une issue](https://github.com/MyrrdinAlsatian/dev-setup/issues) sur GitHub.
