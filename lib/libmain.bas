' libmain
' (c)2014 by Cylexia
'
' Common functions library
#ifdef __FB_WIN32__
    #include once "windows.bi"
    #include once "win\shellapi.bi"
#endif

#ifndef __LIBMAIN__
    #ifdef __DEBUG__
        #define DEBUGMSG(n) Utils.echo( "[" & __FUNCTION__ & " @" & __LINE__ & "] " & n & !"\n")
        #define DEBUGMSGL(n) Utils.echo( "[" & __FILE__ & "/" & __FUNCTION__ & " @" & __LINE__ & "] " & n & !"\n" )
        #define DEBUGPAUSE getkey()
    #else
        #define DEBUGMSG(n)
        #define DEBUGMSGL(n)
        #define DEBUGPAUSE
    #endif

#define __LIBMAIN__

' used simply for marking up strings as being used as dictionaries
#define DICTSTRING string

#ifndef TRUE
#define TRUE -1
#endif

#ifndef FALSE
#define FALSE 0
#endif

namespace LSF
    declare function pack( list as DICTSTRING ) as string
    declare function unpack( s as string ) as DICTSTRING
    declare function unpackNext( s as string, byref __ptr as integer ) as string
    declare function packNext( s as string ) as string
    declare function encode( l as integer ) as string
    declare function decode( s as string ) as integer
    declare sub push( byref l as string, a as string )
end namespace

namespace Dict
    declare function create() as DICTSTRING
    declare function createFromLSF( lsf as string ) as DICTSTRING
    declare function valueOf( byref a as DICTSTRING, k as string, d as string = "" ) as string
    declare function dblValueOf( byref a as DICTSTRING, k as string, d as double = 0 ) as double
    declare function sngValueOf( byref a as DICTSTRING, k as string, d as single = 0 ) as single
    declare function intValueOf( byref a as DICTSTRING, k as string, d as integer = 0 ) as integer
    declare sub set overload ( byref a as DICTSTRING, k as string, v as string )
    declare sub set overload ( byref a as DICTSTRING, k as string, v as integer )
    declare function remove( byref a as DICTSTRING, k as string ) as integer
    declare function containsKey( byref a as DICTSTRING, k as string ) as integer
    declare function keys( byref a as DICTSTRING, ks() as string ) as integer
    declare function keyDict( byref a as DICTSTRING ) as DICTSTRING
    declare function valuesDict( byref a as DICTSTRING ) as DICTSTRING
    declare function copyInto( byref a as DICTSTRING, byref target as DICTSTRING, prefix as string = "" ) as integer
    declare sub dump( byref a as DICTSTRING )
    declare sub pushAsListItem( d as DICTSTRING, item as string )
    declare function toLSF( d as DICTSTRING ) as string
    declare function lstr( s as string ) as string
    declare function lkv( k as string, v as string ) as string
end namespace

namespace Frame
    declare function init() as integer
    declare function valueOf( x as string, k as string, d as string = "" ) as string
    declare function intValueOf( x as string, k as string, d as integer = 0 ) as integer
    declare function lngValueOf( x as string, k as string, d as integer = 0 ) as integer
    declare function boolValueOf( x as string, k as string, d as integer = 0 ) as integer
    declare function dictValueOf( x as string, k as string, d as string = "" ) as DICTSTRING
    declare sub set overload ( x as string, k as string, v as string )
    declare sub set overload ( x as string, k as string, v as integer )
    declare sub set overload ( x as string, k as string, v as long )
    declare sub pushAsListItem( x as string, v as string )
    declare function containsKey( x as string, k as string ) as integer
    declare function keys( x as string, ks() as string ) as integer
    declare function isAllocated( x as string ) as integer
    declare sub dump( x as string )
    declare function remove( x as string, k as string ) as integer
    declare sub removeAll( x as string )
    declare sub alloc( n as string = "" )
    declare sub allocIfNot( n as string )
    declare function dealloc( n as string ) as integer
end namespace

namespace Utils
    const as string EMPTY_STRING = ""
    
    declare sub echo( msg as string )
    declare sub echoError( msg as string, newline as integer = TRUE )
    declare function parseCommandLine( defaults as DICTSTRING = "", force_caps as integer = 0 ) as string
    declare function readFile( fn as string, byref errstate as integer = 0 ) as string
    declare function writeFile( fn as string, byref value as string, byref errstate as integer = 0 ) as integer
    declare function getLastError() as string
    declare sub setLastError( msg as string = "" )
    declare function mdf( src as string ) as DICTSTRING
    declare function makeSafe( v as string ) as string
    declare function unmakeSafe( v as string ) as string
    declare function split( src as string, sep as string ) as DICTSTRING
    declare function replace( src as string, r as string, w as string ) as string
    declare function stripSpecialChars( s as string ) as string
    declare function getEnv( key as string, def as string = "" ) as string
    declare function browseTo( url as string ) as integer
