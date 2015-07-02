#include "libmain.bas"

#ifndef __LIBVECFONT
#define __LIBVECFONT

namespace VecText
    declare function init() as integer
    'declare function loadFromFile( f as string ) as integer
    'declare function loadFromArray(  array() as ubyte ) as integer
    declare sub useContext( c as any ptr )
    declare function drawString( text as string, clr as integer, x as integer, y as integer, s as integer = 2, lw as integer = 1, lh as integer = 1 ) as integer
    declare function drawStringWithBackground( text as string, fg as integer, bg as integer, x as integer, y as integer, s as integer = 2, lw as integer = 1, lh as integer = 1 ) as integer
    declare function getGlyphWidth( s as integer, lw as integer = 1 ) as integer
    declare function getGlyphHeight( s as integer, lh as integer = 1 ) as integer
    declare function _getGlyphInfo( g as ubyte, byref coff as integer, byref clen as integer ) as integer
    declare sub _drawGlyph( dleft as integer, dtop as integer, dwidth as integer, dheight as integer, dsize as integer, dclr as integer, coff as integer, clen as integer )

    dim as ubyte _fdata(1148) = {  _
            &h01,	&h00,	&h00,	&hFC,	&h03,	&h7A,	&h41,	&h00,	   _
            &h00,	&h42,	&h00,	&h0C,	&h43,	&h00,	&h20,	&h44,	   _
            &h00,	&h2A,	&h45,	&h00,	&h36,	&h46,	&h00,	&h3E,	   _
            &h47,	&h00,	&h44,	&h48,	&h00,	&h52,	&h49,	&h00,	   _
            &h58,	&h4A,	&h00,	&h5E,	&h4B,	&h00,	&h68,	&h4C,	   _
            &h00,	&h70,	&h4D,	&h00,	&h74,	&h4E,	&h00,	&h7C,	   _
            &h4F,	&h00,	&h82,	&h50,	&h00,	&h92,	&h51,	&h00,	   _
            &h9E,	&h52,	&h00,	&hB0,	&h53,	&h00,	&hBE,	&h54,	   _
            &h00,	&hD0,	&h55,	&h00,	&hD4,	&h56,	&h00,	&hDE,	   _
            &h57,	&h00,	&hE6,	&h58,	&h00,	&hEE,	&h59,	&h00,	   _
            &hFA,	&h5A,	&h01,	&h04,	&h61,	&h01,	&h0E,	&h62,	   _
            &h01,	&h1E,	&h63,	&h01,	&h2E,	&h64,	&h01,	&h38,	   _
            &h65,	&h01,	&h48,	&h66,	&h01,	&h58,	&h67,	&h01,	   _
            &h60,	&h68,	&h01,	&h74,	&h69,	&h01,	&h7C,	&h6A,	   _
            &h01,	&h88,	&h6B,	&h01,	&h98,	&h6C,	&h01,	&hA4,	   _
            &h6D,	&h01,	&hAA,	&h6E,	&h01,	&hB4,	&h6F,	&h01,	   _
            &hBC,	&h70,	&h01,	&hCC,	&h71,	&h01,	&hD8,	&h72,	   _
            &h01,	&hE4,	&h73,	&h01,	&hEC,	&h74,	&h01,	&hFA,	   _
            &h75,	&h02,	&h02,	&h76,	&h02,	&h0C,	&h77,	&h02,	   _
            &h14,	&h78,	&h02,	&h22,	&h79,	&h02,	&h26,	&h7A,	   _
            &h02,	&h36,	&h31,	&h02,	&h3C,	&h32,	&h02,	&h42,	   _
            &h33,	&h02,	&h4E,	&h34,	&h02,	&h5C,	&h35,	&h02,	   _
            &h62,	&h36,	&h02,	&h70,	&h37,	&h02,	&h84,	&h38,	   _
            &h02,	&h8C,	&h39,	&h02,	&hAA,	&h30,	&h02,	&hBA,	   _
            &h2E,	&h02,	&hCC,	&h2C,	&h02,	&hD2,	&h3A,	&h02,	   _
            &hDA,	&h3B,	&h02,	&hE6,	&h21,	&h02,	&hF4,	&h3F,	   _
            &h02,	&hFC,	&h27,	&h03,	&h0C,	&h22,	&h03,	&h12,	   _
            &h24,	&h03,	&h1E,	&h28,	&h03,	&h2A,	&h29,	&h03,	   _
            &h30,	&h25,	&h03,	&h36,	&h7D,	&h03,	&h48,	&h7B,	   _
            &h03,	&h4E,	&h2F,	&h03,	&h54,	&h5C,	&h03,	&h56,	   _
            &h2D,	&h03,	&h58,	&h2B,	&h03,	&h5A,	&h2A,	&h03,	   _
            &h5E,	&h5E,	&h03,	&h66,	&h26,	&h03,	&h6A,	&h00,	   _
            &h03,	&h7A,	&h01,	&h35,	&h01,	&h01,	&h10,	&h12,	   _
            &h30,	&h21,	&h41,	&h35,	&h03,	&h14,	&h00,	&h36,	   _
            &h00,	&h13,	&h30,	&h21,	&h41,	&h31,	&h33,	&h01,	   _
            &h33,	&h21,	&h44,	&h31,	&h06,	&h13,	&h36,	&h01,	   _
            &h03,	&h13,	&h10,	&h13,	&h01,	&h01,	&h01,	&h34,	   _
            &h05,	&h21,	&h16,	&h13,	&h00,	&h13,	&h30,	&h21,	   _
            &h06,	&h13,	&h36,	&h01,	&h41,	&h34,	&h00,	&h36,	   _
            &h00,	&h36,	&h00,	&h14,	&h03,	&h13,	&h06,	&h14,	   _
            &h00,	&h36,	&h00,	&h14,	&h03,	&h13,	&h10,	&h13,	   _
            &h01,	&h01,	&h01,	&h34,	&h05,	&h21,	&h16,	&h13,	   _
            &h43,	&h33,	&h33,	&h11,	&h00,	&h36,	&h40,	&h36,	   _
            &h03,	&h14,	&h20,	&h36,	&h00,	&h14,	&h06,	&h14,	   _
            &h20,	&h12,	&h40,	&h35,	&h36,	&h01,	&h05,	&h21,	   _
            &h16,	&h12,	&h00,	&h36,	&h13,	&h03,	&h13,	&h23,	   _
            &h03,	&h11,	&h00,	&h36,	&h06,	&h14,	&h00,	&h36,	   _
            &h00,	&h22,	&h22,	&h02,	&h40,	&h36,	&h00,	&h36,	   _
            &h00,	&h24,	&h40,	&h36,	&h01,	&h34,	&h41,	&h34,	   _
            &h10,	&h12,	&h16,	&h12,	&h01,	&h01,	&h30,	&h21,	   _
            &h05,	&h21,	&h36,	&h01,	&h00,	&h36,	&h00,	&h13,	   _
            &h30,	&h21,	&h03,	&h13,	&h33,	&h01,	&h41,	&h31,	   _
            &h01,	&h34,	&h41,	&h34,	&h10,	&h12,	&h16,	&h12,	   _
            &h01,	&h01,	&h30,	&h21,	&h05,	&h21,	&h36,	&h01,	   _
            &h24,	&h22,	&h00,	&h36,	&h00,	&h13,	&h30,	&h21,	   _
            &h03,	&h13,	&h33,	&h01,	&h41,	&h31,	&h13,	&h23,	   _
            &h10,	&h13,	&h01,	&h01,	&h01,	&h31,	&h02,	&h21,	   _
            &h13,	&h12,	&h33,	&h21,	&h44,	&h31,	&h06,	&h13,	   _
            &h36,	&h01,	&h00,	&h14,	&h20,	&h36,	&h00,	&h35,	   _
            &h05,	&h21,	&h16,	&h12,	&h36,	&h01,	&h40,	&h35,	   _
            &h00,	&h34,	&h04,	&h22,	&h26,	&h02,	&h40,	&h34,	   _
            &h00,	&h36,	&h06,	&h02,	&h24,	&h22,	&h40,	&h36,	   _
            &h00,	&h31,	&h40,	&h31,	&h05,	&h31,	&h45,	&h31,	   _
            &h01,	&h24,	&h05,	&h04,	&h00,	&h31,	&h40,	&h31,	   _
            &h01,	&h22,	&h23,	&h02,	&h23,	&h33,	&h00,	&h14,	   _
            &h06,	&h14,	&h40,	&h31,	&h05,	&h31,	&h05,	&h04,	   _
            &h02,	&h13,	&h32,	&h21,	&h43,	&h33,	&h05,	&h01,	   _
            &h14,	&h13,	&h05,	&h21,	&h16,	&h12,	&h36,	&h01,	   _
            &h00,	&h36,	&h03,	&h01,	&h12,	&h12,	&h32,	&h21,	   _
            &h43,	&h32,	&h05,	&h21,	&h16,	&h12,	&h36,	&h01,	   _
            &h03,	&h01,	&h12,	&h13,	&h03,	&h32,	&h05,	&h21,	   _
            &h16,	&h13,	&h03,	&h01,	&h12,	&h12,	&h32,	&h21,	   _
            &h03,	&h32,	&h05,	&h21,	&h16,	&h12,	&h36,	&h01,	   _
            &h40,	&h36,	&h03,	&h01,	&h12,	&h12,	&h32,	&h21,	   _
            &h03,	&h32,	&h05,	&h21,	&h16,	&h13,	&h04,	&h14,	   _
            &h43,	&h31,	&h11,	&h35,	&h11,	&h01,	&h20,	&h12,	   _
            &h03,	&h13,	&h03,	&h01,	&h12,	&h12,	&h32,	&h21,	   _
            &h03,	&h31,	&h04,	&h21,	&h15,	&h12,	&h35,	&h01,	   _
            &h42,	&h34,	&h07,	&h13,	&h37,	&h01,	&h00,	&h36,	   _
            &h02,	&h13,	&h32,	&h21,	&h43,	&h33,	&h06,	&h14,	   _
            &h22,	&h34,	&h12,	&h11,	&h10,	&h21,	&h10,	&h11,	   _
            &h20,	&h31,	&h42,	&h34,	&h06,	&h21,	&h17,	&h12,	   _
            &h37,	&h01,	&h22,	&h12,	&h20,	&h21,	&h20,	&h11,	   _
            &h30,	&h31,	&h00,	&h36,	&h04,	&h11,	&h14,	&h22,	   _
            &h36,	&h11,	&h14,	&h02,	&h32,	&h11,	&h06,	&h14,	   _
            &h10,	&h11,	&h20,	&h36,	&h02,	&h34,	&h02,	&h13,	   _
            &h22,	&h34,	&h32,	&h21,	&h43,	&h33,	&h02,	&h34,	   _
            &h02,	&h13,	&h32,	&h21,	&h43,	&h33,	&h03,	&h01,	   _
            &h12,	&h12,	&h32,	&h21,	&h43,	&h32,	&h03,	&h32,	   _
            &h05,	&h21,	&h16,	&h12,	&h36,	&h01,	&h02,	&h35,	   _
            &h02,	&h13,	&h32,	&h21,	&h43,	&h31,	&h05,	&h13,	   _
            &h35,	&h01,	&h03,	&h01,	&h12,	&h13,	&h42,	&h35,	   _
            &h03,	&h31,	&h04,	&h21,	&h15,	&h13,	&h02,	&h34,	   _
            &h03,	&h01,	&h12,	&h12,	&h32,	&h21,	&h06,	&h13,	   _
            &h36,	&h01,	&h03,	&h01,	&h12,	&h13,	&h03,	&h21,	   _
            &h14,	&h12,	&h34,	&h21,	&h10,	&h35,	&h15,	&h21,	   _
            &h26,	&h12,	&h02,	&h13,	&h02,	&h33,	&h05,	&h21,	   _
            &h16,	&h12,	&h36,	&h01,	&h42,	&h34,	&h02,	&h32,	   _
            &h04,	&h22,	&h26,	&h02,	&h42,	&h32,	&h02,	&h33,	   _
            &h05,	&h21,	&h16,	&h01,	&h25,	&h21,	&h36,	&h01,	   _
            &h23,	&h32,	&h42,	&h33,	&h02,	&h24,	&h06,	&h04,	   _
            &h02,	&h32,	&h04,	&h21,	&h15,	&h12,	&h35,	&h01,	   _
            &h42,	&h34,	&h06,	&h21,	&h17,	&h12,	&h37,	&h01,	   _
            &h02,	&h14,	&h06,	&h04,	&h06,	&h14,	&h02,	&h02,	   _
            &h20,	&h36,	&h06,	&h14,	&h01,	&h01,	&h10,	&h12,	   _
            &h30,	&h21,	&h06,	&h04,	&h41,	&h31,	&h06,	&h14,	   _
            &h00,	&h14,	&h13,	&h03,	&h13,	&h12,	&h33,	&h21,	   _
            &h06,	&h13,	&h36,	&h01,	&h44,	&h31,	&h30,	&h36,	   _
            &h03,	&h03,	&h03,	&h14,	&h00,	&h14,	&h00,	&h33,	   _
            &h03,	&h13,	&h33,	&h21,	&h06,	&h13,	&h36,	&h01,	   _
            &h44,	&h31,	&h10,	&h13,	&h01,	&h01,	&h01,	&h34,	   _
            &h05,	&h21,	&h16,	&h12,	&h36,	&h01,	&h04,	&h01,	   _
            &h13,	&h12,	&h33,	&h21,	&h44,	&h31,	&h00,	&h14,	   _
            &h40,	&h31,	&h23,	&h02,	&h23,	&h33,	&h01,	&h01,	   _
            &h10,	&h12,	&h30,	&h21,	&h41,	&h31,	&h05,	&h21,	   _
            &h16,	&h12,	&h36,	&h01,	&h01,	&h31,	&h04,	&h31,	   _
            &h44,	&h31,	&h02,	&h21,	&h04,	&h01,	&h13,	&h12,	   _
            &h33,	&h01,	&h33,	&h21,	&h01,	&h01,	&h10,	&h12,	   _
            &h30,	&h21,	&h41,	&h35,	&h01,	&h31,	&h02,	&h21,	   _
            &h13,	&h12,	&h33,	&h01,	&h01,	&h01,	&h10,	&h12,	   _
            &h30,	&h21,	&h41,	&h34,	&h01,	&h34,	&h05,	&h21,	   _
            &h16,	&h12,	&h36,	&h01,	&h05,	&h04,	&h15,	&h11,	   _
            &h15,	&h21,	&h25,	&h31,	&h15,	&h11,	&h15,	&h21,	   _
            &h25,	&h31,	&h17,	&h01,	&h15,	&h11,	&h15,	&h21,	   _
            &h25,	&h31,	&h13,	&h11,	&h13,	&h21,	&h23,	&h31,	   _
            &h15,	&h11,	&h15,	&h21,	&h25,	&h31,	&h17,	&h01,	   _
            &h13,	&h11,	&h13,	&h21,	&h23,	&h31,	&h15,	&h11,	   _
            &h15,	&h21,	&h25,	&h31,	&h20,	&h34,	&h15,	&h11,	   _
            &h15,	&h21,	&h25,	&h31,	&h01,	&h01,	&h10,	&h12,	   _
            &h30,	&h21,	&h23,	&h02,	&h23,	&h31,	&h10,	&h11,	   _
            &h10,	&h21,	&h20,	&h31,	&h00,	&h11,	&h00,	&h21,	   _
            &h10,	&h31,	&h30,	&h11,	&h30,	&h21,	&h40,	&h31,	   _
            &h06,	&h14,	&h06,	&h01,	&h11,	&h34,	&h11,	&h01,	   _
            &h20,	&h12,	&h03,	&h14,	&h12,	&h02,	&h12,	&h33,	   _
            &h15,	&h22,	&h10,	&h22,	&h32,	&h33,	&h17,	&h02,	   _
            &h05,	&h04,	&h00,	&h11,	&h00,	&h31,	&h01,	&h11,	   _
            &h10,	&h31,	&h35,	&h11,	&h35,	&h31,	&h45,	&h31,	   _
            &h36,	&h11,	&h03,	&h14,	&h21,	&h22,	&h25,	&h02,	   _
            &h03,	&h14,	&h03,	&h02,	&h03,	&h22,	&h05,	&h04,	   _
            &h01,	&h24,	&h03,	&h14,	&h03,	&h14,	&h21,	&h34,	   _
            &h03,	&h14,	&h21,	&h34,	&h01,	&h24,	&h05,	&h04,	   _
            &h11,	&h01,	&h20,	&h21,	&h01,	&h24,	&h01,	&h01,	   _
            &h10,	&h21,	&h12,	&h01,	&h03,	&h01,	&h03,	&h32,	   _
            &h05,	&h21,	&h16,	&h03   _
        }
    dim as integer _g_table_len
    dim as integer _g_table_offset
    dim as integer _g_data_offset

    dim as any ptr _context
    
    function init() as integer
        VecText._g_table_len = ((VecText._fdata(2) shl 8) or VecText._fdata(3))
        VecText._g_table_offset = 6
        VecText._g_data_offset = (VecText._g_table_len + VecText._g_table_offset)
        VecText._context = 0
        return TRUE
    end function

    sub useContext( c as any ptr )
        VecText._context = c
    end sub

