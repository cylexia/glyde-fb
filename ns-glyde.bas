' Glyde (native)
' (c)2014-15 by Cylexia
'
' MIT Licensed (see LICENSE for info)
'

#ifndef __GLYDE__
#error Build glyde.bas, not this
#endif

namespace Glyde
    const as string  _
            D_WINDOW_FLAGS     = "window.flags",  _
            D_LAST_HIT_BUTTON     = "lasthitbutton",  _
            D_CLOSE_HANDLER       = "handler.close",  _
            D_SHOW_HITZONES       = "hitzones.show"
            
    declare function init() as integer
    declare function readConfigFile( src as string ) as DICTSTRING
    declare function hittest( x as integer, y as integer ) as DICTSTRING ptr        ' POINTER!
    declare function keytest( keycode as string ) as DICTSTRING
    declare sub setData( key as string, value as string )
    declare function getData( key as string ) as string
    declare sub hilightNext()
    declare function getHilightedAction() as string
    declare function morseKeyPressed() as string
    declare function glueCommand( byref w as string, byref vars as string ) as integer
    declare function _loadResource( src as string, w as DICTSTRING ptr ) as integer
    declare function _removeResource( id as string ) as integer
    declare function _buttonize( id as string, d as DICTSTRING ptr ) as integer
    declare function _drawAs( id as string, d as DICTSTRING ptr ) as integer
    declare function _writeAs( id as string, d as DICTSTRING ptr ) as integer
    declare function _markAs( id as string, d as DICTSTRING ptr ) as integer
    declare function _paintRectAs( id as string, d as DICTSTRING ptr, filled as integer ) as integer
    declare function _createEntityAs( id as string, d as DICTSTRING ptr ) as integer
    declare sub _shadeView()
    declare sub _hilight( no_repaint as integer = 0 )
    declare sub _clear()
    'declare function _drawResourceImage( id as string, byref d as DICTSTRING ) as integer
    declare function _addButton( id as string, d as DICTSTRING ptr ) as integer
    declare sub _drawText( text as string, d as DICTSTRING ptr )
    declare function _decodeColour( clr as string ) as integer
    declare function _onKeyGoto( key as string, d as DICTSTRING ptr ) as integer
    declare function _doAction( action as string, d as DICTSTRING ptr ) as integer
    declare function _isUniqueId( id as string ) as integer
    declare sub _applyStyle( d as DICTSTRING ptr )
    declare sub _defineStyle( id as string, d as DICTSTRING )
    declare sub _startTimer( interval as integer, label as string )
    declare sub _stopTimer()
    declare function checkTimer() as integer
    declare function getTimerLabel() as string
    
    dim as DICTSTRING _buttons(255)
    dim as DICTSTRING _keymap
    dim as DICTSTRING _ids
    dim as DICTSTRING _styles
    dim as integer _buttons_last
    dim as integer _clr_0, _clr_1
    dim as DICTSTRING _data
    dim as integer _selected
    dim as any ptr _draw_context
    dim as integer _width, _height
    dim as integer _timer_interval
    dim as double _timer_next
    dim as string _timer_label
    dim as integer _offset_x, _offset_y
    dim as integer _bgcolour
    
    function init() as integer
        Glyde._clr_0 = RGB( 0, 0, 0 )
        Glyde._clr_1 = RGB( 255, 0, 0 )
        Glyde._bgcolour = RGB( 255, 255, 255 )
        Glyde._clear()
        Glyde._data = Dict.create()
        Glyde._timer_next = -1
        Glyde._offset_x = 0
        Glyde._offset_y = 0
        Glyde.setData( Glyde.D_CLOSE_HANDLER, "" )
        Glyde.setData( Glyde.D_LAST_HIT_BUTTON, "" )
        return Glue.addPlugin( @Glyde.glueCommand )
    end function

    ' reads a config file (k=v; per line)
    function readConfigFile( src as string ) as DICTSTRING
        dim as string d = Utils.readFile( src )
        if( len( d ) = 0 ) then
            return ""        ' unable to load or invalid map
        end if
        
        dim as DICTSTRING map = Dict.create()
        dim as string k, v
        dim as integer s = 1, e = instr( d, ";" ), b
        while( e > 0 )
            v = trim( mid( d, s, (e - s) ), any !"\n\r\t " )
            if( (len( v ) > 0) and (asc( v, 1 ) <> 35) ) then       ' 35 => #
                b = instr( v, "=" )
                if( b > 0 ) then
                    k = lcase( mid( v, 1, (b - 1) ) )
                    v = mid( v, (b + 1) )
                    if( Dict.containsKey( map, k ) ) then
                        v = (Dict.valueOf( map, k ) & !"\n" & v)
                    end if
                    Dict.set( map, k, v )
                end if
            end if
            s = (e + 1)
            e = instr( s, d, ";" )
        wend
        return map
    end function

    ' this returns a pointer to save allocating memory
    function hittest( x as integer, y as integer ) as DICTSTRING ptr
        dim as DICTSTRING ptr result = 0
        dim as integer show_zones = Dict.intValueOf( Glyde._data, D_SHOW_HITZONES, 0 )
        Glyde._selected = -1
        if( Glyde._buttons_last > -1 ) then
            dim as integer i, clr
            for i = 0 to Glyde._buttons_last
                dim as DICTSTRING ptr dp = @Glyde._buttons(i)
                dim as integer   _
                        x1 = Dict.intValueOf( *dp, "x1" ),  _
                        y1 = Dict.intValueOf( *dp, "y1" ),  _
                        x2 = Dict.intValueOf( *dp, "x2" ),  _
                        y2 = Dict.intValueOf( *dp, "y2" )
                if( (x >= x1) and (y >= y1) and (x <= x2) and (y <= y2) ) then
                    clr = Glyde._clr_1
                    result = dp
                    Glyde._selected = i
                    ' remove these if "else" and the 2 after are uncommented
                    line (x1,y1)-(x2,y2), clr, B
                    line ((x1+1),(y1+1))-((x2+1),(y2+1)), clr, B
                'else
                '    if( show_zones ) then
                '        clr = Glyde._clr_0
                '    else
                '        continue for
                '    end if
                end if
                'line (x1,y1)-(x2,y2), clr, B
                'line ((x1+1),(y1+1))-((x2-1),(y2-1)), clr, B
            next
        end if
        return result
    end function

    ' check the map for the given keycode and return the dict or ""
    function keytest( keycode as string ) as DICTSTRING
        if( Dict.containsKey( Glyde._keymap, keycode ) ) then
            return Dict.valueOf( Glyde._keymap, keycode )
        end if
        return ""
    end function
    
    sub repaint()
        if( Glyde._draw_context <> 0 ) then
            put (0, 0), Glyde._draw_context, PSet
            if( Glyde._buttons_last > -1 ) then        
                dim as integer i, clr
                for i = 0 to Glyde._buttons_last
                    dim as DICTSTRING ptr dp = @Glyde._buttons(i)
                    dim as integer   _
                            x1 = Dict.intValueOf( *dp, "x1" ),  _
                            y1 = Dict.intValueOf( *dp, "y1" ),  _
                            x2 = Dict.intValueOf( *dp, "x2" ),  _
                            y2 = Dict.intValueOf( *dp, "y2" )
                    if( i = Glyde._selected ) then
                        clr = Glyde._clr_1
                        line (x1,y1)-(x2,y2), clr, B
                        line ((x1+1),(y1+1))-((x2-1),(y2-1)), clr, B
                    'else
                    '    clr = Glyde._clr_0
                    end if
    '                line (x1,y1)-(x2,y2), clr, B
    '                line ((x1+1),(y1+1))-((x2-1),(y2-1)), clr, B
                next
            end if
        else
            Utils.echo( "[Glyde] Notice: context is unavailable" )
        end if
    end sub

    function getData( key as string ) as string
        return Dict.valueOf( Glyde._data, key )
    end function
    
    sub setData( key as string, value as string )
        Dict.set( Glyde._data, key, value )
    end sub

    sub hilightNext()
        if( Glyde._buttons_last > -1 ) then
            if( Glyde._selected < Glyde._buttons_last ) then
                Glyde._selected += 1
                Glyde._hilight()
                return
            end if
        end if
        Glyde._selected = -1
        Glyde._hilight()
    end sub

    sub hilightPrev()
        if( Glyde._buttons_last > -1 ) then
            if( Glyde._selected >= 0 ) then
                Glyde._selected -= 1
            else
                Glyde._selected = Glyde._buttons_last
            end if
            Glyde._hilight()
            return
        end if
        Glyde._selected = -1
        Glyde._hilight()
    end sub

    sub hilightNone()
        Glyde._selected = -1
        Glyde._hilight()
        Glyde.repaint()
    end sub
    
    function getHilightedAction() as string
        if( Glyde._buttons_last > -1 ) then
            if( Glyde._selected > -1 ) then
                dim as DICTSTRING ptr d = @Glyde._buttons(Glyde._selected)
                Glyde.setData( Glyde.D_LAST_HIT_BUTTON, Dict.valueOf( *d, "id" ) )
                return Dict.valueOf( *d, "action" )
            end if
        end if
        return ""
    end function

    function morseKeyPressed() as string
        Glyde.hilightNext()
        if( Dict.containsKey( Glyde._keymap, chr( 9 ) ) ) then
            dim as string kdef = Dict.valueOf( Glyde._keymap, chr( 9 ) )
            Glyde.setData( Glyde.D_LAST_HIT_BUTTON, Dict.valueOf( kdef, "id" ) )
            return Dict.valueOf( kdef, "label" )
        end if
        return Utils.EMPTY_STRING
    end function

    function glueCommand( byref w as string, byref vars as string ) as integer
        dim c as string = Dict.valueOf( w, "_" ), cs as string
        dim ts as string, tn as single, ti as integer
        if( instrrev( c, "f.", 1 ) > 0 ) then
            cs = mid( c, 3 )
        else
            return -1
        end if
        dim as string vv = Dict.valueOf( w, c )
        dim as string into = Dict.valueOf( w, "into" )
        select case cs
