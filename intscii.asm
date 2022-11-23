;; ----------------------------------------------------------------------------
;; SPDX-License-Identifier: WTFPL
;;
;; Copyright 2022 Matt
;; This work is free. You can redistribute it and/or modify it under the
;; terms of the Do What The Fuck You Want To Public License, Version 2,
;; as published by Sam Hocevar. See the COPYING file for more details.
;; ----------------------------------------------------------------------------

;; ------------------------------------------------------------------
;; convert string into a 32 bit integer (ignoring overflow)
;; TODO: check for a sign 
;;
;; if the carry flag is set this indicates that either the string only
;; contained whitespace, or the first non-whitespace character was not
;; a digit. in either case the result is 0
;;
;; >> ecx: string length
;; >> esi: string &
;; << eax: result
;; << esi: remaining string &
;; <<  cf: error
;; ------------------------------------------------------------------
atoi:
		xor	eax, eax
		push	ebx
		push	ecx
		inc	ecx

.skipws:	dec	ecx
		jz	.allws
		movzx	ebx, byte [esi]
		cmp	ebx, ' '
		ja	.notws
		inc	esi
		jmp	.skipws

.notws:		xor	ebx, ebx
		xor	ecx, ecx

.nextc:		add	eax, ebx
		movzx	ebx, byte [esi]
		sub	ebx, '0'
		cmp	ebx, 9
		ja	.notdigit
		imul	eax, 10
		inc	esi
		inc	ecx
		jmp	.nextc

.notdigit:	clc
		test	ecx, ecx
		jnz	.founddigit
.allws:		stc
.founddigit:	pop	ecx
		pop	ebx
		ret

;; ------------------------------------------------------------------
;; >> eax: int (trashed)
;; >> edi: buffer &
;; << edi: next buffer element &
;; ------------------------------------------------------------------
itoa:
		push	ebx
		push	edx
		push	esi

		mov	ebx, 10
		mov	esi, edi

.conv:		xor	edx, edx
		div	ebx
		add	edx, '0'
		mov	[esi], dl
		inc	esi
		test	eax, eax
		jnz	.conv

		push	esi
		dec	esi

.reverse:	movzx	eax, byte [edi]
		movzx	ebx, byte [esi]
		mov	[edi], byte bl
		mov	[esi], byte al
		inc	edi
		dec	esi
		cmp	esi, edi
		jg	.reverse

		pop	edi
		pop	esi
		pop	edx
		pop	ebx
		ret

;; ------------------------------------------------------------------
xtoa:
		ret
