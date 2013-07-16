package eyeblaster.videoPlayer.controls
{
	import eyeblaster.events.EBVideoEvent;
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;

	public class Buffering extends ControlBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "Buffering";	//The component name.
		
		private var animation:MovieClip;
		
		private var intervalId:int;
		
		public function Buffering()
		{
			super();
			
			EBBase.ebSetComponentName("Buffering");
			
			enabled = false;
			
			animation = getChildByName("animation_mc") as MovieClip;
			
			animation.visible = false;
			visible = false;
		}
		
		protected override function OnScreenSet():void
		{
			OnPlaybackStart();
			assignedScreen.addEventListener(EBVideoEvent.PLAYBACK_START,OnPlaybackStart);
			assignedScreen.addEventListener(EBVideoEvent.BUFFER_LOADED,OnBufferLoaded);
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			assignedScreen.removeEventListener(EBVideoEvent.PLAYBACK_START,OnPlaybackStart);
			assignedScreen.removeEventListener(EBVideoEvent.BUFFER_LOADED, OnBufferLoaded);
		}
		
		private function OnPlaybackStart(e:EBVideoEvent = null):void
		{
			intervalId = setInterval(_CheckForBuffering,10);
		}
		
		private function OnBufferLoaded(e:Event):void
		{
			clearInterval(intervalId);
		}
		
		private function _CheckForBuffering():void
		{
			if(enabled){
				if(assignedScreen.isBuffering && animation.visible == false){
					animation.visible = true;
					visible = true;
				} else if (!assignedScreen.isBuffering && animation.visible == true){
					animation.visible = false;
					visible = false;
					clearInterval(intervalId);
				}
			}
		}
	}
}