// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-analytics.js";
import { doc, getDoc, updateDoc, Timestamp, getDocs, setDoc, getFirestore, enableIndexedDbPersistence, collection, query, where, orderBy } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-firestore.js";
import { getDatabase, ref, onValue } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-database.js";
import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-auth.js";
import * as env from "./environment/environment.js";

// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional

$("#translationBloc").hide();
$("#noTranslateFound").hide();
$("#translatorTab").hide();
$("#verifierTab").hide();

const firebaseConfig = (env.prod == true) ? {
  apiKey: "AIzaSyBQja_MCcubMhjmJYhKI50H_Nzn8SkUwgY",
  authDomain: "fs-2022-003-mtannotation.firebaseapp.com",
  databaseURL:
    "https://fs-2022-003-mtannotation-default-rtdb.firebaseio.com",
  projectId: "fs-2022-003-mtannotation",
  storageBucket: "fs-2022-003-mtannotation.appspot.com",
  messagingSenderId: "82914623747",
  appId: "1:82914623747:web:80acd4fb0d31df013ca936",
  measurementId: "G-LXY5Y1HL47",
} : {
    apiKey: "AIzaSyBmmteKSaTJ6KIwABvGGJMsP67oZtEcfmk",
    authDomain: "fs-2022-003-mtannotation-dev.firebaseapp.com",
    projectId: "fs-2022-003-mtannotation-dev",
    storageBucket: "fs-2022-003-mtannotation-dev.appspot.com",
    messagingSenderId: "1085169598448",
    appId: "1:1085169598448:web:f4cc316c508a226cdae735",
    measurementId: "G-TLK38CCN52"
};

console.log("cc:: env.prod : ", env.prod);
console.log("cc:: config : ", firebaseConfig);
  
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
const ACCEPTED_TASK_STATUS = "accepted";
const REJECTED_TASK_STATUS = "rejected";
const CONFIG_COLLECTION_NAME ="config";
const CONFIG_LANGUAGES_DOCUMENT ="languages";

//tabs names
const TRANSLATION_TAB_NAME = "translation";
const VERIFICATION_TAB_NAME = "verification";

const UI_LANG_KEY = "uiLang";


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
  getAllTasks();
}


var logout = document.getElementById("logout");
var tabTranslate = document.getElementById("translorTab");
var tabVerify = document.getElementById("verifierTab");

var completeTranslations = 0;
var completeVerifications = 0;

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
  
  const docRef = doc(firestore, CONFIG_COLLECTION_NAME, CONFIG_LANGUAGES_DOCUMENT);
  const docSnap = getDoc(docRef).then((doc)=>{
    if(doc.exists()){
      languageConfiguation = doc.data();
    }
  });
  getCompletedTasks("translation");
  getCompletedTasks("verification");
});

async function getCompletedTasks(type) {
  const query_ = query(
    collection(firestore, ANNOTATION_TASKS),
    where("assignee_id", "==", currentUser.uid), 
    where("status", "==", "completed"),
    where("type", "==", type)
  );
  const snapshot = await getDocs(query_);
  if(type === "translation") {
    completeTranslations = snapshot.docs.length;
  } else {
    completeVerifications = snapshot.docs.length;
  }
}
//---------------------

/**
 * DATA
 */

var currentTask = null;
var currentTranslation = null;
var defaultLanguage = "eng_Latn";
var activeTab;

var currentTextToVerify = null;
var languageConfiguation = {
  writingDirection: {}
};


function inactiveAllTab(){
  tabTranslate.className = "";
  tabVerify.className = "";
}

function active(currentTab){
  inactiveAllTab(); // nettoyage
  currentTab.className="active"; // je deviens active
}

logout.addEventListener("click",function(){
  auth.signOut()
})

tabTranslate.addEventListener("click",function(){
  enableTranslateTab();
})

tabVerify.addEventListener("click",function(){
  enableVerificationTab();
})

