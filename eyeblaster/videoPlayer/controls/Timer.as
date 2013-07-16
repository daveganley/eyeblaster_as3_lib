package eyeblaster.videoPlayer.controls
{	
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import eyeblaster.events.EBVideoEvent;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	dynamic public class Timer extends ControlBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "Timer";	//The component name.
		
		[Inspectable (defaultValue="countUp",enumeration="countUp,countDown")]
		public var timerMode:String = "countUp";
		
		private var timeFormat:String = null;
		private var updateInterval:Number;
		
		private var timetext:TextField;
		
		public function Timer()
		{
			enabled = false;
			
			EBBase.ebSetComponentName("Timer");
		}
		
		/** @private */
		public override function initialize():void
		{
			super.initialize();
			
			timetext = this["eb_timetext"];
			timetext.selectable = false;
		}
		
		protected override function OnScreenSet():void
		{
			updateInterval = setInterval( updateUI, 500 );
			assignedScreen.addEventListener(EBVideoEvent.PLAYBACK_START, playbackStart );
			assignedScreen.addEventListener(EBVideoEvent.PLAYBACK_STOP, playbackStop );
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			clearInterval(updateInterval);
			assignedScreen.removeEventListener(EBVideoEvent.PLAYBACK_START, playbackStart );
			assignedScreen.removeEventListener(EBVideoEvent.PLAYBACK_STOP, playbackStop );
		}
		
		private function updateUI():void
		{
			if(!assignedScreen.isStopped)
			{
				var timeVar:String = assignedScreen.time.toString();
				
				if( timeFormat ==  null ) timeFormat = timetext.text;
	
				var formatString:String = timeFormat;
				var time:Number = int( Number(timeVar) * 100 ) / 100;
				
				if( timerMode == "countDown" )
				{
					var length:Number = assignedScreen.length;
					length = int( length * 100 ) / 100;
					time = length - time;
				}
				
				var seconds:String = (int(time) % 60).toString();
				var minutes:String = (int(int(time)/60)).toString();
				var hours:String = (int(int(minutes)/60)).toString();
				
				if( parseInt(seconds) < 10 ) seconds = "0" + seconds;
				if( parseInt(minutes) < 10 ) minutes = "0" + minutes;
				if( parseInt(hours) < 10 ) hours = "0" + hours;
				
				formatString = formatString.replace(/HH/g,hours); // Hours
				formatString = formatString.replace(/MM/g,minutes); // Minutes 
				formatString = formatString.replace(/SS/g,seconds); // Seconds
			
				timetext.text = formatString;		
			}
		}
		
		private function playbackStart( event:Event):void
		{
			updateInterval = setInterval( updateUI, 500 );
		}
		
		private function playbackStop( event:Event ):void
		{
			clearInterval( updateInterval );
			timetext.text = "00:00";
		}
	}
}