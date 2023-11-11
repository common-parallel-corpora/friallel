//import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.9.3/firebase-app.js';
//import firebase from 'firebase/app'
//import firebase from "firebase/app";

//import firebase from 'firebase';
//<script defer src="/__/firebase/9.9.3/firebase-app-compat.js"></script>
//import { getAuth, signInWithEmailAndPassword } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-auth.js";
//import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-auth.js";
//import { auth } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-auth-compat.js";


/*const firebaseConfig = {
    apiKey: "AIzaSyBmmteKSaTJ6KIwABvGGJMsP67oZtEcfmk",
    authDomain: "fs-2022-003-mtannotation-dev.firebaseapp.com",
    projectId: "fs-2022-003-mtannotation-dev",
    storageBucket: "fs-2022-003-mtannotation-dev.appspot.com",
    messagingSenderId: "1085169598448",
    appId: "1:1085169598448:web:f4cc316c508a226cdae735",
    measurementId: "G-TLK38CCN52"
};
initializeApp(firebaseConfig);


//var firebase = require('firebase');
//var firebaseui = require('firebaseui');
console.log(getAuth());

// Initialize the FirebaseUI Widget using Firebase.
var ui = new firebaseui.auth.AuthUI(firebase.auth());
var uiConfig = {
  callbacks: {
    signInSuccessWithAuthResult: function(authResult, redirectUrl) {
      // User successfully signed in.
      // Return type determines whether we continue the redirect automatically
      // or whether we leave that to developer to handle.
      return true;
    },
    uiShown: function() {
      // The widget is rendered.
      // Hide the loader.
      document.getElementById('loader').style.display = 'none';
    }
  },
  // Will use popup for IDP Providers sign-in flow instead of the default, redirect.
  signInSuccessUrl: 'http://www.google.com',
  signInOptions: [
    // Leave the lines as is for the providers you want to offer your users.
    firebase.auth.GoogleAuthProvider.PROVIDER_ID,
    firebase.auth.EmailAuthProvider.PROVIDER_ID
  ],
  // Terms of service url.
  tosUrl: '<your-tos-url>',
  // Privacy policy url.
  privacyPolicyUrl: '<your-privacy-policy-url>'
};

// The start method will wait until the DOM is loaded.
ui.start('#firebaseui-auth-container', uiConfig);
*/

