import { initializeApp } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-app.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-firestore.js";


// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional

const firebaseConfig = {
    apiKey: "AIzaSyBmmteKSaTJ6KIwABvGGJMsP67oZtEcfmk",
    authDomain: "fs-2022-003-mtannotation-dev.firebaseapp.com",
    projectId: "fs-2022-003-mtannotation-dev",
    storageBucket: "fs-2022-003-mtannotation-dev.appspot.com",
    messagingSenderId: "1085169598448",
    appId: "1:1085169598448:web:f4cc316c508a226cdae735",
    measurementId: "G-TLK38CCN52"
  };

// Initialize Firebase
const app = firebase.initializeApp(firebaseConfig);
const firestore = getFirestore(app);

var uiConfig = {
    signInSuccessUrl: "../",
    signInOptions: [
      // Leave the lines as is for the providers you want to offer your users.
      firebase.auth.GoogleAuthProvider.PROVIDER_ID,
    ],
    // tosUrl and privacyPolicyUrl accept either url string or a callback
    // function.
    // Terms of service url/callback.
    tosUrl: "privacy.html",
    // Privacy policy url/callback.
    privacyPolicyUrl: function() {
      window.location.assign("policy.html");
    }
};
  
// Initialize the FirebaseUI Widget using Firebase.
var ui = new firebaseui.auth.AuthUI(firebase.auth());
// The start method will wait until the DOM is loaded.
ui.start("#firebaseui-auth-container", uiConfig);
const auth = getAuth();