function enableTranslateTab() {
  activeTab = TRANSLATION_TAB_NAME;
  $("#translation_actions").removeClass("hide");
  $("#verification_actions").addClass("hide");
  active(tabTranslate);
  $("#counter").text(completeTranslations);
  getTranslationTasks();
}

function enableVerificationTab() {
  activeTab = VERIFICATION_TAB_NAME;
  $("#translation_actions").addClass("hide");
  $("#verification_actions").removeClass("hide");
  active(tabVerify);
  $("#counter").text(completeVerifications);
  getVerificationTasks()
}

// translation in spécific language for logged user
const loadTranslations = async(tasks, callback) => {
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

        let neededLang = null;
        for(neededLang of neededLangs) {
          for(trans of res.translations) {
              if (trans?.lang === neededLang) {
                currentTranslations.push({
                  lang : trans.lang,
                  translation: trans.translation
                });
                break;
              }
          }
        }

        //console.log("taskData: ", taskData);
        var textToVerify = null;
        if (taskData.type =="verification") {
          textToVerify = await getTextToVerify(taskData);
        }
        if (index == 0 ) {
          callback(task, currentTranslations, textToVerify);
        }
      }
    }
  })
}

const getTextToVerify = async(task) => {
  const tasksQry = query(
    collection(firestore, ANNOTATION_TASKS),
    where("workflow_id", "==", task.workflow_id),
    where("status", "==", "completed"), 
    (task.verification_level == 1) ? where("type", "==", "translation") : where("verification_level", "==", task.verification_level -1)
  );

  const tasksQrySnap = await getDocs(tasksQry);
  return tasksQrySnap.docs.length > 0 && tasksQrySnap.docs[0].data()?.translated_sentence ? tasksQrySnap.docs[0].data().translated_sentence : "";
}

const getAllTasks = async() => {
  const tasksQry = query(
    collection(firestore, ANNOTATION_TASKS),
    where("assignee_id", "==", currentUser.uid), 
    where("status", "==", "assigned")
  );
  getTasks(tasksQry, (task, currentTranslations, textToVerify) => {
    showTabs();
  });
  
}

const getTranslationTasks = async() => {
  const tasksQry = query(
    collection(firestore, ANNOTATION_TASKS),
    where("assignee_id", "==", currentUser.uid), 
    where("status", "==", "assigned"),
    where("type", "==", "translation"),
    orderBy("priority")
  );
  getTasks(tasksQry, (task, currentTranslations, textToVerify) => {
    updateTranslationView(currentTranslations, task.data().target_lang);
    currentTask = task;
  });
}

const getVerificationTasks = async() => {
  const tasksQry = query(
    collection(firestore, ANNOTATION_TASKS),
    where("assignee_id", "==", currentUser.uid), 
    where("status", "==", "assigned"),
    where("type", "==", "verification"),
    orderBy("priority")
  );
  getTasks(tasksQry, (task, currentTranslations, textToVerify) => {
    updateVerificationView(currentTranslations, textToVerify);
    currentTask = task;
  });
}

const getTasks = async(tasksQry, callback) => {
  console.log(activeTab);
  showLoader();
 
  const tasksQrySnap = await getDocs(tasksQry);
  if (tasksQrySnap.docs.length > 0) {
    $("#translationBloc").show();
    $("#noTranslateFound").hide();
    await loadTranslations(tasksQrySnap.docs, callback);
  } else {
    //TODO display no task view
    $("#translationBloc").hide();
    $("#noTranslateFound").show();
    hideLoader()
  }
}

/**
 * VIEW
 */
function getTranslationTextDirection(target_lang) {
  let writingDirection = "ltr"
  if (target_lang in languageConfiguation.writingDirection){
    writingDirection = languageConfiguation.writingDirection[target_lang];
  }
  return writingDirection;
}

const buildTranslationSourceDom = function(uiTranslation) {
  let writingDirection = 'ltr';
  if (uiTranslation.lang in languageConfiguation.writingDirection){
    writingDirection = languageConfiguation.writingDirection[uiTranslation.lang];
  }
  return `<div class=\"text-to-translate ${writingDirection} col-xs-12 col-sm-12 col-md-6 col-lg-4 col-xl-4\"><p>` + uiTranslation.translation + "<p></div>";
}

