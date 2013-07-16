//****************************************************************************
//class eyeblaster.video.controls.Buffering
//------------------------------------
//This class represents the VideoLoader buffereing animation movie clip
//
//ALL RIGHTS RESERVED TO EYEBLASTER INC. (C)
//****************************************************************************
package eyeblaster.video.controls
{
	import flash.display.MovieClip;
	
	[IconFile("Icons/Buffering.png")]
	
	public class Buffering extends MovieClip
	{
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//----General------
		include "../../core/compVersion.as"
		public var compName:String = "Buffering";	//The component name.
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//===============
		//	Constructor
		//===============
		public function Buffering()
		{
			//Admin component identification
			ebGlobal.ebSetComponentName("Buffering");
		}
	}
}