	/* 'en_video' - A scientific image sequence viewer based on Processing <processingjs.org/>
    Copyright (C) 2014  Imre Gaspar

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.*/
	
/* @pjs globalKeyEvents="true"; */

/** to be set by parent script **/
int wdth, heght;
double scle, maxScle;
String dirToLU;
boolean zipMode;
boolean previewMode=false;
boolean zoomable=true;
var zip;

/** global variables **/
int fontsize=24;
int minWdth=300;
int W;
int H;
int D; 
//int x=0,y=0;
color c;
int mag_size=20;
int magnifiedFrame=-1;
int magn=2;
int f=0;
int noL;
int f_Rate=30;
int fcCounter=0;
int channels=1;
int tChCalc=0;
int chTS=0;
int[] scrbPos=new int[4];
int done_strt=0;
int done_stp=0;
double zoom=1.0;
int mx,my;
int chbtOff=8;
double initScle;
//int mouseScroll=0;
boolean isExplorer=(navigator.appName == "Microsoft Internet Explorer");
//String[] imn=loadStrings("img.txt");
PImage[][] img;
boolean[][] calculated;
boolean[] requested;
boolean[] channeltoggler;
//int tbd=channels*D;
int reqCnt=0;
int maxReqItems;
int lastReqItem=0;
butoons[] btns=new butoons[chbtOff];
scroolBar scrb;
fillBar FPSBar;
boolean mgnify;

