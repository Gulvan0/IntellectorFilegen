package utils;

import format.SVG;
import net.shared.PieceColor;
import net.shared.PieceType;
import openfl.Assets;

class AssetManager 
{
    public static var pieces:Map<PieceType, Map<PieceColor, SVG>> = [];

    private static var loadedResourcesCnt:Int = 0;
    private static var totalResourcesCnt:Int = PieceType.createAll().length * PieceColor.createAll().length;
    private static var onLoadedCallback:Void->Void;

    public static function pieceAspectRatio(type:PieceType, color:PieceColor):Float
    {
        return pieces[type][color].data.width / pieces[type][color].data.height;
    }

    public static function pieceRelativeScale(type:PieceType):Float
    {
        return switch type {
            case Progressor: 0.7;
            case Liberator, Defensor: 0.9;
            default: 1;
        }
    }

    public static inline function piecePath(type:PieceType, color:PieceColor):String
    {
        return "assets/pieces/" + type.getName() + "_" + color.getName() + ".svg";
    }

    private static function onResourceLoaded() 
    {
        loadedResourcesCnt++;
        if (loadedResourcesCnt == totalResourcesCnt)
            onLoadedCallback();
    }

    public static function load(callback:Void->Void)
    {  
        onLoadedCallback = callback;
        for (fig in PieceType.createAll())
        {
            pieces[fig] = new Map<PieceColor, SVG>();
            for (col in PieceColor.createAll())
                Assets.loadText(piecePath(fig, col)).onComplete(s -> {
                    pieces[fig].set(col, new SVG(s));
                    onResourceLoaded();
                });
        }
    }
}