end namespace

namespace Dict
    function create() as string
        return ""
    end function
    
    function createFromLSF( s as string ) as string
        ' this is a modified version of LSF.decode to swap between reading the
        ' key then the value (saves time compared to decomrpessing the lot into
        ' a list then reading that into a dict).  This also doesn't use Dict.set
        ' but directly writes the data into a string
        dim as string a = ""
        dim as integer i, l, y = len( s ), o, kmode = 0
        dim as string key
        i = 1
        while ((i < y) and (i >= 0))
            l = 0
            o = asc( s, i )
            while( o >= 97 )
                l = ((l + (o - 97)) shl 4)
                i += 1
                o = asc( s, i )
            wend
            l += (o - 65)
            if( kmode = 0 ) then
                key = mid( s, (i + 1), l )
                kmode = 1
            else
                a &= Dict.lkv( key, mid( s, (i + 1), l ) )
                'Dict.set( a, key, mid( s, (i + 1), l ) )
                kmode = 0
            end if
            i += l + 1
        wend
        return a
    end function

    function valueOf( byref a as string, k as string, d as string = "" ) as string
        dim l as integer = len( a )
        dim i as integer, r as integer
        dim rk as string
        i = 1
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rk = mid( a, i, r )
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            if( rk = k ) then
                return mid( a, i, r )
            end if
            i += r
        wend
        return d
    end function
    
    function sngValueOf( byref a as string, k as string, d as single = 0 ) as single
        return csng( valueOf( a, k, str( d ) ) )
    end function
    
    function dblValueOf( byref a as string, k as string, d as double = 0 ) as double
        return cdbl( valueOf( a, k, str( d ) ) )
    end function
    
    function intValueOf( byref a as string, k as string, d as integer = 0 ) as integer
        return cint( valueOf( a, k, str( d ) ) )
    end function
            
    ' 1 is true, 0 is false
    function boolValueOf( byref a as string, k as string, d as ubyte = 0 ) as ubyte
        select case( lcase( valueOf( a, k, str( d ) ) ) )
            case "yes", "y", "on", "1", "true"
                return 1
        end select
        return 0
    end function
            
    sub set( byref a as string, k as string, v as string )
        dim l as integer = len( a )
        dim i as integer, r as integer, s as integer
        dim rk as string, rv as string, z as string
        i = 1
        while( i < l )
            s = i
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rk = mid( a, i, r )
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rv = mid( a, i, r )
            i += r
            if( rk = k ) then
                dim l as integer = len( v )
                a = mid( a, 1, (s + len( rk ) + 1) ) & _
                    chr( hibyte( l ) ) & _
                    chr( lobyte( l ) ) & v + _
                    mid( a, i )
                return
            end if
        wend
        a = (a + lkv( k, v ))
    end sub
    
    sub set( byref a as string, k as string, v as integer )
        Dict.set( a, k, str( v ) )
    end sub
    
    function remove( byref a as string, k as string ) as integer
        dim l as integer = len( a )
        dim i as integer, r as integer, s as integer
        dim rk as string, rv as string, z as string
        i = 1
        while( i < l )
            s = i
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rk = mid( a, i, r )
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rv = mid( a, i, r )
            i += r
            if( rk = k ) then
                a = (mid( a, 1, s ) & mid( a, (i + 1) ))
                return 1
            end if
        wend
        ' do nothing as key wasn't found
        return 0
    end function
    
    sub dump( byref a as string )
        dim l as integer = len( a )
        dim i as integer, r as integer, ri as integer
        dim rk as string, rv as string, rc as string
        dim as integer consout = freefile()
        open cons for output as consout
        i = 1
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = r or asc( mid( a, i, 1 ) )
            i += 1
            rk = mid( a, i, r )
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1         
            rv = mid( a, i, r )
            print #consout, rk; mid( "                         ", len( rk ) ); ": ";
            for ri = 1 to len( rv )
                rc = mid( rv, ri, 1 )
                if( asc( rc ) < 32 ) then
                    print #consout, "["; asc( rc ); "]";
                else
                    print #consout, rc;
                end if
            next
            print #consout, ""
            i += r
        wend
        close #consout
    end sub
    
    function containsKey( byref a as string, k as string ) as integer
        dim l as integer = len( a )
        dim i as integer, r as integer
        dim rk as string
        i = 1
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rk = mid( a, i, r )
            if( rk = k ) then
                return 1
            end if
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            i += r
        wend
        return 0
    end function
    
    sub pushAsListItem( byref d as DICTSTRING, item as string )
        dim as integer c = Dict.intValueOf( d, "count", 0 )
        Dict.set( d, str( c ), item )
        Dict.set( d, "count", (c + 1) )
        Dict.set( d, "_count", (c + 1) )    'TODO: legacy, try to remove this
    end sub
    
    function keys( byref a as string, ks() as string ) as integer
        dim l as integer = len( a )
        if( l = 0 ) then
            return 0
        end if
        dim i as integer, r as integer
        dim rk as string
        redim ks(10) as string
        dim ki as integer
        ki = 0
        i = 1
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rk = mid( a, i, r )
            ks(ki) = rk
            ki += 1
            if( ki = ubound( ks ) ) then
                redim preserve ks((ki + 10))
            end if
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            i += r
        wend
        redim preserve ks((ki - 1))
        return ki
    end function
    
    function keyDict( byref a as string ) as string
        dim retdict as string = Dict.create()
        dim l as integer = len( a )
        dim i as integer, r as integer
        dim rk as string
        redim ks(10) as string
        dim ki as integer
        ki = 0
        i = 1
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rk = mid( a, i, r )
            Dict.set( retdict, str( ki ), rk )
            ki += 1
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            i += r
        wend
        Dict.set( retdict, "count", str( ki ) )
        return retdict
    end function
    
    function valueDict( byref a as string ) as string
        dim retdict as string = Dict.create()
        dim l as integer = len( a )
        dim i as integer, r as integer
        dim rk as string
        redim ks(10) as string
        dim ki as integer
        ki = 0
        i = 1
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1
            rk = mid( a, i, r )
            Dict.set( retdict, str( ki ), rk )
            ki += 1
            i += r
        wend
        Dict.set( retdict, "count", str( ki ) )
        return retdict
    end function
    
    function copyInto( byref a as string, byref target as string, prefix as string = "" ) as integer
        dim l as integer = len( a )
        dim i as integer, r as integer, c as integer
        dim rk as string
        i = 1
        c = 0
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = r or asc( mid( a, i, 1 ) )
            i += 1
            rk = mid( a, i, r )
            if( len( prefix ) > 0 ) then
                rk = (prefix + rk)
            end if
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1         
            Dict.set( target, rk, mid( a, i, r ) )
            c += 1
            i += r
        wend
        return c
    end function

