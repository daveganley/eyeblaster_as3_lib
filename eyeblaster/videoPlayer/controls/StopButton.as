package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class StopButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "StopButton";	//The component name.
		
		[Inspectable(type=Boolean,defaultValue=true)]
		public var doClear:Boolean = true;
		
		public function StopButton()
		{
			super();
			
			EBBase.ebSetComponentName("StopButton");
		}
		
		/** @private */
		protected override function release():void
		{			
			if(doClear){
				assignedScreen.stopAndClear();
			} else {
				assignedScreen.stop();
			}
		}
		
	}
}