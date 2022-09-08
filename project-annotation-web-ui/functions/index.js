const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });


// Listens for new messages added to /messages/:documentId/original and creates an
// uppercase version of the message to /messages/:documentId/uppercase
exports.setActiveTranslatorStatus = functions.firestore.document("/users/{documentId}")
    .onCreate((snap, context) => {
      // Grab the current value of what was written to Firestore.
      const dataDict = snap.data();
      functions.logger.log("Created data", context.params.documentId, dataDict);

      dataDict.isActiveTranslator = false;
      functions.logger.log("Updated data", context.params.documentId, dataDict);

      // You must return a Promise when performing asynchronous tasks inside a Functions such as
      // writing to Firestore.
      // Setting an 'uppercase' field in Firestore document returns a Promise.
      return snap.ref.set(dataDict, {merge: true});
    });