'-- Convert a K=>V dict into a K,V LSF string
    function toLSF( a as DICTSTRING ) as string
        ' linearise K=>V to K,V at a very low level
        dim l as integer = len( a )
        dim i as integer, r as integer, c as integer
        dim rk as string, q as string
        i = 1
        c = 0
        while( i < l )
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = r or asc( mid( a, i, 1 ) )
            i += 1
            q &= (LSF.encode( r ) & mid( a, i, r ))     ' write the key
            i += r
            r = (asc( mid( a, i, 1 ) ) shl 8)
            i += 1
            r = (r or asc( mid( a, i, 1 ) ))
            i += 1         
            q &= (LSF.encode( r ) & mid( a, i, r ))     ' write the value
            c += 1
            i += r
        wend
        return q
    end function

    function lstr( s as string ) as string
        dim l as integer = len( s )
        return (chr( hibyte( l ) ) & chr( lobyte( l ) ) & s)
    end function
    
    function lkv( k as string, v as string ) as string
        return (lstr( k ) + lstr( v ))
    end function
    
end namespace

namespace LSF
    'declares are up the top - don't ask...
    
    function pack( list as DICTSTRING ) as string
        dim as string o = "", w, z
        dim as integer i, l
        dim as integer il = (Dict.intValueOf( list, "count" ) - 1)
        for i = 0 to il
            w = Dict.valueOf( list, str( i ) )
            l = len( w )
            z = chr( (65 + (l and &hF)) )
            while( l > 15 )
                l shr= 4
                z = (chr( (97 + (l and &hF)) ) & z)
            wend
            o &= z
            o &= w
        next
        return o
    end function
    
    function unpack( s as string ) as DICTSTRING
        dim as DICTSTRING a = Dict.create()
        dim as integer y = len( s ), i = 1, l, o, idx = 0
        while ((i < y) and (i >= 0))
            l = 0
            o = asc( s, i )
            while( o > 97 )
                l += ((o - 97) shl 4)
                i += 1
                o = asc( s, i )
            wend
            l += (o - 65)
            Dict.set( a, str( idx ), mid( s, (i + 1), l ) )
            i += l + 1
            idx += 1
        wend
        Dict.set( a, "count", str( idx ) )
        return a
    end function
    
    function unpackNext( s as string, byref __ptr as integer ) as string
        dim as integer y = len( s ), l, o, idx = 0
        if ((__ptr < y) and (__ptr >= 0)) then
            l = 0
            o = asc( s, __ptr )
            while( o > 97 )
                l += ((o - 97) shl 4)
                __ptr += 1
                o = asc( s, __ptr )
            wend
            l += (o - 65)
            
            dim as string result = mid( s, (__ptr + 1), l )
            __ptr += (l + 1)
            return result
        end if
        __ptr = -1
        return ""
    end function
    
    function packNext( s as string ) as string
        return (LSF.encode( len( s ) ) & s)
    end function
    
    function encode( l as integer ) as string
        dim as string z
        z = chr( (65 + (l and &hF)) )
        while( l > 15 )
            l shr= 4
            z = (chr( (97 + (l and &hF)) ) & z)
        wend
        return z
    end function
    
    function decode( s as string ) as integer
        dim as integer y = len( s ), i = 1, l, o, idx = 0
        l = 0
        o = asc( s, i )
        while( o >= 97 )
            l = ((l + (o - 97)) shl 4)
            i += 1
            o = asc( s, i )
        wend
        l += (o - 65)
        return l
    end function

    sub push( byref l as string, a as string )
        l &= (str( encode( len( a ) ) ) & a)
    end sub
