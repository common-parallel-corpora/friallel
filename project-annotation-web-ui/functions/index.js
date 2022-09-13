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

/**
 * unassign tasks that have been assigned for too long
 * @return {Promise} the unassignment task
 */
function unassignExpiredAssignments() {
  const maxAssignedDate = new Date(
      new Date().getTime() - (maxAssignmentSeconds * 1000)
  );

  return db.collection(translationTaskCollectionName).where(
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

// /**
//  * Compute the number of tasks assigned to the specified user.
//  * @param {string} userID of the user
//  * @return {number} number of tasks currently assigned to this user.
//  * */
//  async function getUserWorkloadSize(userID){
//   var assignedTasks = await db.collection(
//     translationTaskCollectionName
//   ).where(
//     "status", "==", "assigned"
//   ).where(
//       "assignee_id", "==", userID
//   ).get();
//   return assignedTasks.size;
// }

/**
 * Gets the set of translated sentences for the specified user
 * @param {string} userID the user id
 * @return {set} the set of translated sentences
 */
function getUserTranslatedSentences(userID) {
  console.log(userID);
  return new Set(["dataset-flores-dev/0000000002"]);
}


/**
 * Assign translation tasks to the specified user
 * @param {string} userID the user to assign tasks to
 * @param {number} taskCountToBeAssigned the number of tasks to be assigned
 */
function assignTaskToUser(userID, taskCountToBeAssigned) {
  const excludedSentences = getUserTranslatedSentences(userID);
  db.collection(translationTaskCollectionName).where(
      "status", "==", "unassigned"
  ).orderBy(
      "priority", "asc"
  ).limit(userBucketMaxSize * 2)
      .get().then((unassignedTasks)=>{
        let assignedTaskCount = 0;
        unassignedTasks.docs.forEach((unassignedTask)=>{
          const taskSentenceReference = `${unassignedTask.get("collection_id")}/${unassignedTask.get("document_id")}`;
          if (assignedTaskCount >= taskCountToBeAssigned) {
            console.log(`Enough tasks assigned to user. Skipping task#${unassignedTask.id}`);
          } else if (excludedSentences.has(taskSentenceReference)) {
            console.log(`Task assignment skipping task#${unassignedTask.id} for user`);
          } else {
            unassignedTask.ref.set({
              "status": "assigned",
              "assignee_id": userID,
              "assigned_date": new Date(),
            }, {merge: true}).then(()=>{
              console.log(`Assigned Task# ${unassignedTask.id} to User#${userID}`);
            });
            assignedTaskCount += 1;
            excludedSentences.add(
                taskSentenceReference
            );
          }
        });
      });
}

/**
 * Assign tasks to all active translators. increase user workloads to their max
 * @return {Promise} the workload assignment task
 */
function updateUserWorkload() {
  // Retrieve All actives users with buckets not full
  return db.collection(userCollectionName).where(
      "isActiveTranslator", "==", true
  ).get().then((activeUsers)=>{
    // For each user, fill the bucket by getting the next available tasks
    activeUsers.docs.forEach((activeUser)=>{
      // Check workload of Active user
      // var userWorkLoadSize = getUserWorkloadSize(activeUser.id);

      let userWorkLoadSize = 0;
      db.collection(translationTaskCollectionName).where(
          "status", "==", "assigned"
      ).where(
          "assignee_id", "==", activeUser.id
      ).get().then((assignedTasks)=>{
        // console.log(userID, " has these tasks assigned : ", assignedTasks.size);
        userWorkLoadSize = assignedTasks.size;
        console.log(activeUser.id, " has the current load size : ", userWorkLoadSize);
        if (userWorkLoadSize < userBucketMaxSize) {
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
  const promise1 = unassignExpiredAssignments();

  // Step 2: Assign Tasks to fill user buckets
  const promise2 = updateUserWorkload();
  return Promise.all([
    promise1, promise2,
  ]);
});