/'
    function loadFromFile( f as string ) as integer
        ' load the font
        open f for binary access read as 1
        dim as integer fl = lof( 1 ), fi = 0
        redim as ubyte fdata(fl)
        dim as ubyte fb
        while( not eof( 1 ) )
            get #1, , fb
            fdata(fi) = fb
            fi += 1
        wend
        close 1
        VecText.loadFromArray( fdata() )
        return TRUE         ' todo: fix this
    end function

    function loadFromArray( array() as ubyte ) as integer
        ' todo: could use memcpy for this (include "crt/string.bi") but this'll do
        redim VecText._fdata( ubound( array ) )
        dim i as integer
        for i = 0 to ubound( array )
            VecText._fdata(i) = array(i)
        next
        
        VecText._g_table_len = ((VecText._fdata(2) shl 8) or VecText._fdata(3))
        VecText._g_table_offset = 6
        VecText._g_data_offset = (VecText._g_table_len + VecText._g_table_offset)

        'print "Loaded font"
        'print "Version: "; VecText._fdata(0)
        'print "Flags: "; VecText._fdata(1)
        'print "glyph_def_table_len: "; VecText._g_table_len; " ("; (VecText._g_table_len / 3); " char(s))"
        'print "glyph_data_len: "; ((VecText._fdata(4) shl 8) or VecText._fdata(5))
        'print "glyph_data_offset: "; VecText._g_data_offset
        return TRUE         ' todo: some form of magic test to see if it's a font?
    end function
