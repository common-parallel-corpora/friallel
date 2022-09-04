// Enregistrement du service worker
const registerServiceWorker = async () => {
if ("serviceWorker" in navigator) {
    try {
        console.log("before service worker registration.");
        const registration = await navigator.serviceWorker.register("/offline-service-worker.js", {
            scope: "/",
        });
        if (registration.installing) {
            console.log("Service worker installing");
        } else if (registration.waiting) {
            console.log("Service worker installed");
        } else if (registration.active) {
            console.log("Service worker active");
        }
        } catch (error) {
        console.error(`Registration failed with ${error}`);
        }
    }
    else{
        console.log("Service worker API unavailable");
    }
};
  
  // …
  
  registerServiceWorker();


$(document).ready(function() {
    //main();
});

function main() {
    setTimeout(() => {
        console.log("Alerte lancée !");
    }, 500);


    $("#pId").click(function(){
        alert("The paragraph was clicked.");
    });
}