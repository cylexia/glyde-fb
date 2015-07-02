#ifndef __LIBGLUE__

#define __LIBGLUE__
#define SET_ERR( v ) Dict.set( Glue._vars, "err", str( v ) )
#define SET_INTO( v ) Dict.set( Glue._vars, Dict.valueOf( w, "into" ), v )

#define GLUE_VERSION "1.8/150127"
#define GLUE_COPYRIGHT "(c)2013-15 by Cylexia"

#ifndef __LIBMAIN__
#include "libmain.bas"
#endif

namespace Glue
    const FAILED = 0
    const STOPPED = 1
    const SUSPENDED = 2
    
	const as integer  _
        PLUGIN_DONE = 1,  _
		PLUGIN_NOT_MINE = -1,  _
		PLUGIN_INLINE_REDIRECT = -2,  _      ' call setRedirectLabel() to set the label
		PLUGIN_DONE_STOP_OK = -3,  _
		PLUGIN_DONE_EXIT_ALL = -254
    
    
    declare function init() as integer
    declare sub printInfo()
    declare sub printPoweredBy()
    declare function addPlugin( pl as function( byref as string, byref as string ) as integer ) as integer
'    declare function run( script as string, byref vars as string, label as string = "" ) as integer
    declare function load( script as string, byref vars as string ) as integer
    declare function run( label as string = "" ) as integer
    declare sub setRedirectLabel( label as string )
    declare function parse( a as string, byref vs as string ) as string
    declare sub runInteractiveMode( byref vars as DICTSTRING )
    
    ' declare this in your code - return 0 to fail or 1 to continue
    'declare function pluginCall( byref w as string, byref vars as string ) as integer
    
    ' private
    ' GlueEval built in support...
    declare function testIf( byref w as string, byref vars as string, negate as integer ) as integer
    declare function boolInvert( byref w as string, byref vars as string ) as integer
