# Script de modification de fichiers


Script CLI Python 3 transformant un fichier en entrée vers un nouveau format.

## Mise en place

- Mettre à jour les fichiers de configuration.
- Installer Pipenv : ```pip3 install --user pipenv```
- Ajouter le code suivant au fichier `~/.bashrc` :

```
# Add ~/.local/bin to PATH (Pipenv)
if [ -d "${HOME}/.local/bin" ] ; then
    PATH="${HOME}/.local/bin:$PATH"
fi
```

- Recharger le fichier `~/.bashrc` avec la commande : `source ~/.bashrc`
- **Notes** : il est nécessaire de donner les droits d'execution à GCC pour
tout le monde si l'on veut pouvoir installer correctement le venv
avec `sudo chmod o+x /usr/bin/gcc`. Une fois l'installation terminée,
retirer les à nouveau avec  `sudo chmod o-x /usr/bin/gcc`.
- Installer les dépendances :
  - `pipenv install`
- Vérifier que le script `bin/transformer.py` est bien un lien symbolique
pointant vers `../transformer/runner.py`
  - Si ce n'est pas le cas, il faut le recréer :
  `cd bin/ ; ln -s ../transformer/runner.py transformer.py`


## Utiliser le parser

- Lancer une seule commande : `pipenv run python ./bin/transformer.py <args-opts>`
- Lancer plusieurs commandes :
  - Activer l'environnement virtuel : `pipenv shell`
  - Lancer ensuite les commandes : `python ./bin/transformer.py <args-opts>`
  - Pour désactiver l'environnement virtuel :
  `exit` (`deactivate` ne fonctionne pas avec `pipenv`)

### Plugins disponibles

- PIFH : `pipenv run python ./bin/transform.py ~/Data/pifh/photos/ -o 2022-04-26_pifh_img_for_gn.csv -p pifh_img -c ./config/pifh_img.ini`
- AJARIS : `pipenv run python ./bin/transform.py ./data/2022-04-26_ajaris_export.csv -o 2022-04-26_ajaris_for_gn.csv -p ajaris`

## Développement : préparation de l'espace de travail

Sous Debian Buster :
```bash
cd transform/
pip3 install --user pipenv
pipenv install click colorama
```
