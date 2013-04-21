package {
	import com.codeazur.as3swf.data.SWFRectangle;
	import com.codeazur.as3swf.SWF;
	import com.codeazur.as3swf.tags.TagDefineBits;
	import com.codeazur.as3swf.tags.TagDefineShape;
	import com.codeazur.as3swf.tags.TagEnd;
	import com.codeazur.as3swf.tags.TagShowFrame;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import fl.containers.ScrollPane;
	import fl.controls.Button;
	import fl.events.ComponentEvent;
	
	import ui.BaseSetting;
	import ui.ItemRender;
	
	[SWF(width=615, height=615)]
	public class CoursewareProc extends Sprite {
		//[Embed(source="template.swf")]
		//public static var template : Class;
		//[Embed(source="ffmpeg",mimeType="application/octet-stream")]
		//public static var ffmepg : Class;
		
		public var process:NativeProcess;
		
		private var setting:BaseSetting;
		private var start:Button;
		private var addItem:Button;
		
		private var panel:ScrollPane;
		private var itemsSprite:Sprite;
		
		private var videoGenerateButton:Button;
		
		private var items:Array = [];
		
		private var Config:XML;
		
		private var videoList:XML;
		
		public function CoursewareProc() {
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			setting = new BaseSetting();
			addChild(setting);
			setting.x = setting.y = 10;
			setting.btn_input.addEventListener(MouseEvent.CLICK, onInputClick);
			setting.btn_output.addEventListener(MouseEvent.CLICK, onOutputClick);
			setting.onlyCutVideo.addEventListener(ComponentEvent.BUTTON_DOWN,onOnlyCutVideoClick);
			//setting.onlyCutVideo.addEventListener(MouseEvent.CLICK,onOnlyCutVideoClick);
			
			start = new Button();
			start.label = "开始处理";
			start.addEventListener(MouseEvent.CLICK, onStart);
			addChild(start);
			start.x = 150;
			start.y = 140;
			
			addItem = new Button();
			addItem.label = "添加片段";
			addItem.addEventListener(MouseEvent.CLICK, onAddItem);
			addChild(addItem);
			addItem.x = 10;
			addItem.y = 140;
			
			panel = new ScrollPane();
			addChild(panel);
			panel.x = 10;
			panel.y = 160;
			panel.width = 600;
			panel.height = 460;
			
			videoGenerateButton = new Button();
			videoGenerateButton.label = "合成视频";
			addChild(videoGenerateButton);
			videoGenerateButton.x = 280;
			videoGenerateButton.y = 140;
			videoGenerateButton.addEventListener(MouseEvent.CLICK, onVideoGenerateClick);
			
			itemsSprite = new Sprite();
			panel.source=itemsSprite;
			/*
			var xml:File = File.applicationDirectory.resolvePath("ffmpeg");
			if (xml.exists)
				xml.deleteFile();
			var fs:FileStream = new FileStream();
			fs.open(xml, FileMode.WRITE);
			fs.writeMultiByte(new ffmepg(), "utf-8");
			fs.close();
			
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var file:File = File.applicationDirectory.resolvePath("ffmpeg");
			nativeProcessStartupInfo.executable = file;
			
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs.push("-h");
			nativeProcessStartupInfo.arguments = processArgs;
			
			process = new NativeProcess();
			process.start(nativeProcessStartupInfo);
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
			process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
			*/
		}
		
		private function onOnlyCutVideoClick(e:ComponentEvent):void{
			if(setting.onlyCutVideo.selected){
				for(var i:int=0;i<items.length;i++){
					var r:ItemRender=items[i];
					r.selPic.enabled=true;
				}
			}else{
				for(var i:int=0;i<items.length;i++){
					var r:ItemRender=items[i];
					r.selPic.enabled=false;
					r.picUrl.text="";
				}
			}
		}
		
		private function onVideoGenerateClick(e:MouseEvent):void {
			var windowOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			windowOptions.systemChrome = NativeWindowSystemChrome.STANDARD;
			windowOptions.type = NativeWindowType.NORMAL;
			var vgw:VideoGenerate = new VideoGenerate(windowOptions);
			vgw.stage.scaleMode = StageScaleMode.NO_SCALE;
			vgw.stage.align = StageAlign.TOP_LEFT;
			vgw.width = 430 + 20;
			vgw.height = 145 + 20 + 30;
			vgw.title = "合成视频";
			vgw.activate();
		}
		
		private function pushParagraph(sequence:int, pname:String, plength:int):void {
			var id:int = sequence + 1;
			var pxml:XML =
				<paragraph>
					<sequence>{id}</sequence>
					<pid>{setting.cwid.text + "-" + id}</pid>
					<pname>{pname}</pname>
					<plength>{plength}</plength>
				</paragraph>;
			Config.paragraphs.appendChild(pxml);
		}
		
		private function saveXML():void {
			var saveDir:File = new File(setting.outputDir.text);
			var xml:File = saveDir.resolvePath("date/xml/Config.xml");
			var fs:FileStream;
			if (xml.exists)
				xml.deleteFile();
			fs = new FileStream();
			fs.open(xml, FileMode.WRITE);
			fs.writeMultiByte(Config.toXMLString(), "utf-8");
			fs.close();
			
			xml = saveDir.resolvePath("date/xml/videoList.xml");
			if (xml.exists)
				xml.deleteFile();
			fs = new FileStream();
			fs.open(xml, FileMode.WRITE);
			fs.writeMultiByte(videoList.toXMLString(), "utf-8");
			fs.close();
			
		}
		
		private function pushVideo(title:String, left:String, right:String):void {
			var v:XML = <video/>;
			v.@title = title;
			v.video.@leftVideo = "date/video/" + left;
			v.video.@rightVideo = "date/video/" + right;
			videoList.appendChild(v);
		}
		
		private function onAddItem(e:MouseEvent):void {

			var item:ItemRender = new ItemRender();
			items.push(item);
			reDrawItemSprite();
			panel.source = itemsSprite;
			item.delItem.addEventListener(MouseEvent.CLICK, onItemDelClick);
			item.selPic.addEventListener(MouseEvent.CLICK, onSelPicClick);
			if(setting.onlyCutVideo.selected){
				item.selPic.enabled=false;
			}
			/*
			if(items.length==3){
				addItem.enabled=false;
			}
			*/
		}
		
		private var currentItemRender:ItemRender;
		
		private function onItemDelClick(e:MouseEvent):void {
			currentItemRender = e.target.parent;
			//
			var i:int = items.indexOf(currentItemRender);
			if (i > -1) {
				items.splice(i, 1);
			}
			reDrawItemSprite();
			if(items.length!=3){
				addItem.enabled=true;
			}
		}
		
		private function onSelPicClick(e:MouseEvent):void {
			currentItemRender = e.target.parent;
			//
			var fileToOpen:File = new File();
			var jpg:FileFilter = new FileFilter("图片", "*.jpg");
			
			try {
				fileToOpen.browseForOpen("选择对应的PPT图片", [jpg]);
				fileToOpen.addEventListener(Event.SELECT, onPPTSelected);
			}
			catch (error:Error) {
				trace("Failed:", error.message);
			}
		}
		
		private function onPPTSelected(e:Event):void {
			currentItemRender.picUrl.text = File(e.target).nativePath;
		}
		
		private function reDrawItemSprite():void {
			while (itemsSprite.numChildren > 0)
				itemsSprite.removeChildAt(0)
			for (var i:int = 0; i < items.length; i++) {
				var item:ItemRender = items[i];
				item.y = 60 * i
				itemsSprite.addChild(item);
			}
		}
		
		private function onInputClick(e:MouseEvent):void {
			var fileToOpen:File = new File();
			var videoExts:FileFilter = new FileFilter("视频", "*.avi;*.mp4");
			
			try {
				fileToOpen.browseForOpen("选择输入视频", [videoExts]);
				fileToOpen.addEventListener(Event.SELECT, onInputVideoSelected);
			}
			catch (error:Error) {
				trace("Failed:", error.message);
			}
		}
		
		private function onInputVideoSelected(event:Event):void {
			var file:File = event.target as File;
			setting.inputVideo.text = file.nativePath;
		}
		
		private function onOutputClick(e:MouseEvent):void {
			var fileToOpen:File = new File();
			try {
				fileToOpen.browseForDirectory("选择输出目录");
				fileToOpen.addEventListener(Event.SELECT, onOutputSelected);
			}
			catch (error:Error) {
				trace("Failed:", error.message);
			}
		}
		
		private function onOutputSelected(event:Event):void {
			var file:File = event.target as File;
			setting.outputDir.text = file.nativePath;
		}
		private var _alert:Alert;
		private function onStart(e:MouseEvent):void {
			_alert=Alert.show(stage);
			Config=<swfcourseware>
			<cwname></cwname>
			<cwid></cwid>
			<cwlength></cwlength>
			<paragraphs>
			</paragraphs>
		</swfcourseware>;
			videoList= <data></data>;
			Config.cwname = setting.cwname.text;
			Config.cwid = setting.cwid.text;
			Config.cwlength = setting.cwlength.text;
			if (NativeProcess.isSupported) {
				currentProc = 0;
				procNext();
			}
			else {
				trace("NativeProcess not supported.");
			}
		}
		
		private var currentProc:int = 0;
		
		private function procNext():void {
			if (currentProc >= items.length) {
				saveXML();
				flash.utils.setTimeout(function():void{_alert.hide();},1000*3);
				return;
			}
			
			var item:ItemRender = items[currentProc];
			var start:int = int(item.start.text);
			var end:int = int(item.end.text);
			
			pushParagraph(currentProc, item.title.text, end - start);
			pushVideo(item.title.text, currentProc + "_l.swf", currentProc + "_r.swf");
			var from:String = setting.inputVideo.text;
			var out:String = setting.outputDir.text + "/date/video/" + currentProc + "_l.swf";
			var file:File = new File(out);
			if (file.exists)
				file.deleteFile();
			procVideo(from, out, start, end);
		}
		
		public function procVideo(from:String, out:String, start:int, end:int):void {
			var dir:File = new File(setting.outputDir.text + "/date/video");
			if (!dir.exists)
				dir.createDirectory();
			
			var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			var dir:File = File.applicationDirectory;
			var file:File = dir.resolvePath("ffmpeg.exe");
			nativeProcessStartupInfo.executable = file;
			
			var processArgs:Vector.<String> = new Vector.<String>();
			processArgs.push("-i");
			processArgs.push(from);
			processArgs.push("-r");
			processArgs.push("24");
			processArgs.push("-ss");
			processArgs.push(start);
			processArgs.push("-t");
			processArgs.push(end-start);
			processArgs.push("-acodec");
			processArgs.push("mp3");
			processArgs.push("-b");
			processArgs.push("150");
			processArgs.push("-vcodec");
			processArgs.push("flv");
			processArgs.push("-f");
			processArgs.push("avm2");
			processArgs.push(out);
			nativeProcessStartupInfo.arguments = processArgs;
			
			process = new NativeProcess();
			process.start(nativeProcessStartupInfo);
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
			process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
		}
		
		public function onOutputData(event:ProgressEvent):void {
			_alert.showMesssage(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable));
		}
		
		public function onErrorData(event:ProgressEvent):void {
			_alert.showMesssage(process.standardError.readUTFBytes(process.standardError.bytesAvailable));
		}
		
		public function onExit(event:NativeProcessExitEvent):void {
			_alert.showMesssage("Exite:Code "+event.exitCode);
			if(setting.onlyCutVideo.selected){
				currentProc++;
				procNext();
			}else
				proPic();
		}
		
		public function onIOError(event:IOErrorEvent):void {
			_alert.showMesssage(event.toString());
		}
		
		private var _swfData:ByteArray;
		
		public function proPic():void {
			if (_swfData == null) {
				_swfData = new ByteArray();
				var swf:FileStream = new FileStream();
				swf.open(File.applicationDirectory.resolvePath("template.swf"), FileMode.READ);
				swf.readBytes(_swfData);
			}
			
			var item:ItemRender = items[currentProc];
			var start:int = int(item.start.text);
			var end:int = int(item.end.text);
			var s:int = end - start-1;
			var picFrom:String = item.picUrl.text;
			
			var loader:Loader = new Loader();
			loader.load(new URLRequest(picFrom));
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
				var image:Bitmap = Bitmap(loader.content);
				image.smoothing = true;
				image.width = 638;
				image.height = 484;
				var newbd:BitmapData = new BitmapData(638, 484);
				newbd.draw(image,new Matrix(image.scaleX,0,0,image.scaleY,0,0));
				var jpge:JPGEncoder = new JPGEncoder(100);
				var _jpgData:ByteArray = jpge.encode(newbd);				
				var out:String = setting.outputDir.text + "/date/video/" + currentProc + "_r.swf";
				var jpgswf:File = new File(out);
				if (jpgswf.exists)
					jpgswf.deleteFile();
				var fileStream:FileStream = new FileStream();
				fileStream.open(jpgswf, FileMode.WRITE);
				
				var newswf:SWF = new SWF(_swfData);
				
				var bd:TagDefineBits = newswf.tags[5] as TagDefineBits;
				bd.bitmapData.writeBytes(_jpgData);
				
				var endT:TagEnd = newswf.tags.pop() as TagEnd;
				var addCount:int = newswf.frameRate * s;
				for (var i:int = 0; i < addCount * s; i++) {
					newswf.tags.push(new TagShowFrame());
				}
				
				newswf.frameCount = newswf.frameCount + addCount;
				
				newswf.tags.push(endT);
				// Publish the generated SWF
				var t:ByteArray = new ByteArray();
				newswf.publish(t);
				fileStream.writeBytes(t);
				fileStream.close(); //记得要关闭流
				
				currentProc++;
				procNext();
			}
			);
		}
	}
}
