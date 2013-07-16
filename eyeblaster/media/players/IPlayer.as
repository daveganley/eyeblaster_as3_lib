//****************************************************************************
//class eyeblaster.media.players.IPlayer
//------------------------------------
//This interface contains the player classes common interface, like setter 
//functions and different control functions, to be 
//implemented by the player classes
//
//ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
//****************************************************************************
package eyeblaster.media.players
{
	import flash.net.NetStream;
	public interface IPlayer
	{
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		//						Methods
		//++++++++++++++++++++++++++++++++++++++++++++++++++++
		
		 function getStatus():Number;
		 function play():void;
		 function load(strURL:String,fAutoPlay:Boolean):void;
		 function stop():void;
		 function pause():void;
		 function seek(nSec:Number):void;
		 function close():void;
		 function setMute(fShouldMute:Boolean):void;
		 function getMute():Boolean;
		 function setVolume(nVolLevel:Number):void;
		 function getVolume():Number;
		 function get videoLength():Number;
		 function get state():Number;
		 function setLength(nLength:Number):void;
		 function get bufferSize():Number;
		 function set bufferSize(bufferSize:Number):void;
		 function get startPosition():Number;
		 function set startPosition(pos:Number):void;
		 function setBuffer(nBuffer:Number):void;
		 function set status(nStatus:Number):void;
		 function get position():Number;
		 function get netStreamVideo():NetStream;
		 function addListener(handler:Object):void;
		 function isPlayingComplete():Boolean;
		 //function movieEnd():void;
		 function reset():void;
		// function playProgress(nPerPlayProgress:Number):void;
		 function isLocalFile():Boolean;
		 //function onStatus(info:Object):void;
		 function handleVideoInfoEvent(strEventName:String,eventParam:Object):void;
		 function setClearVideoFlag(clearVideo:Boolean):void;
	}
}