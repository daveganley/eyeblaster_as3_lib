package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import eyeblaster.events.EBVideoStateEvent;
	
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.utils.*;
	
	dynamic public class ProgressBar extends SliderBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "ProgressBar";	//The component name.	
	
		[Inspectable(enumeration="static,snapToScrub,showProgressiveDL",defaultValue="static")]
		public var displayMode:String;
		
		private var updateInterval:Number;
		
		private var snapToScrub:Boolean;
		private var showDownload:Boolean;
		
		private var maxBarWidth:Number;
		private var clicked:Boolean;
		
		public function ProgressBar()
		{
			super();
			
			EBBase.ebSetComponentName("ProgressBar");
			
			_videoInteraction = "ebSliderDragged";
		}
		
		/** @private */
		public override function initialize():void
		{
			_slider = this["slider"];
			_scrubbar = this["scrubbar"];
			_hitArea = this["hit"];
			super.initialize();
			updateInterval = setInterval( updateUI, 50 );
			maxBarWidth = _slider.width;
		}
		
		protected override function OnScreenSet():void
		{
			assignedScreen.addEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE, playbackState);
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			screen.removeEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE, playbackState);
		}
		
		/** @private */
		protected override function _onMouseDown( event:MouseEvent ):void
		{
			if(assignedScreen.isPlaying || assignedScreen.isPaused) 
			{
				///pause video while dragging scrubbar
				assignedScreen.pauseForSlider();
				clearInterval(updateInterval);
				super._onMouseDown( event );
				clicked = true;
			}
		}
		
		/** @private */	
		protected override function _onMouseUp( event:MouseEvent ):void
		{
			if(clicked)
			{
				super._onMouseUp( event );
				
				if(assignedScreen.isStopped)
				{
					_scrubbar.x = startX;
					assignedScreen.stopAndClear();
				}
				
				///resume video in case isPlaying = true (video was paused while dragging scrubbar)
				if(assignedScreen.isPlaying) 
					assignedScreen.playAfterPauseForSlider();
				
				clicked = false;
			}
		}
		
		private function playbackState( event:EBVideoStateEvent ):void
		{
			if( event.isPlaying && !isScrubbing ) updateInterval = setInterval( updateUI, 50 );
			else clearInterval(updateInterval);
			
			if( event.isStopped ) _scrubbar.x = startX;
		}
		
		protected override function doAction( xPos:Number ):void
		{
			if(assignedScreen.isPlaying || assignedScreen.isPaused) 
			{
				updateInterval = setInterval( updateUI, 150 );
				
				var videoLength:int = assignedScreen.length;
				var tempSeek:Number;
				
				if( xPos < startX ) tempSeek = 0;
				else tempSeek = Math.abs( ( xPos - startX ) / _slider.width * videoLength );
				
				assignedScreen.seek( tempSeek );
			}
		}
		
		private function initDisplayMode( mode:String ):void
		{
			switch( mode )
			{
				case "static":
					snapToScrub = false;
					showDownload = false;
				break;
			
				case "snapToScrub":
					snapToScrub = true;
					showDownload = false;
				break;
			
				case "showProgressiveDL":
					snapToScrub = false;
					showDownload = true;
				break;
			}
		}
		
		private function updateUI():void
		{
			if(assignedScreen.isPlaying || assignedScreen.isPaused) 
			{
				var mode:String = displayMode;
				
				initDisplayMode( mode );
				
				var time:Number = int( assignedScreen.time * 100 ) / 100;
				var percentDownloaded:Number = assignedScreen.bytesLoaded / assignedScreen.bytesTotal;
				
				var desiredWidth:Number = maxBarWidth * (time / assignedScreen.length );
				
				if( time > 0 )
				{
					if( !isScrubbing && _scrubbar )
					{
						if( desiredWidth < maxBarWidth ) _scrubbar.x = startX + desiredWidth;
						else _scrubbar.x = startX + _slider.width;
					}
					
					if( showDownload )
					{
						var minBarWidth:Number = 0;
		
						desiredWidth = maxBarWidth * percentDownloaded;
														
						if( assignedScreen.isStopped ) minBarWidth = _slider.width;					
						if( desiredWidth > minBarWidth ) _slider.width = desiredWidth;
						
					} else if ( snapToScrub && _scrubbar)
					{
						_slider.width = _scrubbar.x - startX;
					}
							
				}
			}
		}
	}
}