const updateTranslationView = function(currentTranslations, target_lang){
  if(!currentTranslations || !(currentTranslations.length > 0)){
    return;
  }

  let uiTranslationSourcesDom = "";
  currentTranslations.forEach ( uiTranslation => {
    uiTranslationSourcesDom += buildTranslationSourceDom(uiTranslation);
  });
  let inputDirection = getTranslationTextDirection(target_lang);
  $("#target_language").text(target_lang);
  $("#translation_sources").html(uiTranslationSourcesDom);
  $("#resulttext").addClass(inputDirection);
  $("#resulttext").val('');
  hideLoader();
}

const updateVerificationView = function(currentTranslations, textToVerify) {
  if(!currentTranslations || !(currentTranslations.length > 0)){
    return;
  }

  let uiTranslationSourcesDom = ""
  currentTranslations.forEach ( uiTranslation => {
    uiTranslationSourcesDom += buildTranslationSourceDom(uiTranslation);
  })
  currentTextToVerify = textToVerify;
  $("#verification_correct_btn").hide();
  $("#verification_validate_btn").show();
  $("#translation_sources").html(uiTranslationSourcesDom);
  $("#resulttext").addClass(inputDirection);
  $("#resulttext").val(textToVerify);
  hideLoader();
}

$("#translation_validate_btn").click(function() {
  let translationValue = $("#resulttext").val().trim();
  console.log("translationValue", translationValue)
  if (translationValue.length > 0) {
    currentInteraction = activeTab == TRANSLATION_TAB_NAME ? InteractionType.UPDATE_TRANSLATE : InteractionType.UPDATE_VERIFICATION;
    confirmationModal.show();
  }
});

$("#verification_validate_btn").click(function() {
  let translationValue = $("#resulttext").val().trim();
  console.log("translationValue", translationValue)
  if (translationValue.length > 0) {
    currentInteraction = activeTab == TRANSLATION_TAB_NAME ? InteractionType.UPDATE_TRANSLATE : InteractionType.APPROVE_VERIFICATION;
    confirmationModal.show();
  }
});

$("#verification_correct_btn").click(function() {
  let translationValue = $("#resulttext").val().trim();
  console.log("translationValue", translationValue)
  if (translationValue.length > 0) {
    currentInteraction = activeTab == TRANSLATION_TAB_NAME ? InteractionType.UPDATE_TRANSLATE : InteractionType.UPDATE_VERIFICATION;
    confirmationModal.show();
  }
});

$("#resulttext").on("input", () => {
  let verifiedText = $("#resulttext").val().trim();
  if (currentTextToVerify == verifiedText) {
    $("#verification_validate_btn").show();
    $("#verification_correct_btn").hide();
  } else {
    $("#verification_validate_btn").hide();
    $("#verification_correct_btn").show();
  }
}) 

const actionSaveTranslation = function(){
  let translationValue = $("#resulttext").val().trim();
  console.log("Sauvegarde declenché sur le text : ", translationValue);
  showLoader()
  updateTranslationTask(COMPLETED_TASK_STATUS, translationValue);
  completeTranslations ++;
  currentInteraction = null;
}
const actionSkipTranslation = function(){
  console.log("Ignorer la traduction declenché sur le text");
  showLoader();
  updateTranslationTask(UNASSIGNED_TASK_STATUS, "");
  currentInteraction = null;
}

const actionSaveVerification = function(){
  let verifiedText = $("#resulttext").val().trim();
  console.log("Sauvegarde du texte de vérification : ", verifiedText);
  console.log("Sauvegarde du texte de vérification currentTextToVerify : ", currentTextToVerify);
  showLoader();
  var verificationStatus = currentTextToVerify == verifiedText ? ACCEPTED_TASK_STATUS : REJECTED_TASK_STATUS;
  updateVerificationTask(COMPLETED_TASK_STATUS, verificationStatus, verifiedText);
  completeVerifications ++;
  currentInteraction = null;
}
const actionSkipVerification = function(){
  console.log("Ignorer la tache de vérification");
  showLoader();
  updateVerificationTask(UNASSIGNED_TASK_STATUS, "", "");
  currentInteraction = null;
}

