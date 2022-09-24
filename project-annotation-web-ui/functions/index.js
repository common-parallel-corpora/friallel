const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {getFirestore} = require("firebase-admin/firestore");


admin.initializeApp();
const db = getFirestore();

const translationTaskCollectionName = "tanslation-tasks";
const workflowCollectionName = "workflows";
const annotationTaskCollectionName = "annotation-tasks";
const userCollectionName = "users";

// Constant datas
const constantActive="active";
const constantUnassigned="unassigned";
const constantAssigned="assigned";
const constantCompleted="completed";
const constantAccepted="accepted";

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
async function unassignExpiredAssignments() {
  const maxAssignedDate = new Date(
      new Date().getTime() - (maxAssignmentSeconds * 1000)
  );

  await db.collection(translationTaskCollectionName).where(
      "status", "==", constantAssigned
  ).where(
      "assigned_date", "<", maxAssignedDate
  ).get().then((assignedTasks)=>{
    assignedTasks.docs.forEach((translationTask)=>{
      translationTask.ref.set({
        "status": constantUnassigned,
        "assignee_id": ""
      }, {merge: true}).then(()=>{
        console.log("Unassigned expired task assignment # ", translationTask.id);
      });
    });
  });
}

/**
 * Gets the set of translated sentences for the specified user
 * @param {string} userID the user id
 * @return {set} the set of translated sentences
 */
async function getUserTranslatedSentences(userID) {
  console.log(userID);
  const sentenceReferences = new Set();

  await db.collection(translationTaskCollectionName).where(
      "status", "in", [constantAssigned, constantCompleted]
  ).where(
      "assignee_id", "==", userID
  ).get().then((userPriorTasks)=>{
    userPriorTasks.forEach((task) => {
      const taskSentenceReference = `${task.get("collection_id")}/${task.get("document_id")}`;
      sentenceReferences.add(taskSentenceReference);
      console.log(`Added prior sentence# ${taskSentenceReference} for user user#${userID}`);
    });
  });

  return sentenceReferences;
}


/**
 * Assign translation tasks to the specified user
 * @param {string} userID the user to assign tasks to
 * @param {number} taskCountToBeAssigned the number of tasks to be assigned
 */
