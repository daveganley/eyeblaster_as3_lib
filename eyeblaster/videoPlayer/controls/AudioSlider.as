package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import eyeblaster.events.EBAudioStateEvent;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	dynamic public class AudioSlider extends SliderBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "AudioSlider";	//The component name.
		
		public function AudioSlider()
		{
			super();
			
			EBBase.ebSetComponentName("AudioSlider");
		}
		
		/** @private */
		public override function initialize():void
		{
			_slider = this["slider"];
			_scrubbar = this["scrubbar"];
			super.initialize();
			syncState();
		}
		
		protected override function OnScreenSet():void
		{
			assignedScreen.addEventListener(EBAudioStateEvent.AUDIOSTATE_CHANGE, audioStateChanged);
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			screen.removeEventListener(EBAudioStateEvent.AUDIOSTATE_CHANGE, audioStateChanged);
		}
				
		/** @private */
		protected override function _onMouseDown( event:MouseEvent ):void
		{
			super._onMouseDown( event );
			_slider.addEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
		}

		/** @private */	
		protected override function _onMouseUp( event:MouseEvent ):void
		{
			super._onMouseUp( event );
			_slider.removeEventListener(MouseEvent.MOUSE_MOVE, _onMouseMove);
		}
		
		private function _onMouseMove(event:MouseEvent):void
		{
			doAction( _scrubbar.x );
		}
		
		/** @private */
		protected override function doAction( xPos:Number ):void
		{		
			var audioVolume:Number = Math.abs( ( xPos - startX ) / _slider.width * 100 );
			if( audioVolume < 1 ) audioVolume = 0;
			
			if(audioVolume == 0 && assignedScreen.volume > 0){
				assignedScreen.mute();
				assignedScreen.track("VideoMute");
			}
			
			if(audioVolume > 0 && assignedScreen.volume == 0){
				assignedScreen.track("ebVideoUnmute");
				assignedScreen.unmute();
			}
			
			assignedScreen.volume = audioVolume;
		}
		
		protected override function doTrack():void
		{
			// do nothing -- EB doesn't have a tracker for audio slider dragged
		}
		
		private function audioStateChanged( event:EBAudioStateEvent ):void
		{	
			if( event.isMuted ) _scrubbar.x = startX;
			else {
				var volumePos:Number = ( event.volume / 100 * _slider.width );
				if(!isNaN(volumePos)) _scrubbar.x = startX + volumePos;
			}
		}
		
		private function syncState():void
		{
			if(assignedScreen!=null)
			{
				if( assignedScreen.isMuted ) 
					_scrubbar.x = startX;
				else 
				{
					var volumePos:Number = ( assignedScreen.volume / 100 * _slider.width );
					if(!isNaN(volumePos)) _scrubbar.x = startX + volumePos;
				}
			}
		}
	}
}