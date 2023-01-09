package;

import gif.Gif;
import net.shared.board.RawPly;
import haxe.Timer;
import net.shared.PieceColor;
import utils.AssetManager;
import openfl.geom.Matrix;
import js.html.Blob;
import js.html.FileSaver;
import net.shared.board.Situation;
import js.html.URLSearchParams;
import js.Browser;
import gameboard.Board;
import openfl.display.BitmapData;
import openfl.events.Event;
import openfl.display.Sprite;

class ImageExportData
{
    public final board:Board;
    public final pngWidth:Int;
    public final pngHeight:Int;
    public final backgroundColor:Int;
    public final transform:Matrix;

    public function new(board:Board, pngWidth:Int, pngHeight:Int, boardWidth:Int, boardHeight:Int, backgroundColor:Int)
    {
        this.board = board;
        this.pngWidth = pngWidth;
        this.pngHeight = pngHeight;
        this.backgroundColor = backgroundColor;
        this.transform = new Matrix();
        this.transform.translate(Math.round((pngWidth - boardWidth)/2), Math.round((pngHeight - boardHeight)/2));
    }
}

class Main extends Sprite
{
	private var pngExportData:ImageExportData;
    private var gifExportParams:{board:Board, gifWidth:Int, gifHeight:Int, gifInterval:Float, bgColor:Int, plySequence:Array<RawPly>};
	
	public function new()
	{
		super();

		var params = new URLSearchParams(Browser.location.search);

		switch params.get("a")
		{
			case "png":
				AssetManager.load(prepPNG.bind(params));
			case "gif":
				AssetManager.load(prepGIF.bind(params));
			default:
				Browser.window.close();
		}
	}

	public static function invAspectRatio(lettersEnabled:Bool):Float
    {
        return lettersEnabled? Math.sqrt(3) * (15/28) : Math.sqrt(3) / 2;
    }

	private function onPNGReady(e)
    {
        pngExportData.board.removeEventListener(Event.EXIT_FRAME, onPNGReady);

        var image:BitmapData = new BitmapData(pngExportData.pngWidth, pngExportData.pngHeight, true, pngExportData.backgroundColor);
        image.draw(pngExportData.board, pngExportData.transform);

        stage.removeChild(pngExportData.board);
        pngExportData = null;

        var blob:Blob = new Blob([image.image.encode(PNG).getData()], {type: 'image/png'});
        var unixtime:Int = Math.round(Date.now().getTime());
		FileSaver.saveAs(blob, 'intpos_$unixtime.png');
		Timer.delay(Browser.window.close, 2000);
    }
    
    private function prepPNG(params:URLSearchParams) 
    {
		var pngWidth:Int = Std.parseInt(params.get("w"));
		var pngHeight:Int = Std.parseInt(params.get("h"));
		var addLetters:Bool = params.has("l");
		var backgroundColor:Int = Std.parseInt("0x" + params.get("b"));
		var letterColor:Int = params.has("c")? Std.parseInt("0x" + params.get("c")) : Colors.border;
		var situation:Situation = Situation.deserialize(StringTools.urlDecode(params.get("s")));
		var orientation:PieceColor = params.get("o") == "b"? Black : White;
		
        var estimatedThickness:Int = Math.ceil((3/560) * pngWidth);
        var boardWidth:Int = pngWidth - estimatedThickness - 2;
        var boardHeight:Int = pngHeight - estimatedThickness - 2;

        if (invAspectRatio(addLetters) * boardWidth > boardHeight)
            boardWidth = Math.floor(boardHeight / invAspectRatio(addLetters));
        else
            boardHeight = Math.floor(boardWidth * invAspectRatio(addLetters));

        var hexSideLength:Float = boardWidth / 14;
        
        var board:Board = new Board(situation, orientation, hexSideLength, addLetters, letterColor);
        pngExportData = new ImageExportData(board, pngWidth, pngHeight, boardWidth, boardHeight, backgroundColor);

        board.addEventListener(Event.EXIT_FRAME, onPNGReady);
        stage.addChild(board);
	}

    private function onGIFReady(e)
    {
        gifExportParams.board.removeEventListener(Event.EXIT_FRAME, onGIFReady);
        stage.removeChild(gifExportParams.board);

        var img:Gif = new Gif(gifExportParams.gifWidth, gifExportParams.gifHeight, gifExportParams.gifInterval);
        var bitmapData:BitmapData = new BitmapData(gifExportParams.gifWidth, gifExportParams.gifHeight, false, gifExportParams.bgColor);
        bitmapData.draw(gifExportParams.board);
        img.addFrame(bitmapData);

        for (ply in gifExportParams.plySequence)
        {
            gifExportParams.board.applyTransposition(ply);
            bitmapData = new BitmapData(gifExportParams.gifWidth, gifExportParams.gifHeight, false, gifExportParams.bgColor);
            bitmapData.draw(gifExportParams.board);
            img.addFrame(bitmapData);
        }

        var unixtime:Int = Math.round(Date.now().getTime());
        img.save('intgame_$unixtime.gif');
		Timer.delay(Browser.window.close, 2000);
    }
	
	private function prepGIF(params:URLSearchParams)
	{
		var gifWidth:Int = Std.parseInt(params.get("w"));
		var gifHeight:Int = Std.parseInt(params.get("h"));
        var gifInterval:Float = Std.parseFloat(params.get("i"));
		var letterColor:Int = params.has("c")? Std.parseInt("0x" + params.get("c")) : Colors.border;
		var backgroundColor:Int = Std.parseInt("0x" + params.get("b"));
		var addLetters:Bool = params.has("l");
		var startingSituation:Situation = Situation.deserialize(StringTools.urlDecode(params.get("s")));
		var orientation:PieceColor = params.get("o") == "b"? Black : White;
		var plySequence:Array<RawPly> = StringTools.urlDecode(params.get("p")).split(";").map(RawPly.deserialize);

        var hexSideLength:Float = gifWidth / 14;

        var board:Board = new Board(startingSituation, orientation, hexSideLength, addLetters, letterColor);
        gifExportParams = {board: board, gifWidth: gifWidth, gifHeight: gifHeight, gifInterval: gifInterval, bgColor: backgroundColor, plySequence: plySequence};

        board.addEventListener(Event.EXIT_FRAME, onGIFReady);
        stage.addChild(board);
	}
}
