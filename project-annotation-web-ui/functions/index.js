const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {getFirestore} = require("firebase-admin/firestore");



admin.initializeApp();
const db = getFirestore();

const translationTaskCollectionName = "tanslation-tasks";
const userCollectionName = "users";

// Retrieving Data in Configuration File .env
const maxAssignmentHours = process.env.MAX_TASK_ASSIGNMENT_AGE_HOURS;
const maxAssignmentSeconds = maxAssignmentHours * 60 * 60;
const userBucketMaxSize = process.env.USER_BUCKET_MAX_SIZE;


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

/* Get the user workload size */
// eslint-disable-next-line no-unused-vars
function getUserWorkloadSize(userID){
  var workLoad = 0;
  db.collection(
    translationTaskCollectionName
  ).where(
    "status", "==", "assigned"
  ).where(
      "assignee_id", "==", userID
  ).get().then((assignedTasks)=>{
    // console.log(userID, " has these tasks assigned : ", assignedTasks.size);
    workLoad = assignedTasks.size;
    console.log(userID, " has these tasks assigned : ", workLoad);
  });
  return workLoad;
}

function getUserTranslatedSentences(userID){
    console.log(userID);
    return ["0000000002"];
}

function assignTaskToUser(userID, workloadLoad){

  // const userTranslatedSentences = user.getData().translatedSentences;
  const userTranslatedSentences = getUserTranslatedSentences(userID);

  db.collection(translationTaskCollectionName).where(
  "status", "==", "unassigned"
  ).where(
    "document_id", "not-in", userTranslatedSentences
  ).orderBy(
    "document_id"
  ).orderBy(
    "priority", "asc"
  ).limit(workloadLoad)
  .get().then((availableTasks)=>{
    availableTasks.docs.forEach((availableTask)=>{
      availableTask.ref.set({
        "status": "assigned",
        "assignee_id": userID,
        "assigned_date": new Date(),
      }, {merge: true}).then(()=>{
        console.log("Assigned Task #", availableTask.id, " to User : ", userID);
      });
    });
  });
}

/** Assign Task to increase user workloads to their max */
function updateUserWorkload() {
  // Retrieve All actives users with buckets not full
  db.collection(userCollectionName).where(
  "isActiveTranslator", "==", true
  ).get().then((activeUsers)=>{
    // For each user, fill the bucket by getting the next available tasks
    activeUsers.docs.forEach((activeUser)=>{
      // Check workload of Active user
      // var userWorkLoadSize = getUserWorkloadSize(activeUser.id);

      var userWorkLoadSize = 0;
      db.collection(translationTaskCollectionName).where(
      "status", "==", "assigned"
      ).where(
          "assignee_id", "==", activeUser.id
      ).get().then((assignedTasks)=>{
        // console.log(userID, " has these tasks assigned : ", assignedTasks.size);
        userWorkLoadSize = assignedTasks.size;
        console.log(activeUser.id, " has the current load size : ", userWorkLoadSize);
        if(userWorkLoadSize < userBucketMaxSize){
          console.log("UserWorkLoad ", userWorkLoadSize, " is under the max :", userBucketMaxSize);
          const workLoadToAssign = userBucketMaxSize - userWorkLoadSize;
          assignTaskToUser(activeUser.id, workLoadToAssign);
        }
      });
    });
  });
}

exports.taskAssignmentAgent = functions.pubsub.schedule("every 15 minutes").onRun((context) => {
  console.log("ENV VARIABLE : MAX AGE TASK in HOURS : ", maxAssignmentHours);
  console.log("ENV VARIABLE : USER BUCKET SIZE MAX : ", userBucketMaxSize);
  console.log(context);

  // Step 1: Unassign expired tasks
  unassignExpiredAssignments();

  // Step 2: Assign Tasks to fill user buckets
  updateUserWorkload();
  return null;
});
