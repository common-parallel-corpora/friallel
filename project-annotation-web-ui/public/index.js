// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-analytics.js";
import { doc, getDoc, updateDoc, Timestamp, arrayUnion, getDocs, setDoc, getFirestore, enableIndexedDbPersistence, collection, query, where, FieldValue } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-firestore.js";
import { getDatabase, ref, onValue } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-database.js";
import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-auth.js";

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBQja_MCcubMhjmJYhKI50H_Nzn8SkUwgY",
  authDomain: "fs-2022-003-mtannotation.firebaseapp.com",
  databaseURL:
    "https://fs-2022-003-mtannotation-default-rtdb.firebaseio.com",
  projectId: "fs-2022-003-mtannotation",
  storageBucket: "fs-2022-003-mtannotation.appspot.com",
  messagingSenderId: "82914623747",
  appId: "1:82914623747:web:80acd4fb0d31df013ca936",
  measurementId: "G-LXY5Y1HL47",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const firestore = getFirestore(app);
var currentUser;
var translations = [];
var translationsIndex = 0;

const auth = getAuth();

console.log("before enableIndexedDbPersistence");
enableIndexedDbPersistence(firestore)
  .catch((err) => {
      if (err.code == 'failed-precondition') {
        console.log("Unable to enable offline db");
          // Multiple tabs open, persistence can only be enabled
          // in one tab at a a time.
          // ...
      } else if (err.code == 'unimplemented') {
          // The current browser does not support all of the
          // features required to enable persistence
          // ...
          console.log("offline db not implemented");
      }
  });
// ---------------------------------------------------------


// Collections name
const TRANSLATION_TASKS = "tanslation-tasks"; //TODO rename tanslation-tasks translation-tasks
const USERS = "users";
const DATASET_FLORES_DEV = "dataset-flores-dev";
const DATASET_FLORES_DEVTEST = "dataset-flores-devtest";
const LANG_ENCODING = "nqo_Nkoo";
const COMPLETED_TASK_STATUS = "completed";
const UNASSIGNED_TASK_STATUS = "unassigned";


/**
 * SYNCHRONISATION STATE
 */

const database = getDatabase();
const connectedRef = ref(database, ".info/connected");
onValue(connectedRef, (snap) => {
  if (snap.val() === true) {
    $("#connection-state").removeClass("synchro-light-offline");
    $("#connection-state").addClass("synchro-light-online");
    
  } else {
    $("#connection-state").removeClass("synchro-light-online");
    $("#connection-state").addClass("synchro-light-offline");
  }
});

/**
 * UTILISATEUR
 */

// Sauvegarde
const saveUser = async(user) => {
  const userRef = doc(firestore, "users", user.uid);
  const userSnap = await getDoc(userRef);
  if(!userSnap.exists()) {
      const newRef = doc(firestore, 'users', user.uid); //TODO check with line #82
      setDoc(newRef, { name: user.displayName, isActiveTranslator:false, email:user.email }, { merge: true });
  }
  currentUser["firestoreUser"] = userSnap.data()

}
// Mise à jour interface et redirection
const redirectToLogin = function(){
  window.location.href = 'login/login.html';
}
onAuthStateChanged(auth, (user) => {
  if(!user){
    // User is signed out.
    redirectToLogin()
    return;
  }
  currentUser = user;
  saveUser(currentUser);
  $("#username").html(currentUser.displayName);
  $("#photo").attr("src", currentUser.photoURL);
  
  getTranslationTask();
});
//---------------------

/**
 * DATA
 */

var currentTask = null;
var currentTranslation = null;
var defaultLanguage = "eng_Latn";

/* const loadData = async(index) => {
  if(currentUser) {
    if(translations.length > 0) {
      const docRef = doc(firestore, translations[index].collection_id, translations[index].document_id);
      const docSnap = await getDoc(docRef);
      const doc_data = docSnap.data();
    
      // TODO: change this to tranSlations
      doc_data.tranlations.forEach(translation => {
        const selector = "#" + `txt-${translation.lang}`;
        console.log("Selector", selector);
        console.log("Value", translation.translation);
        $(selector).text(
          translation.translation
        );
      });
    }
  }
} */
// translation in spécific language for logged user
const loadTranslation = async(task) => {
  if(!currentUser) {
    redirectToLogin()
    return;
  }
  var taskData = task ? task.data() : null;
  if(!taskData || !taskData?.collection_id || !taskData?.document_id){
    console.error("error:: task not conform. Task : ", taskData);
    return;
  }

  const docRef = doc(firestore, taskData.collection_id, taskData.document_id);
  const docSnap = await getDoc(docRef);

  

  if(docSnap.exists()){
    var currentTranslations = [];
    var res = docSnap.data();
    if(res?.tranlations != null){
      let trans = null;
      let neededLangs = currentUser.firestoreUser?.translation_from_languages?.length > 0 ? currentUser.firestoreUser.translation_from_languages : [defaultLanguage]
      for(trans of res.tranlations) {
        if(neededLangs.includes(trans?.lang)){
          currentTranslations.push({
            lang : trans.lang,
            translation: trans.translation
          });
        }
      }
      updateView(currentTranslations);
    }
  }
  console.log("ui:: currentTranslation : ", currentTranslations);
}

