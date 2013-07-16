//****************************************************************************
//class eyeblaster.data.DynamicContentManager
//-----------------------------------------
//This class is part of the DynamicContentManager component that allows the flash to access dynamic 
//data on a remote server. Every time the user views the Flash movie, the data will be refreshed. 
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.data
{
	import flash.display.MovieClip;
	import eyeblaster.core.Tracer;
	import eyeblaster.events.EBErrorEvent;
	import flash.events.*;
	import flash.net.*;
	
	[IconFile("Icons/DynamicContentManager.png")]

	public class DynamicContentManager extends MovieClip
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _loaderFile:URLLoader;			//URLLoader object to load file
		private var _xmlCrossDomain:URLLoader;		//XML object to load the crossDomain.xml file (for external data)
		private var _onLoadCB:Function;				//the callBack function of the user when the data is loaded
		private var _fileUrl:String;				//the URL of the data file 
		private var _fileType:String;				//the type of the data file - txt or xml (rss is included as xml
		
		//----General------
		include "../core/compVersion.as"
		public var compName:String = "DynamicContentManager";	//The component name to be used for components detection.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function DynamicContentManager()
		{
			Tracer.debugTrace("DynamicContentManager: Constructor", 6);
			Tracer.debugTrace("DynamicContentManager version: " + compVersion, 0);	
			this._init();
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 API functions					
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//================================
		//	function loadDataFromEBServer
		//================================
		//This function load data file that is located on the Eyablaster servers.
		//Parameters:
		//		fileName:String - the file name of the data file (without the extension)
		//		type - the type of the file. can be txt. xml or rss
		//		callBack - the callBack function when the file is completely loaded
		public function loadDataFromEBServer(fileName:String, type:String, callBack:Function)
		{
			Tracer.debugTrace("DynamicContentManager: loadDataFromEBServer ("+arguments +")", 4);
			 
			//create the file URL:
			//check if the file was passed as a parameter, if not build the old path
			if(EBBase.urlParams["ebDCnt" + fileName])
				fileName = EBBase.urlParams.ebResourcePath + EBBase.urlParams["ebDCnt" + fileName];
			else
				fileName = EBBase.urlParams.ebResourcePath + "DynamicData/" +  fileName + "_" + EBBase.urlParams.ebCampaignID  +  ".txt";
			_setAttributes(fileName, type, callBack);
			//loading the file
			this._loadFile();
		}
		
		//======================================
		//	function loadDataFromExternalServer
		//======================================
		//This function load data file that is located on the advertiser's servers.
		//The resource will be able to communicate with the file only by the crossdomain file with the adequate 
		//permission. There is no need for the shim since AS3 is supported in flash 9 (crossdomain is supported from flash 7)
		//Parameters:
		//		fileURL:String - the file URL of the data file (with the extension)
		//		type:String - the type of the file. can be txt. xml or rss
		//		callBack:Function - the callBack function when the file is completely loaded
		//		shimURL:String - parameter that is inserted just if the users want the communication
		//						 throught the shim
		public function loadDataFromExternalServer(fileURL:String, type:String, callBack:Function)
		{
			Tracer.debugTrace("DynamicContentManager: LoadDataFromExternalServer", 4);
			_setAttributes(fileURL, type, callBack);
			
			//loading the file
			this._loadFile();
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//				private functions 			
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
	
		//========================
		//	function _init
		//========================
		//The function inits the component and the attributes
		private function _init():void
		{
			Tracer.debugTrace("DynamicContentManager: _init", 4);
			this._initComp();
			this._initAttr();
		}
		
		//========================
		//	function _initComp
		//========================
		//The function inits all the things related to the component
		private function _initComp()
		{
			Tracer.debugTrace("DynamicContentManager: _initComp", 4);
			EBBase.ebSetComponentName("DynamicContentManager");
			//hiding component at runtime
			this.alpha = 0;
			if (this.hasOwnProperty("_helper_text")){
				this["_helper_text"].visible=false;
			}
												   
		}
		
		//========================
		//	function _initAttr
		//========================
		//The function inits all the attributes of the VideoStrip class
		private function _initAttr():void
		{
			Tracer.debugTrace("DynamicContentManager: _initAttr", 4);
			try
			{
				//verify the parameter ebCampaignID was transferred to the flash - if not it means that it runs locally
				if(typeof(EBBase.urlParams.ebCampaignID) == "undefined")
					Tracer.debugTrace("DynamicContentManager: _initAttr: the campaignID is missing", 1);	
				
				//set default values
				this._onLoadCB = null;
				this._fileUrl = "";
				this._fileType = "";
				
				//create objects for loading files
				this._loaderFile = null;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("DynamicContentManager: _initAttr: failed to load URL: "+ _fileUrl, -2);
			}
		}
		
		//===========================
		//	function _setAttributes
		//===========================
		//This function sets the class attribues to save data
		private function _setAttributes(file, type, callBack):void
		{
			this._fileUrl = file;
			Tracer.debugTrace("DynamicContentManager: LoadDataFromEBServer: _fileUrl: "+_fileUrl, 5);
			this._fileType = type;
			this._onLoadCB = callBack;
		}
		
		//========================
		//	function _loadFile
		//========================
		//This function loads the data file
		private function _loadFile():void
		{
			Tracer.debugTrace("DynamicContentManager: _loadFile", 4);
			var request:URLRequest = new URLRequest(_fileUrl);
			//object of _loaderFile can be created only once - only one file can be loaded
			if (!_loaderFile)
				_loaderFile = new URLLoader();
			
			//adding eventListeners for loading the file
			_loaderFile.addEventListener(Event.COMPLETE, completeHandler);
			_loaderFile.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this._onLoadError);
			_loaderFile.addEventListener(IOErrorEvent.IO_ERROR, this._onLoadError);
			
			try
			{
				//loading the file
				_loaderFile.load(request);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("DynamicContentManager: _loadFile: failed to load URL: "+ _fileUrl, -2);
			}
		}
		
		//========================
		//	function _getDomain
		//========================
		//This function gets a URL and return the domain from this URL.
		private function _getDomain():String
		{
			try
			{
				var domain:String; //the doamin
				var startInd = this._fileUrl.indexOf("http://", 0);
				if(startInd > -1) //	"http://" exist
					startInd += 7;
				else
				{
					startInd = this._fileUrl.indexOf("https://", 0); //	"https://" exist
					if(startInd > -1)
						startInd += 8;
				}
				
				if(startInd == -1)
				{
					Tracer.debugTrace("DynamicContentManager: _getDomain, no valid URL (should start with http:// or https:// ", -2);
					return "";
				}
			
				var endInd = this._fileUrl.indexOf(":",startInd);
				if(endInd == -1) //':' doesn't exist after the http:// or https://
					endInd = this._fileUrl.indexOf("/",startInd);
					
				if(endInd == -1)
				{
					Tracer.debugTrace("DynamicContentManager: _getDomain, no valid Domain " + this._fileUrl, -2);
					domain = "";
				}
				
				domain = this._fileUrl.slice(0, endInd);
			}
			catch (error:Error)
			{
				Tracer.debugTrace("DynamicContentManager: error in _getDomain function: "+ error.message, -2);
				domain = "";;
			}
			return domain;
		}
		
		//==============================
		//	function completeHandler
		//==============================
		//This function is triggered when the user's file is loaded successfully
		private function completeHandler(event:Event):void
		{
			 Tracer.debugTrace("DynamicContentManager: completeHandler: the data file was loaded", 4);
			 try
			 {
				 //build a suitable object that is sent as a parameter to the callBack function
				 var loader:URLLoader = URLLoader(event.target);
				
				 //calling to the callBack function
				 if (_fileType.toLowerCase() == "txt")
				 {
					//create URLVariables for text file
					 var vars:URLVariables = new URLVariables(loader.data);
					_onLoadCB(vars);
				 }
				 else
				 {
					 //create XML for xml file
					 var xml:XML = new XML(loader.data);
					_onLoadCB(xml);
				 }
			 }
			 catch(error:Error)
			 {
				 Tracer.debugTrace("DynamicContentManager: error in completeHandler function: "+ error.message, -2);
			 }
		}
		
		//====================================
		//	function _onLoadError
		//==================================== 
		// This function is a hanlder function to any error event thrown from the URLLoader object
		private function _onLoadError(event:Event):void
		{
			Tracer.debugTrace("Eyeblaster Dynamic Data component | There was a problem accessing the file you requested. Please verify that the data file and policy file (CrossDomain) are accessible.", 0)
			dispatchEvent(new EBErrorEvent(EBErrorEvent.ERROR, "DynamicContentManager: Error loading '"+_fileUrl+"'"));
		}
	}	
}