boolean stp;
boolean inv;
boolean ovrly;
boolean mI;
boolean playable;
boolean imagesReady=false;
boolean imagesCalculated=false;
boolean mseOver=false;
boolean show_help=false;
XMLElement xml;
//int maxPathLength=5;
String aW;
String ext=".jpg";
String helpString="SPACE - toggle play\nmouse scroll, LEFT/RIGHT arrow - step one frame\nUP/DOWN arrow - adjust the playback speed\n'-' - '+' - zoom out/in\n1-0 - toggle channels\nm - toggle magnifier, i - invert colors\no - toggle overlay\nh - toggle help";
int helpHeight=125;
overlys[] ols;
/** global colors**/
color sC=color(#000022);
color fC=color(#0099ff);
color afC=color(#ff9900);
color ofC=color(#aaaaaa);
color button_bgColor=color(#333333);
/**
* setup the script, the interface (setupButoons()) and load the overlay from 'overlay.xml' (loadXML())
**/
void setup(int _w, int _h, double _s, double _ms, boolean _zm, String _xml, var _zip, boolean _pm, boolean _zoom) {
  if (_w!=null){
	  wdth=_w;
	  heght=_h;
	  scle=_s;
	  maxScle=_ms;
	  initScle=_s;
	  zipMode=_zm;
	  previewMode=_pm;
	  zoomable=_zoom;
	  size(wdth,heght);
	  stp=false;
	  inv=false;
	  ovrly=true;
	  textFont(createFont("Arial",fontsize));
	  PFont fontA = loadFont("Arial");
	  textFont(fontA, 12);
	  mgnify=true;
	  if (zipMode) {
		 
		  xml=new XMLElement(_xml);
		  
		  zip=_zip;
	  }
	  else {
		  dirToLU=_xml;
		  xml=new XMLElement(this,_xml+"overlay.xml");
	  }
	  W=int(xml.getChild(0).getInt("width"));
	  H=int(xml.getChild(0).getInt("height"));
	  D=int(xml.getChild(0).getInt("depth"));
	  channels=int(xml.getChild(0).getInt("channels"));
	  effectiveW=channels>1?wdth-22:wdth;
	  effectiveH=heght-22;
	  //channels=2;
	  if (channels>1) chTS=channels;
	  ext=xml.getChild(0).getStringAttribute("ext");
	  if (ext==null) ext=".jpg";
	  if (match(ext,".")==null) ext="."+ext;
	  maxReqItems=int(20/channels);
	  channeltoggler=new boolean[channels];
	  for (int k=0;k<channels;k++) channeltoggler[k]=true;
	  tbd=channels*D;
	  noL=str(D).length<3?3:str(D).length;
	  if (xml.getChild(1).getName()=="controls"){
		f_Rate=int(xml.getChild(1).getInt("FPS"));
		if (f_Rate<5||f_Rate>60) f_Rate=25;
		playable=(xml.getChild(1).getInt("isPlayable")==1)?true:false;
		resizeable=(xml.getChild(1).getInt("isResizeable")==1)?true:false;
		stp=(xml.getChild(1).getInt("isPlaying")==1)?false:true;
		ovrly=(xml.getChild(1).getInt("overlaid")==1)?true:false;
		mgnify=(xml.getChild(1).getInt("magnifyable")==1)?true:false;
		//zoomable=(xml.getChild(1).getInt("zoomable")==1)?true:false;
		mag_size=xml.getChild(1).getInt("mag_size");
	  }
	  int _D=(previewMode)?D+1:D;
	  img=new PImage[channels+2][_D];
	  calculated=new boolean[channels+2][_D];
	  requested=new boolean[_D];
	  f=(previewMode)?D:0;
	  self=Processing.getInstanceById("envideo_0");
	  noStroke();
	  background(0);
	  fill(0);
	  smooth();
	  frameRate(60);
	  mouseScroll=0;
	  setupButoons();
	  loadXML();
	  if (zipMode) getImgsfromZip();
		else getImgs();
  }
  //else size(300,300);
}
void setupButoons(){
	//play
 int[] vx={3,3,17};
 int[] vy={3,17,10};
 int offH=heght-19;
 btns[0]=new simpleButoon(1,offH,20,20,TRIANGLES,vx,vy); 
	//left
 int[] vx={8,17,17,3,11,11};
 int[] vy={10,3,17,10,3,17};
 btns[1]=new simpleButoon(1,offH,20,20,TRIANGLES,vx,vy); 
	//right
 int[] vx={3,3,12,9,9,17};
 int[] vy={3,17,10,3,17,10};
 btns[2]=new simpleButoon(22,offH,20,20,TRIANGLES,vx,vy); 
 btns[3]=new textButoon(wdth-108,offH,47,20,"MGNFY","magnify area under mouse"); 
 btns[4]=new textButoon(wdth-60,offH,47,20,"OVRLY", "toggle graphical overlay");
 btns[5]=new textButoon(wdth-162,offH,20,20," -", "zoom out"); 
 btns[6]=new textButoon(wdth-140,offH,20,20," +", "zoom in"); 
 btns[7]=new textButoon(wdth-12,offH,12,20,"?", "show help");
 btns[7].setColor=butoons.offColor; 
 if (isExplorer||scle<1) {
    btns[5].setColor=butoons.offColor;
    btns[6].setColor=butoons.offColor;
 }
 if (channels>1) {
   for (int j=0;j<channels;j++) {
       btns[chbtOff+j]=new textButoon(wdth-21,1+j*21,20,20,(j+1)+"","channel "+(j+1));
   }
 }
 //println(f_Rate);
 FPSBar=new fillBar(22,offH,55,20,f_Rate,5,60);
 
 int strtPos=0;
 if (!playable) {
     btns[0].operational=false;
     FPSBar.operational=false;
     scrbPos[0]=44;scrbPos[1]=offH;scrbPos[2]=wdth-208;scrbPos[03]=20;strtPos=f;
 }
 else {
     btns[1].operational=false;
     btns[2].operational=false;
     scrbPos[0]=79;scrbPos[1]=offH;scrbPos[2]=wdth-246;scrbPos[03]=20;     
 }
 if (resizeable||!zoomable) {
	 btns[5].operational=false;
     btns[6].operational=false;
	 scrbPos[0]=80;scrbPos[1]=offH;scrbPos[2]=wdth-190;scrbPos[03]=20;
 }
 scrb=new scroolBar(scrbPos[0],scrbPos[1],scrbPos[2],scrbPos[3],0,D,strtPos,true,true); 
 if (stp) scrb.lop=!stp;
}
void loadXML(){
   ols=new overlys[xml.getChildCount()-1];
   for (int i=0;i<xml.getChildCount()-1;i++){
      XMLElement kid=xml.getChild(i+1);
      int t=int(kid.getInt("type"));
      //println(t+"a");
      switch (t) {
        case overlys.LNE:
          int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          color cl=int(kid.getInt("clor"));
          cl=color((cl>>16&0xff),(cl>>8&0xff),(cl&0xff));
          int _x0=int(kid.getInt("x0"));
          int _x1=int(kid.getInt("x1"));
          int _y0=int(kid.getInt("y0"));
          int _y1=int(kid.getInt("y1"));
          ols[i]=new lne(s,l,cl,_x0,_y0,_x1,_y1);
        break;
		case overlys.ARRW:
          int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          color cl=int(kid.getInt("clor"));
          cl=color((cl>>16&0xff),(cl>>8&0xff),(cl&0xff));
          int _x0=int(kid.getInt("x0"));
          int _x1=int(kid.getInt("x1"));
          int _y0=int(kid.getInt("y0"));
          int _y1=int(kid.getInt("y1"));
		  int _hS=int(kid.getInt("head_size"));
		  bool _dH=(kid.getInt("double_head")==1)?true:false;
          ols[i]=new arrw(s,l,cl,_x0,_y0,_x1,_y1, _hS, _dH);
        break;
        case overlys.PATH:
          int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          int mdl=int(kid.getInt("mdl"));
          color cl=int(kid.getInt("clor"));
          cl=color((cl>>16&0xff),(cl>>8&0xff),(cl&0xff));
          if (kid.getChildCount()==l) {
            ols[i]=new pth(s,l,mdl,cl);
            for (int j=0;j<kid.getChildCount();j++){
               String[] p=split(kid.getChild(j).getContent(),",");
               ols[i].loadPoint(j,int(p[0]),int(p[1])); 
            }
          }
          else ols[i]=new overlys();
          break;
        case overlys.PLYLINE:
		case overlys.PLYGON:
          int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          int n=int(kid.getInt("n"));
          color cl=int(kid.getInt("clor"));
          cl=color((cl>>16&0xff),(cl>>8&0xff),(cl&0xff));
          if (kid.getChildCount()==n) {
            if (t==overlys.PLYLINE) {ols[i]=new plyline(s,l,n,cl);}
			else ols[i]=new plygon(s,l,n,cl);
            for (int j=0;j<kid.getChildCount();j++){
               String[] p=split(kid.getChild(j).getContent(),",");
               ols[i].loadPoint(j,int(p[0]),int(p[1])); 
            }
          }
          else ols[i]=new overlys();
          break;
		case overlys.ELLPSE:
		  int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          color cl=int(kid.getInt("clor"));
          cl=color((cl>>16&0xff),(cl>>8&0xff),(cl&0xff));
		  int _x=int(kid.getInt("x"));
          int _y=int(kid.getInt("y"));
		  int _w=int(kid.getInt("wdth"));
          int _h=int(kid.getInt("heght"));
		  ols[i]=new ellpse(s,l,cl,_x+_w/2,_y+_h/2,_w,_h);
		  break;
        case overlys.TXT:
          int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          int _x=int(kid.getInt("x"));
          int _y=int(kid.getInt("y"));
          color cl=int(kid.getInt("clor"));
          cl=color((cl>>16&0xff),(cl>>8&0xff),(cl&0xff));
          String value=kid.getContent();
          ols[i]=new txt(s,l,cl,_x,_y,value);
          break;
        case overlys.TIME:
          int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          int _x=int(kid.getInt("x"));
          int _y=int(kid.getInt("y"));
          String u=kid.getString("unit");
          float inc=float(kid.getFloat("inc"));
          float init=float(kid.getContent());
          ols[i]=new tme(s,l,color("white"),_x,_y,init,inc,u);
          break;
		case overlys.CHNNEL:
		  int c=int(kid.getInt("channel_no"));
		  int s=int(kid.getInt("strt"));
          int l=int(kid.getInt("len"));
          int _x=int(kid.getInt("x"));
          int _y=int(kid.getInt("y"));
          color cl=int(kid.getInt("clor"));
          cl=color((cl>>16&0xff),(cl>>8&0xff),(cl&0xff));
		  String u=kid.getContent();
		  if (channels>1 && c>0 && c<=channels) {
			  btns[chbtOff+c-1].setTootlTip(u);
			  ols[i]=new txt(s,l,cl,_x,_y,u);
		  }
		  break;
        default:
          ols[i]=new overlys();
        break;
      }
   } 
 
}
/** end setup **/

/**
* main draw() function, this does the stuff
**/ 
void draw() { 
     //println("f:"+f);
    mx=int(mouseX);//int((mouseX+dx)/zoom);
    my=int(mouseY);//(mouseY+dy)/zoom);
	
    scale(scle);
	fill(0);
	rect(0,0,wdth,heght);
	if (previewMode){
		//println(f);
		if (calculated[chTS][f]){
			image(img[chTS][f], 0, 0);
			noLoop();
		}
		else {
			lastReqItem=f;
			preloadImages(f);
			if (channels>1&&calculated[channels-1][f]&&!calculated[chTS][f]) calculateImages(f);
		}
	}
	else{
		if (calculated[chTS][f]){
			if (resizeable) {			
				wdth=scle*img[chTS][f].width+20;
				heght=scle*img[chTS][f].height+20;
				document.getElementById('content').style.width=(wdth)+'px';
				setupButoons();
				self.size(wdth, heght);
				scale(scle);
			}
			image(img[chTS][f], 0, 0); 
			if (!imagesReady) {
				text("loading ",effectiveW/2-40,effectiveH/2);
				checkImages();
				/*int k=0;
				while (k<D&&calculated[chTS][k]) k++;
				done_stp=k-1;
				if (k>=D) {
				  imagesReady=true;
				  done_stp=k;
				}
				else{
				  if (!calculated[channels-1][k]) preloadImages(k);
				  if (channels>1&&calculated[channels-1][k]&&!calculated[chTS][k]) calculateImages(k);
				}*/
			  }
			if (keyPressed&&mI){
				//println("'"+key+"' "+keyCode);
				if (key=='i')inv=!inv;
				if (keyCode==UP) {FPSBar.adjustValue(1);setFRate(++f_Rate);}
				if (keyCode==DOWN) {FPSBar.adjustValue(-1);setFRate(--f_Rate);}
				if (stp&&keyCode==LEFT) mouseScroll=-1;
				if (stp&&keyCode==RIGHT) mouseScroll=1;
				if (key==32) {  scrb.lop=!scrb.lop; 
							stp=!stp;
							f=scrb.pos;}
				int kk=key-49;
				if (kk>=0&&kk<channels) toggleChannel(kk+chbtOff);
				/*if (channels>1&&key=='1') toggleChannel(0+chbtOff);
				if (channels>1&&key=='2') toggleChannel(1+chbtOff);
				if (channels>2&&key=='3') toggleChannel(2+chbtOff);
				if (channels>3&&key=='4') toggleChannel(3+chbtOff);*/
				if (key=='o'||key=='O') buttonClicked(4);
				if (key=='m'||key=='M') buttonClicked(3);
				if (key=='h'||key=='H') buttonClicked(7);
				if (key=='-') buttonClicked(5);
				if (key=='+') buttonClicked(6);
				keyPressed=false;
			}
			
			pushStyle();
			if (ovrly&&!show_help) overly();
			popStyle();
			if (mgnify&&!show_help) Magnify();
			if (imagesReady&&!stp) ply();
			else if (mI) {    
				if (mouseScroll%1!=0) mouseScroll=0;
				f+=mouseScroll;
				
				if (f<0) f=0;
				else if (f>=D) f=D-1;
				scrb.setPos(mouseScroll);
				mouseScroll=0;
			}
		}
		else {
			checkImages();
		}
		if (show_help) showHelp();
		
	}
	scale(1.0/scle);   
	if(!previewMode) drawButoonBar(); 
} 
void drawButoonBar(){
    pushStyle();
    fill(sC);
    noStroke();
    if (channels>1) rect(wdth-22,0,22,heght);
    rect(0,heght-22,wdth,22);
    noStroke();
    fill(button_bgColor);
    rect(scrbPos[0]+int(scrbPos[2]*done_strt/D),scrbPos[1],int(scrbPos[2]*done_stp/D),scrbPos[3]);
    popStyle();
    for (int i=0;i<btns.length;i++) {
       if (mI&&btns[i].museOver()) btns[i].fillColor=afC;
       else btns[i].fillColor=btns[i].setColor;
       if (btns[i].operational) btns[i].draw();
       if (btns[i].mouseClick()) buttonClicked(i);
    }
    if (scrb.mouseClick()) {
      scrb.drag();
      f=scrb.pos;
    }
    scrb.draw();
    if (FPSBar.mouseClick()) {
      FPSBar.setValueByClick();
      setFRate(FPSBar.value);
    }
   if (FPSBar.museOver()) {
	   //println(mouseScroll+"-"+(f_Rate));
       FPSBar.adjustValue(mouseScroll);
       setFRate(f_Rate+mouseScroll);
       mouseScroll=0;
    }
    
    if (FPSBar.operational) FPSBar.draw();
    
    /*pushStyle();
    fill(fC);
    text(fRate+" FPS",66,225);
    popStyle();*/
}
void showHelp(){
	pushStyle();
	fill(afC,180);
	rect (2,2,296,helpHeight+3);
	fill (0xffffff,255);
	text (helpString,4,6,292,helpHeight);
	popStyle();
}
void mousePressed() {
  if (previewMode){
	previewMode=false;	
	f=0;
	lastReqItem=f;
	loop();
  }
}
/** end main **/

/**
* preload and (re)calulate the images from a directory or from a zip file
**/
void checkImages(){
	done_stp=0;
	int i=0,j=0;
	for (i=0;i<D;i++){
		boolean allChannels=true;
		for (j=0;j<channels;j++){
			if (img[j][i]!=undefined&&img[j][i].width!=undefined&&img[j][i].width!=0) calculated[j][i]=true;
			allChannels&=calculated[j][i];	
		}
		if (allChannels) {
			if (! calculated[chTS][i]&&channels>1) calculateImages(i);
			done_stp++;
		}
	}
	if (done_stp>=D) imagesReady=true;
}
void getImgs(){
	for (int i=0;i<D;i++){
		for (int j=0;j<channels;j++){
			img[j][i]=requestImage(getName(j,i));
		}
	}
}
void getImgsfromZip(){
	for (int i=0;i<D;i++){
		for (int j=0;j<channels;j++){
			//println(i+","+j+":"+getName(j,i));
			getImgfromZip(j,i);
			/*zip.file(getName(j,i)).async("binarystring")
				.then(function success(dta){
					//document.write(btoa(dta));
					img[j][i]=requestImage("data:image/jpeg;base64,"+btoa(dta));
					//alert(img[ch][q].width);
					//calculated[ch][q]=true;
				}, function error(e){
					println(i+","+j);
				});*/
		}
	}	
}
void preloadImages(int frme){
   
    if (!requested[frme]&lastReqItem<=D&&reqCnt<maxReqItems) request();
		for (int j=0;j<channels;j++){
		   if ((img[j][frme].width!=undefined&&img[j][frme].width!=0)&&!calculated[j][frme]) { 
			 calculated[j][frme]=true;
			 reqCnt--;
		  
		   }
		}
     for (int j=0;j<channels-1;j++) calculated[channels-1][frme]&=calculated[j][frme];
}
void request(){
  for (int j=0;j<channels;j++) {
    if (zipMode) getImgfromZip(j,lastReqItem);
	else img[j][lastReqItem]=requestImage(getName(j,lastReqItem));
    calculated[j][lastReqItem]=false; 
  }
  if (channels>1){
      //img[channels][lastReqItem]=createImage(W,H,RGB);  
      calculated[channels][lastReqItem]=false;
  }
  requested[lastReqItem]=true;
  reqCnt++; lastReqItem++; 
}
void calculateImages( int frme){
     //noLoop();
     if (calculated[channels-1][frme]){
		  text("computing ",W/2-40,H/2+20);
		  if (chTS>=channels) img[chTS][frme]=createImage(img[0][frme].width,img[0][frme].height,RGB);  
			for (int j=0;j<channels;j++){
				//alert(img[j][frme].width);
				 if (channeltoggler[j]) img[chTS][frme].addChannel(img[j][frme],img[chTS][frme]);
			}
		
	   calculated[chTS][frme]=true;
	 }
   //frameRate(60); 
   //loop();
}

void getImgfromZip(int ch, int q){
	zip.file(getName(ch,q)).async("binarystring")
		.then(function success(dta){
			//document.write(btoa(dta));
			img[ch][q]=requestImage("data:image/jpeg;base64,"+btoa(dta));
			//alert(img[ch][q].width);
			//calculated[ch][q]=true;
		}, function error(e){
			return "";
		});
}
String getName(int ch, int q){
   String ret=str(char(97 + ch));  
   for (int i=0;i<noL-str(q).length;i++) ret+="0";
   ret+=str(q)+ext;
   //alert(ret);
	if (zipMode) return ret;
	else return dirToLU+ret;
}
/*void loadImages(){

    //println(getName(i));
	if (zipMode){
		document.write(zipMode);
		for (int i=0;i<D;i++) {
			for (int j=0;j<channels;j++) {
				getImgfromZip(j,i);
				calculated[j][i]=false; 
			}
		}
	}
	else {
		for (int i=0;i<D;i++) {
			for (int j=0;j<channels;j++) {
				img[j][i]=requestImage(getName(j,i));
				calculated[j][i]=false; 
			}
		}
	}   
    if (channels>1){
      for (int i=0;i<D;i++) {
        img[channels][i]=createImage(W,H,RGB);  
        calculated[channels][i]=false;
        
      }
    } 
    
}*/
/** end preload**/

/**
* controls
**/
void buttonClicked(int i){
 switch(i){
  case 0:
   scrb.lop=!scrb.lop; 
   stp=!stp;
   f=scrb.pos;
  break;
  case 1:
    scrb.setPos(-1);
    f=scrb.pos;
   
  break;
  case 2:
    scrb.setPos(1);
    f=scrb.pos;
    
  break;
  case 3:
    mgnify=!mgnify;
    btns[i].setColor=mgnify?fC:ofC;
  break;
  case 4:
    ovrly=!ovrly;
    btns[i].setColor=ovrly?fC:ofC;
    break;
  case 5:
	scle=(scle*0.75<initScle)?initScle:round(scle*7.5)/10;
	doZoom();
    /*if (!isExplorer){
      zoom=1;
      doZoom();
    }*/
    break;
  case 6:
	scle=(scle*1.25>maxScle)?maxScle:round(scle*12.5)/10;
	doZoom();
    /*if (!isExplorer){
      zoom=(window.innerWidth/(wdth+12)<window.innerHeight/(heght+heightCorrection))?window.innerWidth/(wdth+12):window.innerHeight/(heght+heightCorrection);
      //zoom=(wdth*zoom)/wdth;
      doZoom();
    }*/
    break;
  case 7:
	show_help=!show_help;
	break;
  case 8:
  case 9:
  case 10:
  case 11:
  case 12:
  case 13:
  case 14:
  case 15:
  case 16:
  case 17:
    toggleChannel(i);
   
  break;
  default:
  break;
 }
  mousePressed=false;
}
void doZoom(){
 /*if (document.body.style.WebkitTransform!=null) document.body.style.WebkitTransform="scale("+zoom+")"; 
 else if (document.body.style.MozTransform!=null) document.body.style.MozTransform="scale("+zoom+")"; 
 var canvasBounds=document.getElementById("envideo").getBoundingClientRect(); 
 dx=left-canvasBounds.left;
 dy=top-canvasBounds.top;*/
		
		wdth=round(scle*img[chTS][f].width)+20;
		heght=round(scle*img[chTS][f].height)+20;
		if (wdth<minWdth) wdth=minWdth;
		document.getElementById('OverLAYvideo').style.width=(wdth)+'px';
		effectiveW=channels>1?wdth-22:wdth;
		effectiveH=heght-22;
		setupButoons();
		self.size(wdth, heght);
	
	
	
}
void toggleChannel(int i){
   // println(i);
   if (mouseButton==RIGHT){
     if (chTS==channels) {
       for (int k=0;k<channels;k++) channeltoggler[k]= false; 
       channeltoggler[i-chbtOff]=true;
       chTS=i-chbtOff;
     }
     else {
        for (int k=0;k<channels;k++) channeltoggler[k]= true; 
        chTS=channels;
     }  
     for (int k=0;k<channels;k++)  btns[k+chbtOff].setColor=channeltoggler[k]?butoons.defaultColor:butoons.offColor;
   }
   else {
    channeltoggler[i-chbtOff]=!channeltoggler[i-chbtOff];
    int c=0;
    int c2=0;
    for (int j=0;j<channels;j++) {
       if (channeltoggler[j]) {
          chTS=j;
          c++;
          c2+=1<<j;
          
       } 
    }
    if (c!=0&&c!=1&&c!=channels){
      chTS=channels+1; 
     if (c2!=tChCalc){
       for (int k=0;k<D;k++) calculated[chTS][k]=false;
       imagesReady=false;
       tChCalc=c2;
     }
    
    }
    if (c==channels) {
      chTS=channels;
    }
    if (c==0) {
      channeltoggler[i-chbtOff]=!channeltoggler[i-chbtOff];
    }
   // println(channels+":"+c+"-"+chTS);
    btns[i].setColor=channeltoggler[i-chbtOff]?fC:ofC;
   }
}
void ply(){
    //img=loadImage(imn[f]);
     if (fcCounter/60>=1) {
         f++;
         scrb.setPos(1);
         fcCounter=fcCounter%60;
     }
     fcCounter+=f_Rate; 
     if (f>=D) f=0;
    
}
void setFRate(int fr){
  f_Rate=fr;
  if (f_Rate>60) f_Rate=60;
  else if (f_Rate<5) f_Rate=5;
  //frameRate(fRate);
}
void overly(){
   for (int i=0;i<ols.length;i++){
     //println(ols[i].type);
    // println(overlys.PATH);
    if (f>=ols[i].strt&&f<=ols[i].ed){
      
      ols[i].draw(f);
      
     }
   }
   
}
void Magnify() {
    int x=mx;
    int y=my;
	if (x>0&&x<effectiveW && y>0&&y<effectiveH && mI) {
		//img[chTS][f].magnify(x,y,mag_size,magn);
		//magnifiedFrame=f;
	
    loadPixels();
    int d=2*mag_size+1;
    color[] tc=new color[d*d];
    if (x>0&&x<effectiveW && y>0&&y<effectiveH && mI){
        for (int i=-mag_size;i<mag_size;i++){
        for (int j=-mag_size;j<mag_size;j++){
           if (x+j*magn>0&&y+i*magn>0&&x+j*magn<wdth&&y+i*magn<heght) {
              //println(x+j+(y+i)*wdth);
              c=pixels[x+j+(y+i)*wdth];
              //println(c+",");
              if (inv) c=invrt(c);
              tc[(i+mag_size)*d+j+mag_size]=c;
           }
        }
        }
        for (int i=-mag_size;i<mag_size;i++){
          for (int j=-mag_size;j<mag_size;j++){
           if (x+j*magn>0&&y+i*magn>0&&x+j*magn<wdth&&y+i*magn<heght) {
              for (int a=0;a<2;a++){
                  for (int b=0; b<2;b++){
                    pixels[x+j*magn+b+(y+i*magn+a)*wdth]=tc[(i+mag_size)*d+j+mag_size];
                  }
              }
             //rect(x+j*mag,y+i*mag,mag,mag);
           }
        }
      }
    }
    updatePixels();
	}
}
color invrt(color c){
   
   int r=0xff-(c>>16&0xff); 
   int g=0xff-(c>>8&0xff); 
   int b=0xff-(c&0xff); 
   return color(r,g,b);
}
void mouseOver(){
  mI=true;
  //mgnify=true;
}
void mouseOut(){
  mI=false;

  
}
/*void mouseClicked(){
  //if (mouseButton==LEFT) stp=!stp;
  if (mouseButton==RIGHT) ovrly=!ovrly;
  
}*/
/** end controls **/

/**
* Interface objects
* abstract class 'butoons' defines appearance and basic operations
* such as mouse over and mouse click
* each children must have their own draw method 
**/
class butoons {
  //static color frmeColor=0xff888888;
  color bgColor=button_bgColor;
  /*static color strokeColor=sC;*/
  color defaultColor=fC;
  color alternativeColor=afC;
  color offColor=ofC;
  int x,y;
  int w,h;
  color fillColor;
  color setColor;
  boolean operational, rightAlign, bottomAlign;
  
  butoons(int a, int b, int c, int d){
      x=a;
      y=b;
      w=c;
      h=d; 
	  rightAlign=(wdth-x<50);
	  bottomAlign=(heght-y<30);
      fillColor=fC;
      setColor=fC;
      operational=true;
  }
  void drawFrame(){
     noStroke();
     fill(bgColor);
     rect(x,y,w,h);
  }
   boolean museOver(){
     return (operational&&abs(mx-x-w/2)<w/2)&& (abs(my-y-h/2)<h/2) ;
  }
  boolean mouseClick(){
     return operational&&this.museOver()&&mousePressed; 
  }
}
class textButoon extends butoons{
	String label, tT;
 // PFont lFont=new Font("Arial");
	int fontSize=12;
	int tTx,tTy,tTw,tTh;
	textButoon(int a, int b, int c, int d, String l, String _tT){
		super(a,b,c,d);
		label=l;
		setTootlTip(_tT);
	}
	void draw(){
		pushStyle();
		drawFrame();
		fill(fillColor);
		text(label,x+3,y+fontSize+2);
		if (museOver()) toolTip();
		popStyle();
	}
	void setTootlTip(String _tT){
		tT=_tT;
		int tTl=tT.length();
		tTw=(tTl*fontSize<wdth/4)?tTl*fontSize:wdth/4;
		tTh=(tTw<wdth/4)?fontSize:ceil(tTl/(wdth/(4*fontSize)))*fontSize;
		if (bottomAlign) {
			tTy=y-tTh;
			if (x+tTw-(tTw-w)/2>wdth) tTx=x-tTw-2;
				else tTx=x-(tTw-w)/2-2;
			}
		else if (rightAlign) {tTy=y+3;tTx=x-tTw-2;}
		else {tTy=y+3;tTx=x+30}
	}
	void toolTip(){
		if (rightAlign)  textAlign(RIGHT);
			else textAlign(CENTER, BOTTOM);
		text(tT,tTx,tTy,tTw,tTh);
	}
}
class simpleButoon extends butoons{
	int mode;
	int noV;
	int[] verticesX;
	int[] verticesY;
	color strokeColor;


	simpleButoon(int a, int b, int c, int d, int m, int[] vx, int vy[]){
		if (vx.length==vy.length){
			x=a;
			y=b;
			w=c;
			h=d;
			mode=m;
			noV=vx.length;
		   verticesX=new int[noV];
		   verticesY=new int[noV];
		   for (int i=0;i<vx.length;i++) verticesX[i]=vx[i]+a;
		   for (int i=0;i<vy.length;i++) verticesY[i]=vy[i]+b;
		   fillColor=fC;
		   setColor=fC;
		   strokeColor=sC;
		   operational=true;
		}
		else operational=false;
	}
	void draw(){
		 pushStyle();
		 drawFrame();
		 stroke(strokeColor);
		 fill(fillColor); 
		 beginShape(mode);
		 for (int i=0;i<verticesX.length;i++){ 
		   vertex(verticesX[i],verticesY[i]);
		 }
		 endShape();
		 popStyle();
	  }
 
}
class scroolBar extends butoons{
   int _mn, _mx, range;
   int bw;
   int pos;
   double step;
   boolean lop;  
   boolean vertical;
   boolean transparent;
   scroolBar(int a, int b, int c, int d, int _min, int _max, int _ps, boolean _lop, boolean _t){
        super(a,b,c,d);
        _mn=_min;
        _mx=_max;
        range=_mx-_mn;
        pos=_ps;
        if (h>w) {
          vertical=true;
          step=range/h;
        }
        else {
          vertical=false;
          step=range/w;
        }
        bw=int(round(1/step));
        if (bw<1) bw=1;
        lop=_lop;
        transparent=_t;
        fillColor=fC;
      
         
   }
   void toolTip(){
       //fill(textColor);
       if (vertical){
         int tpos=int((y+h-my)*step)+1;
         text(tpos+"",x-20,my+2);
       }
       else{
         int tpos=int((mx-x)*step)+1;
         text(tpos+"",mx+2,y-3);
       }
   }
   void draw(){
      pushStyle();
      if (!transparent) drawFrame();
      fill(fillColor);
      if (vertical) rect(x,y+h-int(pos/step),w,bw);
      else rect(x+int(pos/step),y,bw,h);
      if (museOver()) toolTip();
      popStyle;      
   }
   void setPos(int increment){
      pos+=increment;
      if (pos<0) {
         if (lop) pos=range-1;
         else pos=0;
      }
      if (pos>=range) {
         if (lop) pos=0;
         else pos=range-1;
      }
      
   }
   void drag(){
     if (vertical) pos=int((y+h-my)*step);
     else pos=int((mx-x)*step);
     //println(pos);
   }
}
class fillBar extends butoons{
   int _mn, _mx, range;
   int bw;
   int value;
   double step;
   boolean vertical;
   fillBar(int a, int b, int c, int d, int initValue, int _min, int _max){
       
       _mn=_min;
       _mx=_max;
       range=_mx-_mn;
      if (abs(initValue-_mn)<=abs(range)){
         x=a;
         y=b;
         w=c;
         h=d; 
         this.value=initValue;
         if (h>w){
           vertical=true;
           step=range/h;
         }
        else{
           vertical=false;
           step=range/w;
         }
         bw=int((value-_mn)/step);

         fillColor=fC;
         setColor=fillColor;
         operational=true;
       } 
       else{ operational=false;
	   }
   }
   void toolTip(){
      if (vertical) {
        text((value)+"",x-20,y+h-bw+2);
      }
      else {
 
        text((value)+"",x+bw+2,y-2);
      }
   }
   void draw(){
     //println("a");
     //println(bw+"="+value+"-"+mn+"*"+step);
      pushStyle();
      drawFrame();
      fill(fillColor);
      
      if (vertical) rect(x,y+h-bw,w,bw);
      else rect(x,y,bw,h);
      if (museOver()) toolTip();
      popStyle();     
   }
   void adjustValue(int increment){
     if (increment%1!=0) increment=0;
      value+=increment;
      check(); 
   }
   void setValue(int nValue){
      value=nValue;
      check(); 
   }
   void setValueByClick(){
      if (vertical) value=_mn+int((y+h-my)*step);
      else value=_mn+int((mx-x)*step);
      check(); 
   }
   void check(){
      if (value<_mn) value=_mn;
      else if (value>_mx) value=_mx;
      bw=int((value-_mn)/step);
   }
}
/** end interface objects**/

/**
* Overlay objects, childred of abstract class 'overlys'
* each children must have their own draw method 
**/
class overlys{
  static int NOTYPE=-1;
  static int PATH=0;
  static int TXT=10;
  static int TIME=11;
  static int LNE=1;
  static int ARRW=2;
  static int PLYLINE=4;
  static int PLYGON=5;
  static int ELLPSE=6;
  static int CHNNEL=12;
  int strt;
  int ln;
  int ed;
  int type;
  color clr;
  overlys(){
    type=NOTYPE;
    strt=0;
    ln=0;
    ed=0;
    clr=color(0,0,0);
  }
  overlys(int s, int l, color c){
    
    strt=s;
    ln=l;
    ed=strt+ln-1;
    clr=c;
  }
  void draw(int _f){
  }
}
class lne extends overlys{
  int x0,y0,x1,y1;
  lne(int s, int l, color c, int _x0, int _y0, int _x1, int _y1){
       strt=s;
       ln=l;
       ed=strt+ln-1;
       clr=c;
       x0=_x0;
       y0=_y0;
       x1=_x1;
       y1=_y1;
       type=overlys.LNE;  
  }
  void draw(int _f){
    stroke(clr,255);
    strokeWeight(1);
    line(x0,y0,x1,y1);
  }
}
class arrw extends lne{
	int headSize;
	int[] arrowCoords;
	bool doubleHeads;
	double arrwAngle=PI/6;
	arrw(int s, int l, color c, int _x0, int _y0, int _x1, int _y1, int _hS, bool _dH){
		super(s,l,c,_x0,_y0,_x1,_y1);
		headSize=_hS;
		doubleHeads=_dH;
		if (doubleHeads) arrowCoords=new int[12];
		else arrowCoords=new int[6];
		int lngth=sqrt(pow(x1-x0,2)+pow(y1-y0,2));
		double angl=-asin((y0-y1)/lngth);
		//alert(angl);
		arrowCoords[0]=x1;arrowCoords[1]=y1;
		if (x1>=x0) {arrowCoords[2]=(int)(x1-cos(angl+arrwAngle)*headSize);arrowCoords[3]=(int)(y1-sin(angl+arrwAngle)*headSize);}
		else {arrowCoords[2]=(int)(x1+cos(angl+arrwAngle)*headSize);arrowCoords[3]=(int)(y1-sin(angl+arrwAngle)*headSize);}
		if (x1<x0) {arrowCoords[4]=(int)(x1+cos(angl-arrwAngle)*headSize);arrowCoords[5]=(int)(y1-sin(angl-arrwAngle)*headSize);}
		else {arrowCoords[4]=(int)(x1-cos(angl-arrwAngle)*headSize);arrowCoords[5]=(int)(y1-sin(angl-arrwAngle)*headSize);}
		if (doubleHeads){
			angl=-1*angl;
			arrowCoords[6]=x0;arrowCoords[7]=y0;
			if (x0>=x1) {arrowCoords[8]=(int)(x0-cos(angl+arrwAngle)*headSize);arrowCoords[9]=(int)(y0-sin(angl+arrwAngle)*headSize);}
			else {arrowCoords[8]=(int)(x0+cos(angl+arrwAngle)*headSize);arrowCoords[9]=(int)(y0-sin(angl+arrwAngle)*headSize);}
			if (x0<x1) {arrowCoords[10]=(int)(x0+cos(angl-arrwAngle)*headSize);arrowCoords[11]=(int)(y0-sin(angl-arrwAngle)*headSize);}
			else {arrowCoords[10]=(int)(x0-cos(angl-arrwAngle)*headSize);arrowCoords[11]=(int)(y0-sin(angl-arrwAngle)*headSize);}
		}
		type=overlys.ARRW;
	}
	void draw(int _f){
		
		stroke(clr,255);
		strokeWeight(1);
		//beginShape(LINES);
		line(x0,y0,x1,y1);
		pushStyle();
		fill(clr);
		triangle(arrowCoords[0],arrowCoords[1],arrowCoords[2],arrowCoords[3],arrowCoords[4],arrowCoords[5]);
		if (doubleHeads) triangle(arrowCoords[6],arrowCoords[7],arrowCoords[8],arrowCoords[9],arrowCoords[10],arrowCoords[11]);
		popStyle();
		//line(arrowCoords[0],arrowCoords[1],arrowCoords[4],arrowCoords[5]);
		//endShape();
	}
}
class ellpse extends overlys{
	int x,y,w,h;
	ellpse(int s, int l, color c, int _x, int _y, int _w, int _h){
		strt=s;
		ln=l;
		ed=strt+ln-1;
		clr=c;
		x=_x;
		y=_y;
		w=_w;
		h=_h;
		type=overlys.ELLPSE; 
	}
	void draw(int _f){
		noFill();
		stroke(clr,255);
		strokeWeight(1);
		ellipse(x,y,w,h);
	}
}
class plyline extends overlys{
  int[] xs;
  int[] ys;  
  int np;
  plyline (int s, int l, int n, color c){
     strt=s;
     ln=l;
     ed=strt+ln-1;
     clr=c;
     np=n;
     xs=new int[n];
     ys=new int[n]; 
     type=overlys.PLYLINE;  
  }  
  void loadPoint(int p, int x, int y){
      if (p>=0&&p<np) {
        xs[p]=x;
        ys[p]=y;
      }
  }
  void draw(int _f){
   noFill();
   stroke(clr,255);
   strokeWeight(1);
   beginShape();
   for (int i=0;i<np;i++){
      vertex(xs[i],ys[i]);
   } 
   if (this.type==overlys.PLYLINE) {endShape();}
   else endShape(CLOSE);
  }
}
class pth extends plyline{
  int maxDispLen;
  pth(int s, int l, int mdl, color c){
     super(s,l,l,c);
     maxDispLen=mdl;
     type=overlys.PATH; 
  }
  void draw(int _f){
   noFill();
   stroke(clr,255);
   strokeWeight(1);
   beginShape();
   for (int i=(_f-strt-maxDispLen<0)?0:(_f-strt-maxDispLen);i<=(_f-strt);i++){
      vertex(xs[i],ys[i]);
   } 
   endShape();
}
}
class plygon extends plyline{
  plygon(int s, int l, int n, color c){
     super(s,l,n,c);
     type=overlys.PLYGON; 
  }
}
class txt extends overlys{
   String value;
   int x0,y0;
   txt(int s, int l, color c, int _x, int _y, String _value) {
       strt=s;
       ln=l;
       ed=strt+ln-1;
       clr=c;
       type=overlys.TXT;
       value=_value;
       x0=_x;
       y0=_y+10;
   }
   void draw(int _f){
      pushStyle();
      fill(clr);
      text (value,x0,y0);
      popStyle();
  } 
}
class tme extends overlys{
   float init;
   float increment;
   float actual;
   int decimals;
   int x0,y0;
   String unit;
   String actTime;
   boolean unitChange;
   tme(int s, int l, color c, int _x,int _y, float _init, float _increment, String _unit){
       strt=s;
       ln=l;
       ed=strt+ln-1;
       clr=c;
       type=overlys.TIME;
       x0=_x;
       y0=_y+10;
       init=_init;
       increment=_increment;
       decimals=getDecimals(increment);
       actual=init;
       unit=_unit;
       if (ln*increment>60&&(unit=="s"||unit=="sec"||unit=="min")) unitChange=true;
   }
   int getDecimals(float fl){
      int dec=0;  
      while (fl%10!=0) {
          fl*=10;
          dec++;
      }
      return --dec; 
   }
   void setTimeString(){
      if (unitChange) actTime=nf(int(floor(actual/60)),2)+":"+nfs(actual%60,2,decimals)+" "+unit;
      else actTime=nfs(actual,2,decimals)+" "+unit;
   }
   void setTme(int noInc){
      actual=init+float(noInc)*increment;
      setTimeString();
   }
  void draw(int _f){
      pushStyle();
      fill(clr);
      setTme(_f);
      text (actTime,x0,y0);
      popStyle();
  } 
}