end namespace

namespace Utils    
    const as integer   _
            PCL_NORMAL = 0,   _
            PCL_UCASE = 1
    
    dim lastErrorMsg as string
    
    ' parse the commandline into a Dict, keys start with "-" and multiple
    '  values are separated with "\n".  The default key is "_"
    function parseCommandLine( defaults as DICTSTRING = "", force_caps as integer = Utils.PCL_NORMAL ) as string
        dim d as string
        if( defaults <> "" ) then
            d = defaults
        else
            d = Dict.create()
        end if
        dim cidx as integer = 1
        dim cmd as string, k as string = "_", v as string = ""
        while( 1 )
            cmd = command( cidx )
            if( (asc( cmd, 1 ) = 45) or (cmd = "") ) then       ' starts with -/is last
                if( k <> "" ) then
                    Dict.set( d, k, v )
                end if
                k = mid( cmd, 2 )
                if( force_caps = Utils.PCL_UCASE ) then
                    k = ucase( k )
                end if
                v = ""
                if( cmd = "" ) then
                    exit while
                end if
            else
                if( asc( cmd, 1 ) = 124 ) then   ' remove initial | if there is one - allows escaping of "-"
                    cmd = mid( cmd, 2 )
                end if
                if( v = "" ) then
                    v = cmd
                else
                    v = (v & !"\n" & cmd)
                end if
            end if
            cidx += 1
            cmd = command( cidx )
        wend
        return d
    end function
    
    'Read a file's contents.  getLastError() will be set on failure
    function readFile( fn as string, byref errstate as integer = 0 ) as string
        dim ff as integer = freefile()
        if( open( fn for binary access read as ff ) = 0 ) then
            dim buf as string = space( lof( ff ) )
            get #ff, , buf
            close #ff
            Utils.setLastError()
            errstate = 0
            return buf
        end if
        errstate = 1
        Utils.setLastError( "Unable to read from file" )
    end function
    
    'Write a file, getLastError() is set on error (as is errstate if given).  Returns -1 (true)
    ' if successful, 0 if not.
    function writeFile( fn as string, byref value as string, byref errstate as integer = 0 ) as integer
        dim ff as integer = freefile()
        if( open( fn for output as ff ) = 0 ) then
            put #ff, , value
            close #ff
            Utils.setLastError()
            errstate = 0
            return -1
        end if
        errstate = 1
        Utils.setLastError( "Unable to write to file" )
        return 0
    end function
    
    ' Functions can set an error message, this will retrieve it.  Note: not
    '  all functions will set this
    function getLastError() as string
        return lastErrorMsg
    end function
    
    ' Set the last error message
    sub setLastError( msg as string = "" )
        lastErrorMsg = msg
    end sub
    
    ' Echo to the console if possible, if not then write to the screen as normal
    sub echo( msg as string )
        dim ff as integer = freefile()
        #ifndef __ECHO_FORCE_PRINT__
        if( open cons( for output as ff ) = 0 ) then
            print #ff, msg;
            close #ff
        else
        #endif
            print msg;
        #ifndef __ECHO_FORCE_PRINT__
        end if
        #endif
    end sub

    ' Echo to the console if possible, if not then write to the screen as normal
    sub echoError( msg as string, newline as integer = TRUE )
        dim ff as integer = freefile()
        #ifndef __ECHO_FORCE_PRINT__
        if( open err( for output as ff ) = 0 ) then
            print #ff, msg;
            if( newline ) then
                print #ff, !"\n"
            end if
            close #ff
        else
        #endif
            print msg;
            if( newline ) then
                print
            end if
        #ifndef __ECHO_FORCE_PRINT__
        end if
        #endif
    end sub

    function mdf( src as string ) as DICTSTRING
        dim as DICTSTRING map
        if( src = "" ) then
            return map
        end if
        dim as integer s = instr( src, "(" )
		if( s > -1 ) then
			dim as integer e = instr( src, ")" )
			dim as string sep = mid( src, (s + 1), (e - s - 1) )
            dim as integer l = len( sep ), sl = len( src ), i
			s = (e + 1)
			while( 1 )
                e = instr( s, src, sep )
				if( e = 0 ) then
					e = sl
				end if
                i = instr( s, src, ":" )
                if( i < e ) then
                    dim as string k = trim( mid( src, s, (i - s) ), any !" \n\r\t" )
                    if( asc( k, 1 ) = 35 ) then     '#
                        k = trim( mid( k, 2, instrrev( k, "#" ) ) )
                    end if
                    Dict.set( map, k, trim( mid( src, (i + 1), (e - i - 1) ), any !" \n\r\t" ) )
                end if
                s = (e + l)
                if( s > sl ) then
                    exit while
                end if
            wend
        end if
        return map
    end function
    

