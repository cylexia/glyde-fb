#include "../lib/libmain.bas"

namespace StdUI

    dim as integer _cols, _rows, _bgclr
    dim as integer _edit_x, _edit_y, _edit_w
    dim as integer _b1x, _b2x, _by
    dim as string _value
    
    function init( bgclr as integer ) as integer
        StdUI._cols = LOWORD( width() )
        StdUI._rows = HIWORD( width() )
        StdUI._bgclr = bgclr
        return TRUE
    end function
    
    function getValue() as string
        return StdUI._value
    end function
    
    sub drawBox( prompt as string, vrows as integer, okcancel as integer = TRUE )
        color 15, StdUI._bgclr
        cls
        
        dim as integer w = 50'(cols * 3) / 4
        dim as integer h = (6 + vrows)
        dim as integer x = ((StdUI._cols - w) / 2)
        dim as integer y = ((StdUI._rows - h) / 2)
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
        StdUI._by = (y + vrows + 3)        
        StdUI._b1x = ((x + w) - 29)
        if( okcancel ) then
            locate StdUI._by, StdUI._b1x
            print "[    OK    ]";
            StdUI._b1x -= 1        ' for mouse code
        end if
        
        StdUI._b2x = (StdUI._b1x + 14)
        locate StdUI._by, StdUI._b2x
        if( okcancel ) then
            print "[  Cancel  ]";
        else
            print "[    OK    ]";
        end if
        StdUI._b2x -= 1        ' for mouse code
        
        y += 2
        w -= 4
        StdUI._edit_x = x
        StdUI._edit_y = y
        StdUI._edit_w = w
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
        
        dim as string c, pr, padding = space( StdUI._edit_w )
        dim as integer vw = StdUI._edit_w, lv = 1, ac, cpos = len( value )
        dim as integer result, tcount = 0, leftpos = 1
        dim as string curs = "<"
        dim as integer mx, my, mb
        
        StdUI.drawBox( prompt, 1 )
        while( 1 )
            ' put the cursor into the value
            dim as string lhs = mid( value, 1, cpos )
            dim as string rhs = mid( value, (cpos + 1) )
            pr = (lhs + curs + rhs)
        
            ' fiddle with the output string to ensure the cursor is visible
            ' and it's the correct width
            if( cpos >= (StdUI._edit_w - 1) ) then
                leftpos = (cpos - StdUI._edit_w + 2)
            elseif( len( pr ) > StdUI._edit_w ) then
                leftpos = 1
            end if
            pr = mid( pr, leftpos, (StdUI._edit_w + 1) )
            
            ' output the display
            locate StdUI._edit_y, StdUI._edit_x
            print pr; mid( padding, len( pr ) );
            locate StdUI._rows, StdUI._cols
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
                    if( (my = StdUI._edit_y) ) then
                        mx += 1
                        if( (mx >= StdUI._edit_x) and (mx <= (StdUI._edit_x + StdUI._edit_w)) ) then
                            'locate my, mx
                            'print "x"
                            if( (leftpos + (mx - StdUI._edit_x)) > cpos ) then
                                mx -= 1
                            end if
                            cpos = (leftpos + (mx - StdUI._edit_x) - 1)
                            if( cpos > len( value ) ) then
                                cpos = len( value )
                            end if
                            exit while
                        end if
                    end if
                    if( my = StdUI._by ) then
                        if( (mx >= StdUI._b1x) and (mx < (StdUI._b1x + 12)) ) then
                            c = chr( 13 )
                            exit while
                        end if
                        if( (mx >= StdUI._b2x) and (mx < (StdUI._b2x + 12)) ) then
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
                            StdUI._value = value
                            result = 1
                            exit while
                        case 27:
                            StdUI._value = ""
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
        dim as integer y = StdUI._edit_y
        dim as string lval
        StdUI.drawBox( prompt, lines )
        
        'dim as integer bux, buy
        'dim as integer bdx, bdy
        
        'color 7, 7
        'for i = 0 to lines
        '    locate (StdUI._edit_y + i), (StdUI._edit_x + StdUI._edit_w - 3)
        '    print "   "
        'next
        'color 15, 8
        'buy = StdUI._edit_y
        'bux = (StdUI._edit_x + StdUI._edit_w - 2)
        'locate buy, bux
        'print "/\"
        'bdy = (StdUI._edit_y + lines - 1)
        'bdx = (StdUI._edit_x + StdUI._edit_w - 2)
        'locate bdy, bdx
        'print "\/"
        
        'dim as integer iwidth = (StdUI._edit_w - 3)
        dim as integer iwidth = StdUI._edit_w
        dim as integer sel = orig_sel, result
        dim as string key
        dim as integer mx, my, mb, mw, omw
        dim as integer  _
                lst_x1 = StdUI._edit_x,  _
                lst_y1 = StdUI._edit_y,  _
                lst_x2 = (StdUI._edit_x + iwidth),  _
                lst_y2 = (StdUI._edit_y + lines)
        dim as integer msfx = 1, msfy = 1
        if( screenptr() <> 0 ) then
            msfx = 8
            msfy = 16
        end if
        while( TRUE )
            y = StdUI._edit_y
            for i = (sel - 1) to (sel + lines - 2)
                locate y, StdUI._edit_x
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
            locate StdUI._rows, StdUI._cols
            
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
                    if( my = StdUI._by ) then
                        if( (mx >= StdUI._b1x) and (mx < (StdUI._b1x + 12)) ) then
                            key = chr( 13 )
                            exit while
                        end if
                        if( (mx >= StdUI._b2x) and (mx < (StdUI._b2x + 12)) ) then
                            key = chr( 27 )
                            exit while
                        end if
                    end if                
                end if
            wend
            
            select case( asc( key, 1 ) )
                case 13, 10:
                    result = sel
                    StdUI._value = items(sel)
                    exit while
                case 27:
                    result = -1
                    StdUI._value = ""
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
        dim as string c, pr, padding = space( StdUI._edit_w )
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
        
        StdUI.drawBox( prompt, lines_count, FALSE )
        color 8, 7
        for e = 0 to (lines_count - 1)
            locate (StdUI._edit_y + e), StdUI._edit_x
            print lines(e);
        next
        locate StdUI._rows, StdUI._cols
        
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
                    if( my = StdUI._by ) then
                        if( (mx >= StdUI._b2x) and (mx < (StdUI._b2x + 12)) ) then
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
                            StdUI._value = ""
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

