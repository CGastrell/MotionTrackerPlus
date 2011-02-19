/**
 *	@author  >> Justin Windle
 *	@link	 >> soulwire.co.uk
 *	@version >> V1
 *	@edited  >> Christian Gastrell
 */

package com.cg.media
{
	// Thanks to Grant Skinner for the ColorMatrix Class
	import com.gskinner.geom.ColorMatrix;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Video;
	import flash.media.Camera;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	
	import com.cg.geom.TempRectangle;

	public class MotionTrackerPlus
	{
		
		/*
		========================================================
		| Private Variables                         | Data Type  
		========================================================
		*/
		
		private static const DEFAULT_AREA:			int = 10;
		private static const DEFAULT_BLUR:			int = 20;
		private static const DEFAULT_BRIGHTNESS:	int = 20;
		private static const DEFAULT_CONTRAST:		int = 150;
		private static const ZERO_POINT:			Point = new Point(0,0);
		private static const WHITE:					uint = 0xFFFFFFFF;
		private static const BLOB_FOUND:			uint = 0xFFFF0000;
		private static const BLOB_OLD:				uint = 0xFF00FF00;
		
		private var _src:							Video;
		private var _now:							BitmapData;
		private var _old:							BitmapData;
		private var _sourceImage:					BitmapData;
		
		private var _blr:							BlurFilter;
		private var _cmx:							ColorMatrix;
		private var _col:							ColorMatrixFilter;
		private var _box:							Rectangle;
		private var _act:							Boolean;
		private var _mtx:							Matrix;
		private var _min:							Number;
		private var timer:							Timer;
		private var MAX_BLOBS:						int = 8;

		private var freezedBackground:				Boolean = false;
		private var processTime:					int;
		private var iAmWorking:						Boolean = true;
		
		//returnBlobs is kinda messy... MT will ALWAYS return array(blobs),
		//but if _returnBlobs is false, the array will have a unique blob (if any)
		private var _returnBlobs:					Boolean = false;
		private var _blobs:							__AS3__.vec.Vector.<TempRectangle>;
		private var oldBlobs:						__AS3__.vec.Vector.<TempRectangle>;
		private var newBlobs:						__AS3__.vec.Vector.<TempRectangle>;
		private var _interval:						int = 80;
		private var _brightness:					Number = 0.00;
		private var _contrast:						Number = 0.00;
		private var scala:							Number = 0.5;
		private var iScala:							Number = 1 / scala;
		
		// PUBLIC VARS ?????
		//when returning only 1 area ( !_returnBlobs ) this vars make sense
		public var x:								Number;
		public var y:								Number;
		
		/*
		========================================================
		| Constructor
		========================================================
		*/
		
		/**
		 * The MotionTracker class will track the movement from a camera
		 * 
		 * @param:Video		vid		A video object which will be feeding images
		 */
		
		public function MotionTrackerPlus( video:Video ) 
		{
			super();
			input = video;
			
			_mtx = new Matrix(scala,0,0,scala);
			_cmx = new ColorMatrix();
			_blr = new BlurFilter();
			
			_blobs = new __AS3__.vec.Vector.<TempRectangle>;
			oldBlobs = new __AS3__.vec.Vector.<TempRectangle>;
			
			blur = DEFAULT_BLUR;
			minArea = DEFAULT_AREA;
			contrast = DEFAULT_CONTRAST;
			brightness = DEFAULT_BRIGHTNESS;
			
			timer = new Timer(_interval);
			timer.addEventListener(TimerEvent.TIMER,track);
			timer.start();
		}
		
		/*
		========================================================
		| Public Methods
		========================================================
		*/
		
		/**
		 * Track movement within the source Video object.
		 */
		
		public function track(e:TimerEvent = null):void
		{
			//e.updateAfterEvent();//useful??
			var inn:int = getTimer();
			_now.draw( _src, _mtx );
			_sourceImage.draw(_now);
			_sourceImage.applyFilter( _sourceImage, _sourceImage.rect, ZERO_POINT, _col );
			_now.draw( _old, null, null, BlendMode.DIFFERENCE );
			_now.applyFilter( _now, _now.rect, ZERO_POINT, _col );
			_now.applyFilter( _now, _now.rect, ZERO_POINT, _blr );
			_now.threshold(_now, _now.rect, ZERO_POINT, '>', 0xFF333333, 0xFFFFFFFF);
			
			if(!freezedBackground) _old.draw( _src, _mtx );
			
			var area:Rectangle = _now.getColorBoundsRect( 0xFFFFFFFF, 0xFFFFFFFF, true );
			_act = ( area.width * iScala > (_src.width / 100) * _min || area.height * iScala > (_src.height / 100) * _min );
			
			newBlobs = new __AS3__.vec.Vector.<TempRectangle>;
			_blobs = new __AS3__.vec.Vector.<TempRectangle>;
			if ( _act )
			{
				_box = area;
				x = _box.x + (_box.width * .5);
				y = _box.y + (_box.height * .5);
				if(_returnBlobs)
				{
					findBlobs();
					recheckBlobs();
				}else{
					newBlobs.push(new TempRectangle(_box));
					recheckBlobs();
				}
			}
			var out:int = getTimer();
			processTime = out - inn;
		}
		
		//	----------------------------------------------------------------
		//	PRIVATE METHODS
		//	----------------------------------------------------------------

		private function applyColorMatrix() : void
		{
			_cmx.reset();
			_cmx.adjustContrast(_contrast);
			_cmx.adjustBrightness(_brightness);
			_col = new ColorMatrixFilter(_cmx);
		}
		
		//the findBlobs process was taken from several sites where the fillRect
		//technique was explained, i just don't know who to give credit about this (gskinner? quasimondo?)
		//and while i think this should be enhanced, i don't really know a way right now
		private function findBlobs():void
		{
			var bData:BitmapData = trackingImage.clone();
			var b:int = 0;
			var r:Rectangle;
			var tr:TempRectangle;
			while(b < MAX_BLOBS)
			{
				r = bData.getColorBoundsRect(WHITE,WHITE);
				//var r:Rectangle = _motionTracker.motionArea;
				
				if(r.isEmpty()) break;
				
				var x0:int = r.x;
				
				for( var y0:uint = r.y; y0 < r.y + r.height; y0++)
				{
					if(bData.getPixel32(x0,y0) != WHITE) continue;
					
					bData.floodFill(x0,y0, BLOB_FOUND);
					
					var blobRect:Rectangle = bData.getColorBoundsRect(WHITE,BLOB_FOUND);
					
					if(blobRect.width > _min && blobRect.height > _min)
					{
						tr = new TempRectangle(blobRect);
						tr.x *= iScala;
						tr.y *= iScala;
						tr.width *= iScala;
						tr.height *= iScala;
						tr.center.x *= iScala;
						tr.center.y *= iScala;
						newBlobs.push( tr );
					}
					bData.floodFill(x0,y0,BLOB_OLD);
				}
				
				b++;
			}
			bData.dispose();
		}
		
		//recheckBlobs takes the previous found blobs and try to see which ones
		//are still there by intersect method (rectangles don't have hitTest)
		//with the new ones, not accurate, but enough for now
		//EDIT: really messy, specially the evolve method (TempRectangle)
		private function recheckBlobs():void
		{
			//var count:int = 0;
			var b:int = 0;
			while(newBlobs.length)
			{
				var r:TempRectangle = newBlobs.shift();
				var c:int = 0;
				while(c < oldBlobs.length)
				{
					var o:TempRectangle = oldBlobs[c];
					if(r.intersects(o))
					{
						o.evolveTo(r);
						r = o;
					}
					c++;
				}
				_blobs.push(r);
				b++;
			}
			oldBlobs = new __AS3__.vec.Vector.<TempRectangle>;
			for(var i:int = 0; i < _blobs.length; i++)
			{
				//i need these NOT to be instances, so i made cloned function
				var e:TempRectangle = _blobs[i].cloned();
				oldBlobs.push(e);
			}
		}
		
		/*
		========================================================
		| Getters + Setters
		========================================================
		*/
		
		/** The image the MotionTracker is working from */
		public function get trackingImage():BitmapData{ return _now; }
		
		/** The area of the image the MotionTracker is working from
		public function get trackingArea():Rectangle { return new Rectangle( _src.x, _src.y, _src.width, _src.height ); }
		*/
		
		/* The image that is processed, so we can have a true preview */
		public function get sourceImage():BitmapData{return _sourceImage; }
		
		//returns the process time for each frame
		public function get workingTime():int {return processTime;}
		
		/** Whether or not movement is currently being detected */
		public function get hasMovement():Boolean { return _act; }
		
		/** The area in which movement is being detected | OBSOLETE? */
		public function get motionArea():Rectangle { return _box; }
		
		
		/* INPUT */
		/** The video (usualy created from a Camera) used to track motion */
		public function get input():Video { return _src; }
		public function set input( v:Video )
		{
			_src = v;
			if ( _now != null ) { _now.dispose(); _old.dispose(); }
			_now = new BitmapData( v.width * scala, v.height * scala, false, 0 );
			_old = new BitmapData( v.width * scala, v.height * scala, false, 0 );
			_sourceImage = new BitmapData( v.width * scala, v.height * scala, false, 0 );
		}
		
		/** If freezeBackground is set, the image compare is made to a static frame */
		public function set freezeBackground(f:Boolean):void{freezedBackground = f;}
		public function get freezeBackground():Boolean{return freezedBackground;}
		
		/* BLUR */
		/**
		 * the blur being applied to the input in order to improve accuracy
		 */
		public function get blur() : int {return _blr.blurX;}
		public function set blur( n : int ) : void 
		{ 
			_blr.blurX = _blr.blurY = n; 
		}

		/* BRIGHTNESS */
		/**
		 * The brightness filter being applied to the input
		 */
		public function get brightness() : Number {return _brightness;}
		public function set brightness( n : Number ) : void
		{
			_brightness = n;
			applyColorMatrix();
		}

		/* CONTRAST */
		/**
		 * The contrast filter being applied to the input
		 */
		public function get contrast() : Number {return _contrast; }
		public function set contrast( n : Number ) : void
		{
			_contrast = n;
			applyColorMatrix();
		}

		/* MIN AREA */
		/**
		 * The minimum area (percent of the input dimensions) of movement to be considered movement
		 */
		public function get minArea() : uint {return _min;}
		public function set minArea( n : uint ) : void {_min = n;}

		/* FLIP INPUT */
		/**
		 * Whether or not to flip the input for mirroring
		 */
		public function get flipInput() : Boolean {return _mtx.a < 0;}

		public function set flipInput( b : Boolean ) : void
		{
			_mtx = new Matrix(scala,0,0,scala);
			if (b) 
			{ 
				_mtx.translate(-_src.width * scala, 0); 
				_mtx.scale(-1, 1); 
			}
		}
		
		//Return matrix, no setter for this?
		public function get colorMatrix() {return _cmx.toArray();}
		
		/* set get status: Boolean */
		public function get active():Boolean { return iAmWorking; }
		public function set active(b:Boolean):void
		{
			iAmWorking = b;
			if(b == false)
			{
				timer.stop();
			}else{
				if(!timer.running) timer.start();
			}
		}
		/* setter for multipoint detection or not */
		public function set returnBlobs( a:Boolean ):void { _returnBlobs = a; }
		
		/* blobs getter */
		public function get blobs():__AS3__.vec.Vector.<TempRectangle> { return _blobs; }
		
		/* limit max number of blobs */
		public function set maxBlobs(b:int):void { MAX_BLOBS = b; }
		public function get maxBlobs():int { return MAX_BLOBS; }
		
		/* why use an interval? enterFrame is somewhat laggy 
		this could be because of the camFps-movieFps loss of sync 
		this here so we can test even tracking faster than movieFps */
		public function set interval(_interval:int):void
		{
			if(iAmWorking) timer.stop();
			timer.delay = _interval;
			timer.start();
			iAmWorking = true;
		}
		public function get interval():int {return timer.delay;}
		
		//the scaleIndex...
		//ok, this is complex to explain, but simple in practice
		//the MotionTracker gets its input from a video, so, return values
		//will always be proportional to the video size (NOT THE SCREEN/STAGE)
		//Problem was, at higher resolutions, the image process for detecting
		//motion and blobs took too long. In order to fix this i use the
		//matrix to scale. This said, the index is a number from 0 to 1 (just as scaleX/Y)
		//which will be used by the matrix to scale the bitmap/bitmapData/video
		//Lazyness is a factor here, this function could be better, but read the steps inside
		public function get scaleIndex():Number{return scala;}
		public function set scaleIndex(s:Number)
		{
			//ok now, making the image bigger won't help us, but a throw error
			//here seemed too much, so, just state the obvious
			if(s > 1) trace("You shouldn't be doing this");
			//turn off the MT, i don't want things going through different matrix here
			active = false;
			//set the value of scala
			scala = s;
			//Lazyness again, i will need this number eventually, so just calculate and store
			iScala = 1 / scala;
			//here is the big deal: RE-set the input. What for? Well, when input is called
			//the _old and _new bitmapDatas are created and there the matrix just doesn't do
			//any good. Instead, the widths and heights are just multiplied by scala (GLOBAL VAR)
			input = input;
			//and finllay i need to re create the matrix, well, i could do this...
			//or just call flipInput which reinitializes the matrix with the given
			//scala var
			flipInput = flipInput;
			//reactivate the MT (this could be set to a previous state instead)
			active = true;
		}
	}
	
}
