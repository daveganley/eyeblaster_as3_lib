//****************************************************************************
//class eyeblaster.utils.MouseTracking
//------------------------------------
//This class is a for the MouseTracker component.
//This component checks the position of the mouse on the page->
//the absolute position of the mouse on the page (x and y cordinates)
//and the position of the mouse relatively to the ad (x and y cordinates)
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************

package eyeblaster.utils
{
	import flash.display.MovieClip;
	import flash.system.fscommand;
	import flash.external.ExternalInterface;
	import eyeblaster.core.Tracer;
	
	public class MouseTracking extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private var _nCompID:Number;	    //id of the component
		private var _JSAPIFuncName:String;  //the name of the function used to recieve calls from the JavaScript
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//				Private Static Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private static var _nInstCount:Number = 0;	//VideoLoader component instance count
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		public var onMouseMoveXY:Function;    //handler to the function that is implemented by the creative
		
		//----General------
		include "../core/compVersion.as"
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Public Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function MouseTracking()
		{
			Tracer.debugTrace("MouseTracking: Constructor", 6);
			Tracer.debugTrace("MouseTracking version: "+compVersion, 0);
			Tracer.debugTrace("Eyeblaster Workshop | MouseTracking | You are currently using a deprecated version of the component, please import a newer version to stage.  For more information see the on-line help.",0);
			this._init();
		}
		
		//============================
		//	function JSAPIFunc
		//============================
		//This function is used to recive calls from the javaScript
		public function JSAPIFunc(funcName:String, strParams:String)
		{
			
			//a call to the function that is implemented by the creative only in case the
			//funcName received from the JS is "onMouseMove" and in case the creative implemented the function
			if ((funcName == "onMouseMove") && (onMouseMoveXY != null))
			{
				//an array for the parameters received from the JS
				var arrParams = strParams.split(",");
				//call to the function of the creative with the parameters received from the JS:
				//absolute position of the mouse - X cordinate
				//absolute position of the mouse - Y cordinate
				//relative position of the mouse - X cordinate
				//relative position of the mouse - Y cordinate
				onMouseMoveXY(Number(arrParams[0]),Number(arrParams[1]),Number(arrParams[2]),Number(arrParams[3]));
			}
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//====================================
		//	function _init
		//====================================
		//This function initializes the class attributes and 
		//add an API function to the JavaScript for communication
		private function _init():void
		{
			try
			{
				ebGlobal.ebSetComponentName("MouseTracker");
				//hiding component at runtime
				this.alpha = 0;
				//setting values to attributes
				this.onMouseMoveXY = null;
				//add an API function to the JavaScript for communication
				if(ExternalInterface.available)
				{
					//update the instance count
					this._nCompID = ++_nInstCount;
					//register the JS API function
					this._JSAPIFuncName = "handleMouseTracker" + this._nCompID;
					ExternalInterface.addCallback(_JSAPIFuncName, JSAPIFunc);
					//send fscommand ebMouseTracker to the JS with the API function
					fscommand("ebMouseTracker", this._JSAPIFuncName);
				} 
				else
				{
					Tracer.debugTrace("MouseTracking: _init - External interface is not available for this container", 1);
				}
			}
			catch(error:Error)
			{
				Tracer.debugTrace("Exception in MouseTracking:_init: "+error,1);
			}
		}
	}
}