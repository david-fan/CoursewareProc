/**
 * Created with IntelliJ IDEA.
 * User: david
 * Date: 3/19/13
 * Time: 8:59 AM
 * To change this template use File | Settings | File Templates.
 */
package {
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.MouseEvent;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.net.FileFilter;
import flash.utils.setTimeout;

import ui.GenerateVideo;

public class VideoGenerate extends NativeWindow {
    private var _setting:GenerateVideo;
	
	private var _alert:Alert;

    public function VideoGenerate(initOptions:NativeWindowInitOptions) {
        super(initOptions);
        _setting = new GenerateVideo();
        _setting.selectPic.addEventListener(MouseEvent.CLICK, onSelPicClick);
        _setting.selectSound.addEventListener(MouseEvent.CLICK, onSelSoundClick);
        _setting.generateVideo.addEventListener(MouseEvent.CLICK, onGenerateClick);
		_setting.selectOutput.addEventListener(MouseEvent.CLICK, onSelOutputClick);
        stage.addChild(_setting);
        _setting.x = _setting.y = 10;
		/*
		_setting.soundLength.text="30";
		_setting.soundLength.enabled=false;
		_setting.soundLength.editable=false;
		*/
    }

    private function onSelPicClick(e:MouseEvent):void {
        //
        var fileToOpen:File = new File();
        var jpg:FileFilter = new FileFilter("图片", "*.jpg");

        try {
            fileToOpen.browseForOpen("选择对应的图片", [jpg]);
            fileToOpen.addEventListener(Event.SELECT, onPicSelected);
        }
        catch (error:Error) {
            trace("Failed:", error.message);
        }
    }

    private function onPicSelected(e:Event):void {
        _setting.picUrl.text = File(e.target).nativePath;
    }

    private function onSelSoundClick(e:MouseEvent):void {
        //
        var fileToOpen:File = new File();
        var sound:FileFilter = new FileFilter("声音", "*.mp3");

        try {
            fileToOpen.browseForOpen("选择对应的声音", [sound]);
            fileToOpen.addEventListener(Event.SELECT, onSoundSelected);
        }
        catch (error:Error) {
            trace("Failed:", error.message);
        }
    }

    private function onSoundSelected(e:Event):void {
        _setting.soundUrl.text = File(e.target).nativePath;
    }
	
	private function onSelOutputClick(e:MouseEvent):void {
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
		_setting.output.text = file.nativePath;
	}
    private function onGenerateClick(e:MouseEvent):void {
        procSound(_setting.picUrl.text, _setting.soundUrl.text,int(_setting.soundLength.text),_setting.output.text);
		_alert=Alert.show(stage);
    }

    private var process:NativeProcess;

    public function procSound(img:String, sound:String, length:int,output:String):void {
        var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
        var dir:File = File.applicationDirectory;
        var file:File = dir.resolvePath("ffmpeg.exe");
        nativeProcessStartupInfo.executable = file;

        //ffmpeg -y -loop 1 -i image.jpg -i audio.mp3 -r 30 -b:v 2500k -vframes 14490 -acodec mp3 -ab 160k -ar 22050 result.mp4
        var processArgs:Vector.<String> = new Vector.<String>();
        processArgs.push("-y");
        processArgs.push("-loop");
        processArgs.push("1");
        processArgs.push("-i");
		processArgs.push(img);
        //processArgs.push(escape(img));
        processArgs.push("-i");
		processArgs.push(sound);
        //processArgs.push(escape(sound));
        processArgs.push("-r");
        processArgs.push("24");
        processArgs.push("-b");
        processArgs.push("250k");
        processArgs.push("-vframes");
        processArgs.push(length * 24);
        processArgs.push("-acodec");
        processArgs.push("mp3");
        processArgs.push("-ab");
        processArgs.push("160k");
        processArgs.push("-ar");
        processArgs.push("44100");
		processArgs.push("-s");
        processArgs.push("320*240");
		processArgs.push(output+"/result.mp4");
        //processArgs.push(escape(output+"/result.mp4"));
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
		var output:String=process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable);
		_alert.showMesssage(output);
        //trace("OutputData:", output);
    }

    public function onErrorData(event:ProgressEvent):void {
		var output:String=process.standardError.readUTFBytes(process.standardError.bytesAvailable);
		_alert.showMesssage(output);
        //trace("ErrorData:", output);
    }

    public function onExit(event:NativeProcessExitEvent):void {
		_alert.showMesssage("Exit:code "+ event.exitCode);
		flash.utils.setTimeout(function():void{_alert.hide();},1000*3);
		
        //trace("Exit:", event.exitCode);
    }

    public function onIOError(event:IOErrorEvent):void {
		_alert.showMesssage(event.toString());
        //trace("IOError:"+event.toString());
    }

}
}
