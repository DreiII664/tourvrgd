// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

//API REST
const PROJECT_ID = "";
const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/"+ PROJECT_ID+"/databases/(default)/documents/";
const HEADER = ["Content-Type: application/json"];
const Environments = FIRESTORE_URL+"";