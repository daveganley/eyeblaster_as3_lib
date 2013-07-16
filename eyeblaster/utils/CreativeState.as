//****************************************************************************
//class eyeblaster.utils.CreativeState
//------------------------------------
//This class is part of the CreativeState component which allows targeting, i.e. allows the Flash 
//movie to behave differently each time a user views it based on previous interaction from the user.
//the component contains 2 logic unit:
// - behavioral ad - works by storing information about the user as in a shared object ('flash cookie')
// - Advanced behavioral ad - works by storing information about the user as in a cookie 
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************
package eyeblaster.utils
{
	import eyeblaster.core.Tracer;
	import flash.net.SharedObject;
	import flash.display.MovieClip;
	import flash.system.fscommand;
	import flash.system.Security;
	import flash.events.Event;
	
	[IconFile("Icons/CreativeState.png")]
	
	public class CreativeState extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----Size and boundaries------
		private var _soName:String;				// The name of the shared object, can be the campaignId (default) or adId.
												// enables to controll the state level (used only for Behavioral Ad)
		private var _strStates:String;		// The names of the states to be used in the targeting flight (used only for Advanced behavioral Ad)
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		include "../core/compVersion.as"
		public var compName:String = "CreativeState";	//The component name to be used for components detection.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function CreativeState()	
		{
			Tracer.debugTrace("CreativeState: Constructor", 6);
			Tracer.debugTrace("CreativeState version: " + compVersion, 0);		
			Tracer.debugTrace("Eyeblaster Workshop | CreativeState | You are currently using a deprecated version of the component, please import a newer version to stage.  For more information see the on-line help.",0);
			_init();
		}
		
		//========================
		// function printSO
		//========================
		//This function prints all the data stored in the local shared object
		function printSO(so) 
		{
			// print all the data stored in the local object
			var strMsg = "objName: " + _soName + "   ";
			for (var i in so.data) 
			{
				strMsg += i + ":" + so.data[i] + ";";
			}
			Tracer.debugTrace("CreativeState: " + strMsg, 1);
		}
		
		//========================
		// function trim
		//========================
		//This function gets a string and remove the preceding and ending
		//space characters.
		function trim(str) 
		{
			while (str.charAt(0) == " ") 
				str = str.substring(1, str.length);
			while (str.charAt(str.length - 1) == " ") 
				str = str.substring(0, str.length - 1);
			return str;
		}
		
		//========================
		// function trimStatesList
		//========================
		//This function gets a list of strings seperated by comma and remove the preceding and ending
		//space characters from each of the strings.
		function trimStatesList(str) 
		{
			var arrStates = str.split(",");
			for (var i = 0; i < arrStates.length; i++) 
				arrStates[i] = trim(arrStates[i]);
			return (arrStates.join(","));
		}
		
		//----------------------------------------------------
		//						API functions:
		//----------------------------------------------------
		
		//--------------Behavioral Ad------------------
		
		//======================================
		// function setStatePersistencyLevel
		//======================================
		//This function sets the state level to be the campaign or the ad
		//(according to the given parameter).
		//Parameters:
		//	String:level
		// 	Possible values:
		// "Ad" - setting the state level to the ad.
		// "Campaign" - setting the state level to the campaign.
		public function setStatePersistencyLevel(level) 
		{
			Tracer.debugTrace("CreativeState: setStatePersistencyLevel(" + level + ")", 1);
			try
			{
				if (level.toLowerCase() == "ad")
					_soName =  ebGlobal.urlParams.ebAdID;
				else if (level.toLowerCase() == "campaign")
					_soName =  ebGlobal.urlParams.ebCampaignID;
			}catch(err:Error)
			{
				Tracer.debugTrace("CreativeState: setStatePersistencyLevel Error: " + err.message, 1);
			}
		}
		
		//===============================
		// function setState
		//===============================
		//This function stores a given value for a given state.
		//(according to the given parameter).
		//Parameters:
		//	String:name - The name of the state that will be used to reference the stored value.
		//	String:val - The value to store.
		public function setState(name, val) 
		{
			try
			{
				//read the local object so if it was updated from outside the changes will be loaded.
				var localData_so = SharedObject.getLocal(_soName, "/");
				Tracer.debugTrace("CreativeState: SetState(" + name + "," + val + ")", 1);
				//save state value
				localData_so.data[name] = val;
				localData_so.flush();
				//prints all the data stored in the local shared object
				printSO(localData_so);
			}catch(err:Error)
			{
				Tracer.debugTrace("CreativeState: setState Error: " + err.message, 1);
			}
		}
		
		//===============================
		// function getState
		//===============================
		//This function retrives the previously stored value for the given state.
		//(according to the given parameter).
		//Parameters:
		//	String:name - The name of the state that containing the stored value.
		// 
		//	Return Value:
		// 	The value of the saved state.
		// 	The value will return undefined for any of the following reasons:
		// 	- The state was never set.
		// 	- The state was set by a different ad, whose state persistency level was set to "Ad" at the time.
		// 	- The state was set by a different ad, whose state persistency level was set to "Campaign" at the time, but the current state consistency level is set to "Ad".
		// 	- Shared objects have been disabled on the user’s browser.
		// 	- Flash is currently not enabled on the user’s browser.
		public function getState(name) 
		{
			try
			{
				//read the local object so if it was updated from outside the changes will be loaded.
				var localData_so = SharedObject.getLocal(_soName, "/");
				//prints all the data stored in the local shared object
				printSO(localData_so);
				Tracer.debugTrace("CreativeState: getState(" + name + ")", 1);
				//get stored data
				return localData_so.data[name];
			}catch(err:Error)
			{
				Tracer.debugTrace("CreativeState: getState Error: " + err.message, 1);
			}
		}
		
		//--------------Advanced behavioral Ad------------------
		
		//===============================
		// function registerState
		//===============================
		//This function is used by the user to register all the state that
		//will be used in this resource.
		//the list of state will be parsed by the admin system to be used in
		//the state based selection method.
		//Parameters:
		//	String:stateNames - The names of the states
		//	Note: as opposed to the state saved for the ad level, there is
		// 	only one state for the campaign level, and when refering to
		// 	"state name" it is actually the state value
		public function registerState(stateNames) 
		{
			try
			{
				//verify that the appropriate value was recieved
				if ((typeof (stateNames) == "undefined") || (stateNames == "")) 
				{
					Tracer.debugTrace("CreativeState: registerState: Invalid parameter", 1);
					return;
				}
				//the state names should be seperated by comma
				if (this._strStates != "") 
					this._strStates = this._strStates += ",";
				this._strStates += stateNames;
				//remove all starting and ending spaces.
				this._strStates = trimStatesList(this._strStates);
				Tracer.debugTrace("CreativeState: registerState: _strStates = "+this._strStates, 1);
			}catch(err:Error)
			{
				Tracer.debugTrace("CreativeState: registerState Error: " + err.message, 1);
			}
		}
		
		//===============================
		// function setStateExt
		//===============================
		//This function sets the state in the server cookie.
		//the state will be saved in the server cookie, to be used in
		//the state based selection method.
		//Parameters:
		// 	String:name - The name of the state
		// 	Note: as opposed to the state saved for the ad level, there is
		// 	only one state for the campaign level, and when refering to
		// 	"state name" it is actually the state value
		public function setStateExt(name) 
		{
			try
			{
				//remove all starting and ending spaces.
				name = trim(name);
				Tracer.debugTrace("CreativeState: setStateExt(" + name + ")", 1);
				//verify that the state exist in the array
				var stateArr = this._strStates.split(",");
				var i = 0;
				while ((stateArr[i] != name) && i < stateArr.length)
					i++;
				//the state does not exist
				if (i == stateArr.length)
					Tracer.debugTrace("CreativeState: setStateExt: Warning: The state '" + name + "' was not registered", 1);
				fscommand("ebSetState", name);
			}catch(err:Error)
			{
				Tracer.debugTrace("CreativeState: setStateExt Error: " + err.message, 1);
			}
		}
		
		//===============================
		// function resetState
		//===============================
		//This function resets the state in the server cookie.
		//the state will be resets(cleared) in the server cookie, to be used
		//in the state based selection method.
		//Parameters:
		// 	None
		// 	Note: as opposed to the state saved for the ad level, there is
		// 	only one state for the campaign level, and when refering to
		// 	"state name" it is actually the state value
		public function resetState() 
		{
			Tracer.debugTrace("CreativeState: resetState", 6);
			try
			{
				fscommand("ebResetState");
			}catch(err:Error)
			{
				Tracer.debugTrace("CreativeState: resetState Error: " + err.message, 1);
			}
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//====================================
		//	function _init
		//====================================
		//This function initializes the class attributes and set the size
		//(including scale).
		//This function is called from constructor
		function _init()
		{
			_initComp();
			_initAttr();
		}
		
		//====================================
		//	function _initComp
		//====================================
		//This function initializes the component
		private function _initComp():void
		{
			//Admin component identification
			ebGlobal.ebSetComponentName("CreativeState");
			
			//Use superdomain when accessing locally persistent data (shared objects). 
			try
			{
				Security.exactSettings = false;
			}catch(error:Error)
			{
				Tracer.debugTrace("Exception in CreativeState: _initComp: " + error, 1);
			}
			//hide the component
			this.alpha = 0;
		}
		
		//====================================
		//	function _initAttr
		//====================================
		//This function initializes the class attributes
		private function _initAttr():void
		{
			var urlParams = ebGlobal.urlParams;
			//set value
			urlParams.ebAdID = (!urlParams.ebAdID || (urlParams.ebAdID == -1)) ? "NoID" : urlParams.ebAdID;
			urlParams.ebCampaignID = (!urlParams.ebCampaignID || (urlParams.ebCampaignID == -1)) ? urlParams.ebAdID : urlParams.ebCampaignID;
			Tracer.debugTrace("CreativeState: campaignID, adID = "+urlParams.ebCampaignID +", "+urlParams.ebAdID, 1);
			
			//init class attributes
			this._soName = "" + urlParams.ebCampaignID;
			this._strStates = "";
		}
	}
}