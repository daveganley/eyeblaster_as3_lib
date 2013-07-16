package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class FastForwardButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "FastForwardButton";	//The component name.
		
		[Inspectable(type=Number, defaultValue=5)]
		public var seconds:Number = 5;
		
		public function FastForwardButton()
		{
			super();
			
			EBBase.ebSetComponentName("FastForwardButton");
		}
		
		/** @private */
		protected override function release():void
		{
			// Seek forward from current time by the given amount of seconds
			assignedScreen.seek( assignedScreen.time + seconds );
		}
	}
}