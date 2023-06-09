package gameboard;

import net.shared.PieceColor;
import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.converters.Notation;
import openfl.display.Sprite;
import openfl.geom.Point;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
    A simplest board with a very basic functionality
**/
class Board extends Sprite
{
    public var hexSideLength(default, null):Float;
    public var lettersEnabled(default, null):Bool;
    public var letterColor:Int;

    public var hexagons:Array<Hexagon>;
    public var pieces:Array<Null<Piece>>;

    public var orientationColor(default, null):PieceColor;

    private var _shownSituation:Situation;

    private var letters:Array<TextField> = [];

    private var hexagonLayer:Sprite;
    private var pieceLayer:Sprite;

    public function applyTransposition(ply:RawPly) 
    {
        var departurePiece = pieces[ply.from.toScalarCoord()];
        var destinationPiece = pieces[ply.to.toScalarCoord()];

        if (ply.morphInto != null)
        {
            pieceLayer.removeChild(departurePiece);
            pieces[ply.from.toScalarCoord()] = null;
            _shownSituation.set(ply.from, Empty);

            if (destinationPiece != null)
                pieceLayer.removeChild(destinationPiece);
            producePiece(ply.to, Hex.construct(ply.morphInto, departurePiece.color));
            _shownSituation.set(ply.to, Hex.construct(ply.morphInto, departurePiece.color));
        }
        else
        {
            departurePiece.reposition(ply.to, this);
            pieces[ply.to.toScalarCoord()] = departurePiece;
            _shownSituation.set(ply.to, Hex.construct(departurePiece.type, departurePiece.color));

            if (destinationPiece == null)
            {
                pieces[ply.from.toScalarCoord()] = null;
                _shownSituation.set(ply.from, Empty);
            }
            else if (departurePiece.color == destinationPiece.color && (departurePiece.type == Intellector && destinationPiece.type == Defensor || departurePiece.type == Defensor && destinationPiece.type == Intellector))
            {
                destinationPiece.reposition(ply.from, this);
                pieces[ply.from.toScalarCoord()] = destinationPiece;
                _shownSituation.set(ply.from, Hex.construct(destinationPiece.type, destinationPiece.color));
            }
            else
            {
                pieceLayer.removeChild(destinationPiece);
                pieces[ply.from.toScalarCoord()] = null;
                _shownSituation.set(ply.from, Empty);
            }
        }
    }

    public function hexCoords(location:HexCoords):Point
    {
        return absHexCoords(location.i, location.j, orientationColor == White);
    }

    private function absHexCoords(i:Int, j:Int, isOrientationNormal:Bool):Point
    {
        if (!isOrientationNormal)
        {
            j = 6 - j - i % 2;
            i = 8 - i;
        }

        var hexWidth:Float = Hexagon.sideToWidth(hexSideLength);
        var hexHeight:Float = Hexagon.sideToHeight(hexSideLength);

        var shift:Point = new Point(hexWidth/2, hexHeight/2);

        var p:Point = new Point(0, 0);
        p.x = 3 * hexSideLength * i / 2;
        p.y = hexHeight * j;

        if (i % 2 == 1)
            p.y += hexHeight / 2;

        return p.add(shift);
    }

    private function produceHexagons(displayRowNumbers:Bool)
    {
        hexagons = [];

        for (s in HexCoords.enumerateScalar())
        {
            var p:HexCoords = HexCoords.fromScalarCoord(s);
            var hexagon:Hexagon = new Hexagon(hexSideLength, p.i, p.j, displayRowNumbers);
            var coords = hexCoords(p);
            hexagon.x = coords.x;
            hexagon.y = coords.y;
            hexagonLayer.addChild(hexagon);
            hexagons.push(hexagon);
        }
    }

    private function producePieces()
    {
        pieces = [];

        for (s in 0...59)
        {
            var p = HexCoords.fromScalarCoord(s);
            producePiece(p, _shownSituation.get(p));
        }
    }

    private function producePiece(location:HexCoords, hex:Hex)
    {
        var scalarCoord = location.toScalarCoord();

        switch hex 
        {
            case Empty:
                pieces[scalarCoord] = null;
            case Occupied(pieceData):
                var piece:Piece = Piece.fromData(pieceData, hexSideLength);
                piece.reposition(location, this);
                pieceLayer.addChild(piece);
                pieces[scalarCoord] = piece;
        }
    }

    private function drawLetters() 
    {
        for (i in 0...9)
        {
            var bottomHexLocation:HexCoords = new HexCoords(i, orientationColor == White? 6 - i % 2 : 0);
            var bottomHexCoords:Point = hexCoords(bottomHexLocation);
            var letter:TextField = createLetter(Notation.getColumn(i), hexSideLength);
            letter.x = bottomHexCoords.x - letter.textWidth/2 - 5;
            letter.y = bottomHexCoords.y + Hexagon.sideToHeight(hexSideLength) / 2;
            letters.push(letter);
            hexagonLayer.addChild(letter); 
        }
    }

    private function createLetter(letter:String, hexSideLength:Float):TextField 
    {
        var tf = new TextField();
        tf.text = letter;
        tf.setTextFormat(new TextFormat(null, Math.round(28 * hexSideLength / 40), letterColor, true));
        return tf;
    }

    public function new(situation:Situation, orientationColor:PieceColor, hexSideLength:Float, letters:Bool, letterColor:Int) 
    {
        super();

        this.hexSideLength = hexSideLength;
        this.lettersEnabled = letters;
        this.orientationColor = orientationColor;
        this._shownSituation = situation.copy();
        this.letterColor = letterColor;
        this.hexagonLayer = new Sprite();
        this.pieceLayer = new Sprite();

        addChild(hexagonLayer);
        addChild(pieceLayer);

        produceHexagons(letters);
        producePieces();
        if (lettersEnabled)
            drawLetters();
    }

}