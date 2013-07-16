//****************************************************************************
//class eyeblaster.video.controls.PlaybackSlider
//---------------------------------------
//This is a stop button.
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************
package eyeblaster.video.controls
{
	import eyeblaster.core.Tracer;
	import eyeblaster.video.controls.BasePlayerCtrl;
	import eyeblaster.video.general.VideoEvent;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Rectangle;
	
	[IconFile("Icons/PlaybackSlider.png")]
	[Event("ebVBUpdatePlayhead", type="mx.eyeblaster.General.VideoEvent")]
	
	public class PlaybackSlider extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----attributes----
		private var _value:Number;	//the slider value
		private var _fEnableDragging:Boolean;		//indicates whether Dragging is enabled
		private var _fIgnoreEvent:Boolean;		//indicates whether the progress event from the VideoLoader should be ignored (after drop event)
		private var _fPlaybackSlider:Boolean = true;	//Indicates whether playback slider is available
		private var _fLoadingBar:Boolean = false;	//Indicates whether loading bar is available
		
		//----slider elements----
		private var _trail:Object;			//trail (dragging area)
		private var _slider:MovieClip;			//slider (dragable element)
		private var _loadBar:MovieClip;			//load progress
		private var _loadBarArea:Number;	//load progress width
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Public Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----UI----
		[Inspectable(defaultValue=true, type=Boolean, category="functionality")]
		public function get fPlaybackSlider():Boolean{return this._fPlaybackSlider;}
		public function set fPlaybackSlider(flag:Boolean):void{this._fPlaybackSlider = flag;}
		
		[Inspectable(defaultValue=false, type=Boolean, category="functionality")]
		public function get fLoadingBar():Boolean{return this._fLoadingBar;}
		public function set fLoadingBar(flag:Boolean):void{this._fLoadingBar = flag;}
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "PlaybackSlider";	//The component name.

		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function PlaybackSlider()
		{
			try
			{
				Tracer.debugTrace("PlaybackSlider: Constructor", 3);
				
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				ebGlobal.ebSetComponentName("PlaybackSlider");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: Constructor: "+ error, 1);
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
			Tracer.debugTrace("PlaybackSlider: initUponEnterFrame", 6);
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
				Tracer.debugTrace("PlaybackSlider: init", 6);
				//the component is not in use
				if(!this._fLoadingBar && !this._fPlaybackSlider)
				{
					this.visible = false;
					return;
				}
				//init inherited attributes
				super.init();
				//init attr
				this._fEnableDragging = false;
				this._value = -1;
				this._fIgnoreEvent = false;
				//init the component
				this._initComp();	
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: init: "+ error, 1);
			}
		}
		
		//========================
		//	function handleEvent
		//========================
		//This function is the event handler of the VideoLaoder events
		public override function handleEvent(evt:Object):void
		{
			try
			{
				Tracer.debugTrace("PlaybackSlider: handle event: "+evt.type + ", value: " + evt.value, 6);
				if(evt.type == "ebVLPlayProgress")
					this._handlePlayProgress(evt.value);
				else
					this._handleLoadProgress(evt);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: handleEvent: "+ error, 1);
			}
		}

		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//========================
		//	function _initComp
		//========================
		//This function init the component elements 
		private function _initComp():void
		{
			try
			{
				//build component elements (slider and trail):
				//get trail
				this._trail = this.getChildAt(0);
				//get loading bar
				this._loadBar = this.getChildAt(1) as MovieClip;
				//to enable the dragging we should place the slider button in a movie clip
				// - get slider button:
				var slider_btn = this.getChildAt(2);
				// - insert the button inside a movie clip
				this._slider = new MovieClip();
				this.addChildAt(this._slider, 2);
				this._slider.addChild(slider_btn);
				//position elements
				_setPosition();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: _initComp: "+ error, 1);
			}
		}
		
		//========================
		//	function _setPosition
		//========================
		//This function set the position of the component elements 
		function _setPosition()
		{
			// - slider
			this._slider.x = this._trail.x = 0;
			this._slider.y = 0;
			// - trail
			this._trail.y = this._slider.y + (this._slider.height - this._trail.height)/2;
			// - loading bar
			this._loadBar.y = this._trail.y + (this._trail.height - 1 - this._loadBar.height)/2;
			this._loadBar.x = this._trail.x + (this._trail.width - 1 - this._loadBar.width)/2;
			this._loadBarArea = this._loadBar.width;
			this._loadBar.width = 1;
			//no playback slider
			if(!_fPlaybackSlider)
				this._slider.alpha = 0;		
			//loading bar should be set to be visible (by default it is transparent)
			if(_fLoadingBar)
				this._loadBar.alpha = 1;
			//hide the trail in case both loading and playback should not be visible
			if(!_fLoadingBar && !_fPlaybackSlider)
				this._trail.alpha = 0;
		}

		//==========================
		//	function _enableDragging
		//==========================
		//This function enables dragging
		private function _enableDragging():void
		{
			try
			{
				Tracer.debugTrace("PlaybackSlider: _enableDragging", 6);
				var slider = this._slider.getChildAt(0);	//slider (dragable element)
				var trail = this._trail;		//trail (dragging area)
				//set the hand cursor over the _loadBar area to allow the click update
				_loadBar.buttonMode = true;
				//attach events
				//	drag
				slider.addEventListener(MouseEvent.MOUSE_DOWN, _startDrag);
            	//	drop (replace onRelease and onRelease outside events)
				stage.addEventListener(MouseEvent.MOUSE_UP, _drop);
				//	update value
				trail.addEventListener(MouseEvent.CLICK, _updateUponClick);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: _enableDragging: "+ error, 1);
			}
		}
		
		//==========================
		//	function _startDrag
		//==========================
		//This function enables dragging upon mouse down event
		private function _startDrag(event:MouseEvent):void 
		{
            this._slider.addEventListener(MouseEvent.MOUSE_MOVE, _updateUponDrag);
			//movement area
			var _x:Number = this._trail.x;
			var _y:Number = this._slider.y;
			var _width:Number = (this._trail.width - this._slider.width);
			//start drag
			this._slider.startDrag(false, new Rectangle(_x, _y, _width + 1, _y));
        }

		//==========================
		//	function _drop
		//==========================
		//This function disable dragging (drop) upon mouse up event
        private function _drop(event:MouseEvent):void 
		{
            this._slider.removeEventListener(MouseEvent.MOUSE_MOVE, _updateUponDrag);
            this._slider.stopDrag();
			//update value
			_calcValue();
        }

        //============================
		//	function _updateUponDrag
		//============================
		//This function updates the volume upon mouse move while the slider is dragged
		private function _updateUponDrag(event:MouseEvent):void 
		{
			//update value
			_calcValue();
        }
		
		//============================
		//	function _updateUponClick
		//============================
		//This function updates the slider position and volume upon click on the trail
		private function _updateUponClick(event:MouseEvent):void 
		{
			//calc new x pos
			var movmentArea = (this._trail.width - this._slider.width) + this._trail.x;
			//verify the nex position is in bounds
			var newX = (this.mouseX > movmentArea) ? movmentArea : this.mouseX;
			newX = (newX < 0) ? 0 : newX;
			//update postion
			this._slider.x = newX;
			//update value
			_calcValue();
		}
		
		//========================
		//	function _updateValue
		//========================
		//This function updates the value in the different controls
		//Parameters:
		//	val:Number - the new value
		private function _updateValue(val:Number):void
		{
			try
			{
				Tracer.debugTrace("PlaybackSlider: _updateValue(" + val + ")", 3);
				//the movment area
				var movmentArea = (this._trail.width - this._slider.width);
				//new position
				var newPos = (val/100 * (movmentArea)) + this._trail.x
				//verify the position is in the boundaries 
				newPos = (newPos > movmentArea) ? movmentArea : newPos;
				newPos = (newPos < 0) ? 0 : newPos;
				//update
				this._slider.x = newPos;
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: _updateValue: "+ error, 1);
			}
		}
		
		
		//==============================
		//	function _handlePlayProgress
		//==============================
		//This function handles the play progress event
		private function _handlePlayProgress(progress:Number):void
		{
			Tracer.debugTrace("PlaybackSlider: _handlePlayProgress: " + progress, 6);
			//after a drop event we should ignore the 1st progress event recieved 
			//from the VideoLoader
			if(!this._fIgnoreEvent)
				this._updateValue(progress);
			this._fIgnoreEvent = false;
		}
		
		//==============================
		//	function _handleLoadProgress
		//==============================
		//This function handles the load/buffer progress events
		private function _handleLoadProgress(evt:Object):void
		{
			Tracer.debugTrace("PlaybackSlider: _handleLoadProgress: " + evt.value, 6);
			this._loadBar.width = evt.value * ((this._loadBarArea)/100);
		}
		
		//========================
		//	function _calcValue
		//========================
		//This function calculates the slider value
		public function _calcValue():void
		{
			try
			{
				Tracer.debugTrace("PlaybackSlider: _calcValue", 6);
				//the area the slider covers (from its position to the beginning of the trail)
				var playbackArea = (this._slider.x - this._trail.x);
				//the movment area
				var movmentArea = (this._trail.width - this._slider.width);
				//verify the area length is in boundaries 
				playbackArea = (playbackArea < 0) ? 0 : playbackArea;
				playbackArea = (playbackArea > movmentArea) ? movmentArea : playbackArea;
				//new value
				var newVal = Math.round((playbackArea/ movmentArea) * 100);
				//update value and send event only if the value was changed
				if(newVal != this._value)
				{		
					//update value
					this._value = newVal;
					//set a flag to ignore the 1st progress event from the VideoLoader
					this._fIgnoreEvent = true;
					//send event
					_sendEvent(this._value);
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: _calcValue: "+ error, 1);
			}
		}
		
		//==============================
		//	function _sendEvent
		//==============================
		//This function dispatch the ebVBUpdatePlayhead
		private function _sendEvent(val)
		{
			try
			{
				Tracer.debugTrace("PlaybackSlider: _sendEvent: "+val, 3);
				//videoLoader instance
				if(typeof(this._videoLoaderInst) == "undefined")
				{
					Tracer.debugTrace("PlaybackSlider: Error, no VideoLoader instance", 6);
					return;
				}
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVBUpdatePlayhead", val);
				// Dispatch the event
				dispatchEvent(ev);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: _sendEvent: "+ error, 1);
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
				this._eventsArr = new Array("ebVLPlayProgress", "ebVLLoadProgress");
				this._compEventsArr = new Array("ebVBUpdatePlayhead");
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlaybackSlider: _setEvents: "+ error, 1);
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
				Tracer.debugTrace("PlaybackSlider: _setAttrFromLoader", 6);
				//update volume from the video component
				if(typeof(this._videoLoaderInst) != "undefined")
				{
					this._fEnableDragging = Boolean(this._videoLoaderInst.nPlaybackMode);
					//enable dragging (only for streaming)
					if(this._fEnableDragging && this.fPlaybackSlider)
					{
						_enableDragging();
					}
					else //disable hand cursor. in AS2 when a button is in movie clip the movie clip blocks the button. In AS3, the movie
						 //clip doesn't block the button and therefore we need to block the hand cursor of the button
					{
						var slider_btn = this._slider.getChildAt(0);
						slider_btn.useHandCursor = false;
						_trail.useHandCursor = false;	
					}
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: _setAttrFromLoader: "+ error, 1);
			}
		}
	}
}