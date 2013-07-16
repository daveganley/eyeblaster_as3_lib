package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import eyeblaster.events.EBVideoStateEvent;
	
	import flash.events.Event;
	
	public class FullScreenButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "FullScreenButton";	//The component name.
		
		private static const FRAME_DISABLED:int = 1;
		private static const FRAME_GOFULLSCREEN:int = 2;
		private static const FRAME_GOREGULAR:int = 3;
		
		public function FullScreenButton()
		{
			super();
			
			EBBase.ebSetComponentName("FullScreenButton");
			
			enabled = false;
		}
		
		protected override function OnScreenSet():void
		{
			assignedScreen.addEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE,playbackStateChange);
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			screen.removeEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE,playbackStateChange);
			gotoAndStop(FRAME_DISABLED);
		}
		
		private function playbackStateChange(event:EBVideoStateEvent):void
		{
			if(event.isStopped && !assignedScreen.isFullScreen){
				gotoAndStop(FRAME_DISABLED);
			} else {
				if(assignedScreen.isFullScreen){
					gotoAndStop(FRAME_GOREGULAR);
				} else {
					gotoAndStop(FRAME_GOFULLSCREEN);
				}
			}
		}
		
		protected override function release():void
		{
			if(currentFrame != FRAME_DISABLED){
				assignedScreen.setFullScreen(!assignedScreen.isFullScreen);
			}
		}
	}
}