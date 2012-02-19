
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

var mapArray = new Array();

