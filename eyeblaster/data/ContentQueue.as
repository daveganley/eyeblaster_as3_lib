/**
 * class eyeblaster.data.ContentQueue
 * -----------------------------------------
 * This class is part of EBContentMgr functionality which allows loading in of external content into the creative
 *
 * ALL RIGHTS RESERVED TO MEDIAMIND INC. (C)
 */
package eyeblaster.data
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.LoaderInfo;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	import eyeblaster.core.Tracer;
	
	public class ContentQueue
	{
		private static var descriptors:Array;
		private var pending:Object;
		private var holders:Object;
		
		/**
		 * Constructor
		 */
		public function ContentQueue()
		{
			pending = {};
			holders = {};
			descriptors = [];
			descriptors.push("root");
		}
		
		/**
		 * Adds a content request to the content queue, ensures content has not been previously loaded. When content is loaded, calls function if given
		 *
		 * @example <listing version="3.0">
		 * ContentQueue.AddContent(targetMC, 1, myFunction);
		 * </listing>
		 *
		 * @param target DisplayObjectContainer that content should be added to when loaded.
		 * @param url Asset ID of content you want loaded, corresponds to External Asset in workshop.
		 * @param callback name of function to be called when content has been loaded.
		 */
		public function AddContent(target:DisplayObjectContainer, url:String, callback:Function = null):void
		{
			var loadObject:Object = {};
			
			loadObject.clip = target;
			loadObject.descriptor = GetDescriptorForContainer(target);
			loadObject.assetURL = url;
			loadObject.callback = callback;
			loadObject.active = true;
			
			descriptors.push(loadObject.descriptor);
			// undefined and null both return false
			if (!holders[loadObject.descriptor])
			{
				loadContent(loadObject);
			}
			else
			{
				RemoveContent(target);
				pending[loadObject.descriptor] = loadObject;
			}
		}
		
		/**
		 * Called when content has been added via the AddContent function
		 * @param	loadObject collection of parameters.
		 */
		private function loadContent(loadObject:Object):void
		{
			holders[loadObject.descriptor] = loadObject;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
			// load() must be called AFTER event listeners are added.
			loader.load(new URLRequest(loadObject.assetURL), new LoaderContext(false, ApplicationDomain.currentDomain));
			
			loadObject.clip.eb_loader = loader;
			loadObject.clip.addChild(loader);
		}
		// TODO: WHy is it necessary to process object with event? It is not an ascynchroneous occurance.
		// logic moved to RemoveContent
		/**
		 * Fired when content has been unloaded and attemps to reload if possible
		 */
		//private function contentUnloaded(event:Event):void
		//{
			//var descriptor:String = GetParentDescriptor(event.target as DisplayObjectContainer);
			//
			//if (pending[descriptor] != null || pending[descriptor] != undefined)
				//loadContent(pending[descriptor]);
		//}
		
		/**
		 * Called if there is a security error when trying to access file.
		 * @param	e
		 */
		private function securityError(e:Event):void
		{
			LoaderInfo(e.target).removeEventListener(Event.COMPLETE, contentLoaded);
			LoaderInfo(e.target).removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);
			Tracer.debugTrace("Error : Security Error caugh in ContentQueue " + e, 0);
		}
		
		/**
		 * Called once file has succesfully loaded
		 * @param	e
		 */
		private function contentLoaded(e:Event):void
		{
			LoaderInfo(e.target).removeEventListener(Event.COMPLETE, contentLoaded);
			LoaderInfo(e.target).removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityError);
			var loadObject:Object = holders[GetDescriptorForContainer(LoaderInfo(e.target).loader.parent as DisplayObjectContainer)];
			if (loadObject.callback)
				loadObject.callback(e);
		}
		
		/**
		 * Returns the descriptor of the DisplayOjbectContainer and and hierarchy of where it is loaded.
		 * Descriptor is set on each content request in the AddContent function;
		 *
		 * @param	targetContainer
		 * @return
		 */
		public static function GetDescriptorForContainer(targetContainer:DisplayObjectContainer):String
		{
			if (!targetContainer)
				return "";
			
			var descriptor:String = targetContainer.name;
			var _parent:DisplayObjectContainer = targetContainer.parent as DisplayObjectContainer;
			
			while (!_parent)
			{
				descriptor = _parent.name + "/" + descriptor;
				_parent = _parent != EBBase._stage ? _parent.parent : null;
			}
			
			return descriptor;
		}
		// TODO: We need a more detailed commenting on function's body. Why descriptors string length is an indicator of changing currentDescriptor value? 
		// It seems like this function looks for substring - if this is true - why do we nedd the loop?
		/**
		 * Returns the descriptor of the parent holder.
		 * @param	object
		 * @return
		 */
		public static function GetParentDescriptor(object:DisplayObjectContainer):String
		{
			var descriptor:String = GetDescriptorForContainer(object);
			
			var currentDescriptor:String = "";
			// for...each is faster
			for each (var val:String in descriptors)
			{
				if (descriptor.indexOf(val) > -1 && val.length > currentDescriptor.length)
					currentDescriptor = val;
			}
			
			return currentDescriptor;
		}
		
		/**
		 * Called when request to load content that already exists, removes current content and once removed attempts to reload content.
		 * @param	targetContainer
		 */
		public function RemoveContent(targetContainer:DisplayObjectContainer):void
		{
			// syntax targetContainer["eb_loader"] will throw erro, hasOwnProperty("eb_loader") is enough
			if (!targetContainer.hasOwnProperty("eb_loader"))
			{
				Tracer.debugTrace("Target Container has already been unloaded or does not exist in ContentQueue RemoveContent", -1);
				return;
			}
			var eb_loader:DisplayObject = Object(targetContainer).eb_loader as DisplayObject;
			//eb_loader.addEventListener(Event.REMOVED_FROM_STAGE, contentUnloaded);
			targetContainer.removeChild(eb_loader);
			(eb_loader as Loader).unload();
			Object(targetContainer).eb_loader = null;
			holders[GetDescriptorForContainer(targetContainer)] = null;
			// logic moved from contentUnloaded
			// attemps to reload if possible
			var descriptor:String = GetParentDescriptor(eb_loader as DisplayObjectContainer);
			
			if (pending[descriptor])
				loadContent(pending[descriptor]);
				
			
		}
	}
}
