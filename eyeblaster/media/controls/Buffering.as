//****************************************************************************
//class eyeblaster.media.controls.Buffering
//------------------------------------
//This class represents the VideoLoader buffereing animation movie clip
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.controls
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
			EBBase.ebSetComponentName("Buffering");
		}
	}
}