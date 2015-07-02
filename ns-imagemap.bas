' Glyde (native)
' (c)2014-15 by Cylexia
'
' MIT Licensed (see LICENSE for info)
'

#ifndef __GLYDE__
#error Build glyde.bas, not this
#endif

namespace ImageMap
    const as string   _
            S_WIDTH       = "w",  _
            S_HEIGHT      = "h"
            
    dim as DICTSTRING _maps

    declare function init() as integer
    declare function loadImageMap( id as string, src as string ) as integer
    declare function deleteImageMap( id as string ) as integer
    declare function drawSegment( map as string, segment as string, x as integer, y as integer, a as integer = -1 ) as integer
    declare function drawSegmentTo( context as any ptr, map as string, segment as string, x as integer, y as integer, a as integer = -1 ) as integer
    declare function getSegmentValue( map as string, segment as string, value as string ) as integer
    declare function _decodeRect( rect as string ) as DICTSTRING

    function init() as integer
        ImageMap._maps = Dict.create()
        return TRUE
    end function
    
    function loadImageMap( id as string, src as string ) as integer
        dim as string d = Utils.readFile( src )
        if( len( d ) = 0 ) then
            return 0        ' unable to load or invalid map
        end if
        
        dim as DICTSTRING map = Dict.create()
        dim as string image_src = ""
        dim as string k, v
        dim as integer s = 1, e = instr( d, ";" ), b
        while( e > 0 )
            v = trim( mid( d, s, (e - s) ), any !"\n\r\t " )
            if( (len( v ) > 0) and (asc( v, 1 ) <> 35) ) then       ' 35 => #
                b = instr( v, "=" )
                if( b > 0 ) then
                    k = lcase( mid( v, 1, (b - 1) ) )
                    v = mid( v, (b + 1) )
                    if( asc( k, 1 ) = 46 ) then     ' 46 is .
                        if( k = ".img" ) then
                            image_src = v
                        end if
                    else
                        Dict.set( map, k, ImageMap._decodeRect( v ) )
                    end if
                end if
            end if
            s = (e + 1)
            e = instr( s, d, ";" )
        wend
        
        dim as integer bmpwidth, bmpheight
        dim as integer ff = freefile()
        if( open( image_src for binary access read as #ff ) <> 0 ) then
            return FALSE
        end if
        
        ' retrieve BMP dimensions
        get #ff, 19, bmpwidth
        get #ff, 23, bmpheight

        close #ff        
        
        dim as any ptr img = imagecreate( bmpwidth, bmpheight )
        
        if( bload( image_src, img ) <> 0 ) then
            imagedestroy( img )
            return FALSE
        end if

        Dict.set( map, "_ptr", cint( img ) )
       
        Dict.set( ImageMap._maps, id, map )
        return TRUE
    end function
    
    function deleteImageMap( id as string ) as integer
        if( Dict.containsKey( ImageMap._maps, id ) ) then
            Dict.remove( ImageMap._maps, id )
            return TRUE
        end if
        return FALSE
    end function
        
    
    function drawSegment( map as string, segment as string, x as integer, y as integer, a as integer = -1 ) as integer
        return ImageMap.drawSegmentTo( 0, map, segment, x, y, a )
    end function
    
    function drawSegmentTo( context as any ptr, map as string, segment as string, x as integer, y as integer, a as integer = -1 ) as integer
        if( Dict.containsKey( ImageMap._maps, map ) ) then
            dim as DICTSTRING mapd = Dict.valueOf( ImageMap._maps, map )
            if( Dict.containsKey( mapd, segment ) ) then
                dim as DICTSTRING box = Dict.valueOf( mapd, segment )
                dim as any ptr ip = cptr( any ptr, Dict.intValueOf( mapd, "_ptr" ) )
                dim as integer dx1 = Dict.intValueOf( box, "x" )
                dim as integer w = Dict.intValueOf( box, "w" )
                select case a
                    case 1:
                        dx1 -= (w / 2)
                    case 2:
                        dx1 -= w
                end select
                dim as integer  _
                        dy1 = Dict.intValueOf( box, "y" ),  _
                        dx2 = (w + dx1 - 1),  _
                        dy2 = (Dict.intValueOf( box, "h" ) + dy1 - 1)
                if( context <> 0 ) then
                    put context, (x, y), ip, (dx1, dy1)-(dx2, dy2), PSet
                else
                    put (x, y), ip, (dx1, dy1)-(dx2, dy2), PSet
                end if
                return TRUE
            end if
        end if
        return FALSE
    end function
    
    function getSegmentValue( map as string, segment as string, value as string ) as integer
        if( Dict.containsKey( ImageMap._maps, map ) ) then
            dim as DICTSTRING mapd = Dict.valueOf( ImageMap._maps, map )
            if( Dict.containsKey( mapd, segment ) ) then
                dim as DICTSTRING box = Dict.valueOf( mapd, segment )
                return Dict.intValueOf( box, value, -1 )
            end if
        end if
        return -1
    end function

    function _decodeRect( rect as string ) as DICTSTRING
        dim as integer i = 1
        dim as integer sl, idx = 0
        dim as DICTSTRING seg = Dict.create()
        sl = (asc( rect, i ) - 48)
        i += 2
        Dict.set( seg, "x", val( mid( rect, i, sl ) ) )
        i += sl
        Dict.set( seg, "y", val( mid( rect, i, sl ) ) )
        i += sl
        Dict.set( seg, "w", val( mid( rect, i, sl ) ) )
        i += sl
        Dict.set( seg, "h", val( mid( rect, i, sl ) ) )
        return seg
    end function
end namespace