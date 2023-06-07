LOCAL_PATH := $(call my-dir)

LIBPAYLOAD_PATH := $(LOCAL_PATH)

include $(CLEAR_VARS)
LOCAL_MODULE := libpayload
LOCAL_MODULE_CLASS := STATIC_LIBRARIES

LPCONFIG := $(call local-generated-sources-dir)/config/libpayload-config.h
ifeq ($(LIBPAYLOAD_BASE_ADDRESS),)
$(LPCONFIG):
	$(error LIBPAYLOAD_BASE_ADDRESS is not defined)
else ifeq ($(LIBPAYLOAD_HEAP_SIZE),)
$(LPCONFIG):
	$(error LIBPAYLOAD_HEAP_SIZE is not defined)
else ifeq ($(LIBPAYLOAD_STACK_SIZE),)
$(LPCONFIG):
	$(error LIBPAYLOAD_STACK_SIZE is not defined)
else
$(LPCONFIG): PRIVATE_LIBPAYLOAD_BASE_ADDRESS := $(LIBPAYLOAD_BASE_ADDRESS)
$(LPCONFIG): PRIVATE_LIBPAYLOAD_HEAP_SIZE := $(LIBPAYLOAD_HEAP_SIZE)
$(LPCONFIG): PRIVATE_LIBPAYLOAD_STACK_SIZE := $(LIBPAYLOAD_STACK_SIZE)

$(LPCONFIG): $(LIBPAYLOAD_PATH)/configs/config.x86.h
	$(hide) mkdir -p $(dir $@)
	$(hide) echo "/* Do not modify this auto-generated file. */" > $@
	$(hide) cat $< >> $@
	$(hide) echo "#define CONFIG_LP_BASE_ADDRESS "$(PRIVATE_LIBPAYLOAD_BASE_ADDRESS) >> $@
	$(hide) echo "#define CONFIG_LP_HEAP_SIZE "$(PRIVATE_LIBPAYLOAD_HEAP_SIZE) >> $@
	$(hide) echo "#define CONFIG_LP_STACK_SIZE "$(PRIVATE_LIBPAYLOAD_STACK_SIZE) >> $@
	$(hide) rm -f $(dir $@)/config.h
	$(hide) ln -s libpayload-config.h $(dir $@)/config.h
endif
LOCAL_GENERATED_SOURCES := $(LPCONFIG)
LOCAL_C_INCLUDES := \
	$(LOCAL_PATH)/include \
	$(LOCAL_PATH)/include/x86 \
	$(dir $(LPCONFIG))
LOCAL_EXPORT_C_INCLUDE_DIRS := \
	$(LOCAL_PATH)/include \
	$(LOCAL_PATH)/include/x86 \
	$(dir $(LPCONFIG))
LOCAL_CFLAGS := \
	-include $(LOCAL_PATH)/include/kconfig.h
LOCAL_SRC_FILES += \
	libpci/libpci.c \
	arch/x86/main.c \
	arch/x86/sysinfo.c \
	arch/x86/timer.c \
	arch/x86/coreboot.c \
	arch/x86/util.S \
	arch/x86/virtual.c \
	arch/x86/selfboot.c \
	arch/x86/exception.c \
	arch/x86/multiboot.c \
	arch/x86/rom_media.c \
	crypto/sha1.c \
	libc/malloc.c \
	libc/printf.c \
	libc/console.c \
	libc/string.c \
	libc/memory.c \
	libc/ctype.c \
	libc/ipchecksum.c \
	libc/lib.c \
	libc/rand.c \
	libc/time.c \
	libc/exec.c \
	libc/readline.c \
	libc/getopt_long.c \
	libc/sysinfo.c \
	libc/args.c \
	libc/strlcpy.c \
	libc/qsort.c \
	libc/hexdump.c \
	libc/die.c \
	libc/coreboot.c \
	libc/64bit_div.c \
	drivers/pci.c \
	drivers/serial/8250.c \
	drivers/serial/serial.c \
	drivers/keyboard.c \
	drivers/nvram.c \
	drivers/options.c \
	drivers/timer/rdtsc.c \
	drivers/hid.c

ifeq ($(TARGET_UEFI_ARCH),x86_64)
LOCAL_SRC_FILES += \
	arch/x86/exception_x64.c
else
LOCAL_SRC_FILES += \
	arch/x86/exec.S \
	arch/x86/exception_asm.S
endif

libpayload_intermediates_32 := $(call local-intermediates-dir,,32-bit)
libpayload_intermediates := $(call local-intermediates-dir,,)

export_includes=$(libpayload_intermediates)/export_includes
export_includes_32=$(libpayload_intermediates_32)/export_includes

$(export_includes): $(LPCONFIG)
$(export_includes_32): $(LPCONFIG)

ifeq ($(TARGET_UEFI_ARCH),x86_64)
LOCAL_CFLAGS += -DBUILD_X64
endif

include $(BUILD_IAFW_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := crt0-libpayload-ia32
LOCAL_SRC_FILES := arch/x86/head.S
include $(BUILD_IAFW_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := crt0-libpayload-x86_64
LOCAL_SRC_FILES := arch/x86/head_64.S
include $(BUILD_IAFW_STATIC_LIBRARY)
