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