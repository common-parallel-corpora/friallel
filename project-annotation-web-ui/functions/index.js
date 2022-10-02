const functions = require("firebase-functions");
const admin = require("firebase-admin");
const {getFirestore} = require("firebase-admin/firestore");


admin.initializeApp();
const db = getFirestore();

const workflowCollectionName = "workflows";
const annotationTaskCollectionName = "annotation-tasks";
const userCollectionName = "users";

// Constant datas
const constantActive="active";
const constantUnassigned="unassigned";
const constantAssigned="assigned";
const constantCompleted="completed";
const constantAccepted="accepted";
const taskTypeTranslation="translation";
const taskTypeVerification="verification";

const constantMapKeyAssignedTranslation = "translationassigned";
const constantMapKeyAssignedVerification = "verificationasssigned";
const constantMapKeyCompletedTranslation = "translationcompleted";
const constantMapKeyCompletedVerification = "verificationcompleted";

// Retrieving Data in Configuration File .env
const maxAssignmentHours = process.env.MAX_TASK_ASSIGNMENT_AGE_HOURS;
const maxAssignmentSeconds = maxAssignmentHours * 60 * 60;
const userTranslationBucketMaxSize = process.env.USER_TRANSLATION_BUCKET_MAX_SIZE;
const userVerificationBucketMaxSize = process.env.USER_VERIFICATION_BUCKET_MAX_SIZE;

/**
 * unassign tasks that have been assigned for too long
 * @return {Promise} the unassignment task
 */
async function unassignExpiredAnnotationTasks() {
  console.log("Unassigned expired Annotation tasks started");
  const maxAssignedDate = new Date(
      new Date().getTime() - (maxAssignmentSeconds * 1000)
  );
  await db.collection(annotationTaskCollectionName).where(
      "status", "==", constantAssigned
  ).where(
      "assigned_date", "<", maxAssignedDate
  ).get().then((assignedTasks)=>{
    assignedTasks.docs.forEach((assignedTask)=>{
      assignedTask.ref.set({
        "status": constantUnassigned,
        "assignee_id": ""
      }, {merge: true}).then(()=>{
        console.log("Unassigned expired task assignment # ", assignedTask.id);
      });
    });
  });
  console.log("Unassigned expired Annotation tasks completed");
}

/**
 * Gets the set of translated sentences for the specified user
 * @param {string} userID the user id
 * @return {Map} the set of translated sentences
 */
async function getUserWorkingSentences(userID) {
  console.log({"userID": userID});
  const mapResult = new Map();

  mapResult.set(
      constantMapKeyAssignedTranslation, new Set()
  ).set(
      constantMapKeyAssignedVerification, new Set()
  ).set(
      constantMapKeyCompletedTranslation, new Set()
  ).set(
      constantMapKeyCompletedVerification, new Set()
  );

  await db.collection(annotationTaskCollectionName).where(
      "status", "in", [constantAssigned, constantCompleted]
  ).where(
      "assignee_id", "==", userID
  ).get().then((userPriorTasks)=>{
    userPriorTasks.forEach((task) => {
      const taskSentenceReference = `${task.get("collection_id")}/${task.get("document_id")}`;
      const currentTaskKey = `${task.get("type")}${task.get("status")}`;
      const taskList = mapResult.get(currentTaskKey);
      taskList.add(taskSentenceReference);
      console.log(`Added prior sentence# ${taskSentenceReference} for user user#${userID}`);
    });
  });

  return mapResult;
}


/**
 * Assign translation tasks to the specified user
 * @param {QueryDocumentSnapshot} user the user to assign tasks to
 * @param {number} taskCountToBeAssigned the number of tasks to be assigned
 * @param {string} taskType Task type to assign
 * @param {Set} excludedSentences Set of excluded sentences
 */
async function assignNextTaskToUser(user, taskCountToBeAssigned, taskType, excludedSentences) {
  const queryUnassignedTasks = db.collection(annotationTaskCollectionName).where(
      "status", "==", constantUnassigned
  ).where(
      "type", "==", taskType
  );
  await queryUnassignedTasks.orderBy(
      "priority", "asc"
  ).limit(taskCountToBeAssigned * 10).get()
      .then(async (unassignedTasks)=>{
        const unassignedTaskCountMax = unassignedTasks.size;
        let assignedTaskCount = 0;
        const availableTasks = unassignedTasks.docs;
        for (let availableTaskIndex = 0; availableTaskIndex < unassignedTaskCountMax; availableTaskIndex += 1) {
          const unassignedTask = availableTasks[availableTaskIndex];
          const taskSentenceReference = `${unassignedTask.get("collection_id")}/${unassignedTask.get("document_id")}`;
          if (excludedSentences.has(taskSentenceReference)) {
            console.log(`Task ${taskType} assignment skipping task#${unassignedTask.id} for user`);
          } else if (unassignedTask.get("verification_level") > user.get("verifier_level")) {
            console.log(`Task ${taskType} assignment skipping task#${unassignedTask.id} for user : Low level`);
          } else {
            console.log(`Awaiting ${taskType} task assignment for task#${unassignedTask.id}`);
            await unassignedTask.ref.set({
              "status": constantAssigned,
              "assignee_id": user.id,
              "assigned_date": new Date()
            }, {merge: true}).then(()=>{
              console.log(`Assigned ${taskType} Task# ${unassignedTask.id} to User#${user.id}`);
            });
            excludedSentences.add(
                taskSentenceReference
            );
            assignedTaskCount += 1;
            if (assignedTaskCount >= taskCountToBeAssigned) break;
          }
        }
      });
}

