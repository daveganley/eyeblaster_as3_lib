//****************************************************************************
//class eyeblaster.media.controls.StopBtn
//---------------------------------------
//This is a stop button.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.controls
{
	import eyeblaster.core.Tracer;
	import eyeblaster.media.controls.BasePlayerCtrl;
	import eyeblaster.media.general.VideoEvent;
	import flash.display.MovieClip;
	import flash.events.Event;
    import flash.events.MouseEvent;
	
	[IconFile("Icons/Stop.png")]
	[Event("ebVBStop", type="mx.eyeblaster.General.VideoEvent")]
	
	public class StopBtn extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "StopBtn";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function StopBtn()
		{
			try
			{
				Tracer.debugTrace("StopBtn: Constructor", 3);
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				EBBase.ebSetComponentName("StopBtn");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StopBtn: Constructor: "+ error, 1);
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
				Tracer.debugTrace("StopBtn: init", 6);
				//init inherited attributes
				super.init();
				//set states	
				this._setStatesArr();
				//set the component default state
				this.updateState("ebVBStop");		
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StopBtn: init: "+ error, 1);
			}
		}
		
		//========================
		//	function handleClick
		//========================
		//This function handles the release event, it execute the  
		//state code and toggle to the other state
		public override function handleClick(mouseEv:MouseEvent):void
		{
			try
			{
				Tracer.debugTrace("StopBtn: handleClick", 3);
				//videoLoader instance
				if(typeof(this._videoLoaderInst) == "undefined")
				{
					Tracer.debugTrace("StopBtn: Error, no VideoLoader instance", 6);
					return;
				}
				
				//fire event
				var ev:VideoEvent = new VideoEvent(this.state, "");
				dispatchEvent(ev);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StopBtn: handleClick: "+ error, 1);
			}
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//================================
		//	function _setStatesArr
		//==============================
		//This function initializes the states arrays with the different component
		//states
		private function _setStatesArr()
		{
			try
			{
				//set the component states
				this._statesArr = new Object();
				this._statesArr["ebVBStop"] = 0;
				this._statesArr.length = 1;
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StopBtn: _setStatesArr: "+ error, 1);
			}
		}
		
		//================================
		//	function _setEvents
		//==============================
		//This function set a list of listeners for the VideoLoader and register 
		//to the video loader events
		private function _setEvents():void
		{
			try
			{
				//attach the appropriate events to the videoLoader
				this._compEventsArr = new Array("ebVBStop");
				//no VL events to listen to
				this._eventsArr = new Array();
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in StopBtn: _setEvents: "+ error, 1);
			}
		}
	}
}