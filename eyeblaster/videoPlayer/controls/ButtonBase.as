package eyeblaster.videoPlayer.controls
{
	import eyeblaster.videoPlayer.IVideoScreen;
	import eyeblaster.videoPlayer.core.RunLoop;
	
	import flash.display.MovieClip;
	import flash.events.Event;

	/** Base class for all video buttons */
	public class ButtonBase extends ControlBase implements IVideoControl
	{
		protected var _videoInteraction:String = null;
		
		public function ButtonBase()
		{			
			this.buttonMode = true;
			this.enabled = false;
			this.addEventListener("click", _doRelease);
		}
		
		/**
		 * Called by VideoController when the associated video comes on stage.
		 * Subclasses <b>SHOULD</b> override and perform all initialiation required here.
		 * Subclasses <b>MUST</b> call into the base function for proper functionality
		 */
		public override function initialize():void
		{
			this.buttonMode = true;
			
			super.initialize();
		}
		
		private function _doRelease(event:Event):void
		{
			if(enabled && assignedScreen != null){
				release();
				
				if(_videoInteraction != null){
					assignedScreen.track(_videoInteraction);
				}
			}
		}
		
		protected function release():void
		{

		}
	}
}