' data
            case "loadresource"
                return Glyde._loadResource( vv, @w )
            case "removeresource"
                return Glyde._removeResource( vv )
                
            ' view actions
            case "clear", "clearview"
                Glyde._clear()
            case "shade", "shadeview"
                Glyde._shadeView()
                
            ' TODO: if using object orientated entities support this
            'case "remove"
            '    Dict.remove( Glyde._ids, vv )
                
            case "setwidth", "setviewwidth"
                Glyde._width = Dict.intValueOf( w, c )
                Glyde._height = Dict.intValueOf( w, "height" )
                dim as integer vf = (  _
                        Dict.intValueOf( w, "flags", 0 ) or   _
                        val( Glyde.getData( Glyde.D_WINDOW_FLAGS ) )  _
                    )
                if( (Glyde._width > 0) and (Glyde._height > 0) ) then
                    screenres Glyde._width, Glyde._height, 32, , vf
                else
                    Utils.echoError( ("[Glyde] Invalid View: w=" & Glyde._width & "; h=" & Glyde._height & "; f=" & vf) )
                    return 0
                end if
                Glyde._bgcolour = Glyde._decodeColour( Dict.valueOf( w, "background", "#fff" ) )
                Glyde._clr_1 = Glyde._decodeColour( Dict.valueOf( w, "hilight", "#f00" ) )
                Glyde._clr_0 = Glyde._decodeColour( Dict.valueOf( w, "border", "#000" ) )
                Glyde._clear()
            case "setoffsetx"
                Glyde._offset_x = Dict.intValueOf( w, c )
                Glyde._offset_y = Dict.intValueOf( w, "y", Dict.intValueOf( w, "andy" ) )
                
            case "settitle"
                windowtitle vv
                
            case "definestyle", "setstyle"      ' setStyle will be removed in the future
                Glyde._defineStyle( vv, w )
                
            case "drawas"
                return Glyde._drawAs( vv, @w )
            case "writeas", "addtext"
                return Glyde._writeAs( vv, @w )
            case "markas", "addbutton"
                return Glyde._markAs( vv, @w )
            case "paintrectas"
                return Glyde._paintRectAs( vv, @w, FALSE )
            case "paintfilledrectas"
                return Glyde._paintRectAs( vv, @w, TRUE )
            case "clearactions"
                Glyde._buttons_last = -1
                Glyde._keymap = Dict.create()
                
            case "getlastactionid"
                SET_INTO( Glyde.getData( Glyde.D_LAST_HIT_BUTTON ) )
            case "doaction"
                return Glyde._doAction( vv, @w )

            'event handlers
            case "onkeypressed"       'onkeypressed KEY goto LABEL
                return Glyde._onKeyGoto( vv, @w )
            
            case "starttimerwithinterval"
                Glyde._startTimer(   _
                        Dict.intValueOf( w, c ),  _
                        Dict.valueOf( w, "ontickgoto" )  _
                    )
            case "stoptimer"
                Glyde._stopTimer()
                
            case "exit", "stop"
                ' notify the parent loop that it must exit
                return -254     ' exit intepreter loop
                
            case else:
                return 0        ' ours (ui.*) but not recognised
        end select
        return 1                ' we handled it
    end function        

    sub _defineStyle( id as string, d as DICTSTRING )
        Glyde._applyStyle( @d )
        Dict.set( Glyde._styles, id, d )
    end sub
    
    sub _applyStyle( d as DICTSTRING ptr )
        dim as string sid = Dict.valueOf( *d, "style" )
        if( len( sid ) > 0 ) then
            dim as DICTSTRING style = Dict.valueOf( Glyde._styles, sid )
            dim as string keys()
            dim as integer i, l = Dict.keys( style, keys() )
            for i = 0 to (l - 1)
                if( not Dict.containsKey( *d, keys(i) ) ) then
                    Dict.set( *d, keys(i), Dict.valueOf( style, keys(i) ) )
                end if
            next
        end if
    end sub

    function _doAction( action as string, w as DICTSTRING ptr ) as integer
        dim as string  _
                args = Dict.valueOf( *w, "args", Dict.valueOf( *w, "withargs" ) ),  _
                ok_label = Dict.valueOf( *w, "ondonegoto" )
        dim as string  _
                err_label = Dict.valueOf( *w, "onerrorgoto", ok_label ),  _
                not_label = Dict.valueOf( *w, "onunsupportedgoto", ok_label )
        
        select case action
            case "movewindowto"
                dim as integer b = instr( args, "," )
                if( b > 0 ) then
                    ' 100 is FB.SET_WINDOW_POS from fbgfx.bi
                    screencontrol 100, cint( mid( args, 1, (b - 1) ) ), cint( mid( args, (b + 1) ) )
                    Glue.setRedirectLabel( ok_label )
                else
                    Glue.setRedirectLabel( err_label )
                end if

            case else
                Glue.setRedirectLabel( not_label )
        end select
        return -2
    end function
    
    function _onKeyGoto( key as string, w as DICTSTRING ptr ) as integer
        dim as string code = ""
        if( len( key ) > 0 ) then
            ' use: #nn for asci value nn, $special for "special" codes or any char for that char
            if( key = "##" ) then
                code = "#"
            elseif( asc( key, 1 ) = 35 ) then       ' 35 => #
                code = chr( cint( mid( key, 2 ) ) )
            elseif( asc( key, 1 ) = 36 ) then   ' 36 => $
                key = lcase( mid( key, 2 ) )
                select case key
                    case "escape", "esc"
                        code = chr( 27 )
                    case "enter", "return"
                        code = chr( 13 )
                    case "direction_up"         ' these map to the cursor pad
                        code = "8"
                    case "direction_down"
                        code = "2"
                    case "direction_right"
                        code = "6"
                    case "direction_left"
                        code = "4"
                    case "direction_fire"
                        code = "5"
                    case "morse_key"
                        code = chr( 9 )
                end select
            else
                code = key
            end if
        end if
        if( len( code ) > 0 ) then
            dim as DICTSTRING d = Dict.create()
            Dict.set( d, "label", Dict.valueOf( *w, "goto" ) )
            Dict.set( d, "id", Dict.valueOf( *w, "id" ) )
            Dict.set( Glyde._keymap, code, d )
            return 1
        else
            Utils.echoError( ("[Glyde] Invalid key code: " & key) )
            return 0
        end if
    end function

    function _loadResource( src as string, w as DICTSTRING ptr ) as integer
        dim as string id = Dict.valueOf( *w, "as" )
        if( ImageMap.loadImageMap( id, src ) = 0 ) then
            return 0        ' error
        end if
        return 1
    end function

    function _removeResource( id as string ) as integer
        ImageMap.deleteImageMap( id )
        return 1
    end function

    function _buttonize( id as string, d as DICTSTRING ptr ) as integer
        if( Dict.containsKey( *d, "onclickgoto" ) ) then
            Glyde._addButton( id, d )
        end if
        return TRUE
    end function

    sub _clear()
        'color 0, RGB( 255, 255, 255 )
        'cls
        Glyde._buttons_last = -1
        Glyde._keymap = Dict.create()
        Glyde._ids = Dict.create()
        Glyde._selected = -1
        if( Glyde._draw_context <> 0 ) then
            imagedestroy( Glyde._draw_context )
            Glyde._draw_context = 0
        end if
        if( (Glyde._width > 0) and (Glyde._height > 0) ) then
            Glyde._draw_context = ImageCreate(  _
                    Glyde._width,  _
                    Glyde._height  _
                )
            line Glyde._draw_context, (0, 0)-(Glyde._width, Glyde._height), Glyde._bgcolour, BF
        end if
    end sub
    
    sub _shadeView()
        Glyde._buttons_last = -1
        Glyde._keymap = Dict.create()
        Glyde._ids = Dict.create()
        Glyde._selected = -1
        dim as integer i, e, s
        if( Glyde._width > Glyde._height ) then
            e = (Glyde._width * 2)
            s = Glyde._height
        else
            e = (Glyde._height * 2)
            s = Glyde._width
        end if
        for i = 0 to e step 10
            line Glyde._draw_context, (i, 0)-STEP(-s, s), 0
        next
        ' since this is often used before execution or such we repaint NOW
        Glyde.repaint()
    end sub        
    
    sub _hilight( no_repaint as integer = 0 )
        Glyde.repaint()
    end sub
    
    function _addButton( id as string, d as DICTSTRING ptr ) as integer
        ' allow multiple buttons with the same id..?
        'if( Glyde._buttons_last > -1 ) then
        '    dim as DICTSTRING ptr dp
        '    dim as integer i
        '    for i = 0 to Glyde._buttons_last
        '        dp = @Glyde._buttons(i)
        '        if( Dict.valueOf( *dp, "id" ) = id ) then
        '            Utils.echoError( "[Glyde] Button with id '" & id & "' already defined" )
        '            return FALSE
        '        end if
        '    next
        'end if
        dim as DICTSTRING def = Dict.create()
        Dict.set( def, "id", id )
        dim as integer  _
                x = Dict.intValueOf( *d, "x", Dict.intValueOf( *d, "atx" ) ),  _
                y = Dict.intValueOf( *d, "y", Dict.intValueOf( *d, "aty" ) ),  _
                w = Dict.intValueOf( *d, "width" ),  _
                h = Dict.intValueOf( *d, "height" )
        x += Glyde._offset_x
        y += Glyde._offset_y
        Dict.set( def, "x1", x )
        Dict.set( def, "y1", y )
        Dict.set( def, "x2", (w + x - 1) )
        Dict.set( def, "y2", (h + y - 1) )
        Dict.set( def, "action", Dict.valueOf( *d, "onclickgoto" ) )
        Glyde._buttons_last += 1
        Glyde._buttons(Glyde._buttons_last) = def

        dim as string border = Dict.valueOf( *d, "border", "" )
        if( len( border ) > 0 ) then
            line Glyde._draw_context, (x, y)-STEP (w, h), Glyde._decodeColour( border ), B
        end if

        Glyde.hittest( -1, -1 )      ' draws the rectangles for unhilighted buttons
        
        return TRUE
    end function
    
    function _drawAs( id as string, d as DICTSTRING ptr ) as integer
        Glyde._applyStyle( d )
        return Glyde._createEntityAs( id, d )
    end function
    
    function _writeAs( id as string, d as DICTSTRING ptr ) as integer
        Glyde._applyStyle( d )
        if( Dict.containsKey( *d, "textcolour" ) = FALSE ) then
            Dict.set( *d, "textcolour", Dict.valueOf( *d, "colour" ) )
        end if
        return Glyde._createEntityAs( id, d )
    end function

    function _paintRectAs( id as string, d as DICTSTRING ptr, filled as integer ) as integer
        Glyde._applyStyle( d )
        if( filled ) then
            if( Dict.containsKey( *d, "fillcolour" ) = FALSE ) then
                Dict.set( *d, "fillcolour", Dict.valueOf( *d, "colour" ) )
            end if
        end if
        if( Dict.containsKey( *d, "linecolour" ) = FALSE ) then
            Dict.set( *d, "linecolour", Dict.valueOf( *d, "colour" ) )
        end if
        return Glyde._createEntityAs( id, d )
    end function

    function _markAs( id as string, d as DICTSTRING ptr ) as integer
        Glyde._applyStyle( d )
        if( Glyde._buttonize( id, d ) ) then
            return 1
        end if
        return 0
    end function

    function _createEntityAs( id as string, d as DICTSTRING ptr ) as integer
        dim as integer  _
                x = Dict.intValueOf( *d, "x", Dict.intValueOf( *d, "atx" ) ),  _
                y = Dict.intValueOf( *d, "y", Dict.intValueOf( *d, "aty" ) ),  _
                w = Dict.intValueOf( *d, "width" ),  _
                h = Dict.intValueOf( *d, "height" )
        dim as integer clr
        x += Glyde._offset_x
        y += Glyde._offset_y
        if( Dict.containsKey( *d, "fillcolour" ) ) then
            clr = Glyde._decodeColour( Dict.valueOf( *d, "fillcolour", "#000" ) )
            line Glyde._draw_context, (x, y)-STEP (w, h), clr, BF
        end if
        if( Dict.containsKey( *d, "linecolour" ) ) then
            clr = Glyde._decodeColour( Dict.valueOf( *d, "linecolour", "#000" ) )
            line Glyde._draw_context, (x, y)-STEP (w, h), clr, B
        end if

        if( Dict.containsKey( *d, "id" ) ) then
            dim as string entity = Dict.valueOf( *d, "id" )
            dim as integer i = instr( entity, "." )
            if( i > 0 ) then
                dim as string map = mid( entity, 1, (i - 1) )
                dim as string seg = mid( entity, (i + 1) )
                if( ImageMap.drawSegmentTo( Glyde._draw_context, map, seg, x, y, 0 ) ) then      ' align is disabled
                    Dict.set( *d, "width", ImageMap.getSegmentValue( map, seg, ImageMap.S_WIDTH ) )
                    Dict.set( *d, "height", ImageMap.getSegmentValue( map, seg, ImageMap.S_HEIGHT ) )
                end if
            else
                Utils.echoError( ("[Glyde] Invalid entity id: " & entity) )            
                return 0
            end if
        end if
        
        if( Dict.containsKey( *d, "value" ) ) then
            clr = Glyde._decodeColour( Dict.valueOf( *d, "textcolour", "#000" ) )
            dim as integer  _
                size = Dict.intValueOf( *d, "size", 2 ),  _
                thickness = Dict.intValueOf( *d, "thickness", 2 )
            dim as string text = Dict.valueOf( *d, "value", Dict.valueOf( *d, "text" ) )
            dim as string align = Dict.valueOf( *d, "align", "2" )
            if( (align = "2") or (align = "centre") ) then
                x += ((w - (VecText.getGlyphWidth( size, thickness ) * len( text ))) / 2)
            elseif( (align = "1") or (align = "right") ) then
                x += ((w - (VecText.getGlyphWidth( size, thickness ) * len( text ))))
            end if
            y += ((h - VecText.getGlyphHeight( size, thickness )) / 2)
            VecText.useContext( Glyde._draw_context )
            VecText.drawString( text, clr, x, y, size, thickness, thickness )
            if( Dict.intValueOf( *d, "width" ) = 0 ) then
                Dict.set( *d, "width", (VecText.getGlyphWidth( size, thickness ) * len( text )) )
            end if
            if( Dict.intValueOf( *d, "height" ) = 0 ) then
                Dict.set( *d, "height", VecText.getGlyphHeight( size, thickness ) )
            end if
        end if
        if( Glyde._buttonize( id, d ) ) then
            return 1
        end if
        return 0
    end function
    
    function _decodeColour( clr as string ) as integer
        if( asc( clr, 1 ) = asc( "#" ) ) then
            clr = mid( clr, 2 )
        end if
        if( len( clr ) = 3 ) then
            return RGB(   _
                    val( ("&h" & mid( clr, 1, 1 ) & mid( clr, 1, 1 )) ),  _
                    val( ("&h" & mid( clr, 2, 1 ) & mid( clr, 2, 1 )) ),  _
                    val( ("&h" & mid( clr, 3, 1 ) & mid( clr, 3, 1 )) )  _
                )
        elseif( len( clr ) = 6 ) then
            return RGB(   _
                    val( ("&h" & mid( clr, 1, 2 )) ),  _
                    val( ("&h" & mid( clr, 3, 2 )) ),  _
                    val( ("&h" & mid( clr, 5, 2 )) )  _
                )
        end if
        return 0
    end function
        
    sub _startTimer( interval as integer, label as string )
        Glyde._timer_interval = interval
        Glyde._timer_label = label
        Glyde._timer_next = (timer() + (interval / 10))
    end sub
    
    sub _stopTimer()
        Glyde._timer_next = -1
    end sub

    function checkTimer() as integer
        if( Glyde._timer_next > -1 ) then
            if( timer() >= Glyde._timer_next ) then
                Glyde._timer_next = (timer() + (Glyde._timer_interval / 10))
                return TRUE
            end if
        end if
        return FALSE
    end function
    
    function getTimerLabel() as string
        return Glyde._timer_label
    end function
    
end namespace
