#include "lib/libmain.bas"
#include "lib/libvecfont.bas"
#include "lib/libglue.bas"
#include "mod/platform.bas"

#define __GLYDE__
#include "ns-ui.bas"
#include "ns-imagemap.bas"
#include "ns-glyde.bas"

VecText.init()
Glue.init()
ExtPlatform.init()
ImageMap.init()
Glyde.init()

dim as DICTSTRING vars = Utils.parseCommandLine( Dict.create(), Utils.PCL_UCASE )

dim as string appfile = Dict.valueOf( vars, "_" )
dim as string morse_key = Dict.valueOf( vars, "MORSEKEY", " " )
Glyde.setData( Glyde.D_WINDOW_FLAGS, Dict.valueOf( vars, "WINDOW_FLAGS" ) )

if( len( appfile ) = 0 ) then
    dim as string exe = command(0)
    dim as integer l = (len( exe ) - 3)
    if( lcase( mid( exe, l ) ) = ".exe" ) then
        exe = mid( exe, 1, (l - 1) )
    end if
    appfile = (exe & ".app")
end if

' Load the definition, exit if unable to load
dim as DICTSTRING appdef = Glyde.readConfigFile( appfile )
if( len( appdef ) = 0 ) then
    Utils.echoError( ("[Glyde] Unable to open file: " & appfile) )
    end
end if

' Get the script file, exit if empty
dim as string scriptfile = Dict.valueOf( appdef, "script" )
if( len( scriptfile ) = 0 ) then
    Utils.echoError( ("[Glyde] Invalid application manifest: " & appfile) )
    end
end if

' Parse the variables list and insert into our existing variables dict
dim as string vardefs = Dict.valueOf( appdef, "var" )
if( len( vardefs ) > 0 ) then
    vardefs = (vardefs & "\n")
    dim as integer vi = instr( vardefs, !"\n" ), vb
    dim as string vardef
    while( vi > 0 )
        vardef = mid( vardefs, 1, (vi - 1) )
        vb = instr( vardef, "=" )
        if( vb > 0 ) then
            Dict.set( vars,  _
                    mid( vardef, 1, (vb - 1) ),  _
                    mid( vardef, (vb + 1) )  _
                )
        end if
        vardefs = mid( vardefs, (vi + 1) )
        vb = instr( vardefs, !"\n" )
    wend
end if

' Load the scriptfile, exit if unable to read
dim as integer ern = 0
dim as string script = Utils.readFile( scriptfile, ern )
if( ern <> 0 ) then
    Utils.echoError( ("[Glyde] Unable to read '" & scriptfile & "'") )
    end
end if

' Load the script into Glue
Glue.load( script, vars )


' Main loop
dim as integer res
dim as string label
dim as integer mx, my, mb
dim as DICTSTRING ptr hit, lasthit = 0
dim as string key, closewindowchr = (chr( 255 ) & "k")
dim as integer running = TRUE
dim as integer ox = -1, oy = -1
dim as double timeout = -1
while( running )
    res = Glue.run( label )
    Glyde.repaint()
    select case res
        case 0:
            Utils.echoError( "[Glyde] Glue Error" )
            exit while
        case -254:
            running = FALSE
            exit while
    end select
    
    while( TRUE )
        getmouse( mx, my, , mb )
        if( (ox <> mx) or (oy <> my) or (mb > 0) ) then
            ox = mx
            oy = my
            hit = Glyde.hittest( mx, my )
            if( hit <> lasthit ) then
                Glyde.repaint()
                lasthit = hit
            end if
            if( (hit <> 0) and (mb > 0) ) then
                while( mb > 0 )
                    getmouse mx, my, , mb
                    sleep 15, 1
                wend
                Glyde.setData( Glyde.D_LAST_HIT_BUTTON, Dict.valueOf( *hit, "id" ) )
                label = Dict.valueOf( *hit, "action" )
                if( len( label ) = 0 ) then
                    Utils.echoError( "[Glyde] No action specified for button" )
                    running = FALSE
                end if
                exit while
            end if
        end if
        
        key = inkey()
        if( len( key ) > 0 ) then
            timeout = -1
            if( (key = chr( 27 )) or (key = closewindowchr) ) then
                dim as string ex = Glyde.getData( Glyde.D_CLOSE_HANDLER )
                if( len( ex ) > 0 ) then
                    label = ex
                    exit while
                else
                    end
                end if
            elseif( key = morse_key ) then
                Glyde.hilightNext()
                timeout = (timer() + 1)
            elseif( (key = chr( 13 )) or (key = chr( 10 )) ) then
                timeout = -1
                label = Glyde.getHilightedAction()
                Glyde.hilightNone()
                if( len( label ) > 0 ) then
                    exit while
                end if
            elseif( asc( key, 1 ) = 255 ) then
                select case asc( key, 2 )
                    case 80:
                        Glyde.hilightNext()
                    case 72:
                        Glyde.hilightPrev()
                end select
            else
                key = Glyde.keytest( key )
                if( len( key ) > 0 ) then
                    Glyde.setData( Glyde.D_LAST_HIT_BUTTON, Dict.valueOf( key, "id" ) )
                    label = Dict.valueOf( key, "label" )
                    exit while
                end if
            end if
        end if
        
        if( (timeout > -1) and (timer() > timeout) ) then
            timeout = -1
            label = Glyde.getHilightedAction()
            Glyde.hilightNone()
            if( len( label ) > 0 ) then
                exit while
            end if
        end if
        
        if( Glyde.checkTimer() ) then
            label = Glyde.getTimerLabel()
            exit while
        end if
        
        sleep 15, 1
    wend
wend

end
