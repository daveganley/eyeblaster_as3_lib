//****************************************************************************
//      EBStd class
//---------------------------
//
//This class containing "top level" Eyeblaster attributes and functions, the class also replaces the _global and _root objects which were removed in AS 3.0 with no replacement. 
//(The class contains static attributes and functions in order to simulate global variables/functions).
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package
{ 
	import flash.display.*;
	import flash.system.*;
	import flash.external.ExternalInterface;

	public class EBStd 
	{
		private static var _eb:EBStd = null;
		public static var urlParams:Object = new Object();			//URL parameters
		//----parameters for saving clickTag value in both ways (clickTag/clickTAG)------
		public static var clickTag:String;						
		public static var clickTAG:String;
		public static var clickTARGET:String;				
		public static var SVversionCT:String="";
		public static var flashId:String;							//the flash id

		//----version------
		include "eyeblaster/core/ebVersion.as"
		include "eyeblaster/core/compVersion.as"
		
		public function EBStd(objRef) 
		{
			try
			{
				urlParams = objRef.getChildAt(0).loaderInfo.parameters;
				Security.allowDomain(urlParams.ebDomain);
				setStaticParams();
				_eb = this;
			}
			catch (error:Error)
			{
				trace("Error | Exception in constructor: "+ error);
			}
        }
			
		public static function Init(objRef)
		{
			try
			{
				var _stage:Stage = ((String(objRef)=="[object MainTimeline]") || (String(objRef.parent)=="[object Stage]")) ? objRef.stage : objRef;
				if(_eb == null)
					_eb = new EBStd(_stage);	
			}
			catch (error:Error)
			{
				trace("Error | Exception in Init function: "+ error);
			}
		}

		//========================
        //	 ebSetComponentName  
		//========================
		//This function allows to identify the different componenets
		//parameters - 
		//	 compName:String - the component name
		public static function ebSetComponentName(compName){}
		
		public static function Clickthrough(name:String = "")
		{
			var strMsg = "Eyeblaster Workshop | Clickthrough tracked";
			trace(strMsg);
				
			// handle SV2 ClickThrough for products or versions
			if (SVversionCT!="")
				name = SVversionCT;
			if (name!="" && name.indexOf("SV2:")!=0)
				name = "";			
			handleCommand("ebClickthrough", name);
		}
		
		//=====================
		//	 handleCommand  
		//=====================
		//The function recieve a command and send it to the JS or the container (depending on the ad format)
		public static function handleCommand(cmd:String,args:String="")
		{
			try
			{
				//send the command to the JS
				if((ExternalInterface.available) && (EBStd.flashId != null) && (ExternalInterface.call("ebIsFlashExtInterfaceExist")))
					ExternalInterface.call(flashId + "_DoFSCommand", cmd, args);
				else
					fscommand(cmd,args);
			}
			catch(error:Error)
			{
				trace("Error | Exception in handleCommand function: "+ error);
			}
		}
		
		//======================
        //	  setStaticParams  
		//======================
		//The function sets the static parameters of clickTag (both ways)
		//and ebMovie (from 1 to 10) according the values transferred from the JS.
		private function setStaticParams()
		{
			clickTag = urlParams.clickTag;
			clickTAG = urlParams.clickTAG;
			clickTARGET = urlParams.clickTARGET;
			flashId = urlParams.ebFlashID;
		}
    } 
}