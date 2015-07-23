namespace Glyde
    dim as integer _hilight_clr
    
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
    
    function loadSettings() as integer
        Glyde._hilight_clr = Glyde._decodeColour( Glyde.getData( Glyde.D_HILITE_COLOUR, "#f00" ) )
        return VecText.init()
    end function
    
    function _setViewSpecs( specs as DICTSTRING ptr ) as integer
        Glyde._width = Dict.intValueOf( *specs, "width" )
        Glyde._height = Dict.intValueOf( *specs, "height" )
        dim as integer vf = (  _
                Dict.intValueOf( *specs, "flags", 0 ) or   _
                val( Glyde.getData( Glyde.D_WINDOW_FLAGS ) )  _
            )
        if( (Glyde._width > 0) and (Glyde._height > 0) ) then
            screenres Glyde._width, Glyde._height, 32, , vf
        else
            Utils.echoError( ("[Glyde] Invalid View: w=" & Glyde._width & "; h=" & Glyde._height & "; f=" & vf) )
            return FALSE
        end if
        Glyde._bgcolour = Glyde._decodeColour( Dict.valueOf( *specs, "backgroundcolour", "#fff" ) )
        Glyde._clr_1 = Glyde._decodeColour( Dict.valueOf( *specs, "hilight", "#f00" ) )
        Glyde._clr_0 = Glyde._decodeColour( Dict.valueOf( *specs, "border", "#000" ) )
        Glyde._clear()
        return TRUE
    end function
    
    sub _repaint()
        if( Glyde._draw_context <> 0 ) then
            put (0, 0), Glyde._draw_context, PSet
            if( Glyde._buttons_last > -1 ) then        
                dim as integer i
                for i = 0 to Glyde._buttons_last
                    dim as DICTSTRING ptr dp = @Glyde._buttons(i)
                    dim as integer   _
                            x1 = Dict.intValueOf( *dp, "x1" ),  _
                            y1 = Dict.intValueOf( *dp, "y1" ),  _
                            x2 = Dict.intValueOf( *dp, "x2" ),  _
                            y2 = Dict.intValueOf( *dp, "y2" )
                    if( i = Glyde._selected ) then
                        line (x1,y1)-(x2,y2), Glyde._hilight_clr, B
                        line ((x1+1),(y1+1))-((x2-1),(y2-1)), Glyde._hilight_clr, B
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

    sub _clearView()
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
        Glyde._repaint()
    end sub        
    
    sub _hilight( no_repaint as integer = 0 )
        Glyde._repaint()
    end sub
    
    sub _drawBorder( x as integer, y as integer, w as integer, h as integer, border as string )
        line Glyde._draw_context, (x, y)-STEP (w, h), Glyde._decodeColour( border ), B
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
                    w = ImageMap.getSegmentValue( map, seg, ImageMap.S_WIDTH )
                    h = ImageMap.getSegmentValue( map, seg, ImageMap.S_HEIGHT )
                    Dict.set( *d, "width", w )
                    Dict.set( *d, "height", h )
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
end namespace

