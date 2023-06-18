E# Deploiement Read Me
## Configuration Firebase

Aller sur https://firebase.google.com/

Si vous n'avez pas de compte, créer en un, puis connectez vous.

<img src="Captures/001.png" width="256"/>

Aller dans la console firebase via l'invite suivante:

<img src="Captures/002.png" width="256"/>

Vous arrivez sur la page des projets.

### Création du projet
Creez un nouveau projet 

<img src="Captures/003.png" width="256"/>

1. Donner un nom au projet
2. Decider de l'utilisation de Google Analytics (Optionnel pour le projet) 
3. Valider

Après validation votre projet est créer et prêt pour utilisation. Cliquer sur continuer. Firebase ouvre par defaut votre projet.

### Création de l'application WEB

1. Creer une application via le bouton

<img src="Captures/004.jpeg" width="256"/>

2. Donner un nom à l'application (Exp : appli-test), et enregistrer l'applicaion

Firebase vous propose d'ajouter le SDK firabase (ajouter Firebase à votre application). Ce qui vous interesse c'est la configuration firebase.

<img src="Captures/005.jpeg" width="256"/>

Acceder à la console via le bouton proposé.

### Installation des dépendances

Acceder à toutes les dépendances via le bouton acceder à tous les produits 

<img src="Captures/006.jpeg" width="256"/>

Ensuite installer les produits encadrés qui sont : 

<img src="Captures/007.jpeg" width="256"/>

#### Authentication

Cliquer sur commencer

<img src="Captures/008.jpeg" width="256"/>

Il vous est proposé un ensemble de moyen de conncetion, nous vous recommandons d'utiliser google comme sur l'image 009;
Configurer google:

<img src="Captures/010.jpeg" width="256"/>

1. Activer l'option
2. Configurer une adresse d'assistance
3. Valider 

Si tout se passe bien vous devez avoir ce résultat

<img src="Captures/011.jpeg" width="256"/>

#### Cloud Firestore

Cliquer sur créer une base de données

<img src="Captures/012.jpeg" width="256"/>

Sur la page de configuration, sélectionner le mode production puis cliquer sur suivant.

<img src="Captures/013.jpeg" width="256"/>

Ensuite sélectionner l'emplacement de stockage de vos données (014) puis activer la base de données.

<img src="Captures/014.jpeg" width="256"/>

Si tout se passe bien vous devez avoir ce résultat 

<img src="Captures/015.jpeg" width="256"/>

#### Realtime database

Cliquer sur créer une base de données

<img src="Captures/016.jpeg" width="256"/>

Sélectionner l'emplacement de stockage de vos données puis cliquer sur suivant

<img src="Captures/017.jpeg" width="256"/>

Selectionner le mode vérrouillé puis cliquer sur Activer

<img src="Captures/018.jpeg" width="256"/>

Si tout se passe bien dous devez avoir ce résultat

<img src="Captures/019.jpeg" width="256"/>

#### Hosting

Cliquer sur Commencer

<img src="Captures/020.jpeg" width="256"/>

Les étapes suivantes vous indique la marche à suivre afin de pouvoir déployer votre application, les ligne de commande seront à executer pas à pas

<img src="Captures/021.jpeg" width="256"/>
<img src="Captures/022.jpeg" width="256"/>
<img src="Captures/023.jpeg" width="256"/>

A l'étape 3 cliquer sur acceder à la console

<img src="Captures/024.jpeg" width="256"/>

Si tout se passe bien vous devez avoir ce résultat 

<img src="Captures/024.jpeg" width="256"/>

## Configuration du Client UI

### Télécharger les sources du projet

### Accès à la configuration Firebase

Dépuis la console firebase, ouvrez votre projet

Acceder à l'application  via le raccourcie

<img src="Captures/025.jpeg" width="256"/>

Acceder aux paramètres de l'application depuis le raccourcie

<img src="Captures/026.jpeg" width="256"/>

Une fois dans la paramètres 

<img src="Captures/027.jpeg" width="256"/>

scroller vers le bas jusqu'a la section Firebase config

## Vérification des installations
