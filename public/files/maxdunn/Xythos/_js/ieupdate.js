
// http://www.amarasoftware.com/flash-problem.htm
theObjects = document.getElementsByTagName("object");
for (var i = 0; i < theObjects.length; i++) {
    theObjects[i].outerHTML = theObjects[i].outerHTML;
}
