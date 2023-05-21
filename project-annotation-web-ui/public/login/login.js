import { initializeApp } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-app.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-firestore.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-auth.js";
import * as env from "../environment/environment.js";

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional

// TO DO : To be replace by your Firebase configuration
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...",
  projectId: "t...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "..."
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