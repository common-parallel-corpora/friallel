// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-analytics.js";
import { doc, getDoc, getDocs, setDoc, getFirestore, enableIndexedDbPersistence, collection, query, where } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-firestore.js";
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
const TRANSLATION_TASKS = "tanslation-tasks";
const USERS = "users";
const DATASET_FLORES_DEV = "dataset-flores-dev";
const DATASET_FLORES_DEVTEST = "dataset-flores-devtest";

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
  const usersRef = doc(firestore, "users", user.uid);
  const usersSnap = await getDoc(usersRef);
  if(!usersSnap.exists()) {
      const newRef = doc(firestore, 'users', user.uid);
      setDoc(newRef, { name: user.displayName, isActiveTranslator:false, email:user.email }, { merge: true });
  }
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

const loadData = async(index) => {
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
}
// translation in spécific language for logged user
const loadTranslation = async(task, lang) => {
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
    currentTranslation = null;
    var res = docSnap.data();
    if(res?.tranlations != null){
      let trans = null;
      for(trans of res.tranlations){
        if(lang != null && trans?.lang == lang){
          currentTranslation = trans;
          updateView();
        }
      }
    }
  }
  console.log("ui:: currentTranslation : ", currentTranslation);
}

// Get user first translation task
const getTranslationTask = async() => {
  const tasksQry = query(
    collection(firestore, TRANSLATION_TASKS), 
    where("assignee_id", "==", currentUser.uid), 
    where("status", "==", "assigned")
  );
  const tasksQrySnap = await getDocs(tasksQry);
  if(tasksQrySnap.docs.length > 0){
    currentTask = tasksQrySnap.docs[0];
    loadTranslation(currentTask, "fra_Latn");
  }
}

/**
 * VIEW
 */
const updateView = function(){
  if(!currentTranslation){
    return;
  }
  $("#txt-fra_Latn").text(currentTranslation.translations);
}




