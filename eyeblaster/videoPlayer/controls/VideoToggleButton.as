package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.events.EBVideoStateEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class VideoToggleButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "VideoToggleButton";	//The component name.
		
		[Inspectable(type=Boolean,defaultValue=true)]
		public var turnAudioOn:Boolean = true;
		
		public function VideoToggleButton()
		{
			super();
			
			EBBase.ebSetComponentName("VideoToggleButton");
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
			playbackStateChange(null); // Set Initial State
			assignedScreen.addEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE, playbackStateChange);
			assignedScreen.addEventListener(EBVideoEvent.MOVIE_END, OnEndOfVideo);
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			assignedScreen.removeEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE, playbackStateChange);
			assignedScreen.removeEventListener(EBVideoEvent.MOVIE_END, OnEndOfVideo);			
		}
		
		/** @private */
		protected override function release():void
		{
			if( assignedScreen.isPlaying ) _videoInteraction = "VideoPause";
			if( assignedScreen.isPaused || assignedScreen.isStopped) _videoInteraction = null;
			if( (assignedScreen.isStopped || assignedScreen.isPaused) && currentFrame >= 5) _videoInteraction = "ebVideoReplay";
			
			if(turnAudioOn && currentFrame >= 5) assignedScreen.unmute(); 
			if(currentFrame >= 5)
				assignedScreen.replay(turnAudioOn);
			else
				assignedScreen.videoToggle();
		}
		
		private function rollOver( event:Event ):void
		{
			switch( this.currentFrame )
			{
				case 1:
					gotoAndStop( 2 );
					break;
				case 3:
					gotoAndStop( 4 );
					break;
				case 5:
					gotoAndStop( 6 );
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
				case 6:
					gotoAndStop( 5 );
				default:
					break;
			}
		}
		
		private function playbackStateChange( event:EBVideoStateEvent ):void
		{
			if( assignedScreen.isPaused ) gotoAndStop( 1 );
			if ( assignedScreen.isPaused && assignedScreen.isPausedOnLastFrame) gotoAndStop( 5 );			
			if( assignedScreen.isPlaying ) gotoAndStop( 3 );
			if( assignedScreen.isStopped && currentFrame < 5) gotoAndStop( 1 );	
		}
		
		private function OnEndOfVideo(event:Event):void
		{
			gotoAndStop(5);
		}
	}
}