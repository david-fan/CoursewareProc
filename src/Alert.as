package
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.text.TextField;
	
	public class Alert extends Sprite
	{
		private var _txt:TextField;
		public function Alert(w:Number,h:Number)
		{
			super();
			graphics.beginFill(0,0.5);
			graphics.drawRect(0,0,w,h);
			graphics.endFill();
			_txt = new TextField();
			_txt.width=w;
			_txt.height=h;
			addChild(_txt);
			_txt.textColor=0xffffff;
			_txt.wordWrap=true;
		}
		
		static public function show(stage:Stage):Alert{
			var alert:Alert = new Alert(stage.stageWidth,stage.stageHeight);
			stage.addChild(alert);
			return alert;
		}
		
		public function showMesssage(message:String):void {
			trace(message);
			if (message.indexOf("frame=") == 0 || message.indexOf("Exit") == 0){
			_txt.text=message;
			
			}
		}
		
		public function hide():void{
			if(parent)
				parent.removeChild(this);
		}
	}
}