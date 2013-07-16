//****************************************************************************
//eyeblaster.data.SmartVersioning class
//---------------------------
//
//This class is part of the SmartVersioning component which enables to change ads dynamically from MediaMind.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.data
{	
	import eyeblaster.core.Tracer;
	import eyeblaster.events.*;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.system.*;
	import flash.net.*;
	import flash.utils.*;
	import flash.utils.getDefinitionByName;
	
	[Event("XMLloaded", type="Event")]
	[Event("Complete", type="eyeblater.events.EBSmartVersioningEvent")]
	[Event("DownloadComplete", type="eyeblater.events.EBSmartVersioningEvent")]
	[Event("Error", type="eyeblater.events.EBErrorEvent")]
	
	public class SmartVersioning extends MovieClip
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		// Private vars declaration
		private var _autoPopulate:Boolean = true;
		private var _data:XML;
		private var counter:int;
		private var urls:Array;
		private var totalXMLs:int //total number of xmls for the component. For example 3 products xmls + 1 additional data xml
		private var loadedXMLs:Array; // array holding the recieved XML files
		private var xmlURL:URLRequest;
		private var xmlLoader:URLLoader;
		private var	manualItems=[];   // holds manually added items 
		private var fontToLoadQueue:Object = new Object(); // maintains a queue of items waiting on previous loaded font swf to load
		private var primaryFontQueue:Object = new Object();// maintains a list of font swf's already loaded
				
		
		// variables needed for loading font assets
		private var fontsToLoad:int = 0;
		private var swfsToLoad:int = 0;
		private var loadedFonts:Object = new Object();		//loaded fonts hash table (map loaded font to its target textField
		private var ignoreTextFormat:Object = {defaultTextFormat:true,text:true,embedFonts:true,name:true,htmlText:true,visible:true,font:true}

		private var nc:NetConnection;
		private var ns:NetStream;
		
		private var map:Object; // Holds the JS maping of display names --> instance names and products order
		
		private var singleUpdate:Boolean; // specify if updating all items at once or just a single item
		
		private var EBClass:Object = null; // holds the EB or EBStd class
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//	Version & component detection
		include "../core/compVersion.as"
		public var compName:String = "SmartVersioning";	//The component name to be used for components detection.
		
		// Setters & Getters
		[Inspectable (type="Boolean", defaultValue=true)]
		public function set autoPopulate(autoPopulateValue:Boolean)
		{
			_autoPopulate = autoPopulateValue;
		}
		public function get autoPopulate():Boolean
		{
			return _autoPopulate;
		}
		
		public function set data(xmlData:XML)
		{
			_data = xmlData;
		}
		public function get data():XML
		{
			return _data;
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		// contructor function
		function SmartVersioning()
		{
			EBClass = getEBClass();
			if (EBClass==null)
			{
				Tracer.debugTrace("Error in SmartVersioning: calling to Init in one of the EB classes is missing",0);
				return;
			}
			Tracer.debugTrace("SmartVersioning: Constructor", 6);
			Tracer.debugTrace("SmartVersioning version: " + compVersion, 0);	
			// Admin component identification
			EBClass["ebSetComponentName"]("SmartVersioning");	
			// hide component icon at runtime
			this.alpha = 0;
			if (this.hasOwnProperty("_helper_text")){
				this["_helper_text"].visible=false;
			}

			// in AS3 the UI parameters get their value only on the next enter frame event
            addEventListener(Event.ENTER_FRAME, loadXML);				
	
		}

		private function getEBClass():Object
		{
			var ebClass:Object = null;
			try
			{
				ebClass = getDefinitionByName("EBBase");
			}
			catch(e:ReferenceError)
			{
				try
				{
					ebClass = getDefinitionByName("EBStd");
				}
				catch(e:ReferenceError)
				{
					Tracer.debugTrace("SmartVersioning Error: Please add EB.Init(this) or EBStd.Init(this) to the script of the first frame", 0);	
				}
			}
			return ebClass;
		}
		
		//===============
		//	createMap
		//===============
		// Creates the maping object of display names --> instance names and products order
		private function createMap():void
		{
			var svMap:String=root.loaderInfo.parameters.ebAdMap;
			if(svMap!=null){
				map=new Object();
				// break to array holding eacg display name and its corresponding instance names
				var DisplayNames:Array=svMap.split(String.fromCharCode(127));
				var tempArr:Array;
				for (var ind:int=0; ind<DisplayNames.length; ind++){
					tempArr=DisplayNames[ind].split("|");
					// create hash table with display name as the key and array of instance names for each display name
					map[tempArr[0]]=tempArr.slice(1);
				}	
			}else{
				dispatchErrorEvent("No ebAdMap available");
			}
		}
		
		//===============
		//	loadXML
		//===============
		// XML loader function - load the XML file
		private function loadXML(event:Event):void
		{
			var i:int;
			
			try
			{
				removeEventListener(Event.ENTER_FRAME, loadXML);
				if (root.loaderInfo.parameters.ebAdVersions == undefined){
					if (root.loaderInfo.parameters.ebAdXML != undefined)
					{
						// this is a regular version of SV with simple XML format
						urls = [root.loaderInfo.parameters.ebAdXML];
						loadedXMLs=new Array();
					}
				}else{
					// this is a catalog version of SV (SVP) with new XML format
					// we need to create the map hash table
					createMap(); 
					// Get the XML list and create the full links of XMLs in an array
					var ResPath:String=root.loaderInfo.parameters.ebResPath;
					var SVBasePath:String=root.loaderInfo.parameters.ebAdSVBasePath;
					var XMLs:String=root.loaderInfo.parameters.ebAdVersions;
					urls=XMLs.split(",");
					for (i=0; i<urls.length; i++){
						urls[i]=ResPath+SVBasePath+urls[i]+".xml";
					}
					
					//SV inside SVP
					if (root.loaderInfo.parameters.ebAdXML != undefined && root.loaderInfo.parameters.ebAdXML != "")
						urls.push(root.loaderInfo.parameters.ebAdXML); // this is an additional SV data XML 
					
					loadedXMLs=new Array(urls.length);
				}
				_data=<SmartData></SmartData>;  // the base node of the XML data to which we will add the data from the recieved XML files
				
				totalXMLs = urls.length;
				
				// load first (0) XML from the XMLs list
				counter = 0;
				xmlURL = new URLRequest(urls[counter]);
				xmlLoader = new URLLoader();
				xmlLoader.addEventListener(Event.COMPLETE, insertData);
				xmlLoader.load(xmlURL);			
			}
			catch(e:Error)
			{
				Tracer.debugTrace("Exception in SmartVersioning: loadXML: "+ e, 1);
				dispatchErrorEvent(e.message);
			}
		}
		
		private function insertData(cEvent:Event)
		{
			var catalogue:Boolean = false;
			try{
				if (XML(cEvent.target.data).@catalogue==true)
					catalogue = true;
			}
			catch(error:Error){}
			// insert each XML we recieve into its correct place in the XML data array 
			if (catalogue)//product XML
			{
				loadedXMLs[counter]=cEvent.target.data;
				counter++;
			}else{ // additional sv items
				loadedXMLs[totalXMLs-1]=cEvent.target.data; //insert additional sv data ALWAIS at the end of loadedXMLs
				totalXMLs--;
			}
			
			if (counter!=totalXMLs)
			{
				xmlURL = new URLRequest(urls[counter]);
				xmlLoader = new URLLoader();
				xmlLoader.addEventListener(Event.COMPLETE, insertData);
				xmlLoader.load(xmlURL);
			}
			else
			{
				// When all the XMLs are recieved - start creating the main XML
				parseXML();
			}
		}
		
		//===============
		//	parseXML
		//===============
		// Create a large SV XML from all the recieved XML files
		private function parseXML ():void
		{
			try
			{		
				var ClickThroughURL:String; // will hold the ClickThrough URL for each SmartItem
				var ProductID:String; // will hold the Product ID for each SmartItem
				var ThirdPartyCT:String; // will hold the 3rd party ClickThrough for each SmartItem
				var ThirdPartyImpsArr:Array=new Array(); // will hold the 3rd party Impressions for all catalog items
				var ThirdPartyImps:String;
				var SmartItem:XML;
				for (var i:int=0; i<loadedXMLs.length; i++){
					// go through all the XML files in the data array
					var tempXML:XML = new XML(loadedXMLs[i]);
					// if this is a version (catalogue XML with only 1 product) - set the ClickThrouh at EB
					if (loadedXMLs.length==1 && tempXML.@catalogue=="true")
					{
						var SV2CT:String="SV2:"+tempXML.@productClickThrough+String.fromCharCode(127)+tempXML.@productID;
						// next we check if 3rd party ClickThrough was defined and add it
						if (tempXML.@ThirdPartyClickThrough!="")
							SV2CT+=String.fromCharCode(127)+tempXML.@ThirdPartyClickThrough;						
						EBClass["SVversionCT"]=SV2CT;
					}	
					// get the XML data
					ClickThroughURL=tempXML.attribute("productClickThrough");
					// save the ClickThrough URL from the main node if it exists
					ProductID=tempXML.attribute("productID");
					// save the product ID
					ThirdPartyCT=tempXML.attribute("ThirdPartyClickThrough");
					// save the 3rd party ClickThrough URL from the main node if it exists
					ThirdPartyImps=tempXML.attribute("ThirdPartyImps");
					if (ThirdPartyImps!="")
						ThirdPartyImpsArr.push(ThirdPartyImps);
					// save 3rd party Impression URLs to the ThirdPartyImpsArr array
					
					for (var j:int=0; j<tempXML.children().length(); j++){
						// go through all the SmartItems in the XML
						SmartItem=tempXML.children()[j];
						// add product index atrtribute (for getClickThroughByIndex API)
						SmartItem.@productIndex=i;
						if (ClickThroughURL!=""){
							// if ClickThrough was specified in this XML, add this as an attribute for each SmartItem
							SmartItem.@ClickThroughURL=ClickThroughURL;
						}
						if (ProductID!=""){
							// if ProductID was specified in this XML, add this as an attribute for each SmartItem
							SmartItem.@ProductID=ProductID;
						}
						if (ThirdPartyCT!=""){
							// if ThirdPartyClickThrough was specified in this XML, add this as an attribute for each SmartItem
							SmartItem.@ThirdPartyClickThrough=ThirdPartyCT;
						}						
						if (tempXML.attribute("catalogue")=="true"){
							// if this is a catalog, get the instance name from the map and add it as an attribute to the SmartItem
							SmartItem.@instanceName=map[SmartItem.@displayName][i];
						}
						// append this data to the main XML data
						_data=_data.appendChild(SmartItem);
						
					}
				}
				dispatchEvent(new EBSmartVersioningEvent("XMLloaded", null));
				if (ThirdPartyImpsArr.length>0)
					reportThirdPartyImps(ThirdPartyImpsArr);
				// report 3rd party impressions if exist	
				if (autoPopulate)
					autoPopulateObjects(null);
			}
			catch(e:Error)
			{
				Tracer.debugTrace("Exception in SmartVersioning: parseXML: "+ e, 1);
				dispatchErrorEvent(e.message);
			}					
		}
		
		//===============
		//	autoPopulateObjects
		//===============
		// auto populating function
		private function autoPopulateObjects(objectName:String):void
		{
			try
			{
				var xmlList:XMLList;
				if (objectName==null)
					xmlList=XMLList(this._data.SmartDataItem);
				else
					xmlList=XMLList(this._data.SmartDataItem.(@instanceName==objectName));
				var obj:Object;
				var pathArr:Array;
				var asset:String;
				var url:URLRequest;
				var ClickThrough:String;
				var assetLoader:Loader;
				var context:LoaderContext;
				var loadingFont:Boolean=false; // for single update - is loading external font
				
				Security.allowDomain("*");
				singleUpdate=(objectName!=null);
				manualItems=[];
				swfsToLoad=0;
				// loop over the XML tags
				for (var i:int = 0; i < xmlList.length(); i++) 
				{
					// find the element in the flash
					pathArr = xmlList[i].attribute("instanceName").split(".");					
					try
					{
						obj = root[pathArr[0]];
					}
					catch(e:Error)
					{
						obj=null;
					}
					var objFound:Boolean = true;
					
					if (obj!=null){
						for (var j:int=1; j < pathArr.length; j++)
						{
							if (obj[pathArr[j]]!=null){
								obj = obj[pathArr[j]];
							}else{
								// might be a manual item within a loaded SWF
								if (objectName==null){
									// autopopulate
									objFound = false;
									// add the suspected manual item to the manualitems array
									manualItems.push(xmlList[i].attribute("instanceName"));	
								}else{
									// trying to load a manual item - we need to find where the SWF is in the path and access its contentLoaderInfo 
									var paths:Array=objectName.split(".");
									var savePaths:Array=objectName.split(".");;
									var SWFContainer:String;
									
									for (var m:int=0; m<paths.length; i++){
										paths.pop();
										SWFContainer=paths.toString().replace(",",".");
										
										// check to see if SWFContainer is in the XML data and is typed flash
										var lst:XMLList=data.SmartDataItem.(@instanceName==SWFContainer && @type=="flash");
										
										if (lst.length()>0){
											// found the SWF container
											obj=root[paths[0]];
											for (var n:int=1; n < paths.length; n++)
											{
												if (obj[paths[n]]!=null){
													obj = obj[paths[n]];
												}
											}			
											// this will re-route the obj reference to reference the content of the loaded SWF
											obj=obj["SVLoaderInst"].contentLoaderInfo.content;
											for (n=paths.length; n < savePaths.length; n++)
											{
												if (obj[savePaths[n]]!=null){
													obj = obj[savePaths[n]];
												}
											}											
											break;
										}
									}
								}
							}
						}
					}
					if (!objFound)
						obj=null; // this will prevent further processing of this item
					// the element was found
					if (objectName==null || objectName==xmlList[i].attribute("instanceName")){
						if (obj != null)
						{
							var objType:String=String(xmlList[i].attribute("type"));
							// set ClickThrough option for the SmartItems that have visible object instance
							if (objType!="sound" && objType!="dataSource" && objType!="variable"){
								// set ClickThrough only if "allowClickThrough" was set to true and ClickThrough was specified
								if (String(xmlList[i].attribute("allowClickThrough"))=="true"){
									var isVideoPlayback:Boolean=false;
									if (obj.hasOwnProperty("compName"))
										isVideoPlayback = obj["compName"]=="VideoPlayback" || obj["compName"]=="VideoScreenPlayer";
									
									if (isVideoPlayback){
										// we will attach the event to the VideoLoader or VideoScreen instance so it won't be triggered by the controller
										if(obj["compName"]=="VideoPlayback")
											obj.video.parent.addEventListener(MouseEvent.CLICK, manageClickThrough);
										else
											//inside a VideoScreenPlayer we have a VideoScreen instance called "screen"
											//for some reasen we attach the click event to a VideoScreen instance as expected
											//but if we'll alert obj.screen.toString() we'll get the VideoScreenPlayer instance name instead of "screen".
											//--- workaround inside manageClickThrough function ---
											obj.screen.addEventListener(MouseEvent.CLICK, manageClickThrough);
									}else{
										obj.addEventListener(MouseEvent.CLICK, manageClickThrough);
									}
								}
							}
							try
							{
								switch (objType)
								{
									case "flash":
										asset = getAssetURL(getValue(xmlList[i].attribute("instanceName")));
										if (asset!=null){
											if (obj.compName=="SWFVideoLoader"){
												//Eyeblaster component
												obj.videoLoadAndPlay(asset, 15);										
											}else{								
												if ((obj.numChildren==0) || !(obj.getChildAt(obj.numChildren-1) is Loader)){												
													swfsToLoad++;
													url = new URLRequest(asset);
													assetLoader = new Loader();
													context = new LoaderContext();
													if (this.loaderInfo.url.indexOf("file://")==0){
														// this is an additional asset
														context.securityDomain = null;						
													}else{
														// this is an external link
														context.securityDomain = flash.system.SecurityDomain.currentDomain;						
													}
													// we will save the instance name, width and height using the Loader name property
													assetLoader.name=String(xmlList[i].attribute("instanceName"))+String.fromCharCode(127)+obj.width+String.fromCharCode(127)+obj.height;
													// add event handler for when the image finish loading in order to handle resize
													assetLoader.contentLoaderInfo.addEventListener(Event.INIT, SVhandleResize);
													assetLoader.load(url,context);
													obj.addChild(assetLoader);		
													objectName==null?obj["SVObjectName"]="":obj["SVObjectName"]=objectName;
													obj["SVLoaderInst"]=assetLoader;
												}
											}
										}		
										break;							
									case "image":
										if ((obj.numChildren==0) || !(obj.getChildAt(obj.numChildren-1) is Loader)){					
											asset = getAssetURL(getValue(xmlList[i].attribute("instanceName")));
											url = new URLRequest(asset);
											assetLoader = new Loader();
											context = new LoaderContext();
											context.checkPolicyFile = true;
											// we will save the instance name, width and height using the Loader name property
											assetLoader.name=String(xmlList[i].attribute("instanceName"))+String.fromCharCode(127)+obj.width+String.fromCharCode(127)+obj.height;
											// add event handler for when the image finish loading in order to handle resize
											assetLoader.contentLoaderInfo.addEventListener(Event.INIT, SVhandleResize);
											assetLoader.load(url,context);
											obj.addChild(assetLoader);
										}
										break;
									case "HTML":
										obj.htmlText = getValue(xmlList[i].attribute("instanceName"));
										break;					
									case "text":										
										// setting the text field text value:
										// 	code for breaking the line on \n 
										obj.text = getValue(xmlList[i].attribute("instanceName")).split("\\n").join("\n");
										// setting the text format
										if (xmlList[i].format.length() > 0)
										{
											obj.setTextFormat(buildTextformat(xmlList[i].format));
											// setting the text font resource
											if (xmlList[i].format.fontResource.length() > 0 && xmlList[i].format.fontResource.value!="" && getAssetURL(xmlList[i].format.fontResource.value)!=null)
											{									
												// the loading methods are asynchronic were as the loop over the XML is synchronic.
												// to verify we reach 0, after all fonts are loaded and the XML parsing is completed, 
												// we will increase this flag for each text and decrease it after handling it.
												setFontResource(obj as TextField, xmlList[i].format.fontResource.value,objectName);
												if (!singleUpdate)
												{
													// updating all items and loading external font
													fontsToLoad++;
												}else{
													// single update - loading external font
													loadingFont=true;
												}
											}
										}						
										break;
									case "video":
										if (obj.hasOwnProperty("compName")){
											//Eyeblaster and MediaMind components
											var videoID:String=getValue(xmlList[i].attribute("instanceName"));
											if (obj.compName=="VideoPlayback" || obj.compName=="VideoLoader" || obj.compName=="VideoScreen" || obj.compName=="VideoScreenPlayer")
												var intervalId:uint = setTimeout(loadVideo, 200, obj, videoID);
										}else if (obj.hasOwnProperty("source")){
											//Flash component
											obj.source=getAssetURL(getValue(xmlList[i].attribute("instanceName")));  
										}else if (obj.hasOwnProperty("smoothing")){
											// Flash video object
											nc=new NetConnection();
											nc.connect(null);
											ns=new NetStream(nc);
											ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, errorHandler);
											obj.attachNetStream(this.ns);
											ns.play(getAssetURL(getValue(xmlList[i].attribute("instanceName"))));
										}
										break;																
									case "sound":	
									case "dataSource":	
									case "variable":
										obj = root;
										for (var k:int = 0; k < pathArr.length-1; k++)
											obj = obj[pathArr[k]];
										obj[pathArr[(pathArr.length-1)]] = getValue(xmlList[i].attribute("instanceName"));
										break;							
									}
							}catch(e:Error){
								Tracer.debugTrace("Exception in SmartVersioning: autoPopulateObjects: "+ e, 1);
								dispatchErrorEvent(e.message);								
							}
						}
					}
				}
				Tracer.debugTrace("SmartVersioning: autoPopulateObjects: XML parse completed: fontsToLoad = "+fontsToLoad, 6); 
				// dispatch the compelete event in case:
				// multiple update and no more external fonts to load or
				// single update and no more external font to load
				if ((fontsToLoad == 0 && !singleUpdate) || (singleUpdate && !loadingFont))
				{
					// we are going to wait for next stage refresh before dispatching the event
					// hence the short timer
					setTimeout(completeFunction,20,objectName);
				}
			}
			catch(e:Error)
			{
				Tracer.debugTrace("Exception in SmartVersioning: autoPopulateObjects: "+ e, 1);
				dispatchErrorEvent(e.message);
			}
		}
		
		//===============
		//	manageClickThrough
		//===============
		//manages the ClickThrough function of smart items
		private function manageClickThrough(e:MouseEvent):void{
			// retrieve the full name of the recieved object
			var mc:DisplayObject=DisplayObject(e.currentTarget);
			var fullName:String=mc.name;
			
			//workaround for a VideoScreenPlayer component special structure
			//inside a VideoScreenPlayer we have a VideoScreen instance called "screen"
			//for some reasen we attach the click event to a VideoScreen instance as expected
			//but if we'll alert e..currentTarget.toString() we'll get the VideoScreenPlayer instance name instead of "screen".
			if(mc.parent.toString() != "undefined" && mc.parent.toString() == "[object VideoScreenPlayer]")
			{
				mc=mc.parent;
				fullName = mc.name;
			}
			
			while (mc.parent.name.toString().indexOf("root")!=0){
				fullName=mc.parent.name+"."+fullName;
				mc=MovieClip(mc.parent);
			}

			// for VideoPlayback the event was attached to the internal VideoLoader insntance so we reemove it from the name
			if (e.currentTarget.parent.toString()!="undefined" && e.currentTarget.parent.toString()=="[object VideoPlayback]")
				fullName=fullName.substr(0,fullName.length-13);
			
			
			// retrieve the ClickThroughURL according to the SmartItem's instance name
			var clickThrough:String=_data.SmartDataItem.(@instanceName==fullName).@ClickThroughURL;
			var productID:String=_data.SmartDataItem.(@instanceName==fullName).@ProductID;
			var SV2CT:String="SV2:"+clickThrough+String.fromCharCode(127)+productID;
			// next we check if 3rd party ClickThrough was defined and add it
			var ThirdPartyCT:String=_data.SmartDataItem.(@instanceName==fullName).@ThirdPartyClickThrough;
			if (ThirdPartyCT!="")
				SV2CT+=String.fromCharCode(127)+ThirdPartyCT;
			// open the ClickThroughURL in a new brwoser window

			EBClass["Clickthrough"](SV2CT);
		}
		//===============
		//	SVhandleResize
		//===============
		// resize image or SWF after they are loaded according to the XML specified resizing parameters
		private function SVhandleResize(e:Event):void{
			if (!(e.currentTarget.content is Bitmap)){
				// this is an external SWF - check if all were loaded
				swfsToLoad--;
				if (swfsToLoad==0){
					// all external SWFs finished loading, we now update all manual items and dispatch event
					if (MovieClip(e.currentTarget.loader.parent)["SVObjectName"]==""){
						for (var i:int=0; i<manualItems.length; i++){
							// we will update each manual item in intervals to prevent getting stuck
							setTimeout(updateManual,i*20+20,manualItems[i]);
						}
					}
					var SWFcompleteEvent:EBSmartVersioningEvent = new EBSmartVersioningEvent(EBSmartVersioningEvent.SWFS_DOWNLOAD_COMPLETE,null);
					dispatchEvent(SWFcompleteEvent);	
				}
				
			}			
			// get the format node for the loaded image/SWF

			
			var formatNode:XMLList=XMLList(_data.SmartDataItem.(@instanceName==e.currentTarget.loader.name.split(String.fromCharCode(127))[0]).format.children());			
			if (formatNode.toString()!=""){ // make sure the format node was specified
				if (formatNode.attribute("autoResize")=="true"){ // make sure auto resize were specified to true
					
					// get the width and height of the loaded image/SWF
					var loadedImageWidth:int=e.currentTarget.width;
					var loadedImageHeight:int=e.currentTarget.height;
					
					// get all the resize info from the XML and store it for resize operation
					var resizeToWidth:int=parseFloat(formatNode.attribute("resizeToWidth"));
					var resizeToHeight:int=parseFloat(formatNode.attribute("resizeToHeight"));
					
					// if the user defined to resize to the Movie Clip size, we will get -1 
					// and used the saved MC width and hight to set resizeToWidth and resizeToHeight
					if (resizeToWidth==-1){
						resizeToWidth=parseFloat(e.currentTarget.loader.name.split(String.fromCharCode(127))[1]);
					}
					if (resizeToHeight==-1){
						resizeToHeight=parseFloat(e.currentTarget.loader.name.split(String.fromCharCode(127))[2]);
					}					
										
					var MaintainAspectRatio:Boolean=String(formatNode.attribute("maintainAspectRatio"))=="true";
					var resizeWhenW:Array=String(formatNode.attribute("WidthDifferFrom")).split("-");
					var resizeWhenH:Array=String(formatNode.attribute("HeightDifferFrom")).split("-");
					
					// check to see if resize is needed:
					var needToResize:Boolean=false;
					var min:int; // for range if specified 
					var max:int; // for range if specified
					// first we check the width
					if (resizeWhenW.length==1 && parseInt(resizeWhenW[0])!=e.currentTarget.width){needToResize=true}
					// if a range was specified:
					if (resizeWhenW.length==2){
						min=parseInt(resizeWhenW[0]);
						max=parseInt(resizeWhenW[1]);
						if (e.currentTarget.width<min || e.currentTarget.width>max){needToResize=true}
					}
					// now we check the height
					if (resizeWhenH.length==1 && parseInt(resizeWhenH[0])!=e.currentTarget.height){needToResize=true}
					// if a range was specified:
					if (resizeWhenH.length==2){
						min=parseInt(resizeWhenH[0]);
						max=parseInt(resizeWhenH[1]);
						if (e.currentTarget.height<min || e.currentTarget.height>max){needToResize=true}
					}
					
					if (needToResize){ // start the resize operation
						// if the loaded item is an image (bitmap) we will turn on smoothing for better resize results
						if (e.currentTarget.content is Bitmap){
							e.currentTarget.content.smoothing=true;
						}
						if (MaintainAspectRatio){
							// we need to make sure aspect ratio is maintained
							var wRatio:Number=e.currentTarget.width/resizeToWidth;
							if (e.currentTarget.height/wRatio<=resizeToHeight){
								// we can resize by width
								e.currentTarget.content.scaleX=resizeToWidth/e.currentTarget.width;
								e.currentTarget.content.scaleY=e.currentTarget.content.scaleX;
							}else{
								// resize by height
								e.currentTarget.content.scaleY=resizeToHeight/e.currentTarget.height;
								e.currentTarget.content.scaleX=e.currentTarget.content.scaleY;
							}
						}else{
							// no worries - just resize
							e.currentTarget.content.scaleX=resizeToWidth/e.currentTarget.width;
							e.currentTarget.content.scaleY=resizeToHeight/e.currentTarget.height;
						}
					}
				}
			}
			// dispatch the DownloadComplete event for this asset (if finished download and resize)
			var downloadCompleteEvent:EBSmartVersioningEvent = new EBSmartVersioningEvent(EBSmartVersioningEvent.DOWNLOAD_COMPLETE,e.currentTarget.loader.parent);
			dispatchEvent(downloadCompleteEvent);				
		}

		//===============
		//	updateManual
		//===============
		//used to update manual items after timeout
		private function updateManual(item:String):void
		{
			this.updateItem(item);
		}		
		//===============
		//	completeFunction
		//===============
		//Dispatches the "Complete" event after a short timer is finished to enable stage refresh
		private function completeFunction(item:String):void
		{
			var completeEvent:EBSmartVersioningEvent = new EBSmartVersioningEvent(EBSmartVersioningEvent.COMPLETE,item);
			dispatchEvent(completeEvent);	
		}
		//===============
		//	loadVideo
		//===============
		//loads video into VideoPlayback component after interval
		private function loadVideo():void{
			// check if we got an additional asset ID or an external link
			var obj:Object=arguments[0];
			var id:String=arguments[1];
			id.length>4?obj.loadAndPlayExt(id):obj.loadAndPlay(parseInt(id));
		}
		
		//===============
		//	buildTextformat
		//===============
		//builds the text textformat
		private function buildTextformat(format:XMLList):TextFormat
		{
			var textFormat:TextFormat;
			if (format.length() > 0)
			{
				textFormat = new TextFormat();
				// font size
				if (format.fontSize.length() > 0 && format.fontSize.value.toString()!="")
					textFormat.size = parseFloat(format.fontSize.value);
				// font weight
				if (format.fontWeight.length() > 0 && format.fontWeight.value.toString()!="")
					textFormat.bold = (String(format.fontWeight.value) == "bold");
				// font color
				if (format.color.length() > 0 && format.color.value.toString()!="")
					textFormat.color = parseInt(format.color.value);
			}
			return textFormat;
		}
		
		//===============
		//	errorHandler
		//===============
		// error handler
		private function errorHandler(eve:ErrorEvent):void
		{
			dispatchErrorEvent(eve.text);
		}
		
		//===============
		//	dispatchErrorEvent
		//===============
		// event dispatcher
		private function dispatchErrorEvent(msg:String):void
		{
			msg = "Eyeblaster Workshop | Error | SmartVersioning: " + msg;
			dispatchEvent(new EBErrorEvent(EBErrorEvent.ERROR, msg));
		}
		
		//----functions for changing the font resource of a text object------
		
		//===============
		//	setFontResource
		//===============
		private function setFontResource(textObject:TextField, fontID:String, textFieldName:String):void
		{
			try
			{
				// first time this text object is being update with the external font file (ebFont)
				if (textObject.name!="ebFont"){
					// get the font URL
					var fontFile:String = getAssetURL(fontID);
					textObject.visible = false;
					// load font:
					var ldr:Loader = new Loader();
					ldr.name = Math.random().toString();
					//	save font info
					loadedFonts[ldr.name] = new Object();
					loadedFonts[ldr.name].ldr = ldr;
					loadedFonts[ldr.name].txt = textObject;
					loadedFonts[ldr.name].singleUpdate = singleUpdate;
					Tracer.debugTrace("SmartVersioning: setFontResource: load "+fontFile + ", loader name: "+ldr.name, 6);
					var fontURLReq:URLRequest = new URLRequest(fontFile);
					///multiple font swf call handling	
					if (primaryFontQueue[fontID] != undefined){//check if this font swf has already been loaded								
						if(!primaryFontQueue[fontID].hasBeenLoaded){//check if font has been loaded yet
							var qFont:Object = new Object();//maintain all prop of font and place in queue to load later										
							qFont.ldr = ldr;								
							qFont.primeFont = primaryFontQueue[fontID];//save reffrence to primary loaded font to check against later
							qFont.fontURLReq = fontURLReq;
							qFont.nameOF = textObject.name;
							fontToLoadQueue[qFont.nameOF] = qFont;							
						}
						else{//if font has been loaded, go ahead and trigger it from cache
							ldr.load(fontURLReq);	
							ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, fontLoadedComplete);							
						}						
						return;
						
					}				
									
					var newPrimeFont:Object = new Object();
					newPrimeFont.fontID = fontID;
					newPrimeFont.ldr = ldr; //maintain data of first font to load to check later against queue
					newPrimeFont.hasBeenLoaded = false;
					primaryFontQueue[newPrimeFont.fontID] =newPrimeFont;
					ldr.load(fontURLReq);	
					ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, fontLoaded); 
				}
				else // no need to load the external font file again
				{			
					// dispatch the compelete event in case:
					// single update and the external font file is already loaded or
					// multiple update and no more external fonts to load
					if (singleUpdate || (!singleUpdate && --fontsToLoad==0))
					{					
						completeFunction(textFieldName);							
					}
				}
								
			}catch(e:Error)
			{
				dispatchErrorEvent(e.message);
				Tracer.debugTrace("Exception in SmartVersioning: setFontResource: "+ e, 1);
			}
		}
		
		//===============
		//	fontLoaded
		//===============
		// font
		private function fontLoaded(event:Event):void
		{
			for each(var qFont:Object in fontToLoadQueue) {//after font is loaded, got through queue and load all waiting													
				if(qFont.primeFont.ldr == event.target.loader){
					primaryFontQueue[qFont.primeFont.fontID].hasBeenLoaded = true;//set font to loaded
					qFont.ldr.load(qFont.fontURLReq);	
					qFont.ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, fontLoadedComplete);
					delete fontToLoadQueue[qFont.nameOF];//remove qFont from queue
				}
			}			
			fontLoadedComplete(event);//init original called font
		}
		
		private function fontLoadedComplete(event:Event):void{
			var ldr:Loader = event.target.loader;
			// get the text field to modify
			var key = ldr.name;
			var orgText:TextField = loadedFonts[key].txt as TextField;
			var isSingleUpdate:Boolean = loadedFonts[key].singleUpdate;
			// get the text field level
			var depth:int = orgText.parent.getChildIndex(orgText);
			// get the loaded text field and add it to the target text level
			var loadedText:TextField = ldr.content["ebFont"] as TextField;
			orgText.parent.addChildAt(loadedText, depth);
			// copy the text format to the loaded font
			copyTextFormat(orgText, loadedText);			
			// copy the events to the loaded font
			copyTextEvents(orgText, loadedText);
			// set the textObject to reference the loaded text field 
			orgText.parent[orgText.name] = loadedText;
			delete loadedFonts[key];
			Tracer.debugTrace("SmartVersioning: fontLoaded: textObject: "+orgText.name + ", font index: "+fontsToLoad, 6);
			// all fonts were loaded
			var item:String=isSingleUpdate?orgText.name:null;
			
			// dispatch the compelete event in case:
			// multiple update and no more external fonts to load
			// single update and the external font file has loaded
			if (isSingleUpdate || (!isSingleUpdate && --fontsToLoad==0))
			{
				Tracer.debugTrace("SmartVersioning: fontLoaded: All fonts were loaded", 6);
				completeFunction(item);
			}
		}
		
		//===============
		//	copyTextFormat
		//===============
		// Copy text format from source text field to target text field 
		private function copyTextFormat(sourceText:TextField, targetText:TextField):void
		{
			
			// loop over sourceText attributes and set it into targetText
			targetText.text = sourceText.text;
			var description:XML  = describeType(sourceText);
			var attr:XMLList = description..accessor;
			for(var i:int = 0; i < attr.length(); i++)
			{
				if(!ignoreTextFormat[attr[i].@name] && (attr[i].@access == "readwrite"))
				{
					targetText[attr[i].@name] = sourceText[attr[i].@name];
				}
			}
			
			// set position
			targetText.x = sourceText.x;
			targetText.y = sourceText.y;
						
			// loop over sourceText TextFormat and set it into targetText
			var newTextFormat:TextFormat = new TextFormat();
			var oldTextFormat:TextFormat;
			if (sourceText.text==""){
				oldTextFormat = sourceText.defaultTextFormat;
			}else{
				oldTextFormat = sourceText.getTextFormat();
			}
			description = describeType(oldTextFormat);
			attr = description..accessor;
			for(i = 0; i < attr.length(); i++)
			{
				if(!ignoreTextFormat[attr[i].@name] && (attr[i].@access == "readwrite"))
					newTextFormat[attr[i].@name] = oldTextFormat[attr[i].@name];
			}	
			targetText.defaultTextFormat = newTextFormat;
			targetText.setTextFormat(newTextFormat);
		}
		
		//===============
		//	copyTextEvents
		//===============
		// Copy events from source text field to target text field
		private function copyTextEvents(sourceText:TextField, targetText:TextField):void
		{
			// handle focus events
			targetText.addEventListener(FocusEvent.FOCUS_IN, onFocusChange);
			targetText.addEventListener(FocusEvent.FOCUS_OUT, onFocusChange);
			function onFocusChange(e:FocusEvent):void
			{
				sourceText.dispatchEvent(new FocusEvent(e.type));
				e.stopImmediatePropagation();
			}			
			// handle scroll event
			sourceText.addEventListener(Event.SCROLL, onScroll);
			targetText.addEventListener(Event.CHANGE, onChange);
			function onScroll(e:Event):void
			{
				targetText.scrollV = e.currentTarget.scrollV * targetText.maxScrollV/e.currentTarget.maxScrollV;			
			}
			function onChange(e:Event):void{
				sourceText.text=targetText.text;
				sourceText.scrollV = e.currentTarget.scrollV * e.currentTarget.maxScrollV/targetText.maxScrollV;						
			}
			// loop over the targetText events and trigger the sourceText events
			//  register TextEvent
			var description:XML  = describeType(TextEvent);
			var attr = description..constant;
			var eventName = "";
			for(var i = 0; i < attr.length(); i++)
			{
				eventName = attr[i].@name;
				if (eventName != "SCROLL")
					targetText.addEventListener(TextEvent[eventName], onEvent);
			}	
			//  register MouseEvent
			description  = describeType(MouseEvent);
			attr = description..constant;
			for(i = 0; i < attr.length(); i++)
			{
				eventName = attr[i].@name;
				try	{
					targetText.addEventListener(MouseEvent[eventName], onMouseEvent);
				}catch(e:Error){}	
			}	
			//  register Event
			description  = describeType(Event);
			attr = description..constant;
			for(i = 0; i < attr.length(); i++)
			{
				eventName = attr[i].@name;
				try	{
					targetText.addEventListener(Event[eventName], onEvent);
				}catch(e:Error){}
			}	
			//  events handler
			function onEvent(e:Event)
			{
				Tracer.debugTrace("SmartVersioning: onEvent: "+ e, 6);
				sourceText.dispatchEvent(new Event(e.type));
			}
			function onMouseEvent(e:Event)
			{
				Tracer.debugTrace("SmartVersioning: onMouseEvent: "+ e, 6);
				sourceText.dispatchEvent(new MouseEvent(e.type));
			}			
		}
		
		//===============
		//	reportThirdPartyImps
		//===============
		// Reports 3rd party impression URLs for all smart catalog prodcuts
		private function reportThirdPartyImps(arr:Array):void{
			var thirdPartyImps:String=arr[0];
			for (var i:int=1; i<arr.length; i++){
				thirdPartyImps+=String.fromCharCode(127)+arr[i];
			}
			EBClass["handleCommand"]("ebversiontrackingimpression",thirdPartyImps);	
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	getAssetURL
		//===============
		// Getting asset relative URL according to its asset ID using the ebMovie Flash Vars
		public function getAssetURL(assetID:String):String
		{
			var res:String;
			if (root.loaderInfo.parameters["ebMovie"+assetID])
				res = root.loaderInfo.parameters["ebMovie"+assetID];
			if (res == null) // In-Stream
				res = EBClass.urlParams["ebMovie"+assetID];
			if (assetID.length>4)
				res=assetID;
			return res;
		}
		
		//===============
		//	getValue
		//===============
		// getting any object value
		public function getValue(objectName:String):String
		{
			var res:String;
			var element:XMLList = _data.SmartDataItem.(@instanceName==objectName).value;
			if (element.length() > 0)
				res = String(element);	
			return res;
		}
		
		//===============
		//	getClickThroughByName
		//===============
		// getting any object ClickThrough URL by instance name
		public function getClickThroughByName(objectName:String):String
		{
			var element:XMLList = _data.SmartDataItem.(@instanceName==objectName).@ClickThroughURL;
			return String(element);
		}
		
		//===============
		//	getClickThroughByIndex
		//===============
		// getting any object ClickThrough URL by product index
		public function getClickThroughByIndex(index:int):String
		{
			var element:XMLList = _data.SmartDataItem.(@productIndex==index.toString()).@ClickThroughURL;
			return String(element[0]);
		}		
		//===============
		//	getTextFormat
		//===============
		// getting text object format
		public function getTextFormat(objectName:String):TextFormat
		{
			var textFormat:TextFormat;
			var element:XMLList = _data.SmartDataItem.((@instanceName == objectName) && (@type == "text")).format;
			return buildTextformat(element);
		}

		//===============
		//	getTextFontID
		//===============
		// getting text object font asset ID
		public function getTextFontID(objectName:String):String
		{
			var res:String;
			var element:XMLList = data.SmartDataItem.((@instanceName == objectName) && (@type == "text")).format;
			if (element.length() > 0)
				res = String(element.fontResource.value);
			return res;
		}	
		//===============
		//	updateAllItems()
		//===============
		// update all smart versioning items
		public function updateAllItems():void{
			autoPopulateObjects(null);
		}
		//===============
		//	updateAllItems()
		//===============
		// update all smart versioning items
		public function updateItem(itemName:String):void{
			autoPopulateObjects(itemName);
		}			
	}
	
}