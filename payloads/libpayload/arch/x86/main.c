/*
 * This file is part of the libpayload project.
 *
 * Copyright (C) 2008 Advanced Micro Devices, Inc.
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

#include <exception.h>
#include <libpayload.h>

unsigned long loader_eax;  /**< The value of EAX passed from the loader */
unsigned long loader_ebx;  /**< The value of EBX passed from the loader */

unsigned int main_argc;    /**< The argc value to pass to main() */

/** The argv value to pass to main() */
char *main_argv[MAX_ARGC_COUNT];

/**
 * This is our C entry function - set up the system
 * and jump into the payload entry point.
 */
int start_main(void);
int start_main(void)
{
	extern int main(int argc, char **argv);
	uint64_t entrance_tsc;
	char stamp_str[32] = {0};

	/* Gather system information. */
	lib_get_sysinfo();

	entrance_tsc = entry_point_tsc();
	/* Optionally set up the consoles. */
#if !IS_ENABLED(CONFIG_LP_SKIP_CONSOLE_INIT)
	console_init();
#endif

	exception_init();

	/* Add boot time stamp to arg */
	boottime_stamp_append(stamp_str, entrance_tsc);
	main_argv[main_argc++] = stamp_str;

	/*
	 * Any other system init that has to happen before the
	 * user gets control goes here.
	 */

	/*
	 * Go to the entry point.
	 * In the future we may care about the return value.
	 */

	/*
	 * Returning from main() will go to the _leave function to return
	 * us to the original context.
	 */
	return main(main_argc, (main_argc != 0) ? main_argv : NULL);
}