'    declare function gluePositionInString( byref w as string, byref vars as string ) as integer
'    declare function glueLengthOfString( byref w as string, byref vars as string ) as integer
'    declare function glueCopyFromString( byref w as string, byref vars as string ) as integer
    
    ' helper functions
    declare sub echo( msg as string )
    declare sub logError( byref vars as string, msg as string )
    declare function bool( byref v as string ) as integer
    
    declare function _setPart( d as string, sk as string, sv as string ) as string
    declare function _getPart( from as string, gk as string ) as string
    declare function _getParts( from as DICTSTRING, keys as string ) as string
    
    dim plugins( 0 to 14 ) as function( byref as string, byref as string ) as integer
    dim pluginCount as integer
    
    dim as string _script
    dim as DICTSTRING _vars
    dim as string _redirect_label
    
    function init() as integer
        pluginCount = 0
        Glue._redirect_label = ""
        return 1
    end function
    
    sub printInfo()
        Glue.echo( "Glue v" )
        Glue.echo( GLUE_VERSION )
        Glue.echo( !"\n" )
        Glue.echo( GLUE_COPYRIGHT )
        Glue.echo( !"\n" )
    end sub

    sub printPoweredBy()
        Glue.echo( "Powered by Glue " )
        Glue.echo( GLUE_VERSION )
        Glue.echo( " " )
        Glue.echo( GLUE_COPYRIGHT )
        Glue.echo( !"\n" )
    end sub

    function addPlugin( pl as function( byref as string, byref as string ) as integer ) as integer
        if( pluginCount < ubound( plugins ) ) then
            plugins(pluginCount) = pl
            pluginCount += 1
            return 1
        else
            return 0
        end if
    end function
    
    sub setRedirectLabel( l as string )
        Glue._redirect_label = l
    end sub
    
    function load( src as string, byref vs as DICTSTRING ) as integer
        Glue._script = src
        Glue._vars = vs
        return 1
    end function
    
    function run( label as string = "" ) as integer
        dim ls as integer = 1, le as integer
        dim lin as string, cr as string = chr( 10 )
        dim tr as string = (cr + chr( 9 ) + chr( 13 ) + " ")
        dim gss() as integer, gssi as integer = 0
        dim w as string, cmd as string
        dim i as integer, ts as string
        dim runline as ubyte
        redim gss(10) as integer
        dim as integer ti, ok, r
        dim as DICTSTRING stop_hooks = Dict.create()
        Dict.set( Glue._vars, "EXIT_CODE", "" )
        if( label <> "" ) then
            if( asc( label, 1 ) <> 58 ) then        ' 58 is :
                label = (":" & label)
            end if
            ti = instr( label, "#" )
            if( ti > 0 ) then
                Dict.set( Glue._vars, "_LABEL", mid( label, (ti + 1) ) )
                label = mid( label, 1, (ti - 1) )
            end if
        end if
        le = instr( Glue._script, cr )
        Glue._script += cr
        while( le > 0 ) 
            lin = trim( mid( Glue._script, ls, (le - ls) ), any tr )
			if( (len( lin ) > 0) and (len( label ) = 0) ) then
                runline = 1
                while( asc( lin, 1 ) = 40 )     ' (
                    i = instr( lin, ")" )
                    if( Glue.bool( Dict.valueOf( Glue._vars, mid( lin, 2, (i - 2 ) ) ) ) = 0 ) then
                        'print "blocking becase "; mid( lin, 2, (i - 2 ) ); " was "; val( mid( lin, 2, (i - 2 ) ) )
                        runline = 0
                        exit while
                    end if
                    lin = trim( mid( lin, (i + 1) ), any tr )
                wend
                if( runline = 1 ) then
                    w = Glue.parse( lin, Glue._vars )
                    if( w = "" ) then
                        Glue.logError( Glue._vars, ("Parser failed: " & lin) )
                        return 0
                    end if
                    cmd = Dict.valueOf( w, "_" )
                    #ifdef _LIBGLUE_TRACE
                    print !"\n--["; cmd; "]--------"
                    Dict.dump( w )
                    #endif
                    dim as string cmdv = Dict.valueOf( w, cmd )
                    if( mid( cmd, 1, 1 ) <> ":" ) then
                        select case cmd
                            case "value", "@", "put":
                                Dict.set( Glue._vars, Dict.valueOf( w, "into" ), Dict.valueOf( w, Dict.valueOf( w, "_" ) ) )
                            case "get@":
                                SET_INTO( Dict.valueOf( Glue._vars, Dict.valueOf( w, Dict.valueOf( w, "_" ) ) ) )
                                
                            case "setpart"
                                SET_INTO( Glue._setPart(  _
                                        Dict.valueOf( w, "in" ),  _
                                        Dict.valueOf( w, cmd ),  _
                                        Dict.valueOf( w, "to" )  _
                                    ) )
                            case "getpart"
                                SET_INTO( Glue._getPart( Dict.valueOf( w, "from" ), Dict.valueOf( w, cmd ) ) )
                            'case "loadpartsfrommdf"
                            '    dim as DICTSTRING td = Utils.mdf( cmdv )
                            '    SET_INTO( Dict.toLSF( td ) )
                                
                            case "getparts"
                                SET_INTO( Glue._getParts( Dict.valueOf( w, "from" ), Dict.valueOf( w, cmd ) ) )
                                
                            case "echo", "print":
                                Glue.echo( Dict.valueOf( w, cmd ) )
                                dim k as string = "&"
                                while( Dict.containsKey( w, k ) = 1 )
                                    Glue.echo( Dict.valueOf( w, k ) )
                                    k &= "&"
                                wend
                            case "stop":
                                ' because this is single threaded STOP should never actually be encountered when dealing
                                ' with events as such code always blocks execution and returns the label to go to as
                                ' part of it's handler (by returning -2 from the plugin).  Stop therefore stops the script
                                
                                ' run any exit hooks
                                ok = 0
                                ti = Dict.intValueOf( stop_hooks, "_count" )
                                if( ti > 0 ) then
                                    for i = 0 to ti
                                        r = Dict.intValueOf( Dict.valueOf( stop_hooks, str( i ) ), "idx" )
                                        r = plugins(r)( "", Glue._vars )
                                        select case( r )
                                            case 0:
                                                exit for    ' stop executing hooks
                                            case 1:
                                                ' continue with next hook
                                            case 2:
                                                label = Dict.valueOf( Glue._vars, "__cont" )
                                                Dict.set( Glue._vars, "__cont", "" )
                                                if( asc( label, 1 ) <> 58 ) then        ' 58 is :
                                                    label = (":" & label)
                                                end if
                                                ok = 1
                                                exit for        ' stop executing future hooks
                                        end select
                                    next
                                end if
                                if( ok = 0 ) then
                                    DEBUGMSG( "Glue has stopped (STOP): 1" )
                                    return 1
                                else
                                    ' restart the script from the label specified above
                                    le = 0                          ' reset to start of script (end of loop updates)
                                    gssi = 0                        ' reset call stack
                                end if
                                
                            case "gosub":
                                gss(gssi) = le
                                gssi += 1
                                label = Dict.valueOf( w, "gosub" )
                                ti = instr( label, "#" )
                                if( ti > 0 ) then
                                    Dict.set( Glue._vars, "_LABEL", mid( label, (ti + 1) ) )
                                    label = mid( label, 1, (ti - 1) )
                                end if
                                'if( asc( label, 2 ) <> 43 ) then
                                    le = 0
                                'end if
                                'Dict.copyInto( w, Glue._vars, "_" )       ' copy other keys into Glue.vars
                            case "return":
                                if( gssi > 0 ) then
                                    gssi -= 1
                                    le = gss(gssi)
                                else
                                    Glue.logError( Glue._vars, "RETURN without GOSUB" )
                                    return 0
                                end if
                            case "goto":
                                label = Dict.valueOf( w, "goto" )
                                le = 0
                                ti = instr( label, "#" )
                                if( ti > 0 ) then
                                    Dict.set( Glue._vars, "_LABEL", mid( label, (ti + 1) ) )
                                    label = mid( label, 1, (ti - 1) )
                                end if
