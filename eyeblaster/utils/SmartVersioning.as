//****************************************************************************
//eyeblaster.utils.SmartVersioning class
//---------------------------
//
//This class is part of the SmartVersioning component which enables to change ads dynamically from the ACM.
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************
package eyeblaster.utils
{	
	import eyeblaster.core.Tracer;
	import eyeblaster.events.*;
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.system.*;
	import flash.net.*;
	import flash.utils.*;
	
	[Event("XMLloaded", type="Event")]
	[Event("Complete", type="eyeblater.events.SmartVersioningEvent")]
	[Event("Error", type="eyeblater.events.EBErrorEvent")]
	
	public class SmartVersioning extends MovieClip
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		// Private vars declaration
		private var _autoPopulate:Boolean = true;
		private var _data:XML;
		
		private var xmlLoader:URLLoader = new URLLoader();
		
		// variables needed for loading font assets
		private var fontsToLoad:int = 0;
		private var loadedFonts:Object = new Object();		//loaded fonts hash table (map loaded font to its target textField
		private var ignoreTextFormat:Object = {defaultTextFormat:true,text:true,embedFonts:true,name:true,htmlText:true,visible:true,font:true}

		private var nc:NetConnection;
		private var ns:NetStream;
		private var intervalID:int;
		
		private var singleUpdate:Boolean; // specify if updating all items at once or just a single item
									
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
			Tracer.debugTrace("SmartVersioning: Constructor", 6);
			Tracer.debugTrace("SmartVersioning version: " + compVersion, 0);	
			Tracer.debugTrace("Eyeblaster Workshop | SmartVersioning | You are currently using a deprecated version of the component, please import a newer version to stage.  For more information see the on-line help.",0);
			// Admin component identification
			EB.ebSetComponentName("SmartVersioning");	
			// hide component icon at runtime
			this.alpha = 0;
			// in AS3 the UI parameters get their value only on the next enter frame event
            addEventListener(Event.ENTER_FRAME, loadXML);
		}
		
		//===============
		//	loadXML
		//===============
		// XML loader function - load the XML file
		private function loadXML(event:Event):void
		{
			try
			{
				removeEventListener(Event.ENTER_FRAME, loadXML);
				var url:URLRequest = new URLRequest(EB.urlParams.ebAdXML);
				xmlLoader.addEventListener(Event.COMPLETE, parseXML);
				xmlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler);
				xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				if (EB.urlParams.ebAdXML)
					xmlLoader.load(url);
				else
					dispatchErrorEvent("No Smart Versioning XML was found");
			}
			catch(e:Error)
			{
				Tracer.debugTrace("Exception in SmartVersioning: loadXML: "+ e, 1);
				dispatchErrorEvent(e.message);
			}
		}
		
		//===============
		//	parseXML
		//===============
		// Parsing the XML
		private function parseXML (event:Event):void
		{
			try
			{		
				_data = new XML(event.target.data);
				dispatchEvent(new SmartVersioningEvent("XMLloaded", null));
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
				var xmlList:XMLList=XMLList(this._data.SmartDataItem);
				var obj:Object;
				var pathArr:Array;
				var asset:String;
				var url:URLRequest;
				var assetLoader:Loader;
				var loadingFont:Boolean=false; // for single update - is loading external font
				
				singleUpdate=(objectName!=null);

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
					if (obj!=null){
						for (var j:int=1; j < pathArr.length; j++)
						{
							if (obj[pathArr[j]]!=null){
								obj = obj[pathArr[j]];
							}
						}
					}
					// the element was found
					if (objectName==null || objectName==xmlList[i].attribute("instanceName")){
						if (obj != null)
						{
							switch (String(xmlList[i].attribute("type")))
							{
								case "flash":
									asset = getAssetURL(getValue(xmlList[i].attribute("instanceName")));
									if (asset!=null){
										if (obj.compName=="SWFVideoLoader"){
											//Eyeblaster component
											obj.videoLoadAndPlay(asset, 15);										
										}else{								
											if ((obj.numChildren==0) || !(obj.getChildAt(obj.numChildren-1) is Loader)){
												url = new URLRequest(asset);
												assetLoader = new Loader();
												assetLoader.load(url);
												obj.addChild(assetLoader);									
											}
										}
									}		
									break;							
								case "image":
									if ((obj.numChildren==0) || !(obj.getChildAt(obj.numChildren-1) is Loader)){					
										asset = getAssetURL(getValue(xmlList[i].attribute("instanceName")));
										url = new URLRequest(asset);
										assetLoader = new Loader();
										assetLoader.load(url);
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
										//Eyeblaster component
										var videoID:String=getValue(xmlList[i].attribute("instanceName"));
										if (obj.compName=="VideoPlayback"){
											//saveFlashObject=obj;										
											intervalID=setInterval(loadVideo,20,obj,videoID);
										}else{
											obj.VideoLoadAndPlay(videoID);
										}
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
		//	completeFunction
		//===============
		//Dispatches the "Complete" event after a short timer is finished to enable stage refresh
		private function completeFunction(item:String):void
		{
			var completeEvent:SmartVersioningEvent = new SmartVersioningEvent(SmartVersioningEvent.COMPLETE,item);
			dispatchEvent(completeEvent);			
		}
		//===============
		//	loadVideo
		//===============
		//loads video into VideoPlayback component after interval
		private function loadVideo(obj:Object,id:String):void{
			obj.VideoLoadAndPlay(id);
			clearInterval(intervalID);
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
				if (format.fontSize.length() > 0)
					textFormat.size = parseFloat(format.fontSize.value);
				// font weight
				if (format.fontWeight.length() > 0)
					textFormat.bold = (String(format.fontWeight.value) == "bold");
				// font color
				if (format.color.length() > 0)
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
			// set position
			targetText.x = sourceText.x;
			targetText.y = sourceText.y;
			
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
				targetText.addEventListener(MouseEvent[eventName], onEvent);
			}	
			//  register Event
			description  = describeType(Event);
			attr = description..constant;
			for(i = 0; i < attr.length(); i++)
			{
				eventName = attr[i].@name;
				targetText.addEventListener(Event[eventName], onEvent);
			}	
			//  events handler
			function onEvent(e:Event)
			{
				Tracer.debugTrace("SmartVersioning: onEvent: "+ e, 6);
				sourceText.dispatchEvent(new Event(e.type));
			}
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
			if (EB.urlParams["ebMovie"+assetID])
				res = EB.urlParams["ebMovie"+assetID];
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