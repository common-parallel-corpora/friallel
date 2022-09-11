const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {getFirestore} = require("firebase-admin/firestore");

admin.initializeApp();
const db = getFirestore();

const translationTaskCollectionName = "tanslation-tasks";
const maxAssignmentSeconds = 3 * 24 * 60 * 60;
// ${process.env.MAX_TASK_ASSIGNMENT_SECONDS}

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

/** unassign tasks that have been assigned for too long */
function unassignExpiredAssignments() {
  const maxAssignedDate = new Date(
      new Date().getTime() - (maxAssignmentSeconds * 1000)
  );

  db.collection(translationTaskCollectionName).where(
      "status", "==", "assigned"
  ).where(
      "assigned_date", "<", maxAssignedDate
  ).get().then((assignedTasks)=>{
    assignedTasks.docs.forEach((translationTask)=>{
      translationTask.ref.set({
        "status": "unassigned",
        "assignee_id": "",
      }, {merge: true}).then(()=>{
        console.log("Unassigned expired task assignment # ", translationTask.id);
      });
    });
  });
}

exports.taskAssignmentAgent = functions.pubsub.schedule("every 15 minutes").onRun((context) => {
  unassignExpiredAssignments();
  return null;
});
