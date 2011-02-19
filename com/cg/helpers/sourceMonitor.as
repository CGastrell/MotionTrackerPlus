package com.cg.helpers
{
	import com.bit101.components.Label;
	import com.bit101.components.Panel;
	import com.bit101.components.Style;
	
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.MouseEvent;
		
	public class sourceMonitor extends Sprite
	{
		private var b:Bitmap;
		
		public function sourceMonitor(bitmap)
		{
			b = bitmap;
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			//Style.LABEL_TEXT = 0xF6F6F6;
			this.removeEventListener(Event.ADDED_TO_STAGE,init);
			this.addChild(b);
			this.x = stage.stageWidth - b.width;
			this.y = 40;
			this.addEventListener(MouseEvent.MOUSE_DOWN,function(e:MouseEvent){e.currentTarget.startDrag();});
			this.addEventListener(MouseEvent.MOUSE_UP,function(e:MouseEvent){e.currentTarget.stopDrag();});
			this.doubleClickEnabled = true;
			this.addEventListener(MouseEvent.DOUBLE_CLICK,function(e:MouseEvent){e.currentTarget.parent.removeChild(e.currentTarget);});
			
			this.addEventListener(Event.ENTER_FRAME,onFrame);
			this.addEventListener(Event.REMOVED_FROM_STAGE,destroy);
			
			var lb:Label = new Label(this, 5, b.height,"Preview\nDraggable\nDoubleClick to remove");
		}
		private function destroy(e:Event = null):void
		{
			trace("source monitor removed from stage");
			//this.removeEventListener(Event.ENTER_FRAME,onFrame);
			this.removeEventListener(Event.REMOVED_FROM_STAGE,destroy);
		}
		private function onFrame(e:Event = null):void
		{
			//b.bitmapData = mt.sourceImage;
		}
	}
}