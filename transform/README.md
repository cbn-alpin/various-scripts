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
  - Si vous utilisez une version de Python différente du système, il se peut
que vous ne puissiez pas construire correctement les dépendances depuis
les sources. Vous pouvez utiliser dans ce cas la commande suivante qui force l'installation des
fichiers binaires :
    - `PIP_ONLY_BINARY=ALL pipenv install`
  - Voir également [la note d'aide sur Pyenv, Pipx et Pipenv](https://wiki-intranet.cbn-alpin.fr/informatique/aides/langages/python/pyenv-pipx-et-pipenv)
- Vérifier que le script `bin/transformer.py` est bien un lien symbolique
pointant vers `../transformer/runner.py`
  - Si ce n'est pas le cas, il faut le recréer :
  `cd bin/ ; ln -s ../transformer/runner.py transform.py`


## Utiliser le parser

- Lancer une seule commande : `pipenv run python ./bin/transform.py <args-opts>`
- Lancer plusieurs commandes :
  - Activer l'environnement virtuel : `pipenv shell`
  - Lancer ensuite les commandes : `python ./bin/transform.py <args-opts>`
  - Pour désactiver l'environnement virtuel :
  `exit` (`deactivate` ne fonctionne pas avec `pipenv`)

### Plugins disponibles

- PIFH : `pipenv run python ./bin/transform.py ~/Data/pifh/photos/ -o 2022-04-26_pifh_img_for_gn.csv -p pifh_img -c ./config/pifh_img.ini`
- AJARIS (SINP AURA): `pipenv run python ./bin/transform.py ./data/2022-04-26_ajaris_export.csv -o 2022-04-26_ajaris_for_gn.csv -p ajaris -c ./config/ajaris_aura.ini`
- AJARIS (Flore Sentinelle): `pipenv run python ./bin/transform.py ./data/2022-11-16_ajaris_export_scalp.csv -o 2022-11-16_ajaris_scalp_for_gn.csv -p ajaris -c ./config/ajaris_floresentinelle.ini`

## Développement : préparation de l'espace de travail

Sous Debian Buster :
```bash
cd transform/
pip3 install --user pipenv
pipenv install click colorama
```
