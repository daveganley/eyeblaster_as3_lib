//****************************************************************************
//class eyeblaster.core.Tracer
//---------------------------
//This is a "static" class that is used for debug messages.
//
//Methods:
//	set debugLvl(debugLvl:Number):Void	- This function set the debug level
//	get debugLvl(Void):Number -	This functions returns the debug level
//	trace(strMsg:String,nLvl:Number):Void - This function display strMsg message in the output panel, in case nLvl <=_debugLvl
//Properties:
//	 _debugLvl:Number - The debug level, values: 0-6(0 default)
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.core
{
	import eyeblaster.events.EBNotificationEvent;
	
	import flash.display.*;
	import flash.system.fscommand;

	//--------------------------------------
    //  	Tracer Class 
    //--------------------------------------
	public class Tracer
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//					Private Attributes
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		private static var _debugLvl:Number = 0;  //debug level
		public static var root:DisplayObjectContainer;
		
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		//=======================
		//	Constructor
		//=======================
		//public function Tracer(){}
		
		//=======================
		//	function debugLvl
		//=======================
		//This is a Setter function, used to set the debug level
		public static function set debugLvl(debugLvl:Number):void
		{
			_debugLvl = debugLvl;
		}
		
		//=======================
		//	function get debugLvl
		//=======================
		//This is a Getter function, used to get the debug level
		public static function get debugLvl():Number
		{
			return _debugLvl;
		}
		
		//=======================
		//	function debugTrace
		//=======================
		//This is a trace function, used to print debug messages
		//	parameters:
		//		strMsg: debug message
		//		nLvl: debug level: (-1)-6
		//			  -2:display always only using fscommand; -1: display always only using trace; 0: display always using trace+ebMsg; 1-6: regular debug 
		public static function debugTrace(strMsg:String, nLvl:Number = 6):void
		{
			if(nLvl > _debugLvl)
				return;
			strMsg = "Eyeblaster Workshop | " + strMsg;
			switch (nLvl)
			{
				case -2:
					try{fscommand("ebMsg",strMsg);}catch (error:Error){}
					break;
				case -1:
					trace(strMsg);
					break;
				default:
					trace(strMsg);
					try{fscommand("ebMsg",strMsg);}catch (error:Error){}
			}
			
			var e:EBNotificationEvent = new EBNotificationEvent(EBNotificationEvent.LOG, EBNotificationEvent.LOG);
			e.level = nLvl;
			e.message = strMsg;
			EBBase.dispatchEvent(e);
		}
	}
}