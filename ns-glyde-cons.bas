namespace Glyde
    dim as string _res_images(5)
    
    ' this returns a pointer to save allocating memory
    function hittest( x as integer, y as integer ) as DICTSTRING ptr
        dim as DICTSTRING ptr result = 0
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
                    
                    'todo: hilight?
                    'line (x1,y1)-(x2,y2), clr, B
                    'line ((x1+1),(y1+1))-((x2+1),(y2+1)), clr, B
                end if
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
    
    function _setViewSpecs( specs as DICTSTRING ptr ) as integer
        dim as integer w = width()
        Glyde._width = LOWORD( w )
        Glyde._height = HIWORD( w )
        Glyde._clr_1 = 9
        Glyde._clr_0 = 0
                
'        Glyde._width = Dict.intValueOf( *specs, "width" )
'        Glyde._height = Dict.intValueOf( *specs, "height" )
'        dim as integer vf = (  _
'                Dict.intValueOf( *specs, "flags", 0 ) or   _
'                val( Glyde.getData( Glyde.D_WINDOW_FLAGS ) )  _
'            )
'        if( (Glyde._width > 0) and (Glyde._height > 0) ) then
'            screenres Glyde._width, Glyde._height, 32, , vf
'        else
'            Utils.echoError( ("[Glyde] Invalid View: w=" & Glyde._width & "; h=" & Glyde._height & "; f=" & vf) )
'            return FALSE
'        end if
'        Glyde._bgcolour = Glyde._decodeColour( Dict.valueOf( *specs, "background", "#fff" ) )
'        Glyde._clr_1 = Glyde._decodeColour( Dict.valueOf( *specs, "hilight", "#f00" ) )
'        Glyde._clr_0 = Glyde._decodeColour( Dict.valueOf( *specs, "border", "#000" ) )
        Glyde._clear()
        return TRUE
    end function
    
    sub _repaint()
        dim as ubyte ptr restr = 0
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
                    restr = ConsoleBuffer.saveBuffers()
                    clr = Glyde._clr_1
                    ConsoleBuffer.drawBox( x1, y1, (x2 - x1), (y2 - y1), clr, FALSE )
                end if
            next
        end if
        ConsoleBuffer.display()
        if( restr <> 0 ) then
            ' restore the buffer to the non-hilighted version
            ConsoleBuffer.loadBuffers( restr )
            deallocate( restr )
            restr = 0
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
                    ' no action is available but the command is kept as valid, maybe
                    ' use to set some form of offsets?
                    Glue.setRedirectLabel( ok_label )
                else
                    Glue.setRedirectLabel( err_label )
                end if

            case else
                Glue.setRedirectLabel( not_label )
        end select
        return -2
    end function
    
    function _loadResource( src as string, w as DICTSTRING ptr ) as integer
        ' TODO: need to provide custom imagemap support
        'dim as string id = Dict.valueOf( *w, "as" )
        'if( ImageMap.loadImageMap( id, src ) = 0 ) then
        '    return 0        ' error
        'end if
        return 1
    end function

    function _removeResource( id as string ) as integer
        ' TODO: provide imagemap support
        'ImageMap.deleteImageMap( id )
        return 1
    end function

    sub _clear()
        ConsoleBuffer.wipe( Glyde._bgcolour )
    end sub
    
    sub _shadeView()
        Glyde._buttons_last = -1
        Glyde._keymap = Dict.create()
        Glyde._ids = Dict.create()
        Glyde._selected = -1
        dim as ubyte ptr disp = ConsoleBuffer.saveBuffers()
        ' format is "textbuffer|clrbuffer"
        dim as integer w = ConsoleBuffer.getWidth()
        dim as integer h = ConsoleBuffer.getHeight()
        dim as integer size = (w * h)
        dim as integer y, x, offset
        for y = 0 to h step 2
            offset = (y * w)
            for x = 0 to w
                disp[(offset + x)] = asc( "/" )
                disp[(offset + x + size)] = 0
            next
        next
        ' load the modified buffers
        ConsoleBuffer.loadBuffers( disp )
        deallocate( disp )
        disp = 0
        ' since this is often used before execution or such we repaint NOW
        Glyde._repaint()
    end sub        
    
    sub _hilight( no_repaint as integer = 0 )
        Glyde._repaint()
    end sub
    
    sub _drawBorder( x as integer, y as integer, w as integer, h as integer, border as string )
        ConsoleBuffer.drawBox( x, y, w, h, Glyde._decodeColour( border ), FALSE )
    end sub
    
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
            clr = Glyde._decodeColour( Dict.valueOf( *d, "fillcolour", "0" ) )
            ConsoleBuffer.drawBox( x, y, w, h, clr, TRUE )
        end if
        if( Dict.containsKey( *d, "linecolour" ) ) then
            clr = Glyde._decodeColour( Dict.valueOf( *d, "linecolour", "0" ) )
            ConsoleBuffer.drawBox( x, y, w, h, clr, FALSE )
        end if

        if( Dict.containsKey( *d, "id" ) ) then
            dim as string entity = Dict.valueOf( *d, "id" )
            dim as integer i = instr( entity, "." )
            if( i > 0 ) then
                dim as string map = mid( entity, 1, (i - 1) )
                dim as string seg = mid( entity, (i + 1) )
                ' TODO: custom imagemap implementation
'                if( ImageMap.drawSegmentTo( Glyde._draw_context, map, seg, x, y, 0 ) ) then      ' align is disabled
'                    Dict.set( *d, "width", ImageMap.getSegmentValue( map, seg, ImageMap.S_WIDTH ) )
'                    Dict.set( *d, "height", ImageMap.getSegmentValue( map, seg, ImageMap.S_HEIGHT ) )
'                end if
            else
                Utils.echoError( ("[Glyde] Invalid entity id: " & entity) )            
                return 0
            end if
        end if
        
        if( Dict.containsKey( *d, "value" ) ) then
            clr = Glyde._decodeColour( Dict.valueOf( *d, "textcolour", "0" ) )
            dim as integer  _
                size = Dict.intValueOf( *d, "size", 2 ),  _
                thickness = Dict.intValueOf( *d, "thickness", 2 )
            dim as string text = Dict.valueOf( *d, "value", Dict.valueOf( *d, "text" ) )
            dim as string align = Dict.valueOf( *d, "align", "2" )
            if( (align = "2") or (align = "centre") ) then
                x += ((w - len( text )) / 2)
            elseif( (align = "1") or (align = "right") ) then
                x += (w - len( text ))
            end if
            y += ((h - 1) / 2)      ' TODO: do we need the -1?
            ConsoleBuffer.writeText( text, x, y, clr, -1 )
            if( Dict.intValueOf( *d, "width" ) = 0 ) then
                Dict.set( *d, "width", len( text ) )
            end if
            if( Dict.intValueOf( *d, "height" ) = 0 ) then
                Dict.set( *d, "height", 1 )
            end if
        end if
        if( Glyde._buttonize( id, d ) ) then
            return 1
        end if
        return 0
    end function
    
    function _decodeColour( clr as string ) as integer
        return val( clr )
    end function
end namespace

