//****************************************************************************
//class eyeblaster.media.controls.SeekBtn
//---------------------------------------
//This is a Seek button.
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
	
	[Event("ebVBSeek", type="mx.eyeblaster.General.VideoEvent")]
	
	public class SeekBtn extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		protected var _secToSeek:Number;					//seek value
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function SeekBtn()
		{
			Tracer.debugTrace("SeekBtn: Constructor", 3);
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
				Tracer.debugTrace("SeekBtn: init", 6);
				//init inherited attributes
				super.init();
				//set states	
				this._setStatesArr();
				//set state button
				this.updateState(this.state);	
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in SeekBtn: init: "+ error, 1);
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
				Tracer.debugTrace("SeekBtn: handleClick", 3);
				//videoLoader instance
				if(typeof(this._videoLoaderInst) == "undefined")
				{
					Tracer.debugTrace("SeekBtn: Error, no VideoLoader instance", 6);
					return;
				}
				
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVBSeek", this._secToSeek);
				dispatchEvent(ev);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in SeekBtn: handleClick: "+ error, 1);
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
				this._statesArr[this.state] = 0;
				this._statesArr.length = 1;
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in SeekBtn: _setStatesArr: "+ error, 1);
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
				this._compEventsArr = new Array("ebVBSeek");
				//no VL events to listen to
				this._eventsArr = new Array();
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in SeekBtn: _setEvents: "+ error, 1);
			}
		}
	}
}