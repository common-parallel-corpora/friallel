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

https://docs.google.com/document/d/1_DSWB4sEAa5hQDEfnxq128vgKVgYFXRmVztWWC_uY4U/edit#

