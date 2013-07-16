package eyeblaster.videoPlayer.controls
{
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.events.EBVideoStateEvent;
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	dynamic public class Facade extends ControlBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "Facade";	//The component name.
		
		private var _startFacade:MovieClip;
		private var _pauseFacade:MovieClip;
		private var _endFacade:MovieClip;
		
		public function Facade()
		{
			EBBase.ebSetComponentName("Facade");
			
			enabled = false;
			
			_startFacade = this["startFacade"];
			_pauseFacade = this["pauseFacade"];
			_endFacade = this["endFacade"];
			
			_startFacade.visible = true;
			_pauseFacade.visible = false;
			_endFacade.visible = false;
		}
		
		/** @private */
		public override function initialize():void
		{
			super.initialize();
			
			showFacade("start");
		}
		
		protected override function OnScreenSet():void
		{
			_playbackState();
			assignedScreen.addEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE, _playbackState);
			assignedScreen.addEventListener(EBVideoEvent.MOVIE_END, _endOfVideo );
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			screen.removeEventListener(EBVideoStateEvent.VIDEOSTATE_CHANGE, _playbackState);
			screen.removeEventListener(EBVideoEvent.MOVIE_END, _endOfVideo );
		}
		
		public function showFacade( facadeName:String ):void
		{
			_startFacade.visible = (facadeName == "start");
			_pauseFacade.visible = (facadeName == "pause");
			_endFacade.visible = (facadeName == "end");
		}
		
		private function _playbackState( event:EBVideoStateEvent = null ):void
		{
			if( assignedScreen.isPaused ) showFacade( "pause" );
			if( assignedScreen.isStopped ) showFacade( "end" );
			if( assignedScreen.isPlaying ) showFacade( "none" );
		}
		
		private function _endOfVideo( event:Event ):void
		{
			showFacade( "end" );
		}
	}
}