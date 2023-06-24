E# Deploiement Read Me
## Configuration Firebase

Aller sur https://firebase.google.com/

Si vous n'avez pas de compte, créer en un, puis connectez vous.

<img src="Images/FR/001.png" width="256"/>

Aller dans la console firebase via l'invite suivante:

<img src="Images/FR/002.png" width="256"/>

Vous arrivez sur la page des projets.

### Création du projet
Creez un nouveau projet 

<img src="Images/FR/003.png" width="256"/>

1. Donner un nom au projet
2. Decider de l'utilisation de Google Analytics (Optionnel pour le projet) 
3. Valider

Après validation votre projet est créer et prêt pour utilisation. Cliquer sur continuer. Firebase ouvre par defaut votre projet.

### Création de l'application WEB

1. Creer une application via le bouton

<img src="Images/FR/004.jpeg" width="256"/>

2. Donner un nom à l'application (Exp : appli-test), et enregistrer l'applicaion

Firebase vous propose d'ajouter le SDK firabase (ajouter Firebase à votre application). Ce qui vous interesse c'est la configuration firebase.

<img src="Images/FR/005.jpeg" width="256"/>

Acceder à la console via le bouton proposé.

### Installation des dépendances

Acceder à toutes les dépendances via le bouton acceder à tous les produits 

<img src="Images/FR/006.jpeg" width="256"/>

Ensuite installer les produits encadrés qui sont : 

<img src="Images/FR/007.jpeg" width="256"/>

#### Authentication

Cliquer sur commencer

<img src="Images/FR/008.jpeg" width="256"/>

Il vous est proposé un ensemble de moyen de conncetion, nous vous recommandons d'utiliser google comme sur l'image 009;
Configurer google:

<img src="Images/FR/010.jpeg" width="256"/>

1. Activer l'option
2. Configurer une adresse d'assistance
3. Valider 

Si tout se passe bien vous devez avoir ce résultat

<img src="Images/FR/011.jpeg" width="256"/>

#### Cloud Firestore

Cliquer sur créer une base de données

<img src="Images/FR/012.jpeg" width="256"/>

Sur la page de configuration, sélectionner le mode production puis cliquer sur suivant.

<img src="Images/FR/013.jpeg" width="256"/>

Ensuite sélectionner l'emplacement de stockage de vos données (014) puis activer la base de données.

<img src="Images/FR/014.jpeg" width="256"/>

Si tout se passe bien vous devez avoir ce résultat 

<img src="Images/FR/015.jpeg" width="256"/>

#### Realtime database

Cliquer sur créer une base de données

<img src="Images/FR/016.jpeg" width="256"/>

Sélectionner l'emplacement de stockage de vos données puis cliquer sur suivant

<img src="Images/FR/017.jpeg" width="256"/>

Selectionner le mode vérrouillé puis cliquer sur Activer

<img src="Images/FR/018.jpeg" width="256"/>

Si tout se passe bien dous devez avoir ce résultat

<img src="Images/FR/019.jpeg" width="256"/>

#### Hosting

Cliquer sur Commencer

<img src="Images/FR/020.jpeg" width="256"/>

Les étapes suivantes vous indique la marche à suivre afin de pouvoir déployer votre application, les ligne de commande seront à executer pas à pas

<img src="Images/FR/021.jpeg" width="256"/>
<img src="Images/FR/022.jpeg" width="256"/>
<img src="Images/FR/023.jpeg" width="256"/>

A l'étape 3 cliquer sur acceder à la console

<img src="Images/FR/024.jpeg" width="256"/>

Si tout se passe bien vous devez avoir ce résultat 

<img src="Images/FR/024.jpeg" width="256"/>

## Configuration du Client UI

### Télécharger les sources du projet

### Accès à la configuration Firebase

Dépuis la console firebase, ouvrez votre projet

Acceder à l'application  via le raccourcie

<img src="Images/FR/025.jpeg" width="256"/>

Acceder aux paramètres de l'application depuis le raccourci

<img src="Images/FR/026.jpeg" width="256"/>

Une fois dans la paramètres 

<img src="Images/FR/027.jpeg" width="256"/>

scroller vers le bas jusqu'a la section Firebase config

## Vérification des installations

__________________________

## Envionrment de Dev et des sources 
### Installer les outils necessaires
- Télécharger et installer VSCode : https://code.visualstudio.com/
- Télécharger et installer NodeJS (version ???) : https://nodejs.org/en/download
- Installer Git : https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
- Configurer Git avec vos informations d'authentification 
- Télécharger et installer Python (version 3.10): 

### Recuperer et installer les sources  
- Configurer l'espace de travail sur votre ordinateur
- Se connecter sur Githut, utiliser le lien courant: "Missing Link"
- Telecharger les sources sur le repertoire de travail: git clone "Missing link"
- Ouvrir le repertoire du project dans VSCode et importer le projet
- Installer les librairies de Python : 
- Installer les dependances : npm install
- Configurer le projet local au projet Firebase créé préalablement
- Télécharger et installer la clé du projet Firebase (Ajouter une image)

### Description des sources installées
Le projet installé est divisé en 4 grands groupes:
1.  Data: localisé dans le dossier "data/" à la racine du projet, data contient les données (datasets) à charger en base de données. On y restrouve des données pour: Flores-Dev, NLLB, NTREX 
2. Scrips Python: localisé dans le dossier "scripts/" à la racine du projet, les scripts (Python) sert à transformer les datasets pour les charger en base dans la Firestore. Les scripts permettent aussi d'exporter les données et de genérer des rapports d'avancement sur les taches.
3. Projet UI: localisé dans le dossier "data/" depuis la racine du projet, il s'agit de l'application front qui permet à l'utilisateur (traducteur ou verificateur) de se connecter et d'effecter ces taches en fonction de leur roles. Cette aplication sera hébergé directement sur Firebase
4. Fonctions: localisé dans le dossier "./project-annotation-web-ui/functions" depuis la racine du projet
5. La base de données: déployé grace à la firestore, sa création initiale ne require aucune entrée d'enregistrement. Les données sont enregistrées progressivement grace l'upload des datasets, l'activité des utilisateurs sur l'interface web, ainsi que les fonctions cloud qui tournent en background.

## Deploiement sur l'environnement
### Context
Ajouter du contenu ...........

### 1. Preparation et chargement des données
Ajouter du contenu ...........

### 2. Mise à jour des indexes et regles Firebase
Ajouter du contenu ...........

### 3. Deploiment des fonctions
Ajouter du contenu ...........

### 4. Deploiment du projet
Ajouter du contenu ...........

