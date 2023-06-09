/*
 * This file is part of the libpayload project.
 *
 * Copyright (C) 2008 Advanced Micro Devices, Inc.
 * Copyright (C) 2017 Patrick Rudolph <siro@das-labor.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

	.code64
	.global _entry
	.text
	.align 4

/*
 * Our entry point - assume that the CPU is in 32 bit protected mode and
 * all segments are in a flat model. That's our operating mode, so we won't
 * change anything.
 */
_entry:
	jmp _init

	.align 4

#define MB_MAGIC 0x1BADB002
#define MB_FLAGS 0x00010003

mb_header:
	.long MB_MAGIC
	.long MB_FLAGS
	.long -(MB_MAGIC + MB_FLAGS)
	.long mb_header
	.long _start
	.long _edata
	.long _end
	.long _init

#define CB_MAGIC_VALUE	0x12345678
#define CB_MAGIC	0x04
#define CB_ARGV		0x08
#define CB_ARGC		0x10

/*
 * This function saves off the previous stack and switches us to our
 * own execution environment.
 */
_init:
	/* No interrupts, please. */
	cli

	/* Store EAX and EBX */
	movl %eax, loader_eax
	movl %ebx, loader_ebx

	/* Copy argv[] and argc as demanded by the Payload API,
	 * see https://www.coreboot.org/Payload_API and exec.S.
	 */
	cmpl $CB_MAGIC_VALUE, CB_MAGIC(%esp)
	jne 1f

	movl CB_ARGV(%esp), %eax
	movl %eax, main_argv

	movl CB_ARGC(%esp), %eax
	movl %eax, main_argc
1:
	/* Store current stack pointer and set up new stack. */
	movl %esp, %eax
	mov $_stack, %rsp

	push %rax

	/* Enable special x86 functions if present. */
	push %rax
	push %rbx
	push %rcx
	push %rdx

	movl $0, %eax
	cpuid
	/* Test if CPUID(eax=1) is available. */
	test %eax, %eax
	je cpuid_done

	/* Get CPU features. */
	movl $1, %eax
	cpuid

cpuid_fpu:
	/* Test if x87 FPU is present */
	test $1, %edx
	je cpuid_sse

	fninit
	mov %cr0, %rax
	andl $0xFFFFFFFB, %eax	/* clear EM */
	orl $0x00000022, %eax	/* set MP, NE */
	mov %rax, %cr0

cpuid_sse:
	/* Test if SSE is available */
	test $0x02000000, %edx
	je cpuid_done

	mov %cr4, %rax
	orl $0x00000600, %eax	/* set OSFXSR, OSXMMEXCPT */
	mov %rax, %cr4

cpuid_done:
	pop %rdx
	pop %rcx
	pop %rbx
	pop %rax

	/* Let's rock. */
	call start_main

	/* %eax has the return value - pass it on unmolested */
_leave:
	/* Restore old stack. */
	pop %rsp

	/* Return to the original context. */
	ret
