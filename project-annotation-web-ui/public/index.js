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

$("#translationBloc").hide();
$("#noTranslateFound").hide();
$("#translatorTab").hide();
$("#verifierTab").hide();

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
var firestoreUser;

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
const ANNOTATION_TASKS = "annotation-tasks"; //TODO rename tanslation-tasks translation-tasks
const USERS = "users";
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
      setDoc(newRef, { 
        name: user.displayName, 
        isActiveTranslator: false, 
        email: user.email,
        isActiveTranslator: false,
        isActiveVerifier: false,
        verifier_level: 0
      }, { merge: true });
  }
  currentUser["firestoreUser"] = userSnap.data();
  firestoreUser = currentUser.firestoreUser;
  getTranslationTask();
}


var tabTranslate = document.getElementById("translorTab");
var tabVerify = document.getElementById("verifierTab");

const showTabs = function() {
  firestoreUser.isActiveTranslator ? $("#translorTab").show() : $('#translorTab').hide();
  firestoreUser.isActiveVerifier ? $("#verifierTab").show() : $('#verifierTab').hide();
  if (firestoreUser.isActiveTranslator) {
    tabTranslate.className="active";
    enableTranslateTab();
  } else if (firestoreUser.isActiveVerifier) {
    tabVerify.className="active";
    enableVerificationTab();
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
});
//---------------------

/**
 * DATA
 */

var currentTask = null;
var currentTranslation = null;
var defaultLanguage = "eng_Latn";
var activeOnglet;


function inactiveAllTab(){
  tabTranslate.className = "";
  tabVerify.className = "";
}

function active(currentTab){
  inactiveAllTab(); // nettoyage
  currentTab.className="active"; // je deviens active
  //getTranslationTask();
}

tabTranslate.addEventListener("click",function(){
  //contenu.innerHTML = "article 1";
  enableTranslateTab();
})

tabVerify.addEventListener("click",function(){
  //contenu.innerHTML = "article 2";
  enableVerificationTab();
})

function enableTranslateTab() {
  activeOnglet = "translation";
  active(tabTranslate);
}

function enableVerificationTab() {
  activeOnglet = "verification";
  active(tabTranslate);
}

// translation in spécific language for logged user
const loadTranslations = async(tasks) => {
  tasks.forEach ( async (task, index) => {
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
      if(res?.translations != null) {
        let trans = null;
        let neededLangs = currentUser.firestoreUser?.translation_from_languages?.length > 0 ? currentUser.firestoreUser.translation_from_languages : [defaultLanguage]
        for(trans of res.translations) {
          if(neededLangs.includes(trans?.lang)){
            currentTranslations.push({
              lang : trans.lang,
              translation: trans.translation
            });
          }
        }
        console.log("ui:: currentTranslation : ", currentTranslations);
        if (index == 0) {
          updateView(currentTranslations, taskData.target_lang);
          currentTask = task;
          console.log("currentTask", currentTask.data())
        }
      }
    }
  })
}

// Get user first translation task
const getTranslationTask = async() => {
  console.log(activeOnglet);
  showLoader();
  const tasksQry = query(
    collection(firestore, ANNOTATION_TASKS),
    where("assignee_id", "==", currentUser.uid), 
    where("status", "==", "assigned")
  );
  const tasksQrySnap = await getDocs(tasksQry);
  if (tasksQrySnap.docs.length > 0) {
    $("#translationBloc").show();
    $("#noTranslateFound").hide();
    await loadTranslations(tasksQrySnap.docs);
  } else {
    //TODO display no task view
    $("#translationBloc").hide();
    $("#noTranslateFound").show();
    hideLoader()
  }
  showTabs();
  
  console.log("Number of tasks=",tasksQrySnap.docs.length)
}

/**
 * VIEW
 */

function getTranslationTextDirection(target_lang) {
  switch(target_lang) {
    case "nqo_Nkoo":
      return "rtl cursor-left"; // Right to left, cursor on left
    default:
      return "ltr cursor-right"; // Left to right, cursor right
  }
}

const buildTranslationSourceDom = function(uiTranslation) {
  return "<div class=\"text-to-translate col-xs-12 col-sm-12 col-md-6 col-lg-4 col-xl-4\"><p>" + uiTranslation.translation + "<p></div>";
}

const updateView = function(currentTranslations, target_lang){
  if(!currentTranslations || !(currentTranslations.length > 0)){
    return;
  }

  let uiTranslationSourcesDom = "";
  currentTranslations.forEach ( uiTranslation => {
    uiTranslationSourcesDom += buildTranslationSourceDom(uiTranslation);
  });
  let inputDirection = getTranslationTextDirection(target_lang);
  $("#resulttext").addClass(inputDirection);
  $("#target_language").text(target_lang);
  $("#translation_sources").html(uiTranslationSourcesDom);
  $("#resulttext").val('');
  hideLoader();
}

