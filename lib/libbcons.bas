' libbcons.bas
' Buffered Console Library
' Copyright, (c)2014-2015 by Cylexia
'
' MIT Licensed
'
' Provides a backbuffer for the console
'

' Displays information about the drawing process
'#define SHOW_BUFFER_STATS

namespace ConsoleBuffer
    declare function init( useansi as integer = 0 ) as integer
    declare sub wipe( bg as integer = 0 )
    declare sub writeText( text as string, col as integer, row as integer, fg as integer, bg as integer = -1 )
    declare sub drawBox( x as integer, y as integer, w as integer, h as integer, fg as integer, filled as integer = 0 )
    declare function loadImage( file as string ) as string
    declare sub drawImage( x as integer, y as integer, idata as string, ix as integer, iy as integer, iw as integer = -1, ih as integer = -1, tc as integer = -1 )
    
    declare sub display( row as integer = 1, lines as integer = -1 )
    declare function _txt( x as integer, y as integer, txtbuffer() as ubyte, ofs as integer, l as integer, fg as integer, bg as integer, flags as ubyte ) as ubyte
    declare function _txt_console( x as integer, y as integer, txtbuffer() as ubyte, ofs as integer, l as integer, fg as integer, bg as integer, flags as ubyte ) as ubyte
    declare function _txt_ansi( x as integer, y as integer, txtbuffer() as ubyte, ofs as integer, l as integer, fg as integer, bg as integer, flags as ubyte ) as ubyte

    dim as string color_map
    
    dim as ubyte s_txtbuffer()
    dim as ubyte s_clrbuffer()
    dim as integer s_bwidth
    dim as integer s_fg
    dim as integer s_bg
    
    dim as integer _useansi
    
    function init( useansi as integer = 0 ) as integer
        ConsoleBuffer._useansi = useansi
        dim as integer wh = width(), w, h
        w = LOWORD( wh )
        h = HIWORD( wh )
        ConsoleBuffer.s_bwidth = w
        redim ConsoleBuffer.s_txtbuffer((w * h))
        redim ConsoleBuffer.s_clrbuffer((w * h))
        return -1
    end function

    ' Note: the pointer created here must be deallocated manually when you're
    '  done with it
    function saveBuffers() as ubyte ptr
        dim as integer blen = (ubound( ConsoleBuffer.s_txtbuffer ) + 1)
        dim as ubyte ptr store = cptr( ubyte ptr, allocate( (blen * 2) ) )
        if( store <> 0 ) then
            dim as integer i, iptr = 0
            for i = 0 to (blen - 1)
                store[iptr] = ConsoleBuffer.s_txtbuffer(i)
                iptr += 1
            next
            for i = 0 to (blen - 1)
                store[iptr] = ConsoleBuffer.s_clrbuffer(i)
                iptr += 1
            next
        end if    
        return store
    end function
    
    function loadBuffers( store as ubyte ptr ) as integer
        if( store <> 0 ) then
            dim as integer blen = (ubound( ConsoleBuffer.s_txtbuffer ) + 1)
            dim as integer i, iptr = 0
            for i = 0 to (blen - 1)
                ConsoleBuffer.s_txtbuffer(i) = store[iptr]
                iptr += 1
            next
            for i = 0 to (blen - 1)
                ConsoleBuffer.s_clrbuffer(i) = store[iptr]
                iptr += 1
            next
            return -1
        end if
        return 0
    end function
            
    function getWidth() as integer
        return ConsoleBuffer.s_bwidth
    end function
    
    function getHeight() as integer
        return (ubound( ConsoleBuffer.s_clrbuffer ) / ConsoleBuffer.s_bwidth)
    end function
    
    sub wipe( bg as integer = 0 )
        dim as integer ofs, m = ubound( ConsoleBuffer.s_clrbuffer )
        for ofs = 0 to m
            ConsoleBuffer.s_clrbuffer(ofs) = bg
            ConsoleBuffer.s_txtbuffer(ofs) = 0
        next
    end sub
    
    sub writeText( text as string, col as integer, row as integer, fg as integer, bg as integer = -1 )
        'dim as integer x = (col - 1), y = (row - 1)
        dim as integer x = col, y = row
        dim as integer i, l = len( text )
        dim as integer ofs = ((ConsoleBuffer.s_bwidth * y) + x)
        dim as ubyte c' = ((ConsoleBuffer.s_fg shl 4) or Deck.s_bg)
        if( bg > -1 ) then
            c = cbyte( bg )
        end if
        for i = 1 to l
            if( ofs >= ubound( ConsoleBuffer.s_txtbuffer ) ) then
                exit for
            end if
            if( bg = -1 ) then
                c = (ConsoleBuffer.s_clrbuffer(ofs) and &h0F)
            end if
            ConsoleBuffer.s_clrbuffer(ofs) = ((fg shl 4) or c)
            ConsoleBuffer.s_txtbuffer(ofs) = asc( text, i )
            ofs += 1
        next
    end sub
    
    function loadImage( file as string ) as string
        dim as string row, cmap
        dim as integer iw, ih, x, y, v
        dim as integer ff = freefile()
        if( open( file, for input, as ff ) = 0 ) then
            line input #ff, row
            iw = val( mid( row, 1, 3 ) )
            ih = val( mid( row, 3, 3 ) )
            cmap = mid( row, 6 )
            
            dim as string idata = (chr( (iw + 36) ) & chr( (ih + 36) ))
            
            for y = 1 to (ih + 1)
                line input #ff, row
                for x = 1 to iw
                    v = instr( cmap, chr( asc( row, x ) ) )
                    if( v > 0 ) then
                        idata &= chr( (v - 1) + 36 )
                    end if
                next
            next
            close #1
            return idata
        else
            return ""
        end if
    end function
    
    sub drawImage( x as integer, y as integer, idata as string, ix as integer, iy as integer, iw as integer = -1, ih as integer = -1, tc as integer = -1 )
        dim as integer fiw = (asc( idata, 1 ) - 36)
        dim as integer fih = (asc( idata, 2 ) - 36)
        dim as integer p
        dim as integer col, row = iy
        dim as integer xi, yi
        dim as integer ofs
        dim as ubyte c
        for yi = 0 to (ih - 1)
            p = ((fiw * (yi + iy)) + 3)
            ofs = ((ConsoleBuffer.s_bwidth * (y + yi)) + x)
            for xi = ix to (ix + iw - 1)
                c = (asc( idata, (p + xi) ) - 36 - 1)
                if( c <> tc ) then
                    c = ((c shl 4) or c)
                    ConsoleBuffer.s_clrbuffer(ofs) = c
                    ConsoleBuffer.s_txtbuffer(ofs) = 32
                end if
                ofs += 1
            next
        next
    end sub
    
    sub drawBox( x as integer, y as integer, w as integer, h as integer, fg as integer, filled as integer = 0 )
        dim as integer i
        dim as string horiz = space( w )
        if( filled ) then
            for i = 0 to (h - 1)
                ConsoleBuffer.writeText( horiz, x, (y + i), fg, fg )
            next
        else
            ConsoleBuffer.writeText( horiz, x, y, fg, fg )
            ConsoleBuffer.writeText( horiz, x, (y + h - 1), fg, fg )
            y += 1
            dim as ubyte c = ((fg shl 4) or fg)
            dim as integer ofsl = ((ConsoleBuffer.s_bwidth * y) + x)
            dim as integer ofsr = ((ConsoleBuffer.s_bwidth * y) + (x + w - 1))
            for i = 1 to (h - 2)
                ConsoleBuffer.s_clrbuffer(ofsl) = c
                ConsoleBuffer.s_txtbuffer(ofsl) = 32
                ConsoleBuffer.s_clrbuffer(ofsr) = c
                ConsoleBuffer.s_txtbuffer(ofsr) = 32
                ofsl += ConsoleBuffer.s_bwidth
                ofsr += ConsoleBuffer.s_bwidth
            next
        end if
    end sub

    sub setPixel( x as integer, y as integer, char as ubyte, fg as ubyte, bg as ubyte )
        dim as integer b = ((y * ConsoleBuffer.s_bwidth) + x)
        if( (b < 0) or (b >= ubound( ConsoleBuffer.s_txtbuffer )) ) then
            return
        end if
        ConsoleBuffer.s_clrbuffer(b) = ((fg shl 4) or bg)
        ConsoleBuffer.s_txtbuffer(b) = char
    end sub

    sub writeToBuffers( x as integer, y as integer, value as string, fg as ubyte, bg as ubyte )
        dim as integer b = ((y * ConsoleBuffer.s_bwidth) + x)
        if( (b < 0) or (b >= ubound( ConsoleBuffer.s_txtbuffer )) ) then
            return
        end if
        ConsoleBuffer.s_clrbuffer(b) = ((fg shl 4) or bg)
        dim as integer i = 1, l = len( value )
        while( i <= l )
            ConsoleBuffer.s_txtbuffer(b) = asc( value, i )
            b += 1
            i += 1
            if( b >= ubound( ConsoleBuffer.s_txtbuffer ) ) then
                exit while
            end if
        wend
    end sub

    ' char, clr are OUTPUTs to pointers.  clr is ((fg << 4) | bg)
    function readFromBuffers( x as integer, y as integer, char as ubyte ptr, clr as ubyte ptr ) as integer
        dim as integer b = ((y * ConsoleBuffer.s_bwidth) + x)
        if( (b < 0) or (b >= ubound( ConsoleBuffer.s_txtbuffer )) ) then
            return 0
        end if
        char = @ConsoleBuffer.s_txtbuffer(b)
        clr = @ConsoleBuffer.s_clrbuffer(b)
        return -1
    end function

    sub display( row as integer = 1, lines as integer = -1 )
        ' fast write clrbuffer all at once (compresses x widths into space strings)
        #ifdef SHOW_BUFFER_STATS
        dim as double start = timer()
        dim as integer hits = 0
        #endif

        dim as integer flags = 0
        dim as integer x = 1, y = 1
        dim as integer dx, dy
        dim as integer bclr, blen, clr, cc
        dim as integer w = ConsoleBuffer.s_bwidth, h
        if( lines = -1 ) then
            h = (ubound( ConsoleBuffer.s_clrbuffer ) / ConsoleBuffer.s_bwidth)
        else
            h = (lines + row - 1)
        end if
        dim as integer vx, vy, bi
        dim as string csi
        if( ConsoleBuffer._useansi ) then
            csi = (chr( 27 ) & "[")
            open cons for output as #1
        end if
        for dy = (row - 1) to (h - 1)
            bclr = -1
            blen = 0
            vy = (y + dy)
            vx = x
            if( ConsoleBuffer._useansi ) then
                ' this only works if you use it once per line
                ' doing it for each block breaks the display
                print #1, (csi & str( vy ) & ";" & str( x ) & "H");
            end if
            for dx = 0 to (w - 1)
                bi = (dy * w) + dx
                if( bi > ubound( ConsoleBuffer.s_clrbuffer ) ) then
                    exit for
                end if
                clr = ConsoleBuffer.s_clrbuffer(bi)
                if( clr <> bclr ) then
                    if( bclr > -1 ) then
                        flags = ConsoleBuffer._txt( vx, vy, ConsoleBuffer.s_txtbuffer(), (((dy * w) + vx) - 1), blen, ((bclr shr 4) and &hF), (bclr and &hF), flags )
                        #ifdef SHOW_BUFFER_STATS
                            hits += 1
                        #endif
                    end if
                    vx += blen
                    bclr = clr
                    blen = 1
                else
                    blen += 1
                end if
            next
            flags = ConsoleBuffer._txt( vx, vy, ConsoleBuffer.s_txtbuffer(), (((dy * w) + vx) - 1), blen, ((bclr shr 4) and &hF), (bclr and &hF), flags )
            #ifdef SHOW_BUFFER_STATS
                hits += 1
            #endif
        next
        #ifdef SHOW_BUFFER_STATS
            if( ConsoleBuffer._useansi ) then
                print #1, (csi & "1;1f" & csi & "37;40m");
            else
                locate 1, 1
                color 7, 0
            endif
            print "writes to console: "; hits; " | rendered in ";
            print int( ((timer() - start) * 1000) ); "ms   "
        #endif
        color 7, 0
        locate 1, 1, 0
        if( ConsoleBuffer._useansi ) then
            close #1
        end if
    end sub

    function _txt( x as integer, y as integer, txtbuffer() as ubyte, ofs as integer, l as integer, fg as integer, bg as integer, flags as ubyte ) as ubyte
        if( ConsoleBuffer._useansi ) then
            return ConsoleBuffer._txt_ansi( x, y, txtbuffer(), ofs, l, fg, bg, flags )
        endif
        return ConsoleBuffer._txt_console( x, y, txtbuffer(), ofs, l, fg, bg, flags )
    end function

    ' text mode (x and y are 1 based):
    function _txt_console( x as integer, y as integer, txtbuffer() as ubyte, ofs as integer, l as integer, fg as integer, bg as integer, flags as ubyte ) as ubyte
        dim as string s = ""
        dim as integer i, c
        for i = 1 to l
            c = txtbuffer( (ofs + i - 1) )
            if( (c < 32) or (c > 128) ) then
                c = 32
            end if
            s &= chr( c )
        next
        locate y, x
        color fg, bg
        print s;
        return flags
    end function

    ' ANSI mode (x and y are 1 based):
    function _txt_ansi( x as integer, y as integer, txtbuffer() as ubyte, ofs as integer, l as integer, fg as integer, bg as integer, flags as ubyte ) as ubyte
        if( ConsoleBuffer._useansi ) then
            dim as string s = ""
            dim as integer i, c
            for i = 1 to l
                c = txtbuffer( (ofs + i - 1) )
                if( c < 32 ) then
                    c = 32
                end if
                s &= chr( c )
            next
            dim as string csi = (chr( 27 ) & "[")
            print #1, csi;
            if( bg > 7 ) then
                print #1, str(40 + (bg - 7)); ";5;";
            else
                print #1, str(40 + bg); ";";
            end if
            if( fg > 7 ) then
                print #1, str(30 + (fg - 7)); ";1";
            else
                print #1, str(30 + fg);
            end if
            print #1, "m";
            print #1, s;
            print #1, csi; "0m";
        end if
        return flags
    end function
end namespace
