# fs-2022-003-mtannotation


# Prepare data
```
make data/flores200_dataset
```

# Setup Firebase Service Account
```
https://console.firebase.google.com/u/0/project/_/settings/serviceaccounts/adminsdk
```

# Firebase instructions - Alias={dev, prod}
```
firebase use {alias}
firebase use {project}
firebase apps:list
firebase projects:list
firebase use --add
firebase deploy -P {alias}
firebase deploy --only firestore:indexes
```

# Firebase - How to export all current indexes
```
firebase firestore:indexes
```

# Deploy Annotation to Project
- Setup firebase to production environment
- Deploy UI
- Deploy Indexes
- Deploy Functions
- Review Security Rules
- Execute scripts & functions
    - Load Dataset
    - Create workflows
    - Optional : Run workflow-manager to create annotation tasks (translations)
    - Optionla : Import Offline translations 

# Process de test : PS conserver l’index dans la traduction par soucis de traçabilités 

Traductions : 
	Traitement par bloc : 
	1 - 30 : Ignorer les traductions;
	31 - 100 : Toutes les phrases sont à traduire 

Vérifications N1 : 
	Traitement par bloc : 
	1 - 50 : Valider toutes les traductions
	51 - 100 : Refuser toutes les traductions et soumettre de nouvelles

Vérification N2 : 
	Traitement par bloc :
	1 - 25 : Valider toutes les traductions (2/2 validations, fin de process)
	26 - 50 : Refuser toutes les validations (1/2 validation -> Niveau 3)
	51 - 75 : Valider toutes les traductions (1/2 validation -> Niveau 3)
	76 - 100 : Refuser toutes les traductions (0/2 validation -> Niveau 3)

Vérification N3 : 
	Toutes les phrases reçoivent une traduction définitive (fin de process)

