var OverLAY_counter=0;
var playerSrc="en_video.pde";
function disableScroll(){
	if (window.addEventListener){ //Firefox only
		window.addEventListener("DOMMouseScroll", function(e){e.preventDefault()}, true);
	}
	window.onmousewheel = document.onmousewheel = window.onscroll = function(e){e.preventDefault()};
}
function enableScroll(){
	if (window.removeEventListener){ //Firefox only
		window.removeEventListener("DOMMouseScroll", function(e){e.preventDefault()}, false);
	}
	window.onmousewheel = document.onmousewheel = window.onscroll = null;
}
function initProcessingInstance(id, wdth, heght, scle,maxScle, zipMode,overlayXML, zip, preview, zoomable) {
	var pjs = Processing.getInstanceById(id);
	if(pjs != null) {
	  pjs.setup(wdth,heght, scle,maxScle, zipMode, overlayXML, zip, preview,zoomable);
	}
	else {
	  setTimeout(initProcessingInstance, 250, id, wdth, heght, scle, maxScle, zipMode,overlayXML, zip, preview, zoomable);
	}
}
function createCanvas(container_id,zipMode,scle,overlayXML,xmlDoc,zip, preview, zoomable){
	wdth=parseInt(xmlDoc.getElementsByTagName("dimensions")[0].getAttribute("width"))*scle;
	ch=xmlDoc.getElementsByTagName("dimensions")[0].getAttribute("channels");
	if (ch>1) wdth+=22;
	if (wdth<300) wdth=300;
	heght=parseInt(xmlDoc.getElementsByTagName("dimensions")[0].getAttribute("height"))*scle+22;
	var wwidth=window.innerWidth-25;
	var wheight=window.innerHeight-50;
	var maxScle=(wwidth/wdth>wheight/heght)?wheight/heght:wwidth/wdth;
	if (wdth>wwidth) {
		scle=(wwidth)/wdth;
		maxScle=scle;
		wdth=wwidth;
		heght=(heght*scle);
	}
	if (heght>wheight) {
		scle=(wheight)/heght;
		maxScle=scle;
		heght=wheight-40;
		wdth=(wdth*scle);
	}
	var id="envideo_"+OverLAY_counter;
	OverLAY_counter++;
	document.getElementById(container_id).style.width=(wdth)+'px';
	document.getElementById(container_id).innerHTML="<canvas id=\""+id+"\" data-processing-sources=\""+playerSrc+"\" width=\""+wdth+"\" height=\""+(heght)+"\"><p>Your browser does not support the canvas tag.</p></canvas>";
	var procCanvas=document.getElementById(id);
	procCanvas.width=wdth;
	procCanvas.height=heght;
	Processing.loadSketchFromSources(id,[playerSrc]);
	initProcessingInstance(id,wdth, heght, scle, maxScle, zipMode,overlayXML, zip, preview, zoomable);
}
function addOverLAYVideo(video_src, container_id, zipMode, scle, preview, zoomable){
	var zip=null;
	var overlayXML="";
	var xmlDoc;
	if (zipMode){
		zip=new JSZip();
		if (video_src!=undefined){
			
			JSZipUtils.getBinaryContent(video_src, function(err, data) {
				if(err) {
					document.getElementById(container_id).innerHTML="Oops. It seems that we ran into some trouble.<br>Please, make sure that you select a valid OverLAY .zip file!";
				  return;
				}

				
				  zip.loadAsync(data)
				  .then(function() {
					//xmlDoc=(new DOMParser).parseFromString(zip.file("overlay.xml").async("string"),"text/xml"); 
					//document.write(zip.file("overlay.xml").async("string"));
					return zip.file("overlay.xml").async("string");
				  })
				  .then(function success(text) {
					  
					xmlDoc=(new DOMParser).parseFromString(text,"application/xml"); 
					overlayXML=text;
					createCanvas(container_id, zipMode,scle,overlayXML,xmlDoc,zip, preview,zoomable);	
					
				  }, function error(e) {
					document.getElementById(container_id).innerHTML="Oops. It seems that we ran into some trouble.<br>Please, make sure that you select a valid OverLAY .zip file!";
				  });
			
			});
		}
	}
	else {
		var overlayXML=video_src+"/";
		if (window.XMLHttpRequest)
			{// code for IE7+, Firefox, Chrome, Opera, Safari
				xmlhttp=new XMLHttpRequest();
			}
			else
			{// code for IE6, IE5
				xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
			}
		xmlhttp.open("GET",dirToLU+"overlay.xml",false);
		xmlhttp.send();
		xmlDoc=xmlhttp.responseXML;
		createCanvas(container_id, zipMode,scle,overlayXML,xmlDoc,zip, preview,zoomable);
	}

}
