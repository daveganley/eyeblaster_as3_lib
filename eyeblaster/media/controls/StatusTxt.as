//****************************************************************************
//class eyeblaster.media.controls.StatusTxt
//---------------------------------------
//This is a stop button.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.controls
{
	import eyeblaster.core.Tracer;
	import eyeblaster.media.controls.BasePlayerCtrl;
	import flash.text.*;
	import flash.events.*;
	
	[IconFile("Icons/Status.png")]
	
	public class StatusTxt extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private static var _strCtrlType:String = "StatusTxt";
		public var txtField:TextField;		//the text object contaning the status
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "StatusTxt";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function StatusTxt()
		{
			try
			{
				Tracer.debugTrace("StatusTxt: Constructor", 3);
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				EBBase.ebSetComponentName("StatusTxt");

				//get textField element
				this.txtField = this.getChildAt(0) as TextField;
				//set default value
				this.txtField.text = "";
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StatusTxt: Constructor: "+ error, 1);
			} 
		}
		
		//====================================
		//	function enterFrameHandler
		//====================================
		// This function calls init function upon enter frame event to
		// allow the UI parameters to get their value before we init
		// the component
		public function initUponEnterFrame(event:Event)
		{
			Tracer.debugTrace("StopBtn: initUponEnterFrame", 6);
			removeEventListener(Event.ENTER_FRAME, initUponEnterFrame);
			this.init();
		}
		
		//=======================
		//	function init
		//=======================
		//This function initialize the class attributes, it calls the
		//super init function, to init the inherited attributes and
		//init the size.
		public override function init():void
		{
			try
			{
				Tracer.debugTrace("StatusTxt: init", 6);
				//init inherited attributes
				super.init();
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StatusTxt: init: "+ error, 1);
			}
		}
		
		//========================
		//	function handleEvent
		//========================
		//This function is the event handler of the "ebVLStatusChanged" events
		public override function handleEvent(evt:Object):void
		{
			try
			{
				//check whether handleEvent is called from the dispatch VideoEvent (which is used for the controls-internal) and not from EBVideoEvent (which is used for teh users - external)
				if (evt.hasOwnProperty("value"))
				{
					Tracer.debugTrace("StatusTxt: handle event: "+ evt.type +", value: " + evt.value, 6);
					this.updateValue(evt.value);
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StatusTxt: handleEvent: "+ error, 1);
			}
		}
		
		//========================
		//	function updateValue
		//========================
		//This function registers to the VideoLoader events
		//Parameters:
		//	text:String - the textField string
		public function updateValue(text:String):void
		{
			try
			{
				this.txtField.text = text;
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StatusTxt: updateValue: "+ error, 1);
			}
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//================================
		//	function _setEvents
		//==============================
		//This function set a list of listeners for the VideoLoader and register 
		//to the video loader events
		private function _setEvents():void
		{
			try
			{
				//no component events
				this._compEventsArr = new Array();
				//listen to the videoLoader events and attach the appropriate events
				//to the videoLoader
				this._eventsArr = new Array("ebVLStatusChanged");	//VideoLoader events
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StatusTxt: _setEvents: "+ error, 1);
			}
		}
		
		//================================
		//	function _setAttrFromLoader
		//==============================
		//This function updates the different attirbutes according to
		//the VideoLoader, in this case it updates the defualt value
		//to handle the situation in which this control is loaded after
		//the video started
		protected override function _setAttrFromLoader():void
		{
			try
			{
				Tracer.debugTrace("StatusTxt: _setAttrFromLoader", 6);
				//Video status
				var strStatus:String = this._videoLoaderInst.status;
				//set a default value
				if(typeof(strStatus) == "undefined")
					strStatus = "Idle";
				//update status
				this.updateValue(strStatus);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StatusTxt: _setAttrFromLoader: "+ error, 1);
			}
		}
	}
}