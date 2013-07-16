package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	
	import flash.text.TextField;
	import flash.utils.setInterval;
	import flash.utils.clearInterval;
	
	public class StatusText extends ControlBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "StatusText";	//The component name.
		
		private var txtField:TextField;
		private var _interval:int;
		
		public function StatusText()
		{
			super();
			
			EBBase.ebSetComponentName("StatusText");
			
			enabled = false;
			
			txtField = getChildAt(0) as TextField;
			
			txtField.text = "Idle";
		}
		
		public override function initialize():void
		{
			super.initialize();
		}
		
		protected override function OnScreenSet():void
		{
			_updateState();
			_interval = setInterval(_updateState,10);
		}
		
		protected override function OnScreenUnset(screen:IVideoScreen):void
		{
			clearInterval(_interval);
			txtField.text = "Idle";
		}
		
		private function _updateState():void
		{
			if(assignedScreen.isStopped){
				txtField.text = "Stopped";
			}
			
			if(assignedScreen.isPlaying){
				txtField.text = "Playing";
			}
			
			if(assignedScreen.isPaused){
				txtField.text = "Paused";
			}
			
			if(assignedScreen.isBuffering){
				txtField.text = "Buffering";
			}
		}
	}
}