/**
 * Gets the list of active users (Translators & Verifiers)
 * @return {Array} the array of active users
 */
async function getActiveTranslatorsAndVerifiers() {
  const activeUsers = [];

  await db.collection(userCollectionName).get().then((activeTranslators)=>{
    activeTranslators.forEach((user) => {
      if (user.get("isActiveVerifier") === true ||
        user.get("isActiveTranslator") === true) {
        activeUsers.push(user);
      }
    });
  });
  return activeUsers;
}


/**
 * Assign translation tasks to all active translators. increase user workloads to their max
 * @return {Promise} the workload assignment task
 */
async function assignAnnotationTasks() {
  // Retrieve All actives users with buckets not full
  const activeUsers = await getActiveTranslatorsAndVerifiers();
  console.log(`List of active Users (translator and Verifier) : ${activeUsers}`);
  // For each user, fill the bucket by getting the next available tasks
  activeUsers.forEach(async (activeUser)=>{
    const userCurrentWorkLoad = await getUserWorkingSentences(activeUser.id);
    const userTranslationLoadSize = userCurrentWorkLoad.get(constantMapKeyAssignedTranslation).size;
    const userVerificationLoadSize = userCurrentWorkLoad.get(constantMapKeyAssignedVerification).size;
    const excludedSentences = new Set([
      ...userCurrentWorkLoad.get(constantMapKeyAssignedTranslation),
      ...userCurrentWorkLoad.get(constantMapKeyAssignedVerification),
      ...userCurrentWorkLoad.get(constantMapKeyCompletedTranslation),
      ...userCurrentWorkLoad.get(constantMapKeyCompletedVerification)
    ]);

    if (activeUser.get("isActiveTranslator") === true && userTranslationLoadSize < userTranslationBucketMaxSize) {
      console.log("User Translation Tasks workload ", userTranslationLoadSize, " is under the max :", userTranslationBucketMaxSize);
      const workLoadToAssign = userTranslationBucketMaxSize - userTranslationLoadSize;
      await assignNextTaskToUser(activeUser, workLoadToAssign, taskTypeTranslation, excludedSentences);
    }
    // Carry the state of excluded sentences
    if (activeUser.get("isActiveVerifier") === true && userVerificationLoadSize < userVerificationBucketMaxSize) {
      console.log("User Verification Tasks workload ", userVerificationLoadSize, " is under the max :", userVerificationBucketMaxSize);
      const workLoadToAssign = userVerificationBucketMaxSize - userVerificationLoadSize;
      await assignNextTaskToUser(activeUser, workLoadToAssign, taskTypeVerification, excludedSentences);
    }
  });
}


exports.workflowTaskAssignmentAgent = functions.pubsub.schedule("every 5 minutes").onRun(async (context) => {
  console.log("ENV VARIABLE : MAX AGE TASK in HOURS : ", maxAssignmentHours);
  console.log("ENV VARIABLE : USER TRANSLATION BUCKET SIZE MAX : ", userTranslationBucketMaxSize);
  console.log("ENV VARIABLE : USER VERIFICATION BUCKET SIZE MAX : ", userVerificationBucketMaxSize);
  console.log(context);

  // Step 1: Unassign expired tasks
  await unassignExpiredAnnotationTasks();

  // Step 2: Assign Annontation Tasks to fill user buckets
  await assignAnnotationTasks();
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
    priority: workflowDocument.get("priority"),
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
    priority: workflowDocument.get("priority"),
    assignee_id: "",
    verification_status: "",
    translated_sentence: "",
    creation_date: new Date()
  });
}

/**
 * Complete workflow by changing it status and updating the translations
 * @param {string} workflowId workflow of the task to create
 * @param {string} translatedSentence Final translation to update in the translations collection
 */
async function completeActiveWorkflow(workflowId, translatedSentence) {
  console.log("Workflow #", workflowId, " last verification is done => completing the workflow");
  // Complete the workflow now
  const workflowRef = db.collection(workflowCollectionName).doc(workflowId);
  await workflowRef.set({
    status: constantCompleted,
    translation: translatedSentence,
    updated: new Date()
  }, {merge: true});
  // Update translated sentences
  console.log("Workflow completion final step => Saving translated sentences: ", translatedSentence);
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
                const translatedSentence = lastVerificationTask.get("translated_sentence");
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
              const translatedSentence = lastVerificationTask.get("translated_sentence");
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

