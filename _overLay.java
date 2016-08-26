import java.awt.*;
import java.awt.geom.*;
import java.awt.event.*;
import java.awt.SystemColor;
import java.util.*;
import ij.*;
import ij.process.*;
import ij.gui.*;
import java.io.*;
import ij.io.*;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import java.util.zip.ZipInputStream;

import org.jdom2.Attribute;
import org.jdom2.Document;
import org.jdom2.Element;
import org.jdom2.JDOMException;
import org.jdom2.input.SAXBuilder;

import ij.measure.*;
import ij.plugin.HyperStackConverter;
import ij.plugin.filter.*;
import ij.plugin.filter.PlugInFilter;

public class _overLay implements PlugInFilter {
	ImagePlus imp;
	CompositeImage cimp;
	Calibration cal;
	int noOverlys=0;
	ArrayList overlys =new ArrayList(100);
	overlayWindow cW;
	public int slices, currSlice, channels, currChannel, W, H;
	public double px;
	public double zoom;
	private boolean loaded=false;
	private boolean[] chBxs=new boolean[4];
	public int setup(String arg, ImagePlus imp) {
		this.imp = imp;
		if (arg.equals("load")||imp==null) loadOverlay(true);
		else if (imp!=null){
			channels=imp.getNChannels();
			slices=imp.getNSlices()*imp.getNFrames();
			this.W=imp.getWidth();
			this.H=imp.getHeight();
			cal = imp.getCalibration();
			init();
		}
		return NO_IMAGE_REQUIRED+DOES_8G+DOES_16+DOES_32;
	}
	public void init(){
		if (channels>1) {
			this.cimp=(CompositeImage)imp;
			cimp.setMode(IJ.COLOR);
		}
		
		px=cal.pixelWidth;
		ImageWindow ic=new ImageWindow(imp);
		zoom=ic.getInitialMagnification();
		currSlice=1; currChannel=1;
	}
	public void loadOverlay(boolean loadImage){
		OpenDialog oD=new OpenDialog("Open .zip or overlay.xml file...","");
		String filename=oD.getFileName();
		String dirname=oD.getDirectory();
		if (filename==null||(!filename.equals("overlay.xml")&&!filename.contains(".zip"))) return;
		try{
			if (filename.contains(".zip")){
				byte[] buffer = new byte[1024];
				
				FileInputStream fs = new FileInputStream(dirname+filename);
				dirname+=filename.substring(0,filename.indexOf(".zip"))+"\\";
				new File(dirname).mkdir();
				ZipInputStream zip = new ZipInputStream(fs);
				ZipEntry ze = zip.getNextEntry();
				while(ze!=null){
					String fileName = ze.getName();
					if (loadImage||fileName.equals("overlay.xml")){
						File newFile = new File(dirname+fileName);
						FileOutputStream fos = new FileOutputStream(newFile);
						int len;
						while ((len = zip.read(buffer)) > 0) {
							fos.write(buffer, 0, len);
						}
						fos.close();
					}
					ze = zip.getNextEntry();
				}
				zip.closeEntry();
				zip.close();		
			}
			File overlayFile=new File(dirname+"overlay.xml");
			SAXBuilder saxBuilder = new SAXBuilder();
			Document document = saxBuilder.build(overlayFile);
			Element overlay = document.getRootElement();
			Element dimensions=overlay.getChild("dimensions");
			if (dimensions==null) throw new FileNotFoundException();
			Element controls=overlay.getChild("controls");
			if (controls==null) throw new FileNotFoundException();
			chBxs[0]=controls.getAttribute("isPlayable").getValue().equals("1");
			chBxs[1]=controls.getAttribute("isPlaying").getValue().equals("1");
			chBxs[2]=controls.getAttribute("overlaid").getValue().equals("1");
			chBxs[3]=controls.getAttribute("magnifyable").getValue().equals("1");
			int _channels=Integer.parseInt(dimensions.getAttribute("channels").getValue());
			int _slices=Integer.parseInt(dimensions.getAttribute("depth").getValue());
			int _W=Integer.parseInt(dimensions.getAttribute("width").getValue());
			int _H=Integer.parseInt(dimensions.getAttribute("height").getValue());
			if (loadImage){
				cal=new Calibration();
				try{
					String pw=dimensions.getAttribute("lateral_resolution").getValue();
					cal.pixelWidth=Double.parseDouble(pw);
					cal.pixelHeight=cal.pixelWidth;
					cal.pixelDepth=Double.parseDouble(dimensions.getAttribute("axial_resolution").getValue());
					cal.setUnit(dimensions.getAttribute("unit").getValue());
				}
				catch (NullPointerException ne){}
				channels=_channels;slices=_slices;W=_W;H=_H;
				ImageStack stack=new ImageStack(W,H);
				Opener o=new Opener();
				for (int i=0;i<slices;i++){
					for (int j=0;j<channels;j++){
						stack.addSlice(o.openImage(dirname+(char)(97+j)+(counter(i,3))+".jpg").getProcessor().convertToByteProcessor());
						IJ.showProgress((i*channels+j),(channels*slices));
					}
				}
				this.imp= (new HyperStackConverter()).toHyperStack(new ImagePlus("",stack), channels, slices,1);
				init();
				imp.setCalibration(cal);
				imp.show();
			}
			if (W==_W&&H==_H&&slices==_slices&&channels==_channels){
				java.util.List<Element> overlysToRead=overlay.getChildren();
				for (int i=0;i<overlysToRead.size();i++){
					Element currentChild=overlysToRead.get(i);
					Attribute typeAttr=currentChild.getAttribute("type");
					int type=0, strt=0, len=0, id=0, clor=0;
					if (typeAttr!=null) type=Integer.parseInt(typeAttr.getValue());
					if (type>0) {
						overly _tmp=null;
						id=Integer.parseInt(currentChild.getAttribute("id").getValue())+noOverlys;
						strt=Integer.parseInt(currentChild.getAttribute("strt").getValue());
						len=Integer.parseInt(currentChild.getAttribute("len").getValue());
						clor=Integer.parseInt(currentChild.getAttribute("clor").getValue());
						switch (type){
							case 1://line
								_tmp = new overly(new Line(Integer.parseInt(currentChild.getAttribute("x0").getValue()),Integer.parseInt(currentChild.getAttribute("y0").getValue()),Integer.parseInt(currentChild.getAttribute("x1").getValue()),Integer.parseInt(currentChild.getAttribute("y1").getValue())),strt+1,new Color(clor),new BasicStroke(1f),id);
								break;
							case 2://arrow
								Arrow _tarrow=new Arrow(Double.parseDouble(currentChild.getAttribute("x0").getValue()),Double.parseDouble(currentChild.getAttribute("y0").getValue()),Double.parseDouble(currentChild.getAttribute("x1").getValue()),Double.parseDouble(currentChild.getAttribute("y1").getValue()));
								_tarrow.setHeadSize(Double.parseDouble(currentChild.getAttribute("head_size").getValue()));
								_tarrow.setDoubleHeaded(currentChild.getAttribute("double_head").getValue().equals("1"));
								_tmp = new overly(_tarrow,strt+1,new Color(clor),new BasicStroke(1f),id);
								break;
							case 4:
							case 5:
								int n=Integer.parseInt(currentChild.getAttribute("n").getValue());
								int[] x=new int[n]; int[] y=new int[n];
								java.util.List<Element> points=currentChild.getChildren();
								for (int j=0;j<points.size();j++){
									String[] p=points.get(i).getText().split(",");
									x[j]=Integer.parseInt(p[0]);
									y[j]=Integer.parseInt(p[1]);
								}
								PolygonRoi _tpoly=null;
								if (type==4) _tpoly=new PolygonRoi(x,y,n,Roi.POLYLINE);
								else _tpoly=new PolygonRoi(x,y,n,Roi.POLYGON);
								_tmp = new overly(_tpoly,strt+1,new Color(clor),new BasicStroke(1f),id);
								break;
							case 6:
								_tmp = new overly(new OvalRoi(Integer.parseInt(currentChild.getAttribute("x").getValue()),Integer.parseInt(currentChild.getAttribute("y").getValue()),Integer.parseInt(currentChild.getAttribute("wdth").getValue()),Integer.parseInt(currentChild.getAttribute("heght").getValue())),strt+1,new Color(clor),new BasicStroke(1f),id);
								break;
							case 10:
							case 11:
							case 12:
								String _txt=currentChild.getText();
								if (type==11) _txt="time:"+_txt+":"+currentChild.getAttribute("inc").getValue()+":"+currentChild.getAttribute("unit").getValue();
								else if (type==12) _txt="channel:"+currentChild.getAttribute("channel_no").getValue()+":"+currentChild.getText();
								_tmp = new overly(new TextRoi(Integer.parseInt(currentChild.getAttribute("x").getValue()),Integer.parseInt(currentChild.getAttribute("y").getValue()),_txt),strt+1,new Color(clor),new BasicStroke(1f),id);
								break;
						}
						if (_tmp!=null) {
							_tmp.setDepth(len);
							overlys.add(_tmp);
							noOverlys++;
							if (!loadImage) cW.overlyList.add(_tmp.getName());
						}
					}
					
				}
			}
			else IJ.showMessage("The dimensions specified in the 'overlay.xml' do not match the image dimensions");
			if (filename.contains(".zip")){
				File dirToDelete=new File(dirname);
				String[] files=dirToDelete.list();
				for (int i=0;i<files.length;i++) new File(dirToDelete, files[i]).delete();
				dirToDelete.delete();
			}
			loaded=loadImage;
		}
		catch (JDOMException e){
			IJ.showMessage(e.getLocalizedMessage());
		}
		catch (FileNotFoundException fne) {
			IJ.showMessage("overlay.xml was not found or corrupt!" + fne.getMessage());
		} 

		catch (IOException ioe) {
			IJ.showMessage("I/O error: " + ioe.getMessage());
		}
		catch (Throwable t){
			IJ.showMessage("Something unexpected happened : " + t.getLocalizedMessage());
		}
	}
	public void run(ImageProcessor ip){
		cW=new overlayWindow(imp, loaded);
	}
	public class overly {
		Roi r;
		int type;
		int x,y,z,d;
		private String name;
		int id;
		Color color;
		/*BasicStroke stroke;*/
		
