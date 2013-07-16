//****************************************************************************
//class eyeblaster.video.controls.VolumeSlider
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
	
	[IconFile("Icons/VolumeSlider.png")]
	[Event("ebVBVolume", type="mx.eyeblaster.General.VideoEvent")]
	
	public class VolumeSlider extends BasePlayerCtrl
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		private static var _strCtrlType:String = "VolumeSlider";
		
		//----attributes----
		private var _value:Number;	//the slider value
		
		//----slider elements----
		private var _trail:DisplayObject;			//trail (dragging area)
		private var _slider:MovieClip;		//slider (dragable element)
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "VolumeSlider";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function VolumeSlider()
		{
			try
			{
				Tracer.debugTrace("VolumeSlider: Constructor", 3);
				
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				ebGlobal.ebSetComponentName("VolumeSlider");
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: Constructor: "+ error, 1);
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
			Tracer.debugTrace("VolumeSlider: initUponEnterFrame", 6);
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
				Tracer.debugTrace("VolumeSlider: init", 6);
				//init inherited attributes
				super.init();
				//init attr
				this._value = -1;
				//init the component
				this._initComp();	
				//register to the VideoLoader events
				//and register it to the component events
				this._setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: init: "+ error, 1);
			}
		}
		
		//========================
		//	function handleEvent
		//========================
		//This function is the event handler of the "ebVLVolume" events
		public override function handleEvent(evt:Object):void
		{
			try
			{
				Tracer.debugTrace("VolumeSlider: handle event: "+evt.type + ", value: " + evt.value, 6);
				this._updateValue(evt.value);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: handleEvent: "+ error, 1);
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
				//to enable the dragging we should place the slider button in a movie clip
				// - get slider button:
				var slider_btn = this.getChildAt(1);
				// - insert the button inside a movie clip
				this._slider = new MovieClip();
				this.addChildAt(this._slider, 1);
				this._slider.addChild(slider_btn);
				//position elements
				this._slider.x = this._trail.x = 0;
				this._slider.y = 0;
				this._trail.y = this._slider.y + (this._slider.height - this._trail.height)/2;
				
				//enable dragging
				_enableDragging();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: _initComp: "+ error, 1);
			}
		}

		//==========================
		//	function _enableDragging
		//==========================
		//This function enables dragging
		private function _enableDragging():void
		{
			try
			{
				Tracer.debugTrace("VolumeSlider: _enableDragging", 6);
				var slider = this._slider.getChildAt(0);	//slider (dragable element)
				var trail = this._trail;		//trail (dragging area)
				//attach events
				//	drag
				slider.addEventListener(MouseEvent.MOUSE_DOWN, _startDrag);
            	//	drop (replace onRelease and onRelease outside events)
				stage.addEventListener(MouseEvent.MOUSE_UP, _drop);
				//	update value
				trail.addEventListener(MouseEvent.CLICK, _updateUponClick);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: _enableDragging: "+ error, 1);
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
				Tracer.debugTrace("VolumeSlider: _updateValue(" + val + ")", 3);
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
				Tracer.debugTrace("Exception in VolumeSlider: _updateValue: "+ error, 1);
			}
		}
		
		//========================
		//	function _calcValue
		//========================
		//This function calculates the slider value
		public function _calcValue():void
		{
			try
			{
				Tracer.debugTrace("VolumeSlider: _calcValue", 6);
				//the area the slider covers (from its position to the beginning of the trail)
				var volArea = (this._slider.x - this._trail.x);
				//the movment area
				var movmentArea = (this._trail.width - this._slider.width);
				//verify the area length is in boundaries 
				volArea = (volArea < 0) ? 0 : volArea;
				volArea = (volArea > movmentArea) ? movmentArea : volArea;
				//new value
				var newVal = Math.round((volArea/movmentArea) * 100);
				//update value and send event only if the value was changed
				if(newVal != this._value)
				{		
					//update value
					this._value = newVal;
					//send event
					_sendEvent(this._value);
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: _calcValue: "+ error, 1);
			}
		}
		
		//==============================
		//	function _sendEvent
		//==============================
		//This function dispatch the ebVBVolume
		private function _sendEvent(val)
		{
			try
			{
				Tracer.debugTrace("VolumeSlider: _sendEvent: "+val, 3);
				//videoLoader instance
				if(typeof(this._videoLoaderInst) == "undefined")
				{
					Tracer.debugTrace("VolumeSlider: Error, no VideoLoader instance", 6);
					return;
				}
				//fire event
				var ev:VideoEvent = new VideoEvent("ebVBVolume", val);
				// Dispatch the event
				dispatchEvent(ev);
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: _sendEvent: "+ error, 1);
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
				this._eventsArr = new Array("ebVLVolume");
				this._compEventsArr = new Array("ebVBVolume");
				this.setEvents();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in VolumeSlider: _setEvents: "+ error, 1);
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
				Tracer.debugTrace("VolumeSlider: _setAttrFromLoader", 6);
				//update volume from the video component
				if(typeof(this._videoLoaderInst) != "undefined")
				{
					var value:Number = this._videoLoaderInst.VideoGetVolume();
					if(typeof(value) == "undefined")
					{
						if(typeof(ebGlobal.urlParams.ebVolume) != "undefined")
							value = Number(ebGlobal.urlParams.ebVolume);
						else
							value = 100;
					}
					this._updateValue(value);
				}
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in PlayPauseBtn: _setAttrFromLoader: "+ error, 1);
			}
		}
	}
}