//****************************************************************************
//      DataCapture class
//---------------------------
//
//The class allows an ad to capture user input to be stored on the Eyeblaster servers. 
//It also allows you to retrieve an aggregation of stored data from the Eyeblaster servers for real 
//time display back to the user right within the ad. 
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.data
{ 
	import eyeblaster.core.Tracer;
	import flash.net.*;
	import flash.events.*;
	import flash.net.URLVariables;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.display.MovieClip;

	public class DataCapture extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		public var formFields:URLVariables; 		//responsible for sending URL with all the data to the server
		public var compName:String = "DataCapture";	//The component name to be used for components detection.
		public var postStatusCB:Function;			//a callback function that is triggers whenb the data is sent to the server
		
		//----UI------
		private var _formName:String = "";				//the form name
		
		private var _securedProtocol:Boolean = false;	//a flag to indicate whether the protocol is secured or not
		
		private var _emailFormat:String = "HTML";		//the mail format: text/html
		
		//----set / get functions for the UI parameters------
	
		//sets / gets the formName the user entered.
		[Inspectable(defaultValue="",type=String)]
		public function set formName(strName:String):void
		{
			this._formName = strName;
		}
		public function get formName():String
		{
			return this._formName;
		}
		
		//sets / gets the whether the mail is in secured protocol or not
		[Inspectable(defaultValue=false,type=Boolean)]
		public function set securedProtocol(value:Boolean):void
		{
			this._securedProtocol = value;
		}
		public function get securedProtocol():Boolean
		{
			return this._securedProtocol;
		}
		
		//sets / gets the emailFormat text or html
		[Inspectable(enumeration="Text,HTML",defaultValue="HTML",type=String)]
		public function set emailFormat(format:String):void
		{
			this._emailFormat= format;
		}
		public function get emailFormat():String
		{
			return this._emailFormat;
		}
		
		//----General------
		include "../core/compVersion.as"
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//===============
		//	Constructor
		//===============
		public function DataCapture() 
		{
			Tracer.debugTrace("DataCapture: Constructor", 6);
			Tracer.debugTrace("DataCapture version: "+compVersion, 0);
			_init();
        }
		
		//=======================
		//	function saveForm
		//=======================
		//The function collects all the component parameters and call to _saveForm function
		public function saveForm()
		{
			Tracer.debugTrace("DataCapture: saveForm", 4);
			return _saveForm();
		} 
		
		//====================================
		//	function getFormDistributionURL
		//====================================
		//The function returns the URL of the XML document that contains the polling data
		public function getFormDistributionURL()
		{
			if(!_checkIfValidDataPolling())
				return "";
			
			var url = EBBase.urlParams.ebResourcePath + "PollingData/" + this._formName + "_" + EBBase.urlParams.ebCampaignID + ".xml";
			Tracer.debugTrace("DataCapture: getFormDistributionURL: url= "+url, 4);
			return url;
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	function _init
		//=======================
		//The function initialize the component and the attributes
		private function _init():void
		{
			try
			{
				//Admin component identification
				EBBase.ebSetComponentName("DataCapture");
				//hide the component
				this.alpha = 0;
				if (this.hasOwnProperty("_helper_text")){
					this["_helper_text"].visible=false;
				}
				this.formFields = new URLVariables();
				this.postStatusCB = null;
			}
			catch(error:Error)
			{
				Tracer.debugTrace("DataCapture: error in _init: "+error, 1);
			}
		}
		
		//=======================
		//	function _saveForm
		//=======================
		//The function validates all the component parameters and in case the are valid
		//all the parameters (component parameters and dynamic parameters are transferred to the server
		private function _saveForm():Boolean
		{
			Tracer.debugTrace("DataCapture _saveForm ", 4);	
			var urlParams = EBBase.urlParams;
			//verify all mandatory data is available and valid
			if(!_checkIfValidData())
				return false;
			//transfer the mail format to 0 if it is text, 1 otherwise
			var mailFormat = (this._emailFormat == "HTML") ? "1" : "0";
			
			//send data
			var pipeUrl = "ebFormName=" + this._formName + "&ebReplyEmail=" + this.formFields.emailAddress + "&ebSendAsHTML=" + mailFormat;
			
			//serving or old DC test page
			if(!urlParams.ebNewPreview || urlParams.ebNewPreview == "0")
			{
				pipeUrl = urlParams.ebDCPipe + "?" + pipeUrl;
				pipeUrl = (pipeUrl.indexOf("://") < 0) ? "http://" + pipeUrl : pipeUrl;
				//serving
				if (urlParams.ebAdID != null)
				{
					_postVars(pipeUrl);
				}
				else if (urlParams.ebFormID != "")
				{
					//old DC test page
					_postVarsTest(pipeUrl);
				}
			}
			else
			{
					//new preview test
					_postVarsPreview(pipeUrl);
			}
			return true;
		}
			
		//==============================
		//   function _checkIfValidData		
		//==============================
		//The function verifies the mandatory data is available and valid
		private function _checkIfValidData():Boolean
		{
			Tracer.debugTrace("DataCapture _checkIfValidData ", 4);	
			var urlParams = EBBase.urlParams;
			//verify the form name is not empty
			if (this._formName == "")
			{
				Tracer.debugTrace("Eyeblaster Data Capture component | The form name is missing. Please use the component inspector panel to edit that field.", 0);
				return false;
			}
			
			//ebDCPipe or ebNewPreview must be given on the URL transferred to the flash.
			//ebAdID must be given in case of running ad and ebFormID must be given in case of test
			//if these parameters are missing it means that we are running it locally
			if (((urlParams.ebDCPipe == null) && (urlParams.ebNewPreview == null)) ||
						((urlParams.ebAdID  == null) && (urlParams.ebFormID == null)))
			{
				Tracer.debugTrace("DataCapture: _checkIfValidData: one of the following parameters is missing: ebDCPipe or ebAdID in case of running an ad or ebFormID or ebNewPreview in case of Test.", 4);
				return false;
			}
			
			//verify that the email Address is valid
			return _checkIfValidEmail();
		}
		
		//=====================================
		//   function _checkIfValidDataPolling		
		//=====================================
		//The function verifies the mandatory data for polling is available and valid
		private function _checkIfValidDataPolling():Boolean
		{
			var urlParams = EBBase.urlParams;
			//verify the form name is not empty
			if (this._formName == "")
			{
				Tracer.debugTrace("Eyeblaster Data Capture component | The form name is missing. Please use the component inspector panel to edit that field.", 0);
				return false;
			}
				
			//verify the parameters ebResourcePath and ebCampaignID were transferred to the flash - if not it means that it runs locally
			//These parameters are needed for polling
			if ((urlParams.ebResourcePath == null) || (urlParams.ebCampaignID == null))
			{
				Tracer.debugTrace("DataCapture: _checkIfValidDataPolling: one of the following parameters is missing: ebResourcePath or ebCampaignID", 4);
				return false;
			}
			return true;
		}
		
		//==============================
		//   function _checkIfValidEmail		
		//==============================
		//This function verify that the email Address is valid
		private function _checkIfValidEmail():Boolean
		{
			Tracer.debugTrace("DataCapture _checkIfValidEmail ", 4);		
			var email = this.formFields.emailAddress; 
		
			if (email)
			{
				if ((email.indexOf(" ") != -1) || (email.indexOf("@") == -1) ||
							(email.indexOf(".") == -1) || (email.length < 5) ||
										(email.lastIndexOf(".") < email.indexOf("@"))) 
				{
					Tracer.debugTrace("Eyeblaster Data Capture component | email address is not valid", 0);
					return false;
				}
			}
			else
				this.formFields.emailAddress = "";
			return true;
		}
		
		//==============================
		//   function _buildRequest		
		//==============================
		//This function builds the URLRequest
		private function _buildRequest(pipeUrl:String):URLRequest
		{
            try
			{
				Tracer.debugTrace("DataCapture _buildRequest ", 4);		
				//create URLRequest object from the pipeUrl
				var request:URLRequest = new URLRequest(pipeUrl);
				request.method = URLRequestMethod.POST;
				//setting data to the URLRequest object to be transmitted with the URL request.
				request.data = this.formFields;
			}
			catch (error:Error)
			{
				Tracer.debugTrace("DataCapture: _buildRequest: Error occured : " + error, -2);
			}
			return request;
		}	
		
		//==============================
		//   function _postVars
		//==============================
		//The function build the URL that the variables are posted to and send them 
		//to this URL by the function sendAndLoad that doesn't open a new page (case that the ad runs
		//and not test)
		private function _postVars(pipeUrl):void
		{
			Tracer.debugTrace("DataCapture: _postVars", 4);
			//build the pipeUrl in case of running ad
			pipeUrl = pipeUrl + "&ebAdID=" + EBBase.urlParams.ebAdID;
			if (this.securedProtocol)
			{
				var ind = pipeUrl.indexOf("://") + 3;
				pipeUrl = "https://" + pipeUrl.substr(ind);
			}
			Tracer.debugTrace("DataCapture: _postVars: pipeUrl: " +pipeUrl, -2);
			
			//build the request for the server
			var request = _buildRequest(pipeUrl);
			//sending the request to the server
			var loader:URLLoader = new URLLoader();
			
			//decalring events of the URLLoader
			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			//Load the URLRequest
			loader.load(request);
		}
		
		//==============================
		//   function _postVarsPreview(pipeUrl)		
		//==============================
		//The function is used for testing the data capture in the preview page (ad level), 
		//it collects the data capture form data and sends it to the preview page for validation
		private function _postVarsPreview(pipeUrl:String):void
		{
			Tracer.debugTrace("DataCapture: _postVarsPreview", 4);
			var formParams = pipeUrl  + "&ebAdID=" + EBBase.urlParams.ebAdID + "||" + this.formFields.toString();
			Tracer.debugTrace("DataCapture: _postVarsPreview: formParams: "+formParams, -2);
			//posts variables to the preview page
			EBBase.handleCommand("ebTestDC", formParams);
		}
		
		//==============================
		//   function _postVarsTest		
		//==============================
		//The function is used for test data capture, it builds the URL that the variables are posted to and send them 
		//to this URL by the function send that opens a new page (Test case)
		//---------------------------------------------
		//this function is for backward comatability
		//---------------------------------------------
		private function _postVarsTest(pipeUrl:String):void
		{
			Tracer.debugTrace("DataCapture: _postVarsTest", 4);
			//build the pipeUrl in case of Test
			pipeUrl = pipeUrl + "&ebFormID=" + EBBase.urlParams.ebFormID;
			Tracer.debugTrace("DataCapture: _postVarsTest: pipeUrl: "+pipeUrl, -2);
			//build the request for the server
			var request = _buildRequest(pipeUrl);
			//navigate to the request URL
			navigateToURL(request, "_blank");
		}
		
		//==============================
		//	function errorHandler     
		//==============================
		//This function is called when an ErrorEvent is triggered 
		private function errorHandler(error:ErrorEvent):void 
		{
			Tracer.debugTrace("DataCapture: Error "+error.type+" occured : " + error, -2);
			//call to callBack function to inform the user that an error occured while loading
		   if (postStatusCB != null)
		  	 	postStatusCB(false);
        }
		
		//==============================
		//	function completeHandler    
		//==============================
		//This function is called when the request to the server returns
		private function completeHandler(event:Event):void 
		{
			Tracer.debugTrace("DataCapture: completeHandler: Data was sent successfully to the server", -2);
			//call to callBack function to inform the user that the data was loaded
			if (postStatusCB != null)
				postStatusCB(true);
		}
	}
}