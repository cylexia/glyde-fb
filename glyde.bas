#include "lib/libmain.bas"
#include "lib/libvecfont.bas"
#include "lib/libglue.bas"
#include "mod/platform.bas"

#define __GLYDE__
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
dim as integer morse_mouse_key = -1
Glyde.setData( Glyde.D_WINDOW_FLAGS, Dict.valueOf( vars, "WINDOW_FLAGS" ) )

if( (morse_key = "kiosk") or Dict.intValueOf( vars, "KIOSK", 0 ) = 1 ) then
    morse_mouse_key = -2
elseif( len( morse_key ) = 4 ) then
    ' use "mb:(a-z)" to define the mouse button mapping
    morse_mouse_key = (asc( morse_key, 4 ) - 96)
    ' since morse_key will be "mb:X" the standard keyboard method is disabled
end if

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
dim as integer kiosk_mouse_timeout = 0      ' will trigger kiosk changes immediately
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
        ' if morse_mouse_key is -1 then work as normal, if 1 disable normal
        '  mouse hittesting and only use morse-key, if >1 then enable normal
        '  left-button hittesting and use morse-key on the other button
        if( mb > 0 ) then
            if( morse_mouse_key = -2 ) then     ' kiosk mode
                dim as integer mbt = mb
                while( mbt > 0 )
                    getmouse mx, my, , mbt
                    sleep 15, 1
                wend
                if( mb = 1 ) then
                    'left mouse button to select
                    timeout = (timer() + 2)
                    Glyde.hilightNext()
                    key = ""
                elseif( mb = 2 ) then
                    timeout = -1
                    key = chr( 13 )
                end if
            elseif( (mb = 1) or (morse_mouse_key > -1) ) then                   ' left mouse, or morse-key
                ' since we're using the left mouse button for the morse-key functionaility
                ' we don't allow clicking with it
                if( mb = morse_mouse_key ) then
                    while( mb > 0 )
                        getmouse mx, my, , mb
                        sleep 15, 1
                    wend
                    key = morse_key
                else
                    ' not the morse_key was pressed so it must be the lmb, we'll continue as normal
                    if( (ox <> mx) or (oy <> my) ) then
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
                            Glyde.hilightNone()
                            label = Dict.valueOf( *hit, "action" )
                            if( len( label ) = 0 ) then
                                Utils.echoError( "[Glyde] No action specified for button" )
                                running = FALSE
                            end if
                            exit while
                        end if
                    end if
                end if
            end if
        else
            key = inkey()
        end if
        
        if( len( key ) > 0 ) then
            timeout = -1
            if( (key = closewindowchr) ) then 'or (key = chr( 27 )) ) then
                dim as string ex = Glyde.getData( Glyde.D_CLOSE_HANDLER )
                if( len( ex ) > 0 ) then
                    label = ex
                    exit while
                else
                    end
                end if
            elseif( key = morse_key ) then
                timeout = (timer() + 1)
                label = Glyde.morseKeyPressed()
                if( len( label ) > 0 ) then
                    exit while
                end if
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
            if( morse_mouse_key <> -2 ) then
                ' timeout for normal morse-key is to trigger the selected item
                label = Glyde.getHilightedAction()
                Glyde.hilightNone()
                if( len( label ) > 0 ) then
                    exit while
                end if
            else
                'timeout for kiosk mode morse-key is to reset the hilight only
                Glyde.hilightNone()
            end if
        end if
        
        ' Do Glyde's timer checks
        if( Glyde.checkTimer() ) then
            label = Glyde.getTimerLabel()
            exit while
        end if

        ' Kiosk mode's move mouse to stop screen saver?
        if( morse_mouse_key = -2 ) then
            if( timer() > kiosk_mouse_timeout ) then
                kiosk_mouse_timeout = (timer() + 30)
                setmouse (rnd() * 20), (rnd() * 20), 0
            end if
        end if
        
        sleep 15, 1
    wend
wend

end