async function assignTaskToUser(userID, taskCountToBeAssigned) {
  const excludedSentences = await getUserTranslatedSentences(userID);
  await db.collection(translationTaskCollectionName).where(
      "status", "==", constantUnassigned
  ).orderBy(
      "priority", "asc"
  ).limit(userBucketMaxSize * 2)
      .get()
      .then((unassignedTasks)=>{
        let assignedTaskCount = 0;
        unassignedTasks.docs.forEach((unassignedTask)=>{
          const taskSentenceReference = `${unassignedTask.get("collection_id")}/${unassignedTask.get("document_id")}`;
          if (assignedTaskCount >= taskCountToBeAssigned) {
            console.log(`Enough tasks assigned to user. Skipping task#${unassignedTask.id}`);
          } else if (excludedSentences.has(taskSentenceReference)) {
            console.log(`Task assignment skipping task#${unassignedTask.id} for user`);
          } else {
            console.log(`Awaiting task assignment for task#${unassignedTask.id}`);
            (async () => {
              await unassignedTask.ref.set({
                "status": constantAssigned,
                "assignee_id": userID,
                "assigned_date": new Date()
              }, {merge: true}).then(()=>{
                console.log(`Assigned Task# ${unassignedTask.id} to User#${userID}`);
              });
            })();
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
async function updateUserWorkload() {
  // Retrieve All actives users with buckets not full
  await db.collection(userCollectionName).where(
      "isActiveTranslator", "==", true
  ).get().then((activeUsers)=>{
    // For each user, fill the bucket by getting the next available tasks
    activeUsers.docs.forEach((activeUser)=>{
      // Check workload of Active user
      // var userWorkLoadSize = getUserWorkloadSize(activeUser.id);

      let userWorkLoadSize = 0;
      db.collection(translationTaskCollectionName).where(
          "status", "==", constantAssigned
      ).where(
          "assignee_id", "==", activeUser.id
      ).get().then(async (assignedTasks)=>{
        // console.log(userID, " has these tasks assigned : ", assignedTasks.size);
        userWorkLoadSize = assignedTasks.size;
        console.log(activeUser.id, " has the current load size : ", userWorkLoadSize);
        if (userWorkLoadSize < userBucketMaxSize) {
          console.log("UserWorkLoad ", userWorkLoadSize, " is under the max :", userBucketMaxSize);
          const workLoadToAssign = userBucketMaxSize - userWorkLoadSize;
          await assignTaskToUser(activeUser.id, workLoadToAssign);
        }
      });
    });
  });
}

exports.taskAssignmentAgent = functions.pubsub.schedule("every 1 minutes").onRun(async (context) => {
  console.log("ENV VARIABLE : MAX AGE TASK in HOURS : ", maxAssignmentHours);
  console.log("ENV VARIABLE : USER BUCKET SIZE MAX : ", userBucketMaxSize);
  console.log(context);

  // Step 1: Unassign expired tasks
  await unassignExpiredAssignments();

  // Step 2: Assign Tasks to fill user buckets
  await updateUserWorkload();
});

/**
 * Gets list of active workflows
 * @return {set} the set active workflows
 */
async function getActiveWorkflows() {
  const activeWorkflows = new Set();
  await db.collection(workflowCollectionName).where(
      "status", "==", constantActive
  ).orderBy(
      "priority", "asc"
  ).get().then((activeWorkflowResults)=>{
    activeWorkflowResults.forEach((workflow) => {
      activeWorkflows.add(workflow.id);
      console.log(`Added active workflows# ${workflow.id} for secentence#${workflow.get("document_id")}`);
    });
  });
  return activeWorkflows;
}

/**
 * Create new tasks for translation
 * @param {string} workflowId workflow of the task to create
 */
async function createTranslationTask(workflowId) {
  const workflow = db.collection(workflowCollectionName).doc(workflowId);
  const workflowDocument = await workflow.get();
  await db.collection(annotationTaskCollectionName).add({
    type: "translation",
    status: constantUnassigned,
    document_id: workflowDocument.get("document_id"),
    collection_id: workflowDocument.get("collection_id"),
    workflow_id: workflowDocument.id,
    target_lang: workflowDocument.get("target_lang"),
    assignee_id: "",
    translated_sentence: "",
    creation_date: new Date()
  });
}

/**
 * Create new tasks for translation
 * @param {string} workflowId workflow of the task to create
 * @param {number} verificationLevel Level of the verification
 */
async function createVerificationTask(workflowId, verificationLevel) {
  const workflow = db.collection(workflowCollectionName).doc(workflowId);
  const workflowDocument = await workflow.get();
  await db.collection(annotationTaskCollectionName).add({
    type: "verification",
    verification_level: verificationLevel,
    status: constantUnassigned,
    document_id: workflowDocument.get("document_id"),
    collection_id: workflowDocument.get("collection_id"),
    workflow_id: workflowDocument.id,
    target_lang: workflowDocument.get("target_lang"),
    assignee_id: "",
    verification_status: "",
    translated_sentence: "",
    creation_date: new Date()
  });
}

/**
 * Complete workflow by changing it status and updating the translations
 * @param {string} workflowId workflow of the task to create
 * @param {string} translation Final translation to update in the translations collection
 */
async function completeActiveWorkflow(workflowId, translation) {
  console.log("Workflow #", workflowId, " last verification is done => completing the workflow");
  // Complete the workflow now
  const workflowRef = db.collection(workflowCollectionName).doc(workflowId);
  await workflowRef.set({
    status: constantCompleted
  }, {merge: true});
  // Update translated sentences
  console.log("Workflow completion final step => Saving translated sentences: ", translation);
}

exports.workflowTaskWorker = functions.pubsub.schedule("0 12 * * *").onRun(async (context) => {
  // Get all active workflows
  const activeWorkflows = await getActiveWorkflows();
  if (activeWorkflows.size === 0) {
    console.log("There are no active workflows");
  } else {
    // Go through each workflow to update the task list if needed
    activeWorkflows.forEach(async (activeWorkflow)=>{
      console.log("Working on workflow : ", activeWorkflow);
      await db.collection(annotationTaskCollectionName).where(
          "workflow_id", "==", activeWorkflow
      ).orderBy(
          "creation_date", "desc"
      ).get().then(async (workFlowTasks)=>{
        console.log("Checking workflow #", activeWorkflow, " annontation tasks");
        if (workFlowTasks.size === 0) {
          // Create first translation tasks
          console.log("Workflow #", activeWorkflow, " has no task - Creating Translation Task");
          await createTranslationTask(activeWorkflow);
        } else {
          if (workFlowTasks.size < 3) {
            console.log("Workflow #", activeWorkflow, "has 1 or 2 tasks : Translation and (possibly) verification Level 1");
            const task = workFlowTasks.docs[0];
            if (task.get("status") === constantCompleted) {
              console.log("Workflow #", activeWorkflow, " last Task (Translation or Verification Level 1) has been completed");
              // Verification level matches the number of task
              const verificationLevel = workFlowTasks.size;
              console.log("Creating Verification Task for level : ", verificationLevel);
              // Translation task complete, need new verification task
              await createVerificationTask(activeWorkflow, verificationLevel);
            } else {
              console.log("Workflow #", activeWorkflow, " last task is still pending completion");
            }
          } else if (workFlowTasks.size < 4) {
            console.log("Workflow #", activeWorkflow, " has 1 translation tasks and 2 verifications");
            const lastVerificationTask = workFlowTasks.docs[0];
            if (lastVerificationTask.get("status") === constantCompleted) {
              console.log("Workflow #", activeWorkflow, " last verification task has been completed");
              const beforeLastVerificationTask = workFlowTasks.docs[1];
              // Two verification completed and both accepted - Complete the workflow
              if (lastVerificationTask.get("verification_status") === constantAccepted &&
                beforeLastVerificationTask.get("verification_status") === constantAccepted) {
                // Completing active workflow
                const translatedSentence = "This is a dummy value for NKO translation";
                completeActiveWorkflow(activeWorkflow, translatedSentence);
              } else {
                console.log("Workflow #", activeWorkflow,
                    " One (or two) of the two verifications has been rejected => Need one last verification task Level 3");
                // Need to create a 3rd level verification
                const verificationLevel = workFlowTasks.size;
                console.log("Creating Verification Task for level : ", verificationLevel);
                // Translation task complete, need new verification task
                await createVerificationTask(activeWorkflow, verificationLevel);
              }
            } else {
              console.log("Workflow #", activeWorkflow, " last task is still pending completion");
            }
          } else {
            console.log("Workflow #", activeWorkflow, " has 1 translation tasks and 2 verifications");
            // 3rd Level verification completed
            const lastVerificationTask = workFlowTasks.docs[0];
            if (lastVerificationTask.get("status") === constantCompleted) {
              // Completing active workflow
              const translatedSentence = "This is a dummy value for NKO translation";
              completeActiveWorkflow(activeWorkflow, translatedSentence);
            } else {
              console.log("Workflow #", activeWorkflow, " last task is still pending completion");
            }
          }
        }
      });
    });
  }
});

