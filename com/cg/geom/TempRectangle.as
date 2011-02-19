package com.cg.geom
{
	import flash.geom.Rectangle;
	
	public class TempRectangle extends Rectangle
	{
		public var lastCenter:Object;
		public var center:Object;
		//lifeSpan will be used to stablish how many times this was inherited
		//from a previous TempRectangle
		public var lifeSpan:int = 0;
		//public var vectorData:Object;
		
		public function TempRectangle(rect:Rectangle)
		{
			this.x = rect.x;
			this.y = rect.y;
			this.width = rect.width;
			this.height = rect.height;
			this.center = {x:this.x + this.width * 0.5, y: this.y + this.height * 0.5};
			//this.vectorData = {x:0, y: 0, vx:0, vy:0, xy:0, angle:0};
			this.lastCenter = center;
			return;
		}
		//this function takes one TempRectangle and 
		//sets this properties to the one supplied
		//Sets lastCenter (to know previous x y) and lifeSpan++
		public function evolveTo(r:TempRectangle):void
		{
			this.x = r.x;
			this.y = r.y;
			this.width = r.width;
			this.height = r.height;
			this.lastCenter = this.center;
			this.center = r.center;
			this.lifeSpan += r.lifeSpan;
			this.lifeSpan++;
			
			//vector
			//var originX:Number = this.center.x;
			//var originY:Number = this.center.y;
			
			//var vx:Number = this.center.x - this.lastCenter.x;
			//var vy:Number = this.center.y - this.lastCenter.y;
			//length
			//var xy:Number = Math.sqrt(vx * vx + vy * vy);
			//angle in rads
			//var angle:Number = Math.atan2(vy,vx);
			//angle to grads
			//var angleGrads:Number = angle * 180 / Math.PI;
			
			//this.vectorData = {x:originX, y: originY, vx:vx, vy:vy, xy:xy, angle:angle};
		}
		
		public function cloned():TempRectangle
		{
			var o:TempRectangle = this;
			var n:TempRectangle = new TempRectangle(new Rectangle(o.x,o.y,o.width,o.height));
			n.center = o.center;
			n.lastCenter = o.lastCenter;
			n.lifeSpan = o.lifeSpan;
			//n.vectorData = o.vectorData;
			return n;
		}
		/*
		public function scaleTo(n:Number = 1):void
		{
			this.x *= n;
			this.y *= n;
			this.width *= n;
			this.height *= n;
			this.center.x *= n;
			this.center.y *= n;
			this.lastCenter.x *= n;
			this.lastCenter.y *= n;
			this.vectorData.x *= n;
			this.vectorData.y *= n;
			this.vectorData.vx *= n;
			this.vectorData.vy *= n;
			this.vectorData.xy *= n;
		}
		*/
	}
}