package eyeblaster.videoPlayer.core
{
	import eyeblaster.core.Tracer;
	import eyeblaster.events.EBBandwidthEvent;
	import eyeblaster.videoPlayer.events.VideoStreamConnectorEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	/** @private */
	public class VideoStreamConnector extends EventDispatcher
	{
		private var connection:EBNetConnection;
		
		private var connections:Array;
		private var connectSuccess:Boolean;
		
		private var streamXMLLoader:URLLoader;
		private var streamXML:XML;
		
		private var appName:String;
		private var server:String;
		private var serverIP:String;
		private var alternativeHost:String;
		
		public function VideoStreamConnector(url:String = null)
		{
			if(url == null){
				url = EBBase.urlParams.ebStreamingAppURL;
			}
			
			connections = new Array();
			connectSuccess = false;
			
			var startIndex:int = url.indexOf("://") + 3;
			var endIndex:int = url.indexOf("/", startIndex);
			server = url.substring(startIndex, endIndex);
			appName = url.substring(endIndex);
			
			streamXMLLoader = new URLLoader( new URLRequest("http://" + server + "/fcs/ident"));
			streamXMLLoader.addEventListener("complete", identXML_Success);
			streamXMLLoader.addEventListener("ioError", identXML_Error);
			streamXMLLoader.addEventListener("securityError", identXML_Error);
			
			//EWBase.addEventListener("shutdown",OnShutdown);
		}
		
		private function startConnection(protocol:String, port:String):void
		{
			var connect:EBNetConnection = new EBNetConnection(protocol + "_" + port);
			connect.addEventListener(NetStatusEvent.NET_STATUS, handleConnectStatus);
			connect.addEventListener(EBBandwidthEvent.BW_DETECT, bandwidth_Callback);
			
			var url:String = protocol + "://" + serverIP + ":" + port + appName + alternativeHost ;
			connect.connect(url,true);
			
			connections.push(connect);
		}
		
		public function killAllConnections():void
		{
			for(var i:int = 0; i < connections.length; i++){
				if(connections[i].connected){
					connections[i].close();
				}
			}
		}
		
		private function OnShutdown(event:Event):void
		{
			if(connectSuccess && connection.connected)
			{
				killAllConnections();
			}
		}
		
		private function handleConnectStatus( event:NetStatusEvent):void
		{	
			var connect:EBNetConnection = event.target as EBNetConnection;
			
			if (event.info.code == "NetConnection.Connect.Success" && connectSuccess == false)
			{
				Tracer.debugTrace("FMS Connected to: " + connect.uri,2);
				
				connectSuccess = true;
				connection = connect;
				dispatchEvent(new VideoStreamConnectorEvent(VideoStreamConnectorEvent.STREAM_CONNECTED, connect));
				
				for(var i:int = 0; i < connections.length; i++){
					if(connections[i] != connect){
						connections[i].close();
					}
				}	
			} else {
				if(connectSuccess){
					connect.close();
				}
			}
		}
		
		private function bandwidth_Callback( event:EBBandwidthEvent ):void
		{
			if(event.target.connected) dispatchEvent(new EBBandwidthEvent(EBBandwidthEvent.BW_DETECT,event.bandwidth));
		}
		
		/**************************************************/
		/* call from client to fcs/ident was successfull  */
		/**************************************************/
		private function identXML_Success(event:Event ):void
		{
		   	if(!connectSuccess)
			{	
				streamXML = XML( streamXMLLoader.data );
				serverIP = streamXML.ip[0];
				alternativeHost = "?_fcs_vhost=" + server;
				streamXML_Complete();
			}
		}
		/**************************************************/
		/* call from client to fcs/ident failed  */
		/**************************************************/
		private function identXML_Error(event:Event ):void
		{
			if(!connectSuccess)
			{	
				serverIP = server;
				alternativeHost = "";
				streamXML_Complete();
			}
		}
		
		private function streamXML_Complete():void
		{
			if(!connectSuccess)
			{	
				// Connections
				startConnection("rtmp","1935");
				startConnection("rtmp", "80");
				startConnection("rtmp","443");
				startConnection("rtmpt","80");
				startConnection("rtmpt","1935");
				startConnection("rtmpt","443");
				startConnection("rtmpe","1935");
				startConnection("rtmpe","80");
				startConnection("rtmpe","443");
				startConnection("rtmpte","1935");
				startConnection("rtmpte","80");
				startConnection("rtmpte","443");
			}
		}
	}
}
