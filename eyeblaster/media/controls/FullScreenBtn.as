//****************************************************************************
//class eyeblaster.media.controls.FullScreenBtn
//---------------------------------------
//This is a FullScreen button.
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
	
	[IconFile("Icons/FullScreen.png")]
	[Event("ebVBFullscreen", type="mx.eyeblaster.General.VideoEvent")]
	
	public class FullScreenBtn extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----State------
		private var _stateID:Array;			//map state id to name
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "FullScreen";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function FullScreenBtn()
		{
			try
			{
				Tracer.debugTrace("FullScreenBtn: Constructor", 3);
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				EBBase.ebSetComponentName("FullScreenBtn");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in FullScreenBtn: Constructor: "+ error, 1);
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
			Tracer.debugTrace("FullScreenBtn: initUponEnterFrame", 6);
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
				Tracer.debugTrace("FullScreenBtn: init", 6);
				//init inherited attributes
				super.init();
				//set states	
				this._setStatesArr();
				//set the component default state
				this.updateState("ebVBDisabledFS");		
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in FullScreenBtn: init: "+ error, 1);
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
				Tracer.debugTrace("FullScreenBtn: handleClick", 3);
				//videoLoader instance
				if(typeof(this._videoLoaderInst) == "undefined")
				{
					Tracer.debugTrace("FullScreenBtn: Error, no VideoLoader instance", 6);
					return;
				}
				
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVBFullscreen", this._statesArr[this.state]);
				dispatchEvent(ev);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in FullScreenBtn: handleClick: "+ error, 1);
			}
		}
		
		//========================
		//	function handleEvent
		//========================
		//This function is the event handler of the "ebVLFullScreen" event
		public override function handleEvent(evt:Object):void
		{
			try
			{
				Tracer.debugTrace("FullScreenBtn: handle event type : "+evt.type + ", value: " + evt.value, 6);
				//update state
				this.updateState(this._stateID[evt.value]);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in FullScreenBtn: handleEvent: "+ error, 1);
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
				this._statesArr["ebVBDisabledFS"] = 0;
 				this._statesArr["ebVBFullScreen"] = 1;
				this._statesArr["ebVBRegularScreen"] = 2;
				this._statesArr.length = 3;
		
				//update the array with the states
				this._stateID = new Array("ebVBDisabledFS", "ebVBFullScreen", "ebVBRegularScreen");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in FullScreenBtn: _setStatesArr: "+ error, 1);
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
				this._eventsArr = new Array("ebVLFullscreen");
				this._compEventsArr = new Array("ebVBFullscreen");
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in FullScreenBtn: _setEvents: "+ error, 1);
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
				Tracer.debugTrace("FullScreenBtn: _setAttrFromLoader", 6);
				//listen to the videoLoader events and attach the appropriate events
				//to the videoLoader
				if(typeof(this._videoLoaderInst) != "undefined")
				{
					//set defualt value
					var FSState:Number = 0;
					//the full screen button should be updated only when 
					//the Video is playing.
					if(_videoLoaderInst.isVideoPlaying())
						FSState = this._videoLoaderInst.fullScreenState;
					//update state
					this.updateState(this._stateID[FSState]);
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in FullScreenBtn: _setAttrFromLoader: "+ error, 1);
			}
		}
	}
}