// INTERACTION VALIDATION
const InteractionType = {
	SKIP_TRANSLATION: {
    MESSAGE: "ignore-translate",
    VALUE: 0,
    ACTION: actionSkipTranslation
  },
	UPDATE_TRANSLATE: {
    MESSAGE: "apply-translate",
    VALUE: 1,
    ACTION: actionSaveTranslation
  },
  SKIP_VERIFICATION: {
    MESSAGE: "ignore-verification",
    VALUE: 2,
    ACTION: actionSkipVerification
  },
	APPROVE_VERIFICATION: {
    MESSAGE: "approve-verification",
    VALUE: 3,
    ACTION: actionSaveVerification
  },
	UPDATE_VERIFICATION: {
    MESSAGE: "apply-correction",
    VALUE: 4,
    ACTION: actionSaveVerification
  }
};
var currentInteraction = null;
// -----------------------------------------------------------------

function isValidTask() {
  var taskData = currentTask ? currentTask.data() : null;
  if(!taskData || !taskData?.collection_id || !taskData?.document_id){
    console.error("error:: task not conform. Task : ", taskData);
    return false;
  }
  return true;
}

const updateTranslationTask = async function(status, newValue) {
  if (!isValidTask()) {
    return;
  }
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
  $("#counter").text(completeTranslations);
  getTranslationTasks();
}

const updateVerificationTask = async function(status, verificationStatus, newValue) {
  if (!isValidTask()) {
    return;
  }
  const docRef = doc(firestore, ANNOTATION_TASKS, currentTask.id);
  updateDoc(docRef, {
    status: status,
    verification_status: verificationStatus,
    translated_sentence: newValue,
    updated_date : Timestamp.fromDate(new Date())
  })
  .catch(error => {
      hideLoader();
      console.log(error);
  });
  console.log("Verification task updated successfully");
  currentTask = null;
  $("#counter").text(completeVerifications);
  getVerificationTasks();
}

const confirmationModal = new bootstrap.Modal('#confirmationModal', {});
//const confirmationModalDOM = document.getElementById('confirmationModal');
const confirmationModalDOM = $("#confirmationModal");

confirmationModalDOM.on("show.bs.modal", event => {
  console.log("modal:: etat: Demande d'ouverture");
  if(InteractionType != null){
    $("#confirmationModalMessage").attr("data-i18n-key",currentInteraction.MESSAGE);
    translateModal();
  }
});

$( "#translation_skip_btn" ).click(function() {
  currentInteraction = activeTab == TRANSLATION_TAB_NAME ? InteractionType.SKIP_TRANSLATION : InteractionType.SKIP_VERIFICATION;
  confirmationModal.show();
});
$( "#modal-confirm-btn" ).click(function() {
  currentInteraction.ACTION();
});

$( "#verification_skip_btn" ).click(function() {
  currentInteraction = activeTab == TRANSLATION_TAB_NAME ? InteractionType.SKIP_TRANSLATION : InteractionType.SKIP_VERIFICATION;
  confirmationModal.show();
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
var defaultLocale = "fr";
var uiLang = localStorage.getItem(UI_LANG_KEY);
defaultLocale = uiLang != null ? uiLang : defaultLocale;


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
  $(".modal-dialog [data-i18n-key]").each((idx, el) => {
    $(el).html(translationsTexts[$(el).attr("data-i18n-key")]);
  });
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

    localStorage.setItem(UI_LANG_KEY, e.target.value);

    if(e.target.value == "nqo"){
      $("#task-instruction-container").addClass("rtl");
    } else {
      $("#task-instruction-container").removeClass("rtl");
    }
    setLocale(e.target.value);
  };
}