$( "#validate_btn" ).click(function() {
  let translationValue = $("#resulttext").val().trim();
  console.log("translationValue", translationValue)
  if (translationValue.length > 0) {
    currentInteraction = InteractionType.UPDATE_TRANSLATE;
    translateModal();
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
  updateTranslationTask(UNASSIGNED_TASK_STATUS, "");
  currentInteraction = null;
}

// INTERACTION VALIDATION
const InteractionType = {
	SKIP: {
    MESSAGE: "ignore-translate",
    VALUE: 0,
    ACTION: actionSkipTranslation
  },
	UPDATE_TRANSLATE: {
    MESSAGE: "apply-translate",
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

  //TODO translations to translations
  /*updateDoc(docRef, {
    translations: arrayUnion( {
      created : now,
      lang : LANG_ENCODING,
      translation : translationValue,
      updated : now,
      user_id : currentUser.uid,
    })
  })
  .catch(error => {
      hideLoader();
      console.log(error);
  });*/

  updateTranslationTask(COMPLETED_TASK_STATUS, translationValue)
}

const updateTranslationTask = async function(status, newValue) {

  var taskData = currentTask ? currentTask.data() : null;
  if(!taskData || !taskData?.collection_id || !taskData?.document_id){
    console.error("error:: task not conform. Task : ", taskData);
    return;
  }

  var taskData = currentTask ? currentTask.data() : null;

  const docRef = doc(firestore, ANNOTATION_TASKS, currentTask.id);

  updateDoc(docRef, {
    status: status,
    translated_sentence: newValue,
    updated_date : Timestamp.fromDate(new Date())
  })
  .catch(error => {
      hideLoader();
      console.log(error);
  });
  console.log("Translation task updated successfully");
  currentTask = null;
  getTranslationTask();
}

const confirmationModal = new bootstrap.Modal('#confirmationModal', {});
//const confirmationModalDOM = document.getElementById('confirmationModal');
const confirmationModalDOM = $("#confirmationModal");

confirmationModalDOM.on("show.bs.modal", event => {
  console.log("modal:: etat: Demande d'ouverture");
  if(InteractionType != null){
    $("#confirmationModalMessage").attr("data-i18n-key",currentInteraction.MESSAGE);
  }
});

$( "#skip_btn" ).click(function() {
  currentInteraction = InteractionType.SKIP;
  translateModal();
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


//////////// Translations-------------------------
// The locale our app first shows
const defaultLocale = "fr";


// The active locale
let locale;

// Gets filled with active locale translations
let translationsTexts = {};

// When the page content is ready...
document.addEventListener("DOMContentLoaded", () => {
  // Translate the page to the default locale
  setLocale(defaultLocale);
});

// Load translations for the given locale and translate
// the page to this locale
async function setLocale(newLocale) {
  if (newLocale === locale) return;

  const newTranslations = 
    await fetchTranslationsFor(newLocale);

  locale = newLocale;
  translationsTexts = newTranslations;

  translatePage();
}

// Retrieve translations JSON object for the given
// locale over the network
async function fetchTranslationsFor(newLocale) {
  const response = await fetch(`/i18n/${newLocale}.json`);
  return await response.json();
}

// Replace the inner text of each element that has a
// data-i18n-key attribute with the translation corresponding
// to its data-i18n-key
function translatePage() {
  document
    .querySelectorAll("[data-i18n-key]")
    .forEach(translateElement);
}

function translateModal() {
  document.querySelectorAll("modal-body").forEach(translateElement);
}

// Replace the inner text of the given HTML element
// with the translation in the active locale,
// corresponding to the element's data-i18n-key
function translateElement(element) {
  const key = element.getAttribute("data-i18n-key");
  const translation = translationsTexts[key];
  element.innerText = translation;
}

// When the page content is ready...
document.addEventListener("DOMContentLoaded", () => {
  setLocale(defaultLocale);

  bindLocaleSwitcher(defaultLocale);
});

// ...

// Whenever the user selects a new locale, we
// load the locale's translations and update
// the page
function bindLocaleSwitcher(initialValue) {
  const switcher = 
    document.querySelector("[data-i18n-switcher]");

  switcher.value = initialValue;

  switcher.onchange = (e) => {
    // Set the locale to the selected option[value]
    if(e.target.value == "nqo"){
      $("#task-instruction-container").addClass("rtl");
    } else {
      $("#task-instruction-container").removeClass("rtl");
    }
    setLocale(e.target.value);
  };
}