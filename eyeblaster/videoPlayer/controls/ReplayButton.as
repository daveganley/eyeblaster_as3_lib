package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class ReplayButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "ReplayButton";	//The component name.
		
		[Inspectable(type=Boolean,defaultValue=false)]
		public var turnAudioOn:Boolean = false;
		
		public function ReplayButton()
		{
			super();
			
			EBBase.ebSetComponentName("ReplayButton");
			
			_videoInteraction = "ebVideoReplay";
		}
		
		/** @private */
		protected override function release():void
		{
			assignedScreen.replay(turnAudioOn);
		}
	}
}