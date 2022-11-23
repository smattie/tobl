;; ----------------------------------------------------------------------------
;; SPDX-License-Identifier: WTFPL
;;
;; Copyright 2022 Matt
;; This work is free. You can redistribute it and/or modify it under the
;; terms of the Do What The Fuck You Want To Public License, Version 2,
;; as published by Sam Hocevar. See the COPYING file for more details.
;; ----------------------------------------------------------------------------

format elf executable 3
entry start

define exit         1
define read         3
define write        4
define open         5
define close        6
define ioctl       54
define getdents64 220
define openat     295

define O_RDONLY 0
define O_WRONLY 1
define O_RDWR   2

define TCGETS  5401h
define TCSETS  5402h
define TIOCSTI 5412h
define ICANON  00000002h
define ECHO    00000008h
define VTIME   5
define VMIN    6

define b byte
define w word
define d dword

;; ------------------------------------------------------------------
;; >> edi: errptr index
die:
		mov	ecx, [errptr + edi * 4]
		movzx	edx, b[ecx]
		inc	ecx
		mov	eax, write
		mov	ebx, 2
		int	80h
		jmp	finish.exit

;; ------------------------------------------------------------------
start:
		mov	edx, 1024
		sub	esp, edx

		mov	eax, open
		mov	ebx, syspath
		xor	ecx, ecx
		int	80h
		xor	edi, edi
		mov	ebp, eax
		test	eax, eax
		js	die

		mov	eax, getdents64
		mov	ebx, ebp
		mov	ecx, esp
		int	80h
		inc	edi  ; 1
		mov	ecx, eax
		test	eax, eax
		jle	die

.getbl:		movzx	ebx, w[esp + 16]
		movzx	eax, b[esp + 19]
		cmp	 al, 2eh
		jne	.opendir
.skip:		add	esp, ebx
		sub	ecx, ebx
		jg	.getbl
		jmp	finish

.opendir:	mov	eax, openat
		mov	ebx, ebp
		lea	ecx, [esp + 19]
		xor	edx, edx
		int	80h
		inc	edi  ; 2
		mov	ebp, eax
		test	eax, eax
		js	die
		mov	eax, close
		int	80h

		mov	eax, openat
		mov	ebx, ebp
		mov	ecx, brightness
		mov	edx, O_RDWR
		int	80h
		mov	esi, eax
		mov	eax, openat
		mov	ecx, maxbrightness
		xor	edx, edx
		int	80h
		inc	edi  ; 3
		mov	ebp, eax
		mov	eax, close
		mov	edx, eax
		int	80h
		mov	eax, esi
		or	eax, ebp
		js	die
		mov	[curfd], esi

		mov	eax, read
		mov	ebx, ebp
		int	80h
		mov	eax, close
		int	80h

.ldtermcfg:	mov	eax, ioctl
		xor	ebx, ebx
		inc	ebx
		mov	ecx, TCGETS
		mov	edx, esp
		int	80h
		inc	edi  ; 4
		test	eax, eax
		jnz	die
		lea	edi, [esp + 19]
.initterm:	and	d[esp + 12], not (ICANON or ECHO)
		movzx	eax, w[edi]
		mov	[savedcc], ax
		mov	 ax, 0100h
		mov	w[edi], ax
		mov	eax, ioctl
		mov	ecx, TCSETS
		int	80h
		mov	eax, ioctl
		mov	ecx, TIOCSTI
		mov	edx, maxbrightness - 1
		int	80h

		mov	eax, write
		mov	ebx, 1
		mov	ecx, windowtitle
		mov	edx, windowtitle.len
		int	80h

;; ------------------------------------------------------------------
finish:
		xor	ebx, ebx
.exit:		xor	eax, eax
		inc	eax
		int	80h

;; ------------------------------------------------------------------

include "intscii.asm"

align 4
errptr:
	dd syserr
	dd nobl ;; i dont want to live anymore
	dd direrr
	dd fileerr
	dd notterm

curfd:   dd ?
savedcc: dw ?

syspath: db "/sys/class/backlight", 0

brightness:    db "brightness", 0
maxbrightness: db "max_brightness", 0

windowtitle: db 1bh, "]0;ToBL", 1bh, "\"
	.len = $ - windowtitle

syserr:  db 24, "error: is /sys mounted?", 10
nobl:    db 20, "no backlights found", 10
direrr:  db 35, "failed to open backlight directory", 10
fileerr: db 32, "failed to open brightness files", 10
notterm: db 42, "stdin/out must be connected to a terminal", 10
