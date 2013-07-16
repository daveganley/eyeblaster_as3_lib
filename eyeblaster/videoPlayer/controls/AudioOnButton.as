package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class AudioOnButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "AudioOnButton";	//The component name.
		
		public function AudioOnButton()
		{
			super();
			
			EBBase.ebSetComponentName("AudioOnButton");
			
			_videoInteraction = "ebVideoUnmute";
		}
		
		/** @private */
		protected override function release():void
		{
			assignedScreen.unmute();
		}
	}
}