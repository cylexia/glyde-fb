#ifndef __LIBGLUE__
#error Glue needs to be included first
#endif

' External platform module.
' (c)2014 by Cylexia
'
' Provides various platform specific operations.  All commands should be
'  available across platforms but can do nothing, show a warning or do the
'  closest thing/most sensible thing available.
'
' Frame support is built into this module as well as ExtFrame
'
' Generally included with any implentation


' Provides frame support, this is part of the platform subsystem but has
' the prefix frame.

namespace ExtPlatform
    declare function init() as integer
    declare function glueCommand( byref w as string, byref vars as string ) as integer

    declare function _readFromFile( n as string ) as string
    declare function _writeToFile( n as string, v as string ) as string
    declare function _listFilesIn( path as string ) as string
    declare function _loadConfig( n as string ) as string
    declare function _createDateSerial() as string
    
    declare function _lsfValue( value as string ) as string
    
'    declare function _browseTo( page as string, query as string ) as integer
'    declare function _download( file as string, d as DICTSTRING ptr, vars as DICTSTRING ptr ) as integer
'    declare function _pcEncode( p as string ) as string
 '   declare function _pcDecode( p as string ) as string

    function init() as integer
        'if( Glue.addPlugin( @ExtPlatform.glueCommand ) ) then
        '    return ExtFrame.init()
        'end if
        randomize timer()           ' for getRandomNumberFrom_upTo
        return Glue.addPlugin( @ExtPlatform.glueCommand )
    end function
    
    function glueCommand( byref w as string, byref vars as string ) as integer
        dim c as string = Dict.valueOf( w, "_" ), cs as string
        dim ts as string, tn as single, ti as integer
        if( instrrev( c, "platform.", 1 ) = 1 ) then
            cs = mid( c, 10 )
        else
            return -1
        end if
        dim as string wc = Dict.valueOf( w, c )
        select case cs
            case "pause"
                sleep
            case "readfromfile", "load"
                SET_INTO( ExtPlatform._readFromFile( wc ) )
            case "writetofile", "save"
                SET_INTO( ExtPlatform._writeToFile( wc, Dict.valueOf( w, "value" ) ) )
            case "currentpath"
                SET_INTO( curdir )
            case "setcurrentpathto"
                chdir wc
            case "listfilesin"
                SET_INTO( ExtPlatform._listFilesIn( wc ) )
                
            case "loadconfigfrom", "loadconfig"
                SET_INTO( _loadConfig( wc ) )
            case "dateserial", "getdateserial", "putdateserial"
                SET_INTO( _createDateSerial() )
            case "setenv", "setenvironmentvariable"
                setenviron (wc & "=" & Dict.valueOf( w, "to" ))
            case "getenv", "putenv", "getenvironmentvariable", "putenvironmentvariable"
                SET_INTO( environ( wc ) )
            case "exec"
                ts = Dict.valueOf( w, "ondonegoto" )
                if( exec( wc, Dict.valueOf( w, "args", Dict.valueOf( w, "withargs" ) ) ) = -1 ) then
                    ts = Dict.valueOf( w, "onerrorgoto", ts )
                end if
                Glue.setRedirectLabel( ts )
                return -2       ' redirect to label (can be 1 since above call will ensure redirect)
            case "getrandomnumberfrom":
                ti = Dict.intValueOf( w, c )
                SET_INTO( ((rnd() * (Dict.intValueOf( w, "upto" ) - ti)) + ti) )
            
            case "browseto"
                Utils.browseTo( wc )
                
            case "exit"
                return -254     ' any event loop should see this as exit
                
            case "getid"
                #ifdef __FB_WIN32__
                    SET_INTO( "native/w32" )
                #endif
                #ifdef __FB_LINUX__
                    SET_INTO( "native/linux" )
                #endif
                #ifdef __FB_DOS__
                    SET_INTO( "native/dos" )
                #endif
                
            case else:
                return -1       ' not ours
        end select
        return 1                ' we handled it
    end function
    
    function _readFromFile( n as string ) as string
        dim ff as integer = freefile()
        dim buf as string
        open n for binary access read as ff
        dim as integer l = lof( ff )
        if( l > 0 ) then
            buf = space( l )
            get #ff, , buf
        else
            buf = ""
        end if
        close #ff
        return buf
    end function
    
    function _writeToFile( n as string, v as string ) as string
        dim ff as integer = freefile()
        if( open( n for output as ff ) = 0 ) then
            close #ff       ' we only opened it to create or truncate it
            open n for binary access write as ff  ' now we will write it
            put #ff, , v
            close #ff
            return "1"
        end if
        return "0"
    end function
    
    function _listFilesIn( path as string ) as string
        if( len( path ) > 0 ) then
            #ifdef __FB_WIN32__
                if( mid( path, (len( path ) - 1) ) <> "\" ) then
                    path &= "\"
                end if
            #else
                if( mid( path, (len( path ) - 1) ) <> "/" ) then
                    path &= "/"
                end if
            #endif
        end if
        dim as string file = dir( (path & "*") )
        dim as string result = "", z
        dim as integer index = 0, l
        while( len( file ) > 0 )
            z = str( index )
            result &= (chr( (65 + len( z )) ) & z)        ' length always < 65
            result &= _lsfValue( file )
            file = dir()
            index += 1
        wend
        result &= _lsfValue( "count" )
        result &= _lsfValue( str( index ) )        
        return result
    end function
    
    function _lsfValue( value as string ) as string
        dim as integer l = len( value )
        dim as string z = chr( (65 + (l and 15)) )
        while( l > 15 )
            l = (l shr 4)
            z = (chr( (97 + (l and 15)) ) & z)
        wend
        return (z & value)
    end function
    
    function _loadConfig( n as string ) as string
        dim as string key = "", value, l
        dim as integer ff = freefile(), e
        dim as string prefix = "", result = ""
        if( open( n for input as ff ) = 0 ) then
            while( not eof( ff ) )
                line input #ff, l
                if( (asc( l, 1 ) = 91) and (asc( l, len( l ) ) = 93) ) then  '[ and ]
                    prefix = (mid( l, 2, (len( l ) - 2) ) & ".")
                elseif( asc( l, 1 ) = 35 ) then
                    ' comment
                else
                    e = instr( l, "=" )
                    if( e > 0 ) then
                        result &= ExtPlatform._lsfValue( (prefix & mid( l, 1, (e - 1) )) )
                        result &= ExtPlatform._lsfValue( mid( l, (e + 1) ) )
                    end if
                end if
            wend
        end if
        return result
    end function
    
    function _createDateSerial() as string
        dim ts as string = (date() & time())
        return (mid( ts, 7, 4 ) & mid( ts, 1, 2 ) & mid( ts, 4, 2 ) & _
                mid( ts, 11, 2 ) & mid( ts, 14, 2 ) & mid( ts, 17, 2 ) )
    end function
end namespace
