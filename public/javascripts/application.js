// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
    if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}

function eraseCookie(name) {
  document.cookie = name+"=; path=/";
}

function simpleUnescape(val) {
  val = val.replace(/\+/g, ' ');
  val = val.replace(/%2Fn/g, '<br/>');
  val = val.gsub(/%(..)/, function(x){ return String.fromCharCode(('0x'+x[1])*1); })
  return val;
}		  

function hideClass(name) {
  allNodes = document.getElementsByClassName(name);
  for(i = 0; i < allNodes.length; i++) {
    Element.hide(allNodes[i]);
  }  
}    

function showClass(name) {
  allNodes = document.getElementsByClassName(name);
  for(i = 0; i < allNodes.length; i++) {
    $(allNodes[i]).style.display = 'inline';
  }  
}    

function hideMarkers(name, marker) {
  allNodes = document.getElementsByClassName(name);
  var pos;
  var str;
  for(i = 0; i < allNodes.length; i++) {
    str = allNodes[i].innerHTML
    pos = str.indexOf(marker)
    if (pos > 0) {
      allNodes[i].innerHTML = str.substr(pos + marker.length, str.length)
    }
  }  
} 

// this is for drag_and_drop_media
var olddiv = 0;
var olddivh = 0;
var olddivw = 0;
function drag_and_drop_media_thumbnail_blowup(id,f)
{
  var mydiv = $(id);
  if ( olddiv )
  { 
    olddiv.style.width = olddivw + 'px';
    olddiv.style.height = olddivh + 'px';
  }
  olddiv = mydiv;
  olddivw = mydiv.offsetWidth;
  mydiv.style.width = f * olddivw + 'px';
  olddivh = mydiv.offsetHeight;
  mydiv.style.height = f * olddivh + 'px';
} 

// this is from/for darg and drop plugins
var mapArray = new Array();

// this is not used?
function addDropped(element, dropon, event) {
  alert('addDropped is called - I thought its obsolete!!')
  insertAtCursor(document.editForm.content, mapArray[element.id]);
}



function addDropped2Fck(instance, id) {
  var oEditor = FCKeditorAPI.GetInstance(instance) ;
  // this is to append
  oEditor.SetData( oEditor.GetData( true ) + mapArray[id], true );

  // this is to insert at the cursot
  // oEditor.InsertHtml(mapArray[id]);
  
  // this is to scroll the editor window to the bottom - doesn't work
  ediv = oEditor.EditorDocument.getElementById('fck_body');
  ediv.scrollIntoView( false );
}
    
function insertAtCursor(myField, myValue) {
  //IE support
  if (document.selection) {
    myField.focus();
    sel = document.selection.createRange();
    sel.text = myValue;
  }
  //MOZILLA/NETSCAPE support
  else if (myField.selectionStart || myField.selectionStart == '0') {
    var startPos = myField.selectionStart;
    var endPos = myField.selectionEnd;
    myField.value = myField.value.substring(0, startPos)
      + myValue
      + myField.value.substring(endPos, myField.value.length);
  } else {
    myField.value += myValue;
  }
  myField.focus()
}

function insertAtEnd(myField, myValue) {
  myField.value += myValue;
  myField.focus()
}

function insertAndReturnString(myField, myValue, retString) {
  insertAtEnd(myField, myValue);
  
  //var oEditor = FCKeditorAPI.GetInstance('content') ;
  //oEditor.SetHTML( oEditor.GetXHTML( true ) + myValue, true );
  
  return retString;
}