		overly(Roi _r, int _z, Color _color, BasicStroke _stroke, int _id){
			this.r=_r;
			this.z=_z;
			this.d=1;
			Rectangle rect=r.getBounds();
			this.x=rect.x;
			this.y=rect.y;
			this.type=r.getType();
			this.color=_color;
			/*this.stroke=_stroke;*/
			this.r.setStroke(_stroke);
			this.r.setStrokeColor(_color);
			this.id=_id;
			switch (r.getType()){
				case Roi.LINE:
					name="line_";
					type=1;
					
					break;
				case Roi.POINT:
					name="pt_";
					type=3;
					break;
				case Roi.NORMAL:
				
				case Roi.FREELINE:
				//case Roi.FREEROI:
				case Roi.POLYLINE:
					name="poly_";
					type=4;
					
					break;
				case Roi.POLYGON:
				case Roi.RECTANGLE:
					name="poly_";
					type=5;
					break;
				case Roi.OVAL:
					name="oval_";
					type=6;
					break;
				default:
					name="roi_";
					break;
			}
			try{
				if (((TextRoi)r).getText()!="") {
					String[] params=((TextRoi)this.r).getText().split(":");
					double secondParam=0.0;
					try{	
						secondParam=Double.parseDouble(params[1]);
					}
					catch (Throwable t){}
					if (params.length==4&&params[0].equals("time")) {
						name="time_";
						type=11;
					}
					else if (params.length==3&&params[0].equals("channel")&&secondParam>0&&secondParam<=channels) {
						name="channel"+params[1]+"_";
						type=12;
					}
					else if (params.length==2&&params[0].equals("scale")){
						int l=(int)(secondParam/px);
						Rectangle rct=this.r.getBounds();
						int y=rct.y+5;
						//IJ.log((int)(rct.x-l/2)+","+y+","+(int)(rct.x+l/2)+","+y);
						this.r=new Line((int)(rct.x-l/2),y,(int)(rct.x+l/2),y);
						name="scale"+params[1]+"_";
						type=1;
					}
					else{
						name="text_";
						type=10;
					}
				
				}
				
			}
			catch (Throwable t){}
			try{
				if (((Arrow)r).getHeadSize()>0){
					name="arrow_";
					type=2;
				}
			}
			catch (Throwable t){}
			name+=id+","+z;
		}
		public String getName(){
			return name;
		}
		public void setDepth(){
			//IJ.log(currSlice+"-"+this.z);
			setDepth(currSlice-this.z);
		}
		public void setDepth(int _d){
			if (_d<0) {
				this.z+=_d;
				this.d=-_d+1;
			}
			else if (_d>0) this.d=_d+1;
			name+="-"+d;
		}
		public String getXMLCode(){
			String ret="";
			switch(type){
				case 1:
					Polygon p=((Line)this.r).getPoints();
					ret="<line type=\"1\" id=\""+this.id+"\" clor=\""+(this.colorToInt())+"\" strt=\""+(z-1)+"\" len=\""+d+"\" x0=\""+p.xpoints[0]+"\" y0=\""+p.ypoints[0]+"\" x1=\""+p.xpoints[1]+"\" y1=\""+p.ypoints[1]+"\"></line>";
					break;
				case 2:
					p=((Line)this.r).getPoints();
					int dH=((Arrow)this.r).getDoubleHeaded()?1:0;
					int HS=(int)((Arrow)this.r).getHeadSize() ;
					ret="<arrow type=\"2\" id=\""+this.id+"\" clor=\""+(this.colorToInt())+"\" strt=\""+(z-1)+"\" len=\""+d+"\" x0=\""+p.xpoints[0]+"\" y0=\""+p.ypoints[0]+"\" x1=\""+p.xpoints[1]+"\" y1=\""+p.ypoints[1]+"\" head_size=\""+HS+"\" double_head=\""+dH+"\"></arrow>";
					break;
				case 4:
				case 5:
					p=this.r.getPolygon();
					ret="<polygon type=\""+type+"\" id=\""+this.id+"\" clor=\""+(this.colorToInt())+"\" strt=\""+(z-1)+"\" len=\""+d+"\" n=\""+p.npoints+"\">\n";
						for (int j=0;j<p.npoints;j++){
							ret+="<p>"+p.xpoints[j]+","+p.ypoints[j]+"</p>\n";
						}
						ret+="</polygon>";
					break;
				case 6:
					Rectangle rct=this.r.getBounds();
					//IJ.log(rct.x+"");
					ret=("<ellipse type=\"6\" id=\""+this.id+"\" clor=\""+(this.colorToInt())+"\" strt=\""+(z-1)+"\" len=\""+d+"\" x=\""+rct.x+"\" y=\""+rct.y+"\" wdth=\""+rct.width+"\" heght=\""+rct.height+"\"></ellipse>");
					break;
				case 10:
					rct=this.r.getBounds();
					ret="<text type=\"10\" id=\""+this.id+"\" clor=\""+(this.colorToInt())+"\" strt=\""+(z-1)+"\" len=\""+d+"\" x=\""+rct.x+"\" y=\""+rct.y+"\">"+((TextRoi)this.r).getText()+"</text>";
					break;
				case 11:
					rct=this.r.getBounds();
					String[] params=((TextRoi)this.r).getText().split(":");
					ret="<time type=\"11\" id=\""+this.id+"\" clor=\""+(this.colorToInt())+"\" strt=\""+(z-1)+"\" len=\""+d+"\" x=\""+rct.x+"\" y=\""+rct.y+"\" unit=\""+params[3]+"\" inc=\""+params[2]+"\">"+params[1]+"</time>";
					break;
				case 12:
					rct=this.r.getBounds();
					params=((TextRoi)this.r).getText().split(":");
					ret="<channel type=\"12\" id=\""+this.id+"\" clor=\""+(this.colorToInt())+"\" strt=\""+(z-1)+"\" len=\""+d+"\" x=\""+rct.x+"\" y=\""+rct.y+"\" channel_no=\""+params[1]+"\">"+params[2]+"</channel>";
					break;
				default:
					break;
			}
			return ret;
		}
		private int colorToInt(){
			return color.getRed()*65536+color.getGreen()*256+color.getBlue();
		}
	}
	private class overlayWindow extends StackWindow implements ActionListener, AdjustmentListener, ItemListener, MouseWheelListener{ //, MouseListener,  KeyListener{
		Button addButton;
		Button updateButton;
		Button removeButton;
		Button expandButton;
		Button exportButton;
		Button loadButton;
		Checkbox zipBox, isPlaying, playable, showOverlay, magnifyable;
		TextField jpegQuality, FPSBox;
		java.awt.List overlyList;
		ScrollbarWithLabel[] scrlB=new ScrollbarWithLabel[2];
		int CH=-1, SLCS=-1;
		Toolbar tB;
		int currOverly=0;
		BasicStroke stroke;
		
		
		Color currColor=Color.RED;
		private overlayWindow(ImagePlus imp, boolean initOverlay) {
        	super(imp);
			//StackWindow sw=new StackWindow(imp);
			//IJ.log(+"");
			imp.setSlice(1);
			currSlice=1;
			
			stroke=new BasicStroke(1f);
			
			GridBagLayout gbl=new GridBagLayout(); 
			setLayout(gbl); 
			GridBagConstraints c = new GridBagConstraints();
			c.fill = GridBagConstraints.HORIZONTAL;
			c.gridx = 0;
			c.gridwidth=1;
			c.gridy = 0;
			c.insets = new Insets(1,1,1,1);
			exportButton=new Button("Export");
			exportButton.addActionListener(this);
			add(exportButton,c);
			c.gridx++;
			c.insets = new Insets(1,1,1,1);
			zipBox=new Checkbox("save .zip file",true);
			add(zipBox,c);
			c.gridx++;
			add(new Label("Image quality:"),c);
			c.gridx++;
			jpegQuality=new TextField("80");
			add(jpegQuality,c);
			c.gridx++;
			loadButton=new Button("Load overlay");
			loadButton.addActionListener(this);
			add(loadButton,c);
			c.gridx=0;
			c.gridy++;
			addButton=new Button("Add");
			addButton.addActionListener(this);
			add(addButton,c);
			c.gridx++;
			updateButton=new Button("Update");
			updateButton.addActionListener(this);
			updateButton.setEnabled(false);
			add(updateButton,c);
			c.gridx++;
			expandButton=new Button("Expand");
			expandButton.addActionListener(this);
			expandButton.setEnabled(false);
			add(expandButton,c);
			c.gridx++;
			removeButton=new Button("Remove");
			removeButton.addActionListener(this);
			removeButton.setEnabled(false);
			add(removeButton,c);
			//c.insets = new Insets(1,1,10,1);
			//c.anchor = GridBagConstraints.EAST;
			
			
			c.gridx = 0;
			c.gridy++;
			overlyList=new java.awt.List (1,false);
			Font f=new Font("Arial",Font.PLAIN,10);
			
			overlyList=new  java.awt.List ((int)(H*zoom/overlyList.getFontMetrics(f).getHeight()),false);
			//overlyList.addNotify();
			//IJ.log(zoom+","+overlyList.getFontMetrics(f).getHeight()+"");
			overlyList.setFont(f);
			//IJ.log(overlyList.getFontMetrics(f).getHeight()+"");
			overlyList.addItemListener (this);
			add(overlyList,c);
			c.gridx = 1;
			c.gridwidth=10;
			
			c.insets = new Insets(0,0,0,0);
			
			gbl.setConstraints(getComponent(0),c);
			getComponent(0).addComponentListener(new ComponentListener(){
				@Override
				public void componentResized(ComponentEvent e) {
					//IJ.log(overlyList.getSize().width+","+getComponent(0).getSize().height);
					overlyList.setPreferredSize(new Dimension(overlyList.getSize().width,getComponent(0).getSize().height));
				}
				public void componentHidden(ComponentEvent e) {}
				public void componentMoved(ComponentEvent e) {}
				public void componentShown(ComponentEvent e) {}
			});
			int cnt=0;
			
			if (channels>1){
				scrlB[cnt]=(ScrollbarWithLabel)getComponent(cnt+1);
				CH=cnt;
				cnt++;
				
			}
			if (slices>1){
				scrlB[cnt]=(ScrollbarWithLabel)getComponent(cnt+1);
				scrlB[cnt].setMaximum(slices+1);
				SLCS=cnt;
				cnt++;
			}
			if (super.getNScrollbars()>2) getComponent(cnt+1).setVisible(false);
			for (int a=0;a<cnt;a++) {
				c.gridy++;
				gbl.setConstraints(scrlB[a],c);
				scrlB[a].addAdjustmentListener(this);
			}
			c.gridx = 0;
			c.gridy++;
			c.gridwidth=1;
			c.insets = new Insets(1,1,1,1);
			c.anchor = GridBagConstraints.WEST;
			playable=new Checkbox("Can be played",chBxs[0]);
			add(playable,c);
			c.gridx++;
			isPlaying=new Checkbox("Is playing",chBxs[1]);
			add(isPlaying,c);
			c.gridx++;
			showOverlay=new Checkbox("Show overlay",chBxs[2]);
			add(showOverlay,c);
			c.gridx++;
			magnifyable=new Checkbox("Magnifyer",chBxs[3]);
			add(magnifyable,c);
			c.gridx++;
			add(new Label("Playback speed (5-60FPS):"),c);
			c.gridx++;
			FPSBox=new TextField("25");
			add(FPSBox,c);
			tB=Toolbar.getInstance();
			currColor=tB.getForegroundColor();
			pack();
			if (initOverlay) {
				for (int i=0;i<overlys.size();i++){
					overlyList.add(((overly)overlys.get(i)).getName());
				}
				updateCanvas();
			}
		}		
		public void updateCanvas(){
			
			Overlay ol=new Overlay();

			for (int i=0;i<noOverlys;i++){
				overly o=(overly)(overlys.get(i));
				//IJ.log(o.getName()+":"+o.z+"-"+(o.z+o.d-1)+"~"+currSlice);
				if (o.z<=currSlice&(o.z+o.d-1)>=currSlice) ol.add(o.r);
			}

			imp.setOverlay(ol);
	
		}
		public void itemStateChanged(ItemEvent e){
			currOverly=overlyList.getSelectedIndex();
			overly o=(overly)(overlys.get(currOverly));
			imp.setRoi(o.r);
			currSlice=o.z;
			if (SLCS>-1) scrlB[SLCS].setValue(currSlice);
			imp.setSlice((currSlice-1)*channels+currChannel);
			updateButton.setEnabled(true);
			expandButton.setEnabled(true);
			removeButton.setEnabled(true);
			updateCanvas();
		}
		public synchronized void actionPerformed(ActionEvent e) {
			Object eS=e.getSource();
			if (SLCS>-1) currSlice=scrlB[SLCS].getValue();//imp.getSlice();
			//IJ.log(currSlice+"");
			if (eS==addButton) {
				Roi r = imp.getRoi();
				if (r!=null) addOverlay(r);
				//imp.setRoi(0,0,0,0);
				updateButton.setEnabled(true);
				expandButton.setEnabled(true);
				removeButton.setEnabled(true);
				this.updateCanvas();
			}
			if (eS==updateButton) {
				Roi r = imp.getRoi();
				if (r!=null) updateOverlay(r);
				//imp.setRoi(0,0,0,0);
				updateButton.setEnabled(true);
				expandButton.setEnabled(true);
				removeButton.setEnabled(true);
				this.updateCanvas();
			}
			if (eS==removeButton) {
				if (currOverly>-1){
					overlys.remove(currOverly);
					overlyList.remove(currOverly);
					noOverlys--;
					currOverly=-1;
					imp.setRoi(0,0,0,0);
					this.updateCanvas();
				}
			}
			if (eS==expandButton) {
				if (currOverly!=-1){
					
					((overly)overlys.get(currOverly)).setDepth();
					this.updateCanvas();
				}
			}
			if (eS==exportButton) {
				export();
			}
			if (eS==loadButton) {
				loadOverlay(false);
				this.updateCanvas();
			}
			if (eS==overlyList) {
				//IJ.log("list");
			}
			
		}
		public synchronized void adjustmentValueChanged(AdjustmentEvent e) {
			if (CH>-1&&e.getSource() == scrlB[CH]) {
				currChannel=scrlB[CH].getValue();
				imp.setC(currChannel);		
			}	
			if (SLCS>-1&&e.getSource() == scrlB[SLCS]) {
				currSlice=scrlB[SLCS].getValue();	
			}
			//IJ.log(currChannel+","+currSlice+"="+((currSlice-1)*channels+currChannel));
			imp.setSlice((currSlice-1)*channels+currChannel);
			this.updateCanvas();	
		}
		public void mouseWheelMoved(MouseWheelEvent e) {
			int notches = e.getWheelRotation();
			currSlice+=notches;
			if (currSlice<1) currSlice=1;
			if (currSlice>slices) currSlice=slices;
			scrlB[SLCS].setValue(currSlice);
			imp.setSlice((currSlice-1)*channels+currChannel);
			
			this.updateCanvas();
		}
		private void updateOverlay (Roi r){
			currColor=tB.getForegroundColor();
			overly o=new overly(r, currOverly.z, currColor, stroke, currOverly);
			o.setDepth(currOverly.d)
			overlys.set(currOverly,o);
			//imp.setRoi(0,0,0,0);
			overlyList.replaceItem(o.getName(),overlyList.getSelectedIndex());
			this.updateCanvas();	
			
		}
		private void addOverlay (Roi r){
			currColor=tB.getForegroundColor();
			overly o=new overly(r, currSlice, currColor, stroke, noOverlys);
			overlys.add(o);
			//imp.setRoi(0,0,0,0);
			overlyList.add(o.getName());
			currOverly=noOverlys;
			noOverlys++;
			this.updateCanvas();	
			
		}
		private void export(){
			SaveDialog sd=new SaveDialog("Save file...","","");
			String dirname=sd.getDirectory()+sd.getFileName();
			int W=imp.getWidth();
			int H=imp.getHeight();
			int jQ, FPS;
			try{
				jQ=Integer.parseInt(jpegQuality.getText());
				FPS=Integer.parseInt(FPSBox.getText());
				if (FPS<5||FPS>60) FPS=25;
			}
			catch (NumberFormatException e){
				IJ.showMessage("Wrong nuber format for jpeg quality or FPS");
				return;
			}
			try{
				new File(dirname).mkdir();
				String filename=dirname+"\\overlay.xml";
				PrintWriter output = new PrintWriter(new FileWriter(filename));
				output.println("<?xml version=\"1.0\"?>");
				output.println("<overlay>");
				String unit=cal.getUnit();
				if (unit.equals("µm")) unit="um";
				output.println("<dimensions id=\"99\" width=\""+W+"\" height=\""+H+"\" depth=\""+slices+"\" channels=\""+channels+"\" ext=\".jpg\" lateral_resolution=\""+px+"\" axial_resolution=\""+cal.pixelDepth+"\" unit=\""+unit+"\"></dimensions>");
				output.println("<controls id=\"98\" isPlayable=\""+(playable.getState()?1:0)+"\" isPlaying=\""+(isPlaying.getState()?1:0)+"\" FPS=\""+FPS+"\" overlaid=\""+(showOverlay.getState()?1:0)+"\" magnifyable=\""+(magnifyable.getState()?1:0)+"\" mag_size=\"30\" isResizeable=\"0\"></controls>");
				//IJ.log("<line type=\"1\" id=\"97\" clor=\""+((255<<16)+(255<<8)+255)+"\" strt=\"0\" len=\""+(valid_slices)+"\" x0=\""+((int)(W-10-10/px))+"\" y0=\""+(H-10)+"\" x1=\""+(W-10)+"\" y1=\""+(H-10)+"\"></line>");
				Iterator<overly> oI=overlys.iterator();

				while(oI.hasNext()){
					
					output.println(oI.next().getXMLCode());
				
				}
				output.println("</overlay>");
				output.close();	
				
						
			}
		
			catch (FileNotFoundException fne) {
				IJ.showMessage("File not found!" + fne.getMessage());
			} 

			catch (IOException ioe) {
				IJ.showMessage("I/O error: " + ioe.getMessage());
			}
			
			for (int j=0;j<channels;j++){
				imp.setC(j+1);
				for (int i=0;i<slices;i++){
					imp.setSliceWithoutUpdate(i*channels+j+1);
					ImageProcessor tip=imp.getProcessor();
					ImagePlus timp=new ImagePlus (((char)(97+j)+""+j),tip.createImage());
					ImageConverter tic=new ImageConverter(timp);
					tic.convertToRGB();
					FileSaver fs=new FileSaver(timp);
					fs.setJpegQuality(jQ);
					fs.saveAsJpeg(dirname+"\\"+(char)(97+j)+(counter(i,3))+".jpg");
				}	
			}
			if (zipBox.getState()) {
				try{
					byte[] buffer = new byte[1024];
					File[] toCompress = new File(dirname).listFiles();
					String zipname=dirname+".zip";
					FileOutputStream fs = new FileOutputStream(zipname);
					ZipOutputStream zip = new ZipOutputStream(fs);
					for (int i=0;i<toCompress.length;i++){
						FileInputStream inputStr=new FileInputStream(toCompress[i]);
						zip.putNextEntry(new ZipEntry(toCompress[i].getName()));
						int l;
						while ((l = inputStr.read(buffer)) > 0) {
							zip.write(buffer, 0, l);  
						}
						zip.closeEntry();
						inputStr.close();
						toCompress[i].delete();
					}
					zip.close();
					new File(dirname).delete();
				}
				catch (IOException ioe) {
					IJ.showMessage("I/O error: " + ioe.getMessage());
				}
			}
			IJ.showStatus("Files saved");
		}

	}
	private String counter(int a, int l){
		String ret=a+"";
		//IJ.log(ret+"-"+ret.length()+"-"+(l-ret.length()));
		int e=l-ret.length();
		for (int i=0;i<e;i++) ret="0"+ret;
		return ret;
	}
}