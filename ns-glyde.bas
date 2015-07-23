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
            D_SHOW_HITZONES       = "hitzones.show",  _
            D_HILITE_COLOUR       = "colour.hilite",  _
            D_CONSOLE_USE_ANSI    = "tty.ansi"
            
    declare function init() as integer
    declare function readConfigFile( src as string ) as DICTSTRING
    declare function hittest( x as integer, y as integer ) as DICTSTRING ptr        ' POINTER!
    declare function keytest( keycode as string ) as DICTSTRING
    declare sub setData( key as string, value as string )
    declare function getData( key as string, def as string = "" ) as string
    declare sub hilightNext()
    declare function getHilightedAction() as string
    declare function morseKeyPressed() as string
    declare sub repaint()
    declare function checkTimer() as integer
    declare function getTimerLabel() as string
    declare function loadSettings() as integer
    declare function glueCommand( byref w as string, byref vars as string ) as integer
    declare function _setViewSpecs( specs as DICTSTRING ptr ) as integer
    declare function _loadResource( src as string, w as DICTSTRING ptr ) as integer
    declare function _removeResource( id as string ) as integer
    declare function _buttonize( id as string, d as DICTSTRING ptr ) as integer
    declare function _drawAs( id as string, d as DICTSTRING ptr ) as integer
    declare function _writeAs( id as string, d as DICTSTRING ptr ) as integer
    declare function _markAs( id as string, d as DICTSTRING ptr ) as integer
    declare function _paintRectAs( id as string, d as DICTSTRING ptr, filled as integer ) as integer
    declare function _createEntityAs( id as string, d as DICTSTRING ptr ) as integer
    declare sub _drawBorder( x as integer, y as integer, w as integer, h as integer, border as string )
    declare sub _repaint()
    declare sub _hilight( no_repaint as integer = 0 )
    declare sub _clear()
    declare sub _clearView()
    declare sub _shadeView()
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

    function getData( key as string, def as string = "" ) as string
        return Dict.valueOf( Glyde._data, key, def )
    end function
    
    sub setData( key as string, value as string )
        Dict.set( Glyde._data, key, value )
    end sub

    sub repaint()
        Glyde._repaint()
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
        Glyde._repaint()
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
                Dict.set( w, "width", vv )
                if( Glyde._setViewSpecs( @w ) = FALSE ) then
                    return 0
                end if
                
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

    function _buttonize( id as string, d as DICTSTRING ptr ) as integer
        if( Dict.containsKey( *d, "onclickgoto" ) ) then
            Glyde._addButton( id, d )
        end if
        return TRUE
    end function

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
            Glyde._drawBorder( x, y, w, h, border )
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

    sub _clear()
        Glyde._buttons_last = -1
        Glyde._keymap = Dict.create()
        Glyde._ids = Dict.create()
        Glyde._selected = -1        
        Glyde._clearView()
    end sub

    sub _startTimer( interval as integer, label as string )
        Glyde._timer_interval = interval
        Glyde._timer_label = label
        Glyde._timer_next = (timer() + (interval / 10))
    end sub

    sub _stopTimer()
        Glyde._timer_next = -1
    end sub
end namespace