//
//   google map supporting functions
//
function google_map_js( div, lat, long, zoom ) { 
  map = new GMap2(document.getElementById(div)); 
  var point = new GLatLng(long,lat);  
  map.setCenter(point,zoom); 
  map.addControl(new GSmallMapControl(),  
                     new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(10, 10)));  
  return map;
} 
function google_map_by_adr_js( div, address, zoom ) { 
  var map = new GMap2(document.getElementById(div));
  map.addControl(new GSmallMapControl(),
                 new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(10, 10)));
  var geocoder = new GClientGeocoder();        
  geocoder.getLatLng( address,
    function(pnt) { 
      if (!pnt) { alert( address + " not found" ); }
      else { map.setCenter(pnt,zoom); }
      } );  
  return map;  
} 
function google_map_icon_add_js( map, point, content, icn, shadow, thumb ) {
  var icon = new GIcon(); 
  if ( icn ) {
    icon.shadow = shadow;
    icon.iconAnchor = new GPoint(10, 10);
    icon.image = icn;
    icon.infoWindowAnchor = new GPoint(10, 10);
    icon.iconSize = new GSize(20, 20);
    icon.shadowSize = new GSize(50, 30);
  }
  else {       
    icon.shadow = 'http://www.google.com/intl/en_ALL/mapfiles/arrowshadow.png'; 
    icon.iconAnchor = new GPoint(10, 10); 
    icon.image = 'http://www.google.com/intl/en_ALL/mapfiles/arrow.png'; 
    icon.infoWindowAnchor = new GPoint(10, 10);	 
    icon.iconSize = new GSize(50, 30); 
    icon.shadowSize = new GSize(50, 30); 
  }
  var marker = new GMarker(point, icon);  
  if ( thumb )
  {
    GEvent.addListener(marker, "mouseover", function()
    { 
      var mp = map.getPane(G_MAP_MARKER_PANE);
      var pre = $("preview");
      if( pre ) { mp.removeChild(pre); }
      var pnt = map.fromLatLngToDivPixel(marker.getPoint());
      var img = document.createElement('img');
      img.src = thumb;
      img.id = "previewimg";
      img.style.position = 'relative';
      img.style.left = parseInt(pnt.x) + 10 + 'px';
      img.style.top = parseInt(pnt.y) + 10 + 'px';
      mp.appendChild( img );
      //thumbnail_resize(img,100);
      
      var txt = document.createElement('text');
      txt.innerHTML = "click!";
      txt.id = "previewtxt";   
      txt.style.position = 'relative';
      txt.style.left = parseInt(pnt.x) + 10 + 'px';
      txt.style.top = parseInt(pnt.y) + 'px' ;
      txt.style.color = 'blue';
      txt.style.backgroundColor = 'yellow';
      mp.appendChild( txt );
      

    });
  }
  GEvent.addListener(marker, "mouseout", function()
    { 
      var mp = map.getPane(G_MAP_MARKER_PANE);
      var pre = $("previewimg");
      if( pre ) { mp.removeChild(pre); }
      var pre = $("previewtxt");
      if( pre ) { mp.removeChild(pre); }
    });  
  if ( content ) GEvent.addListener(marker, "click", function() {
                     marker.openInfoWindowHtml(content); });
  map.addOverlay(marker);
}

function google_map_icon_js( map, lat, long, content, icon, shadow, thumb ) { 
  var point = new GLatLng(long,lat); 
  google_map_icon_add_js( map, point, content, icon, shadow, thumb );
}
function google_map_icon_by_adr_js( map, address, content, icon, shadow, thumb ) { 
  var geocoder = new GClientGeocoder();        
  geocoder.getLatLng( address,
    function(point) { 
      if (!point) { alert( address + " not found" ); }
      else { google_map_icon_add_js( map, point, content, icon, shadow, thumb  ); }
      } );    
}
function google_map_boundary_add_js( map, points ) {
  var pline = new GPolyline( points ); 
  map.addOverlay(pline);
}

// end google map javascripts

function getDocHeight(doc) {
  var docHt = 0, sh, oh;
  if (doc.height) docHt = doc.height;
  else if (doc.body) {
    if (doc.body.scrollHeight) docHt = sh = doc.body.scrollHeight;
    if (doc.body.offsetHeight) docHt = oh = doc.body.offsetHeight;
    if (sh && oh) docHt = Math.max(sh, oh);
  }
  if (docHt > 10000) docHt = null; //If too big, then don't return anything so the default will be used
  //alert('Height=' + docHt + ' doc.height=' + doc.height + ' scrollHeight=' + sh + ' offsetHeight=' + oh);
  return docHt;
}

function getElement(iframeName) {
  return document.getElementById? document.getElementById(iframeName): document.all? document.all[iframeName]: null;
}

function getIframeHeight(iframeName) {
  var iframeWin = window.frames[iframeName];
  return iframeWin? getDocHeight(iframeWin.document) : null;
}

function setIframeHeight(iframeName) {
  var iframeHeight = getIframeHeight(iframeName);
  var iframeEl = getElement(iframeName)
  if ( iframeEl && iframeHeight ) {
    iframeEl.style.height = "auto"; // helps resize (for some) if new doc shorter than previous  
    iframeEl.style.height = iframeHeight + 10 + "px"; // need to add to height to be sure it will all show
  }
}

function loadIframe(iframeName, url) {
  if ( window.frames[iframeName] ) {
    window.frames[iframeName].location = url;   
    return false;
  }
  else return true;
}

/* onload functions */
var onload_functions = new Array();

function onloadInit(){
  window.onload = onloadProcess;
}

function onloadProcess() {
  for(var i = 0;i < onload_functions.length;i++) {
    onload_functions[i]();
    }
}

function onloadAdd(func) {
  onload_functions[onload_functions.length] = func;
}

/* Misc */
function openPopUp(popurl, width, height) {
  var winpops=window.open(popurl,"","width="+width+"px,height="+height+"px,status,resizable")
}
