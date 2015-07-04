
namespace UI
    declare function glueCommand( byref w as string, byref vars as string ) as integer
    declare function getValue() as string
    declare function ask( prompt as string, value as string ) as integer        
    
    dim as integer _cols, _rows, _bgclr
    dim as integer _edit_x, _edit_y, _edit_w
    dim as integer _b1x, _b2x, _by
    dim as string _value
    dim as integer _inited
    
    function init() as integer
        UI._cols = LOWORD( width() )
        UI._rows = HIWORD( width() )
        UI._bgclr = 0
        if( not UI._inited ) then
            UI._inited = TRUE
            return Glue.addPlugin( @UI.glueCommand )
        end if
        return TRUE
    end function
    
   function glueCommand( byref w as string, byref vars as string ) as integer
        dim c as string = Dict.valueOf( w, "_" ), cs as string
        dim ts as string, tn as single, ti as integer
        if( instrrev( c, "ui.", 1 ) > 0 ) then
            cs = mid( c, 4 )
        else
            return -1
        end if
        dim as string vv = Dict.valueOf( w, c )
        dim as string into = Dict.valueOf( w, "into" )
        select case cs
            case "ask"
                if( UI.ask( vv, Dict.valueOf( vv, "value" ) ) ) then
                    Glue.setRedirectLabel( Dict.valueOf( vv, "ondonegoto" ) )
                else
                    Glue.setRedirectLabel( Dict.valueOf( vv, "oncancelgoto" ) )
                end if
                return Glue.PLUGIN_INLINE_REDIRECT
                
            case "getlastvalue"
                SET_INTO( UI.getValue() )
                
            case else:
                return 0        ' ours (ui.*) but not recognised
        end select
        return 1                ' we handled it
    end function  
    
    function getValue() as string
        return UI._value
    end function
    
    sub drawBox( prompt as string, vrows as integer, okcancel as integer = TRUE )
        'color 15, UI._bgclr
        'cls
        
        dim as integer w = 50'(cols * 3) / 4
        dim as integer h = (6 + vrows)
        dim as integer x = ((UI._cols - w) / 2)
        dim as integer y = ((UI._rows - h) / 2)
        dim as integer i
        
        if( x < 1 ) then
            x = 1
        end if
        if( y < 1 ) then
            y = 1
        end if
        
        dim as string value
        
        color 0, 7
        for i = 0 to h
            locate (y + i), x
            print space( w );
        next
        if( y = 1 ) then
            locate 1, 1
            color 15, 1
            print space( w );
            color 0, 7
        end if

        x += 2
        y += 2
        locate y, x
        print prompt;
        
        color 15, 8
        UI._by = (y + vrows + 3)        
        UI._b1x = ((x + w) - 29)
        if( okcancel ) then
            locate UI._by, UI._b1x
            print "[    OK    ]";
            UI._b1x -= 1        ' for mouse code
        end if
        
        UI._b2x = (UI._b1x + 14)
        locate UI._by, UI._b2x
        if( okcancel ) then
            print "[  Cancel  ]";
        else
            print "[    OK    ]";
        end if
        UI._b2x -= 1        ' for mouse code
        
        y += 2
        w -= 4
        UI._edit_x = x
        UI._edit_y = y
        UI._edit_w = w
        if( okcancel ) then
            color 14, 0
            for i = 1 to vrows
                locate y, x
                print space( w );
                y += 1
            next
        else
            color 0, 7
        end if
    end sub
    
    function ask( prompt as string, value as string ) as integer        
        dim as string origvalue = value
        
        dim as string c, pr, padding = space( UI._edit_w )
        dim as integer vw = UI._edit_w, lv = 1, ac, cpos = len( value )
        dim as integer result, tcount = 0, leftpos = 1
        dim as string curs = "<"
        dim as integer mx, my, mb
        
        UI.drawBox( prompt, 1 )
        while( 1 )
            ' put the cursor into the value
            dim as string lhs = mid( value, 1, cpos )
            dim as string rhs = mid( value, (cpos + 1) )
            pr = (lhs + curs + rhs)
        
            ' fiddle with the output string to ensure the cursor is visible
            ' and it's the correct width
            if( cpos >= (UI._edit_w - 1) ) then
                leftpos = (cpos - UI._edit_w + 2)
            elseif( len( pr ) > UI._edit_w ) then
                leftpos = 1
            end if
            pr = mid( pr, leftpos, (UI._edit_w + 1) )
            
            ' output the display
            locate UI._edit_y, UI._edit_x
            print pr; mid( padding, len( pr ) );
            locate UI._rows, UI._cols
            'process keys
            dim as integer msfx = 1, msfy = 1
            if( screenptr() <> 0 ) then
                msfx = 8
                msfy = 16
            end if
            c = ""
            while( c = "" )
                c = inkey()
                sleep 20, 1
                tcount += 1
                if( tcount > 20 ) then
                    tcount = 0
                    if( curs = "<" ) then
                        curs = "_"
                    else
                        curs = "<"
                    end if
                    exit while
                end if
                getmouse( mx, my, , mb )
                if( mb > 0 ) then
                    while( mb > 0 )
                        getmouse( mx, my, , mb )
                        sleep 20, 1
                    wend
                    mx \= msfx
                    my \= msfy
                    my += 1
                    if( (my = UI._edit_y) ) then
                        mx += 1
                        if( (mx >= UI._edit_x) and (mx <= (UI._edit_x + UI._edit_w)) ) then
                            'locate my, mx
                            'print "x"
                            if( (leftpos + (mx - UI._edit_x)) > cpos ) then
                                mx -= 1
                            end if
                            cpos = (leftpos + (mx - UI._edit_x) - 1)
                            if( cpos > len( value ) ) then
                                cpos = len( value )
                            end if
                            exit while
                        end if
                    end if
                    if( my = UI._by ) then
                        if( (mx >= UI._b1x) and (mx < (UI._b1x + 12)) ) then
                            c = chr( 13 )
                            exit while
                        end if
                        if( (mx >= UI._b2x) and (mx < (UI._b2x + 12)) ) then
                            c = chr( 27 )
                            exit while
                        end if
                    end if
                end if
                    
            wend
            if( len( c ) = 1 ) then
                ac = asc( c )
                if( ac < 32 ) then
                    select case ac
                        case 8:
                            if( cpos > 0 ) then
                                value = (mid( lhs, 1, (cpos - 1) ) + rhs)
                                cpos -= 1
                            end if
                        case 13:
                            UI._value = value
                            result = 1
                            exit while
                        case 27:
                            UI._value = ""
                            result = 0
                            exit while
                    end select
                else
                    lv += 1
                    cpos += 1
                    value = (lhs + c + rhs)
                end if
            else
                ' 75 is left, 77 right, 72 up, 80 down
                select case( asc( c, 2 ) )
                    case 72:    'up
                        value = origvalue
                        cpos = len( value )
                    case 80:    'down
                        value = ""
                        cpos = 0
                    case 75:    'left
                        if( cpos > 0 ) then
                            cpos -= 1
                        end if
                    case 77:    'right
                        if( cpos < len( value ) ) then
                            cpos += 1
                        end if
                    case 83:    'del
                        if( len( rhs ) >= 1 ) then
                            value = (lhs & mid( rhs, 2 ))
                        end if
                    case 71:    'home
                        cpos = 0
                    case 79:    'end
                        cpos = len( value )
                end select
            end if
        wend
        return result
    end function
    
    function choose( prompt as string, itemsdict as DICTSTRING, orig_sel as integer = 0 ) as integer
        dim as integer items_last = (Dict.intValueOf( itemsdict, "count" ) - 1)
        dim as string items((items_last + 1))
        dim as string value
        
        dim as integer i
        for i = 0 to items_last
            items(i) = Dict.valueOf( itemsdict, str( i ) )
        next
        
        dim as integer lines = 10
        dim as integer y = UI._edit_y
        dim as string lval
        UI.drawBox( prompt, lines )
        
        'dim as integer bux, buy
        'dim as integer bdx, bdy
        
        'color 7, 7
        'for i = 0 to lines
        '    locate (UI._edit_y + i), (UI._edit_x + UI._edit_w - 3)
        '    print "   "
        'next
        'color 15, 8
        'buy = UI._edit_y
        'bux = (UI._edit_x + UI._edit_w - 2)
        'locate buy, bux
        'print "/\"
        'bdy = (UI._edit_y + lines - 1)
        'bdx = (UI._edit_x + UI._edit_w - 2)
        'locate bdy, bdx
        'print "\/"
        
        'dim as integer iwidth = (UI._edit_w - 3)
        dim as integer iwidth = UI._edit_w
        dim as integer sel = orig_sel, result
        dim as string key
        dim as integer mx, my, mb, mw, omw
        dim as integer  _
                lst_x1 = UI._edit_x,  _
                lst_y1 = UI._edit_y,  _
                lst_x2 = (UI._edit_x + iwidth),  _
                lst_y2 = (UI._edit_y + lines)
        dim as integer msfx = 1, msfy = 1
        if( screenptr() <> 0 ) then
            msfx = 8
            msfy = 16
        end if
        while( TRUE )
            y = UI._edit_y
            for i = (sel - 1) to (sel + lines - 2)
                locate y, UI._edit_x
                if( (i >= 0) and (i <= items_last) ) then
                    lval = items(i)
                else
                    lval = string( iwidth, ":" )
                end if
                if( i = sel ) then
                    color 0, 14
                else
                    color 14, 0
                end if
                print lval; space( (iwidth - len( lval )) );
                y += 1
            next
            locate UI._rows, UI._cols
            
            key = ""
            while( key = "" )
                key = inkey()
                sleep 20, 1
                getmouse( mx, my, mw, mb )
                if( (mw <> omw) and (mx <> -1) ) then
                    if( mw < omw ) then
                        key = (chr( 255 ) + chr( 80 ))
                    elseif( mw > omw ) then
                        key = (chr( 255 ) + chr( 72 ))
                    end if
                    omw = mw
                    exit while
                end if
                if( mb <> 0 ) then
                    while( mb <> 0 )
                        getmouse( mx, my, , mb )
                    wend
                    mx \= msfx
                    my \= msfy
                    mx += 1
                    my += 1
                    if( (mx >= lst_x1) and (mx < lst_x2) ) then
                        if( (my >= lst_y1) and (my < lst_y2) ) then
                            locate my, mx
                            sel += ((my - lst_y1) - 1)
                            if( sel < 0 ) then
                                sel = 0
                            end if
                            if( sel > items_last ) then
                                sel = items_last
                            end if
                            exit while
                        end if
                    end if
                    if( my = UI._by ) then
                        if( (mx >= UI._b1x) and (mx < (UI._b1x + 12)) ) then
                            key = chr( 13 )
                            exit while
                        end if
                        if( (mx >= UI._b2x) and (mx < (UI._b2x + 12)) ) then
                            key = chr( 27 )
                            exit while
                        end if
                    end if                
                end if
            wend
            
            select case( asc( key, 1 ) )
                case 13, 10:
                    result = sel
                    UI._value = items(sel)
                    exit while
                case 27:
                    result = -1
                    UI._value = ""
                    exit while
                case 255:
                    select case( asc( key, 2 ) )
                        case 72:
                            if( sel > 0 ) then
                                sel -= 1
                            end if
                        case 80:
                            if( sel < items_last ) then
                                sel += 1
                            end if
                    end select
            end select
            
        wend
        return result
    end function
    
    function tell( prompt as string, value as string ) as integer        
        dim as string c, pr, padding = space( UI._edit_w )
        dim as integer result, ac
        dim as integer mx, my, mb
        
        dim as string lines(20)
        dim as integer lines_count = 0
        
        value &= "//"
        dim as integer s = 1, e = instr( value, "//" )
        while( e > 0 )
            lines(lines_count) = mid( value, s, (e - s) )
            s = (e + 2)
            e = instr( s, value, "//" )
            lines_count += 1
        wend
        
        UI.drawBox( prompt, lines_count, FALSE )
        color 8, 7
        for e = 0 to (lines_count - 1)
            locate (UI._edit_y + e), UI._edit_x
            print lines(e);
        next
        locate UI._rows, UI._cols
        
        while( 1 )
            'process keys
            dim as integer msfx = 1, msfy = 1
            if( screenptr() <> 0 ) then
                msfx = 8
                msfy = 16
            end if
            c = ""
            while( c = "" )
                c = inkey()
                sleep 20, 1
                getmouse( mx, my, , mb )
                if( mb > 0 ) then
                    while( mb > 0 )
                        getmouse( mx, my, , mb )
                        sleep 20, 1
                    wend
                    mx \= msfx
                    my \= msfy
                    my += 1
                    if( my = UI._by ) then
                        if( (mx >= UI._b2x) and (mx < (UI._b2x + 12)) ) then
                            c = chr( 27 )
                            exit while
                        end if
                    end if
                end if
                    
            wend
            if( len( c ) = 1 ) then
                ac = asc( c )
                if( ac < 32 ) then
                    select case ac
                        case 13, 27:
                            UI._value = ""
                            result = 1
                            exit while
                    end select
                end if
            end if
        wend
        return result
    end function
    
    function countLines( value as string ) as integer
        if( value = "" ) then
            return 0
        end if
        dim as integer lines_count = 1
        dim as integer e = instr( value, "//" )
        while( e > 0 )
            e = instr( (e + 2), value, "//" )
            lines_count += 1
        wend
        return lines_count
    end function
end namespace
