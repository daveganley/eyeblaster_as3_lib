//****************************************************************************
//class eyeblaster.video.controls.SeekBackwardBtn
//---------------------------------------
//This is a Seek button.
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************
package eyeblaster.video.controls
{
	import eyeblaster.core.Tracer;
	import eyeblaster.video.controls.SeekBtn;
	import flash.display.MovieClip;
	import flash.events.*;
	
	[IconFile("Icons/SeekBackward.png")]
	
	public class SeekBackwardBtn extends SeekBtn
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----UI----
		[Inspectable(defaultValue=-5, type=Number)]
		public function get secToSeek():Number{return this._secToSeek;}
		public function set secToSeek(nSec:Number):void{this._secToSeek = nSec;}
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "SeekBackwardBtn";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		public function SeekBackwardBtn()
		{
			try
			{
				Tracer.debugTrace("SeekBackwardBtn: Constructor", 3);
				//set defualt value
				if(isNaN(this.secToSeek))
					this.secToSeek = -5;
				//in AS3 the UI parameters get their value only on the next enter frame event
				addEventListener(Event.ENTER_FRAME, initUponEnterFrame);
				
				//Admin component identification
				ebGlobal.ebSetComponentName("SeekBackwardBtn");
				//set state
				this.state = "ebVBSeekBack";
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in SeekBackwardBtn: Constructor: "+ error, 1);
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
			Tracer.debugTrace("SeekBackwardBtn: initUponEnterFrame", 6);
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
				Tracer.debugTrace("SeekBackwardBtn: init", 6);
				//init inherited attributes
				super.init();
			}catch (error:Error)
			{
				Tracer.debugTrace("Exception in SeekBackwardBtn: init: "+ error, 1);
			}
		}
	}
}