'-- replace any "_xx" string with the character represented by the hex value
'-- "xx"
    function unmakeSafe( v as string ) as string
        dim as string s = ""
        dim as integer i, c, l = len( v )
        for i = 1 to l
            c = asc( v, i )
            if( c = 95 ) then   ' underscore
                c = val( ("&h" & mid( v, (i + 1), 2 )) )
                i += 2
            end if
            s &= chr( c )
        next
        return s
    end function
    
'-- Replace any character not A-Z, a-z or 0-9 with _xx where xx is the hex
'-- value of the character
    function makeSafe( v as string ) as string
        dim as integer c, i
        dim as string result = ""
        for i = 1 to len( v )
            c = asc( v, i )
            if( ((c >= 48 ) and (c <= 57)) or ((c >= 97) and (c <= 122)) or ((c >= 65) and (c <= 90)) ) then
                result &= chr( c )
            else
                result &= ("_" & hex( c, 2 ))
            end if
        next
        return result
    end function
    
'-- split a string into a DICTSTRING
    function split( a as string, o as string ) as string
        dim as integer i = 0, s = 1, e, l = len( o )
        dim r as DICTSTRING = Dict.create()
        e = instr( a, o )
        while( e > 0 )
            Dict.set( r, str( i ), mid( a, s, (e - s) ) )
            i += 1
            s = (e + l)
            e = instr( s, a, o )
        wend
        Dict.set( r, str( i ), mid( a, s ) )
        Dict.set( r, "count", str( (i + 1) ) )
        return r
    end function

