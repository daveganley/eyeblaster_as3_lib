package eyeblaster.videoPlayer.controls
{
	import flash.events.Event;
	
	public class PlayButton extends ButtonBase
	{
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "PlayButton";	//The component name.
		
		[Inspectable(type="Number",defaultValue="-1")]
		public var assetId:int = -1;
		
		public function PlayButton()
		{
			super();
			
			EBBase.ebSetComponentName("PlayButton");
		}
		
		/** @private */
		protected override function release():void
		{
			assignedScreen.loadAndPlay(assetId);
		}
		
	}
}