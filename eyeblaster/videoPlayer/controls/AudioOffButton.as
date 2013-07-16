package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class AudioOffButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "AudioOffButton";	//The component name.
		
		public function AudioOffButton()
		{
			super();
			
			EBBase.ebSetComponentName("AudioOffButton");
			
			_videoInteraction = "VideoMute";
		}
		
		/** @private */
		protected override function release():void
		{
			assignedScreen.mute();
		}
	}
}