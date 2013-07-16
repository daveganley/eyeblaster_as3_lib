package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	import eyeblaster.videoPlayer.core.RunLoop;
	
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class ControlBase extends MovieClip implements IVideoControl
	{
		protected var _targetVideo:String = "";
		private var _previousScreen:IVideoScreen;
		
		public function ControlBase()
		{
			super();
			addEventListener(Event.ENTER_FRAME,OnEnterFrame);
		}
		
		private function OnEnterFrame(e:Event):void
		{
			removeEventListener(Event.ENTER_FRAME,OnEnterFrame);
			EBVideoMgr.RegisterControlToScreen(this);
		}
		
		public function initialize():void
		{
			CheckForInit();	
			RunLoop.addFunction(CheckForInit);
		}
		
		protected function get assignedScreen():IVideoScreen
		{
			var screen:IVideoScreen = null;
			
			if(_targetVideo != ""){
				screen = EBVideoMgr.GetScreen(_targetVideo);
			} else {
				screen = EBVideoMgr.Current;
			}
			
			return screen;
		}
		
		private function CheckForInit():void
		{
			if(assignedScreen != _previousScreen && _previousScreen != null && assignedScreen != null){
				OnScreenUnset(_previousScreen);
				_previousScreen = assignedScreen;
				OnScreenSet();
			}
			
			if(assignedScreen != null && enabled == false)
			{
				enabled = true;
				_previousScreen = assignedScreen;
				OnScreenSet();
			} else if (_previousScreen != null && assignedScreen == null) {
				enabled = false;
				OnScreenUnset(_previousScreen);
				_previousScreen = null;
			}
		}
		
		protected function OnScreenSet():void
		{
			
		}
		
		protected function OnScreenUnset(screen:IVideoScreen):void
		{
			
		}
		
		[Inspectable(defaultValue="")]
		public function set targetVideo( value:String ):void
		{
			_targetVideo = value;
		}
		
		public function get targetVideo():String
		{
			return _targetVideo;
		}
	}
}