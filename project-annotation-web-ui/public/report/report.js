import { initializeApp } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-app.js";
import * as env from "../environment/environment.js";

import { doc, getDoc, updateDoc, Timestamp, arrayUnion, getDocs, setDoc, getFirestore, enableIndexedDbPersistence, collection, query, where, FieldValue } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-firestore.js";
import { getDatabase, ref, onValue } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-database.js";
import { getAuth, onAuthStateChanged } from "https://www.gstatic.com/firebasejs/9.9.3/firebase-auth.js";


// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional

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

// Collections name
const ANNOTATION_TASKS = "annotation-tasks"; //TODO rename tanslation-tasks translation-tasks
const USERS = "users";
const COMPLETED_TASK_STATUS = "completed";
const UNASSIGNED_TASK_STATUS = "unassigned";
const ACCEPTED_TASK_STATUS = "accepted";
const REJECTED_TASK_STATUS = "rejected";

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const firestore = getFirestore(app);
const auth = getAuth();

const getTasks = async() => {
    const tests = query(
        collection(firestore, ANNOTATION_TASKS)
    );
    const testsSnap = await getDocs(tests);
    return testsSnap.docs;
}

const stat = function(title, arr) {
    console.log(title);
    console.log("Total : ", arr.length);
    console.log("Assigned : ", arr.filter(obj => obj.status == "assigned").length);
    console.log("Completed : ", arr.filter(obj => obj.status == "completed").length);
}

const sortTasks = async() => {
    const translationsPromise = await getTasks();
    const tasks = [];
    translationsPromise.forEach(element => {
        const task = element.data();
        tasks.push(task);
    });

    function compare(a, b){
        if(a && b) {
            return b - a;
        } else if(a) {
            return -1;
        } 
        return 1;
    }
    /*tasks.sort((a, b) => {
        return  compare(a.collection_id, b.collection_id)
            ||  compare(a.type, b.type)
            ||  compare(a.verification_level, b.verification_level);
    });
    tasks.map((a) => {
        console.log("[", a.collection_id, ", ", a.type, ", ", a.verification_level, ", ", a.document_id, "]");
    });*/

    const result = tasks.reduce(function (r, a) {
        r[a.collection_id] = r[a.collection_id] || [];
        r[a.collection_id].push(a);
        return r;
    }, Object.create(null));

    const result2 = result.forEach((element) => {
        element.reduce(function (r, a) {
            r[a.type] = r[a.type] || [];
            r[a.type].push(a);
            return r;
        }, Object.create(null));
    });

    console.log(result2);

    /*const translations = [];
    const verifications1 = [];
    const verifications2 = [];
    const verifications3 = [];

    translationsPromise.forEach(element => {
        const task = element.data();
        if (task.type == "translation"){
            translations.push(task);
        } else {
            if (task.verification_level == 1) {
                verifications1.push(task)
            }
            if (task.verification_level == 2) {
                verifications2.push(task)
            }
            if (task.verification_level == 2) {
                verifications3.push(task)
            }
        }
    });

    stat("Traductions", translations);
    stat("Verifications1", verifications1);
    stat("Verifications2", verifications2);
    stat("Verifications3", verifications3);*/
}

sortTasks();