'/

    function getGlyphWidth( s as integer, lw as integer = 1 ) as integer
        return ((s * 5) + lw)
    end function
    
    function getGlyphHeight( s as integer, lh as integer = 1 ) as integer
        return ((s * 8) + lh)
    end function
    
    
    function drawStringWithBackground( text as string, fg as integer, bg as integer, x as integer, y as integer, s as integer = 2, lw as integer = 1, lh as integer = 1 ) as integer
        dim as integer dw = (VecText.getGlyphWidth( s, lw ) * len( text ))
        dim as integer dh = VecText.getGlyphHeight( s, lh )
        line ((x - 1), (y - 1))-STEP ((dw - 1), (dh - 1) ), bg, BF
        return VecText.drawString( text, fg, x, y, s, lw, lh )
    end function
        
    function drawString( text as string, clr as integer, x as integer, y as integer, s as integer = 2, lw as integer = 1, lh as integer = 1 ) as integer
        dim as integer cw = ((s * 5) + lw)
        dim as integer coff, clen
        dim as integer i
        for i = 1 to len( text )
            if( VecText._getGlyphInfo( asc( text, i ), coff, clen ) ) then
                VecText._drawGlyph( x, y, lw, lh, s, clr, coff, clen )
            end if
            x += cw
        next
        return (y + (s * 9) + lh)
    end function
    
    function _getGlyphInfo( g as ubyte, byref coff as integer, byref clen as integer ) as integer
        if( g = 0 ) then
            return FALSE
        end if
        dim as integer i, coffnext
        for i = VecText._g_table_offset to (VecText._g_table_offset + VecText._g_table_len - 1) step 3
            if( VecText._fdata(i) = g ) then
                coff = ((VecText._fdata(i+1) shl 8) or VecText._fdata(i+2))
                coffnext = ((VecText._fdata(i+4) shl 8) or VecText._fdata(i+5))
                clen = (coffnext - coff)
                return TRUE
            end if
        next
        return FALSE
    end function
    
    sub _drawGlyph( dleft as integer, dtop as integer, dwidth as integer, dheight as integer, dsize as integer, dclr as integer, coff as integer, clen as integer )
        dim as integer y, x, i = 0
        dim as integer dx, dy, dd, dl, dw, dh
        dim as integer dwidtha = dwidth
        coff += VecText._g_data_offset
        
        ' adjusts the diagonals to look the same width as the straights (rms)
        ' but causes the straights to cut into them horribly :(
        'dwidtha = dwidth / 1.44

        'debug: draw a grid showing the coordinates we're using
        'for x = 0 to 5
        '    for y = 0 to 7
        '        line (dleft+(x * dsize),dtop+(y*dsize))-STEP((dwidth),(dheight)),RGB(0,255,0),B
        '    next
        'next

        for i = coff to (coff + clen - 1) step 2
            x = VecText._fdata(i) shr 4
            y = VecText._fdata(i) and &hF
            dd = VecText._fdata(i+1) shr 4
            dl = (VecText._fdata(i+1) and &hF)
            dl *= dsize     ' adjust scale
            
            'print "will draw type "; dd; " at "; dx; ","; dy; " for "; dl
            dy = (dtop + (y * dsize))
            for dh = 1 to dheight
                dx = (dleft + (x * dsize))
                select case dd
                    case 0:
                        for dw = 1 to dwidtha
                            if( VecText._context = 0 ) then
                                line (dx, dy)-((dx + dl), (dy - dl)), dclr
                            else
                                line VecText._context, (dx, dy)-((dx + dl), (dy - dl)), dclr
                            end if
                            dx += 1
                        next
                    case 1:
                        if( VecText._context = 0 ) then
                            line (dx, dy)-((dx + dl+dwidth - 1), dy), dclr
                        else
                            line VecText._context, (dx, dy)-((dx + dl+dwidth - 1), dy), dclr
                        end if
                    case 2:
                        for dw = 1 to dwidtha
                            if( VecText._context = 0 ) then
                                line (dx, dy)-((dx + dl), (dy + dl)), dclr
                            else
                                line VecText._context, (dx, dy)-((dx + dl), (dy + dl)), dclr
                            end if
                            dx += 1
                        next
                    case 3:
                        if( dwidth = 1 ) then
                            if( VecText._context = 0 ) then
                                line (dx, dy)-(dx, (dy + dl)), dclr
                            else
                                line VecText._context, (dx, dy)-(dx, (dy + dl)), dclr
                            end if
                        else
                            if( VecText._context = 0 ) then
                                line (dx, dy)-((dx + dwidth - 1), (dy + dl)), dclr, BF
                            else
                                line VecText._context, (dx, dy)-((dx + dwidth - 1), (dy + dl)), dclr, BF
                            end if
                        end if
                end select
                dy += 1
            next
        next
    end sub
end namespace

#endif
