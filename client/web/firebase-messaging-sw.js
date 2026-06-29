importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBnhFFHbfGdM6vZ1ox3SyCZc73zwb2QIvQ",
  authDomain: "quero-doce-d5f27.firebaseapp.com",
  projectId: "quero-doce-d5f27",
  storageBucket: "quero-doce-d5f27.firebasestorage.app",
  messagingSenderId: "444565550302",
  appId: "1:444565550302:web:0aa2bbd9fc41db64cafe4f",
});

const messaging = firebase.messaging();