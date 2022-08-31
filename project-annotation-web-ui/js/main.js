$(document).ready(function() {
    main();
});

function main() {
    setTimeout(() => {
        alert("Alerte lancée !");
    }, 500);


    $("#pId").click(function(){
        alert("The paragraph was clicked.");
    });
}