//****************************************************************************
//class eyeblaster.media.controls.MuteBtn
//---------------------------------------
//This is a Mute button.
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
	
	[IconFile("Icons/Mute.png")]
	[Event("ebVBMute", type="mx.eyeblaster.General.VideoEvent")]
	
	public class MuteBtn extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "MuteBtn";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function MuteBtn()
		{
			try
			{
				Tracer.debugTrace("MuteBtn: Constructor", 3);
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				EBBase.ebSetComponentName("MuteBtn");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in MuteBtn: Constructor: "+ error, 1);
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
			Tracer.debugTrace("MuteBtn: initUponEnterFrame", 6);
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
				Tracer.debugTrace("MuteBtn: init", 6);
				//init inherited attributes
				super.init();
				//set states	
				this._setStatesArr();
				//set the component default state
				this.updateState("ebVBMute");		
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in MuteBtn: init: "+ error, 1);
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
				Tracer.debugTrace("MuteBtn: handleClick", 3);
				//videoLoader instance
				if(typeof(this._videoLoaderInst) == "undefined")
				{
					Tracer.debugTrace("MuteBtn: Error, no VideoLoader instance", 6);
					return;
				}
				
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVBMute", this._statesArr[this.state]);
				dispatchEvent(ev);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in MuteBtn: handleClick: "+ error, 1);
			}
		}
		
		//========================
		//	function handleEvent
		//========================
		//This function is the event handler of the "ebVLMute" event
		public override function handleEvent(evt:Object):void
		{
			try
			{
				Tracer.debugTrace("MuteBtn: handle event type : "+evt.type + ", value: " + evt.value, 6);
				this.state = evt.value ? "ebVBMute" : "ebVBUnmute";
				this.updateState(this.state);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in MuteBtn: handleEvent: "+ error, 1);
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
				this._statesArr["ebVBMute"] = 0;
				this._statesArr["ebVBUnmute"] = 1;
				this._statesArr.length = 2;
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in MuteBtn: _setStatesArr: "+ error, 1);
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
				//listen to the videoLoader events and attach the appropriate events
				//to the videoLoader
				this._eventsArr = new Array("ebVLMute");
				this._compEventsArr = new Array("ebVBMute");
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in MuteBtn: _setEvents: "+ error, 1);
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
				Tracer.debugTrace("MuteBtn: _setAttrFromLoader", 6);
				//listen to the videoLoader events and attach the appropriate events
				//to the videoLoader
				if(typeof(this._videoLoaderInst) != "undefined")
				{
					this.state = this._videoLoaderInst.isMute ? "ebVBMute" : "ebVBUnmute";
					this.updateState(this.state);
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in MuteBtn: _setAttrFromLoader: "+ error, 1);
			}
		}
	}
}