dim as DICTSTRING args = Utils.parseCommandLine()

dim as integer bgclr = Dict.intValueOf( args, "bgclr", 1 )

dim as string prompt
dim as integer result
dim as string value

select case Dict.valueOf( args, "_" )
    case "choose":
        ' dialog:
        dim as integer sw = (50 * 8), sh = (17 * 16)        ' use 8 for height for ask
        screenres sw, sh, , , (&h04 or &h20 or &h08) 'no fullscreen, always on top, no frame
        width (sw\8),(sh\16)
        
        dim as DICTSTRING itemsdict
        itemsdict = Utils.split( Dict.valueOf( args, "items" ), "/" )
        prompt = Dict.valueOf( args, "prompt", "Select an item" )
        StdUI.init( bgclr )
        result = StdUI.choose( prompt, itemsdict, Dict.intValueOf( args, "value" ) )
        if( result = -1 ) then
            value = ""
            result = 0
        else
            value = str( result )
            result = 1
        end if
        
    case "ask":
        ' dialog:
        prompt = Dict.valueOf( args, "prompt", "Enter a value" )
        dim as integer sw = (50 * 8), sh = (8 * 16)        ' use 8 for height for ask
        screenres sw, sh, , , (&h04 or &h20 or &h08) 'no fullscreen, always on top, no frame
        width (sw\8),(sh\16)
        
        StdUI.init( bgclr )
        result = StdUI.ask(   _
                Dict.valueOf( args, "prompt" ),  _
                Dict.valueOf( args, "value" )  _
            )
        value = StdUI.getValue()
    
    case "tell"
        ' dialog:
        prompt = Dict.valueOf( args, "prompt", "Enter a value" )
        value = Dict.valueOf( args, "value" )
        dim as integer lines_count = StdUI.countLines( value )
        dim as integer sw = (50 * 8), sh = ((7 + lines_count) * 16) '7 is for chrome
        screenres sw, sh, , , (&h04 or &h20 or &h08) 'no fullscreen, always on top, no frame
        width (sw\8),(sh\16)
        
        StdUI.init( bgclr )
        result = StdUI.tell(   _
                Dict.valueOf( args, "prompt" ),  _
                Dict.valueOf( args, "value" )  _
            )
        value = ""
    
    case else:
        print "FastUI (c)2015 by Cylexia"
        print ""
        print "Use: ui MODE [options]"
        print " MODE is ""ask"", ""choose"" or ""tell"""
        print " options contains:"
        print "  -prompt     The prompt to show"
        print "  -to         Target file to write to, use ""."" for STDOUT or """" (or skip) "
        print "              to not write anything (ie. for INFO)"
        print "  -format     Output format:"
        print "               txt|text - the string or "" if cancelled or nothing entered"
        print "               mtext|"""" - marked text, ""+"" (OK) or ""-"" (Cancel) followed"
        print "                          by the value (text for ""ask"" or 0-n for ""choose"")"
        print "               json - json object with the keys ""status"" (1|0) and ""value"""
        print "               jsonp - same as json but wrapped in the function specified"
        print "                       with -func"
        print "  -value       The current value (a string for ""ask""/, or index for"
        print "               ""choose"") or the message for ""tell"""
        print "  -items       / separated list of items to use with choose"
        print "  -func        The name of the function for use with ""-format jsonp"""
        print
        end
        
end select

'dim as string value = StdUI.getValue()

color 7, 0
cls
    
dim as string file = Dict.valueOf( args, "to", "." )
if( (len( file ) = 0) or (file = ".") ) then
    open cons for output as 1
else
    if( open( file for output as 1 ) <> 0 ) then
        Utils.echoError( "Unable to write to file" )
        end
    end if
end if

dim as string outmode = Dict.valueOf( args, "format" )

select case outmode
    case "jsonp", "jsonp":
        if( outmode = "jsonp" ) then
            print #1, Dict.valueOf( args, "func" ); "( " 
        end if
        print #1, "{ ""value"":"; result; ", value: """
        dim as integer i
        for i = 1 to len( value )
            if( asc( value, i ) = 34 ) then
                print #1, "\";
            end if
            print #1, chr( asc( value, i ) );
        next
        print #1, """ }"
        if( outmode = "jsonp" ) then
            print #1, " );"
        end if
        
    case "text":
        if( result <> 0 ) then
            print #1, value
        else
            print #1, ""
        end if

    case else:
        if( result <> 0 ) then
            print #1, "+"; value
        else
            print #1, "-"; value
        end if
end select

close #1