'-- replace instances of r with w in src
    function replace( src as string, r as string, w as string ) as string
        dim as integer i = instr( src, r ), l = len( r )
        while( i > 0 )
            src = mid( src, 1, (i - 1) ) & w & mid( src, (i + l) )
            i = instr( src, r )
        wend
        return src
    end function
    
    function stripSpecialChars( s as string ) as string
        dim as integer c
        dim as string res = ""
        dim as integer i, l = len( s )
        for i = 1 to l
            c = asc( s, i )
            if( (c >= 48) and (c <= 57) ) then       ' 0-9
                '
            elseif( (c >= 65) and (c <= 90) ) then   ' A-Z
                '
            elseif( (c >= 97) and (c <= 122) ) then  ' a-z
                '
            else
                c = 95      ' underscore
            end if
            res &= chr( c )
        next
        return res
    end function
    
    function getEnv( key as string, def as string = "" ) as string
        if( environ( key ) <> "" ) then
            return environ( key )
        else
            return def
        end if
    end function
    
    function browseTo( url as string ) as integer
        #ifdef __FB_WIN32__
            ShellExecute( NULL, "open", url, "", "", SW_SHOWNORMAL )
        #else
            dim as string cmd
            if( len( dir( "/usr/bin/xdg-open" ) ) > 0 ) then
                cmd = "xdg-open"
            elseif( len( dir( "/usr/bin/gnome-open") ) > 0 ) then 
                cmd = "gnome-open"
            elseif( len( dir( "/usr/bin/kde-open" ) ) > 0 ) then
                cmd = "kde-open"
            else
                return FALSE
            end if
            exec( cmd, ("""" & url & """") )
        #endif
        return TRUE
    end function
end namespace

namespace Frame
    dim as DICTSTRING _x
    dim as integer inited
    dim as integer next_id = 1001
    
    function init() as integer
        if( Frame.inited = 0 ) then
            Frame._x = Dict.create()
            Frame.inited = 1
        end if
        return 1
    end function
    
    function valueOf( x as string, k as string, d as string = "" ) as string
        return Dict.valueOf( Dict.valueOf( Frame._x, x ), k, d )
    end function
    
    function intValueOf( x as string, k as string, d as integer = 0 ) as integer
        return cint( Frame.valueOf( x, k, str( d ) ) )
    end function
    
    function lngValueOf( x as string, k as string, d as integer = 0 ) as integer
        return clng( Frame.valueOf( x, k, str( d ) ) )
    end function
    
    function boolValueOf( x as string, k as string, d as integer = 0 ) as integer
        if( Dict.containsKey( Frame._x, k ) <> 0 ) then
            dim as string z = Frame.valueOf( x, k )
            if( (z = "1") or (z = "-1") or (z = "on") or (z = "yes") ) then
                return -1
            else
                return 0
            end if
        else
            return d
        end if
    end function
    
    function dictValueOf( x as string, k as string, d as string = "" ) as DICTSTRING
        return Frame.valueOf( x, k, d )
    end function
    
    sub set overload ( x as string, k as string, v as string )
        dim as DICTSTRING fd = Dict.valueOf( Frame._x, x )
        Dict.set( fd, k, v )
        Dict.set( Frame._x, x, fd )
    end sub
    
    sub set overload ( x as string, k as string, v as integer )
        Frame.set( x, k, str( v ) )
    end sub
    
    sub set overload ( x as string, k as string, v as long )
        Frame.set( x, k, str( v ) )
    end sub

    'sub set overload ( x as string, k as string, v as DICTSTRING )
    '    Frame.set( x, k, str( v ) )
    'end sub

    sub pushAsListItem( x as string, v as string )
        dim as DICTSTRING fd = Dict.valueOf( Frame._x, x )
        Dict.pushAsListItem( fd, v )
        Dict.set( Frame._x, x, fd )
    end sub
    
    function containsKey( x as string, k as string ) as integer
        return Dict.containsKey( Dict.valueOf( Frame._x, x ), k )
    end function
    
    function keys( x as string, ks() as string ) as integer
        return Dict.keys( Dict.valueOf( Frame._x, x ), ks() )
    end function
    
    function isAllocated( x as string ) as integer
        if( Dict.containsKey( Frame._x, x ) = 0 ) then
            return 0
        else
            return -1
        end if
    end function
    
    sub dump( x as string )
        Dict.dump( Dict.valueOf( Frame._x, x ) )
    end sub
    
    function remove( x as string, k as string ) as integer
        return Dict.remove( x, k )
    end function
    
    sub removeAll( x as string )
        Dict.set( Frame._x, x, Dict.create() )
    end sub

    sub alloc( n as string = "" )
        if( n = "" ) then
            n = str( Frame.next_id )
            Frame.next_id += 1
        end if
        Dict.set( Frame._x, n, Dict.create() )
    end sub
    
    sub allocIfNot( n as string )
        if( Dict.containsKey( Frame._x, n ) = 0 ) then
            Frame.alloc( n )
        end if
    end sub
    
    function dealloc( n as string ) as integer
        if( Dict.containsKey( Frame._x, n ) <> 0 ) then
            Dict.remove( Frame._x, n )
            return 1
        end if
        return 0
    end function
end namespace

#endif
