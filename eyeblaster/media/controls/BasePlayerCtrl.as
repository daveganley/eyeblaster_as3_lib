//****************************************************************************
//class eyeblaster.media.controls.BasePlayerCtrl
//----------------------------------------
//This is a base control class to be extended by the differnt player control 
//classes.
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.controls
{
	import eyeblaster.core.Tracer;
	import flash.display.MovieClip;
	import flash.events.*;
	import flash.utils.*;
	
	public class BasePlayerCtrl extends MovieClip
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
	
		//----State------
		private var _state_btn:Object;		//The button state icon
		private var _strState:String;		//The button state name
		protected var _statesArr:Object;		//states list
		
		//----Init-------
		protected var _videoLoaderInst:Object;		//the VideoLoader instance
		private var _videoLoaderInstName:String = "_videoLoaderInst";	//the VideoLoader instance name
					
		//----Events-----
		protected var _eventsArr:Array;		//an array containing the events to 
											//register to
		protected var _compEventsArr:Array;	//an array containing the component events
											
		private var _intervalID:Number;				//interval id for the _registerEvents						
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
	
		//----UI------
		[Inspectable(defaultValue="_videoLoaderInst", type=String)]
		public function get strVideoLoaderInst():String {return this._videoLoaderInstName}
		public function set strVideoLoaderInst(name:String):void {this._videoLoaderInstName = name;}
		
		//----State------
		public function get state():String {return _strState}
		public function set state(strState:String):void{_strState = strState;}
	
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function BasePlayerCtrl()
		{
		}
		
		//=======================
		//	function init
		//=======================
		//This function initialize the class attributes
		public function init():void
		{
			try
			{
				Tracer.debugTrace("BasePlayerCtrl: init", 3);
				//hide the component if it is size 1x1
				if((this.width <= 1) && (this.height <= 1))
					this.visible = false;
				
				//init attribute
				this._intervalID = -1;
				
				//init VideoLoader instance
				this._videoLoaderInst = parent.getChildByName(this._videoLoaderInstName);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in BasePlayerCtrl: init: "+ error, 1);
			} 
		}
		
		//========================
		//	function handleClick
		//========================
		//This function handles the release event, it execute the  
		//state code and toggle to the other state
		public function handleClick(mouseEv:MouseEvent):void
		{
		}
		
		//========================
		//	function handleEvent
		//========================
		//This function is the event handler of the component events
		public function handleEvent(evt:Object):void
		{
		}
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Protected Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//========================
		//	function updateState
		//========================
		//This function updates the state in the different controls
		//This function is used by the Video Loader component instance
		//this object is connected to.
		protected function updateState(strState:String):void
		{
			try
			{
				this._strState = strState;
				//update state button - the order of the states is revered from the frames order (see MuteBtn, FullScreenBtn and PlayPauseBtn)
				this.gotoAndStop(this._statesArr[this._strState] + 1);
				//set the onRlease event
				_setClickEvent();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in BasePlayerCtrl: updateState: "+ error, 1);
			} 
		}
		
		//================================
		//	function setEvents
		//==============================
		//This function set a list of listeners for the VideoLoader and register 
		//to the video loader events
		protected function setEvents():void
		{
			try
			{
				this._registerEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in BasePlayerCtrl: setEvents: "+ error, 1);
			} 
		}
		
		//==============================
		//	function _setAttrFromLoader
		//==============================
		//This function updates the different attirbutes according to
		//the VideoLoader, in this case it updates the defualt value
		//to handle the situation in which this control is loaded after
		//the video started
		protected function _setAttrFromLoader():void
		{
		}
	
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					 Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===========================
		//	function _registerEvents
		//===========================
		//This function registers to the VideoLoader events
		private function _registerEvents()
		{
			try
			{
				Tracer.debugTrace("BasePlayerCtrl: _registerEvents", 3);
				if((this._videoLoaderInst) && 
						(typeof(this._videoLoaderInst.addEventListener) == "function"))
				{	
					//register to the VideoLoader events
					for(var i = 0;i < this._eventsArr.length;i++)
						this._videoLoaderInst.addEventListener(this._eventsArr[i], this.handleEvent);
					//add listeners for all the component events for the VideoLoader
					for(i = 0;i < this._compEventsArr.length;i++)
						this.addEventListener(this._compEventsArr[i], this._videoLoaderInst.handleEvent);
					//clear interval
					if(this._intervalID != -1)
						clearInterval(this._intervalID);
					//set Attributes according to VideoLoader
					this._setAttrFromLoader();
				}
				else
				{
					Tracer.debugTrace("BasePlayerCtrl: _registerEvents: no addEventListener", 6);
					if(this._intervalID == -1)
					{
						Tracer.debugTrace("BasePlayerCtrl: _registerEvents: set interval", 6);
						this._intervalID = setInterval(_registerEvents, 10);
					}
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in BasePlayerCtrl: _registerEvents: "+ error, 1);
			} 
		}
		
		//==========================
		//	function _setClickEvent
		//==========================
		//This function sets the click event to the current state button of the component
		private function _setClickEvent()
		{
			try
			{
				Tracer.debugTrace("BasePlayerCtrl: _setClickEvent: "+this.state, 3);
				this._state_btn = this.getChildAt(0);
				//we set the click event on the button and not the component because mouse events are not bubbled
				//if the event if handled by the component, the different button frames (rollover, rollout, click) will be ignored.
				if(this._state_btn)
					this._state_btn.addEventListener(MouseEvent.CLICK, handleClick);
				else
					setTimeout(this._setClickEvent, 50);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in BasePlayerCtrl: _setClickEvent: "+ error, 1);
			} 
		}
	}
}