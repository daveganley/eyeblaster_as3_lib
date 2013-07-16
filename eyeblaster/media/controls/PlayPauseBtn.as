//****************************************************************************
//class eyeblaster.media.controls.PlayPauseBtn
//---------------------------------------
//This is a PlayPause button.
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
	
	[IconFile("Icons/PlayPause.png")]
	[Event("ebVBPlay", type="mx.eyeblaster.General.VideoEvent")]
	[Event("ebVBPause", type="mx.eyeblaster.General.VideoEvent")]
	
	public class PlayPauseBtn extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "PlayPauseBtn";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function PlayPauseBtn()
		{
			try
			{
				Tracer.debugTrace("PlayPauseBtn: Constructor", 3);
				
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				EBBase.ebSetComponentName("PlayPauseBtn");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: Constructor: "+ error, 1);
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
			Tracer.debugTrace("PlayPauseBtn: initUponEnterFrame", 6);
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
				Tracer.debugTrace("PlayPauseBtn: init", 6);
				//init inherited attributes
				super.init();
				//set states	
				this._setStatesArr();
				//set the component default state
				this.updateState("ebVBPlay");		
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: init: "+ error, 1);
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
				Tracer.debugTrace("PlayPauseBtn: handleClick", 3);
				//videoLoader instance
				if(typeof(this._videoLoaderInst) == "undefined")
				{
					Tracer.debugTrace("PlayPauseBtn: Error, no VideoLoader instance", 6);
					return;
				}
				
				//fire event
				var ev:VideoEvent = new VideoEvent(this.state, "");
				dispatchEvent(ev);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: handleClick: "+ error, 1);
			}
		}
		
		//========================
		//	function handleEvent
		//========================
		//This function is the event handler of the "ebVLPlayPause" event
		public override function handleEvent(evt:Object):void
		{
			try
			{
				Tracer.debugTrace("PlayPauseBtn: handle event type : "+evt.type, 6);
				//the state is opposite to the event name the VideoLoader fires
				var state = evt.type.substr(4).toLowerCase();
				state = (state == "play") ? "ebVBPause" : "ebVBPlay";
				
				this.updateState(state);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: handleEvent: "+ error, 1);
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
				this._statesArr["ebVBPlay"] = 0;
				this._statesArr["ebVBPause"] = 1;
				this._statesArr.length = 2;
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: _setStatesArr: "+ error, 1);
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
				this._eventsArr = new Array("ebVLPlay", "ebVLPause");	//VideoLoader events
				this._compEventsArr = new Array("ebVBPlay", "ebVBPause");	//the component events
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: _setEvents: "+ error, 1);
			}
		}
		
		//================================
		//	function _setAttrFromLoader
		//==============================
		//This function updates the different attirbutes according to
		//the VideoLoader, in this case it updates the default value
		//to handle the situation in which this control is loaded after
		//the video started
		protected override function _setAttrFromLoader():void
		{
			try
			{
				Tracer.debugTrace("PlayPauseBtn: _setAttrFromLoader", 6);
				if(this._videoLoaderInst.isVideoPlaying())
					this.updateState("ebVBPause");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: _setAttrFromLoader: "+ error, 1);
			}
		}
	}
}