'                            case "if":
'                                if( Dict.valueOf( w, "if" ) = Dict.valueOf( w, "is", "1" ) ) then
'                                    ts = Dict.valueOf( w, "thengoto", "" )
'                                else
'                                    ts = Dict.valueOf( w, "elsegoto", Dict.valueOf( w, "endat", "" ) )
'                                end if
'                                if( ts <> "" ) then
'                                    label = ts
'                                    le = 0
'                                end if
'                            case "ifnot":
'                                if( Dict.valueOf( w, "ifnot" ) <> Dict.valueOf( w, "is", "1" ) ) then
'                                    ts = Dict.valueOf( w, "thengoto", "" )
'                                else
'                                    ts = Dict.valueOf( w, "elsegoto", Dict.valueOf( w, "endat", "" ) )
'                                end if
'                                if( ts <> "" ) then
'                                    label = ts
'                                    le = 0
'                                end if
                            case "while"
                                if( Glue.bool( Dict.valueOf( w, "while" ) ) ) then
                                    label = Dict.valueOf( w, "goto" )
                                    le = 0
                                end if
                            case "until"
                                if( Glue.bool( Dict.valueOf( w, "until" ) ) = FALSE ) then
                                    label = Dict.valueOf( w, "goto" )
                                    le = 0
                                end if
                            case "":
                                'nop
                                
                            ' special debug command (implement the command but doesn't have to work)
                            case "+++"
                                Glue.runInteractiveMode( Glue._vars )
                                
                            case "testif"
                                Glue.testIf( w, Glue._vars, FALSE )
                            case "not"
                                Glue.boolInvert( w, Glue._vars )
    '                        case "positioninstring"
    '                            gluePositionInString( w, Glue.vars )
    '                        case "lengthofstring"
    '                            glueLengthOfString( w, Glue.vars )
    '                        case "copyfromstring"
    '                            glueCopyFromString( w, Glue.vars )
                                
                            ' better eval function names
                            case "increase", "incr"
                                SET_INTO( (str( csng( cmdv ) + Dict.sngValueOf( w, "by" ) )) )
                            case "decrease", "decr"
                                SET_INTO( (str( csng( cmdv ) - Dict.sngValueOf( w, "by" ) )) )
                            case "divide"
                                SET_INTO( (str( csng( cmdv ) / Dict.sngValueOf( w, "by" ) )) )
                            case "multiply"
                                SET_INTO( (str( csng( cmdv ) * Dict.sngValueOf( w, "by" ) )) )
                            case "moddiv"
                                SET_INTO( (str( csng( cmdv ) mod Dict.sngValueOf( w, "by" ) )) )
                            case "join"
                                dim k as string = "&"
                                while( Dict.containsKey( w, k ) = 1 )
                                    cmdv &= Dict.valueOf( w, k )
                                    k &= "&"
                                wend
                                SET_INTO( cmdv )
                            
                            'case "cut"
                            '    SET_INTO( mid(   _
                            '            cmdv,   _
                            '            (Dict.intValueOf( w, "from", 0 ) + 1),  _
                            '            Dict.intValueOf( w, "from", len( cmdv ) )  _
                            '        ) )
                            
                            case "cutleftof", "croprightoffof"
                                SET_INTO( mid( cmdv, 1, (Dict.intValueOf( w, "at", 1 )) ) )
                            case "cutrightof", "cropleftoffof"
                                SET_INTO( mid( cmdv, (Dict.intValueOf( w, "at", 0 ) + 1) ) )
                            case "findindexof" '"findstring"
                                if( Glue.bool( Dict.valueOf( w, "ignorecase" ) ) ) then
                                    SET_INTO( str( (instr(  _ 
                                            lcase( Dict.valueOf( w, "in" ) ),   _
                                            lcase( cmdv ) ) - 1)   _
                                        ) )
                                else
                                    SET_INTO( str( (instr( Dict.valueOf( w, "in" ), cmdv ) - 1) ) )
                                end if
                            case "getlengthof"
                                SET_INTO( str( len( cmdv ) ) )
                                
                            case else:
                                ok =  0
                                Dict.set( Glue._vars, "err", "0" )
                                for i = 0 to (pluginCount - 1)
                                    r = plugins(i)( w, Glue._vars )
                                    ' 0 is fail, 1 is done, -1 is not this plugin, 
                                    ' -2 is plugin wants script restarted at the label specified in __cont in vars
                                    if( r = 0 ) then
                                        ok = 0
                                        exit for
                                    end if
                                    ' * if Glue::setRedirectLabel has been called to set _redirect_label
                                    '   then -2 is assumed and will be redirected
                                    if( len( Glue._redirect_label ) > 0 ) then
                                        r = -2
                                    end if
                                    if( r = 1 ) then
                                        ok = 1
                                        exit for
                                    elseif( r = -2 ) then
                                        ' plugin has requested redirection to a label (eg. event handler)
                                        label = Glue._redirect_label
                                        if( len( label ) = 0 ) then
                                            label = Dict.valueOf( Glue._vars, "__cont" )
                                            Utils.echoError( "[Glue] Use of __cont is depreciated" )
                                        end if
                                        if( len( label ) > 0 ) then
                                            Dict.set( Glue._vars, "__cont", "" )
                                            Glue._redirect_label = ""
                                            if( asc( label, 1 ) <> 58 ) then        ' 58 is :
                                                label = (":" & label)
                                            end if
                                            ok = 1
                                            le = 0                          ' reset to start of script (end of loop updates)
                                            gssi = 0                        ' reset call stack
                                            'return 2
                                        else
                                            Glue.logError( Glue._vars, "PLUGIN_RESTART_AT: no label specified in '__cont'" )
                                            return 0
                                        end if
                                    elseif( r = -3 ) then
                                        DEBUGMSG( "Glue has stopped (plugin requested STOP)" )
                                        return 1
                                    'elseif( r = -3 ) then
                                    '    dim as DICTSTRING sh = Dict.create()
                                    '    Dict.set( sh, "idx", i )
                                    '    Dict.set( sh, "data", Dict.valueOf( Glue._vars, "_hookdata" ) )
                                    '    Dict.pushAsListItem( stop_hooks, sh )
                                    '    ok = 1          ' mark command as successful
                                    '    exit for
                                    elseif( r < -128 ) then     
                                        ' returns below -128 get passed back to the caller immediately
                                        ' defined:
                                        '   -254    stop interpreter loop NOW
                                        DEBUGMSG( ("Glue has stopped (plugin request): " & r) )
                                        return r
                                    end if
                                next
                                Dict.set( Glue._vars, "err", str( err ) )
                                if( ok = 0 ) then
                                    Glue.logError( Glue._vars, ("Invalid command " & Dict.valueOf( w, "_" )) )
                                    return 0
                                end if
                        end select
                    end if
                end if
			elseif( lin = label ) then
				label = ""
			end if
            ls = (le + 1)
            le = instr( ls, Glue._script, cr )
        wend
        if( label = "" ) then
            ' no label being searched for so we just ran out of code
            DEBUGMSG( "Glue has stopped (end of code): 1" )
            return 1
        else
            ' searching for a label we didn't find
            Glue.logError( Glue._vars, ("Invalid marker " & label) )
        end if
	end function

    function parse( a as string, byref vs as string ) as string
        '// parse a sentence type string (eg key value key "value"...).  Separators are in $b
		if( (len( a ) = 0) or (mid( a, 1, 1 ) = "#") ) then
			'// comment or empty
			return (Dict.lkv( "_", "" ) + Dict.lkv( "", "" ))
		end if
		dim r as string = Dict.create()
        dim i as integer
        dim c as string, k as string, z as string
        dim tr as string = !"\t\n\r "
        if( asc( a, 1 ) = 40 ) then     ' (
            i = instr( a, ")" )
            Dict.set( r, "?", trim( mid( a, 2, (i - 2) ), any tr ) )
            a = trim( mid( a, (i + 1) ), any tr )
        end if
        i = instr( a, " " )
		if( i > 0 ) then
			c = mid( a, 1, (i - 1) )        '-1 is needed JUST for this, other langs don't need it
            i += 1
			if( mid( a, i, 1 ) = "=" ) then
				Dict.set( r, "into", c )
				k = ""
				i += 2
			else
				k = lcase( c )
                z = k
			end if
			dim b as string = (" ,;" + chr( 10 ) + chr( 13 ) + chr( 9 ))
            dim s as string = ""
			dim n as integer = 0
            dim l as integer = len( a ), e as integer
            l = (len( a ) + 1)
			s = ""
			for i = i to l
                if( i < l ) then
                    c = mid( a, i, 1 )
                else
                    c = " "
                end if
				if( c = chr( 34 ) ) then
                    i += 1
                    e = instr( i, a, chr( 34 ) )
					if( e > 0 ) then
						'$r[$k] = strtr( substr( $a, $i, ($e - $i) ), $esc );
                        dim er as string, es as string
                        while( i < e )
                            es = mid( a, i, 1 )
                            if( es = "\" ) then
                                i += 1
                                select case mid( a, i, 1 )
                                    case "q": er += chr( 34 )
                                    case "n": er += (chr( 13 ) + chr( 10 ))
                                    case "t": er += chr( 9 )
                                    case "s", "\": er += "\"                                    
                                end select
                            else
                                er += es
                            end if
                            i += 1
                        wend
                        Dict.set( r, k, er )
						k = ""
                        s = ""
						n = 0
					else
						return ""
					end if
                elseif( c = "~" ) then
                    ' using ~ in a value resets eg. "and~width" will be reset after "and~" so the
                    ' result will be "width".  Allows for natural language additions
                    s = ""
					n = 0
				elseif( instr( b, c ) > 0 ) then
					if( k = "" ) then
						k = lcase( s )
                        if( k = "=>" ) then
                            k = "into"
                        end if
						if( z = "" ) then
							z = k
						end if
					elseif( n = 1 ) then
                        if( (s = "") or (instr( "+-0123456789:", mid( s, 1, 1 ) ) > 0) ) then
'print s; " is a number (or label)"
                            Dict.set( r, k, s )
                        else
'print s; " is a variable, it contains '"; Dict.valueOf( vs, s ); "'"
                            Dict.set( r, k, Dict.valueOf( vs, s ) )
                        end if
                        k = ""
					end if
					s = ""
					n = 0
				else
					s += c
					n = 1
				end if
			next i
            if( (k <> "") and (not Dict.containsKey( r, k )) ) then
                Dict.set( r, k, "" )
            end if
            Dict.set( r, "_", lcase( z ) )
'Dict.dump( r )
'getkey()       
            'if( z = "eval" ) then
            '    ' this is a special case as eval needs
            '    Dict.set( r, "__all__", a )
            'end if
			return r
		else
			return (Dict.lkv( a, "" ) + Dict.lkv( "_", lcase( a ) ))
		end if 
    end function
    
    sub runInteractiveMode( byref vars as DICTSTRING )
        dim as integer stdin = freefile()
        open cons for input as stdin
        Glue.echo( !"\n[Glue] Running in interactive mode...\n" )
        Glue.echo( !"x: quit, ?: dump, =: set, #: load\n\n" )
        dim as string script
        while 1
            dim cmd as string
            Glue.echo( "g> " )
            line input #stdin, cmd
            select case cmd
                case "x"
                    exit while
                case "?"
                    Dict.dump( vars )
                    Glue.echo( "" )
                case "#"
                    Glue.echo( "Script to load: " )
                    line input #stdin, cmd
                    if( cmd <> "" ) then
                        dim as integer ec = 0
                        cmd = Utils.readFile( cmd, ec )
                        if( ec = 0 ) then
                            script = cmd
                            Glue.echo( "Script loaded, use ""/"" to run it" )
                        else
                            Glue.echo( "Unable to load script" )
                        end if
                    end if
                case "="
                    dim as string k, v
                    Glue.echo( "Variable Name: " )
                    line input #stdin, k
                    Glue.echo( "Value: " )
                    line input #stdin, v
                    Dict.set( vars, k, v )
                    
                case else
                    Glue.echo( !"Unsupported command\n" )
            end select
        wend
        close #stdin
        Glue.echo( !"[Glue] left interactive mode\n" )
    end sub

'    function glueSum( byref w as string, byref vars as string ) as integer
'        dim v as string = Dict.valueOf( w, "sum" )
'        Dict.set( vars, Dict.valueOf( w, "into" ), str( Eval.sum( v, vars ) ) )
'        return 1
'    end function

    function testIf( byref w as string, byref vars as string, negate as integer ) as integer
        dim v as string = Dict.valueOf( w, Dict.valueOf( w, "_" ) )
        dim r as integer = 0
        'only "is" and "isnot" are supported for strings, all other operations
        ' will convert the values to numbers before comparing them
		if( Dict.containsKey( w, "is" ) ) then 
            r = (v = Dict.valueOf( w, "is" ))
        elseif( Dict.containsKey( w, "isnot" ) ) then 
            r = (v <> Dict.valueOf( w, "isnot" ))
		else
            ' numeric only
            dim iv as integer = val( v )
            if( Dict.containsKey( w, "==" ) ) then 
                r = (iv = val( Dict.valueOf( w, "==" ) ))
            elseif( Dict.containsKey( w, "=" ) ) then 
                r = (iv = val( Dict.valueOf( w, "=" ) ))
            elseif( Dict.containsKey( w, "!=" ) ) then 
                r = (iv <> val( Dict.valueOf( w, "!=" ) ))
            elseif( Dict.containsKey( w, "<>" ) ) then 
                r = (iv <> val( Dict.valueOf( w, "<>" ) ))
            elseif( Dict.containsKey( w, "<" ) ) then 
                r = (iv < val( Dict.valueOf( w, "<" ) ))
            elseif( Dict.containsKey( w, "lt" ) ) then 
                r = (iv < val( Dict.valueOf( w, "lt" ) ))
            elseif( Dict.containsKey( w, ">" ) ) then 
                r = (iv > val( Dict.valueOf( w, ">" ) ))
            elseif( Dict.containsKey( w, "gt" ) ) then 
                r = (iv > val( Dict.valueOf( w, "gt" ) ))
            elseif( Dict.containsKey( w, "<=" ) ) then 
                r = (iv <= val( Dict.valueOf( w, "<=" ) ))
            elseif( Dict.containsKey( w, "lte" ) ) then 
                r = (iv <= val( Dict.valueOf( w, "lte" ) ))
            elseif( Dict.containsKey( w, ">=" ) ) then 
                r = (iv >= val( Dict.valueOf( w, ">=" ) ))
            elseif( Dict.containsKey( w, "gte" ) ) then 
                r = (iv >= val( Dict.valueOf( w, "gte" ) ))
            elseif( Dict.containsKey( w, "and" ) ) then 
                r = (Glue.bool( v ) and Glue.bool( Dict.valueOf( w, "and" ) ))
            elseif( Dict.containsKey( w, "or" ) ) then 
                r = (Glue.bool( v ) or Glue.bool( Dict.valueOf( w, "or" ) ))
            end if
        end if
        if( negate ) then
            if( r = -1 ) then
                r = 0
            else
                r = -1
            end if
        end if
        if( r = -1 ) then
            Dict.set( vars, Dict.valueOf( w, "into" ), "1" )
        else 
            Dict.set( vars, Dict.valueOf( w, "into" ), "0" )
        end if
		return 1
    end function
    
    ' not is a special case from and and or as it cannot be tested - it only
    ' has one param.  is a standalone command, which is useful anyway...
    function boolInvert( byref w as string, byref vars as string ) as integer
        dim v as string
        if( Glue.bool( Dict.valueOf( w, "not" ) ) = 0 ) then
            v = "1"
        else
            v = "0"
        end if
        Dict.set( vars, Dict.valueOf( w, "into" ), v )
        return 1
    end function


'    function gluePositionInString( byref w as string, byref vars as string ) as integer
'        dim i as integer = instr( Dict.valueOf( w, "positioninstring" ), Dict.valueOf( w, "of" ) )
'        Dict.set( vars, Dict.valueOf( w, "into" ), str( (i - 1) ) )
'        return 1
'    end function
'    
'    function glueLengthOfString( byref w as string, byref vars as string ) as integer
'        dim s as string = Dict.valueOf( w, "lengthofstring" )
'        dim l as integer = len( s )
'        Dict.set( vars, Dict.valueOf( w, "into" ), str( l ) )
'        return 1
'    end function
'    
'    function glueCopyFromString( byref w as string, byref vars as string ) as integer
'        dim v as string = Dict.valueOf( w, "copyfromstring" )
'        dim s as integer = Dict.intValueOf( w, "startat", 0 )
'        dim l as integer = Dict.intValueOf( w, "length", (len( v ) - s) )
'        Dict.set( vars, Dict.valueOf( w, "into" ), mid( v, s, l ) )
'        return 1
'    end function
        
    ' convert a string into a bool, glue uses 0/"" as false and anything else
    '  as true (prefers 1), BASIC uses -1 for true, 0 for false
    function bool( byref s as string ) as integer
        if( (s = "") or (s = "0") ) then
            return 0
        else
            return -1
        end if
    end function
    
    ' Echo to the console if possible, if not then write to the screen as normal
    sub echo( msg as string )
        dim ff as integer = freefile()
        #ifndef __GLUE_FORCE_PRINT__
        if( open cons( for output as ff ) = 0 ) then
            print #ff, msg;
            close #ff
        else
        #endif
            print msg;
        #ifndef __GLUE_FORCE_PRINT__
        end if
        #endif
    end sub
    
    ' Log an error - normally just prints but if 
    sub logError( byref vars as string, msg as string )
        if( Dict.intValueOf( vars, "__store_err", 0 ) = 1 ) then
            dim s as string = (Dict.valueOf( vars, "__stderr", "" ) & "[Glue] " & msg & !"\n")
            Dict.set( vars, "__stderr", s )
        else
            Glue.echo( ("[Glue] " & msg & !"\n") )
        end if
    end sub
    
    function _setPart( d as string, sk as string, sv as string ) as string
        dim ofs as integer = 1
        dim k as string
        dim as integer m = 0
        dim as string result = ""
        dim as string s = k
        dim as integer i
        dim as integer rstart
        while( ofs <= len( d ) )
            dim o as integer
            dim rl as integer = 0
            rstart = ofs
            o = asc( d, ofs )
            ofs += 1
            while( o >= 97 )
                rl = ((rl + (o - 97)) shl 4)
                o = asc( d, ofs )
                ofs += 1
            wend    
            rl += (o - 65)
            o = ofs
            ofs += rl
            if( m = 0 ) then
                k = mid( d, o, rl )
                if( k = sk ) then
                    m = 2   ' don't write the key and value back, we will add at the end
                else
                    result &= mid( d, rstart, (rl + (o - rstart)) )
                    m = 1   ' write the key and value
                end if
            else
                if( m = 1 ) then
                    result &= mid( d, rstart, (rl + (o - rstart)) )
                end if
                m = 0
            end if
        wend
        s = sk
        for i = 0 to 1
            dim l as integer = len( s )
            dim z as string = chr( (65 + (l and 15)) )
            while( l > 15 )
                l = (l shr 4)
                z = (chr( (97 + (l and 15)) ) & z)
            wend
            result &= z
            result &= s
            s = sv
        next
        return result
    end function
    
    function _getPart( from as string, gk as string ) as string
        dim ofs as integer = 1
        dim k as string
        dim as integer m = 0
        
        while( ofs < len( from ) )
            dim o as integer
            dim l as integer = 0
            o = asc( from, ofs )
            ofs += 1
            while( o >= 97 )
                l = ((l + (o - 97)) shl 4)
                o = asc( from, ofs )
                ofs += 1
            wend    
            l += (o - 65)
            o = ofs
            ofs += l
            if( m = 0 ) then
                k = mid( from, o, l )
                m = 1
            else
                if( k = gk ) then
                    return mid( from, o, l )
                end if
                m = 0
            end if
        wend        
        return ""
    end function

    function _getParts( from as DICTSTRING, keys as string ) as string
        from &= ","
        dim as integer s = 1, e = instr( keys, "," )
        dim as string key, result = ""
        while( e > 0 )
            key = mid( keys, s, (e - s) )
            result = Glue._setPart( result, key, Glue._getPart( from, key ) )
            s = (e + 1)
            e = instr( s, from, "," )
        wend
        return result
    end function

end namespace

#endif