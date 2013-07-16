package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class RewindButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "RewindButton";	//The component name.
		
		[Inspectable(type=Number, defaultValue=5)]
		public var seconds:Number = 5;
		
		public function RewindButton()
		{
			super();
			
			EBBase.ebSetComponentName("RewindButton");
		}
		
		public override function initialize():void
		{
			super.initialize();
		}
		
		/** @private */
		protected override function release():void
		{
			// Seek backward from current time by the given amount of seconds
			assignedScreen.seek( assignedScreen.time - seconds );
		}
	}
}