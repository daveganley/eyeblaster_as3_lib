package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import eyeblaster.events.EBAudioStateEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	public class AudioToggleButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "AudioToggleButton";	//The component name.
		
		public function AudioToggleButton()
		{
			super();
			
			EBBase.ebSetComponentName("AudioToggleButton");
		}
		
		/** @private */
		public override function initialize():void
		{
			super.initialize();
			
			addEventListener( MouseEvent.MOUSE_OVER, rollOver);
			addEventListener( MouseEvent.MOUSE_OUT, rollOut);
		}
		
		protected override function OnScreenSet():void
		{
			audioStateChanged(null);
			assignedScreen.addEventListener(EBAudioStateEvent.AUDIOSTATE_CHANGE, audioStateChanged);
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			screen.removeEventListener(EBAudioStateEvent.AUDIOSTATE_CHANGE, audioStateChanged);
		}
		
		/** @private */
		protected override function release():void
		{
			if( assignedScreen.isMuted ) _videoInteraction = "ebVideoUnmute";
			else _videoInteraction = "VideoMute";
			
			assignedScreen.audioToggle();
		}
		
		private function rollOver( event:MouseEvent ):void
		{
			switch( this.currentFrame )
			{
				case 1:
					gotoAndStop( 2 );
					break;
				case 3:
					gotoAndStop( 4 );
					break;
				default:
					break;
			}
		}
		
		private function rollOut( event:Event ):void
		{
			switch( this.currentFrame )
			{
				case 2:
					gotoAndStop( 1 );
					break;
				case 4:
					gotoAndStop( 3 );
					break;
				default:
					break;
			}
		}
		
		private function audioStateChanged( event:EBAudioStateEvent ):void
		{
			if( assignedScreen.isMuted ) gotoAndStop( 1 );
			else gotoAndStop( 3 );
		}
	}
}