// Get user first translation task
const getTranslationTask = async() => {
  showLoader();
  const tasksQry = query(
    collection(firestore, TRANSLATION_TASKS), 
    where("assignee_id", "==", currentUser.uid), 
    where("status", "==", "assigned")
  );
  const tasksQrySnap = await getDocs(tasksQry);
  if(tasksQrySnap.docs.length > 0){
    currentTask = tasksQrySnap.docs[0];
    console.log("currentTask", currentTask)
    loadTranslation(currentTask);
  }
}

/**
 * VIEW
 */

const buildTranslationSourceDom = function(uiTranslation) {
  return "<div class=\"text-to-translate\"><p>" + uiTranslation.translation + "<p></div>";
}

const updateView = function(currentTranslations){
  if(!currentTranslations || !(currentTranslations.length > 0)){
    return;
  }

  let uiTranslationSourcesDom = ""
  currentTranslations.forEach ( uiTranslation => {
    uiTranslationSourcesDom += buildTranslationSourceDom(uiTranslation);
  })
  $("#translation_sources").html(uiTranslationSourcesDom);
  $("#resulttext").val('');
  hideLoader();
}

$( "#validate_btn" ).click(function() {
  let translationValue = $("#resulttext").val().trim();
  console.log("translationValue", translationValue)
  if (translationValue.length > 0) {
    currentInteraction = InteractionType.UPDATE_TRANSLATE;
    confirmationModal.show();
    //saveTranslation(translationValue)
  }
});

const actionSaveTranslation = function(){
  let translationValue = $("#resulttext").val().trim();
  console.log("Sauvegarde declenché sur le text : ", translationValue);
  showLoader()
  saveTranslation(translationValue);
  currentInteraction = null;
}
const actionSkipTranslation = function(){
  console.log("Ignorer la traduction declenché sur le text");
  showLoader();
  updateTranslationTask(UNASSIGNED_TASK_STATUS);
  currentInteraction = null;
}

// INTERACTION VALIDATION
const InteractionType = {
	SKIP: {
    MESSAGE: "Voulez vous ignorez la traduction courante ?",
    VALUE: 0,
    ACTION: actionSkipTranslation
  },
	UPDATE_TRANSLATE: {
    MESSAGE: "Confirmez vous la soumission de la traduction ?",
    VALUE: 1,
    ACTION: actionSaveTranslation
  }
};
var currentInteraction = null;
// -----------------------------------------------------------------

const saveTranslation = async function(translationValue) {
  var taskData = currentTask ? currentTask.data() : null;
  if(!taskData || !taskData?.collection_id || !taskData?.document_id){
    console.error("error:: task not conform. Task : ", taskData);
    return;
  }
  const docRef = doc(firestore, taskData.collection_id, taskData.document_id);

  console.log("docRef",docRef)

  //TODO format date for firestore
  let now = Timestamp.fromDate(new Date());//Date.now();

  //TODO tranlations to translations
  await updateDoc(docRef, {
    tranlations: arrayUnion( {
      created : now,
      lang : LANG_ENCODING,
      translation : translationValue,
      updated : now,
      user_id : currentUser.uid,
    })
  }).then(docRef => {
    alert("Translation added successfully");
    updateTranslationTask(COMPLETED_TASK_STATUS)
  })
  .catch(error => {
      hideLoader();
      console.log(error);
  });
}

const updateTranslationTask = async function(status) {

  var taskData = currentTask ? currentTask.data() : null;
  if(!taskData || !taskData?.collection_id || !taskData?.document_id){
    console.error("error:: task not conform. Task : ", taskData);
    return;
  }

  var taskData = currentTask ? currentTask.data() : null;

  const docRef = doc(firestore, TRANSLATION_TASKS, currentTask.id);

  await updateDoc(docRef, {
    status: status
  }).then(docRef => {
    console.log("Translation task updated successfully");
    getTranslationTask();
  })
  .catch(error => {
      hideLoader();
      console.log(error);
  });
}

const confirmationModal = new bootstrap.Modal('#confirmationModal', {});
//const confirmationModalDOM = document.getElementById('confirmationModal');
const confirmationModalDOM = $("#confirmationModal");

confirmationModalDOM.on("show.bs.modal", event => {
  console.log("modal:: etat: Demande d'ouverture");
  if(InteractionType != null){
    $("#confirmationModalMessage").html(currentInteraction.MESSAGE);
  }
});

$( "#skip_btn" ).click(function() {
  currentInteraction = InteractionType.SKIP;
  confirmationModal.show();
});
$( "#modal-confirm-btn" ).click(function() {
  currentInteraction.ACTION();
});




// Spinner
const hideLoader = function() {
  $("#spinners").addClass("hide");
}
const showLoader = function() {
  $("#spinners").removeClass("hide");
}