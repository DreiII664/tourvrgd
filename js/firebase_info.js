// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyAx7zIsF66NgMGkerg0BohfRqThR6rFX0g",
  authDomain: "tvrn29475ao4u67gffk312gh9bc8h3.firebaseapp.com",
  projectId: "tvrn29475ao4u67gffk312gh9bc8h3",
  storageBucket: "tvrn29475ao4u67gffk312gh9bc8h3.firebasestorage.app",
  messagingSenderId: "468569832944",
  appId: "1:468569832944:web:16fa818f2e888468217135",
  measurementId: "G-ED66F1RDLF"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);

//API REST
const PROJECT_ID = "tvrn29475ao4u67gffk312gh9bc8h3";
const FIRESTORE_URL = "https://firestore.googleapis.com/v1/projects/"+ PROJECT_ID+"/databases/(default)/documents/";
const HEADER = ["Content-Type: application/json"];
const Environments = FIRESTORE_URL+"Environments/";