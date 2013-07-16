package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class PauseButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "FullScreenButton";	//The component name.
		
		public function PauseButton()
		{
			super();
			_videoInteraction = "VideoPause";
		}
		
		/** @private */
		protected override function release():void
		{
			assignedScreen.pause();
		}
	}
}