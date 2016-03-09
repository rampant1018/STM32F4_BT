TARGET = google_adk
.DEFAULT_GOAL = all

# Toolchain configurations
CROSS_COMPILE ?= arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE = $(CROSS_COMPILE)size

CFLAGS = -mcpu=cortex-m4 -march=armv7e-m -mtune=cortex-m4
CFLAGS += -mlittle-endian -mthumb

CFLAGS += -g -std=c99 -Wall -O3
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections
CFLAGS += -fno-common
CFLAGS += --param max-inline-insns-single=1000

CFLAGS += -DSTM32F429_439xx
CFLAGS += -DUSE_STDPERIPH_DRIVER

CFLAGS += -DVECT_TAB_FLASH
CFLAGS += -T stm32f429zi_flash.ld

CFLAGS += -D"assert_param(expr)=((void)0)"

ARCH = CM4
VENDOR = ST
PLAT = STM32F4xx

STDP = ../../STM32F429I-Discovery_FW_V1.0.1

LIBDIR = ./Libraries
CMSIS_LIB = $(LIBDIR)/CMSIS
STM32_LIB = $(LIBDIR)/STM32F4xx_StdPeriph_Driver

OUTDIR = build
SRCDIR = src \
	 $(STM32_LIB)/src
INCDIR = src \
	 $(STM32_LIB)/inc \
	 $(CMSIS_LIB)/Include \
	 $(CMSIS_LIB)/Device/$(VENDOR)/$(PLAT)/Include \
	 $(STDP)/Utilities/STM32F429I-Discovery

INCLUDES = $(addprefix -I,$(INCDIR))

SRC = $(wildcard $(addsuffix /*.c,$(SRCDIR))) \
      $(wildcard $(addsuffix /*.s,$(SRCDIR)))
OBJ := $(addprefix $(OUTDIR)/,$(patsubst %.s,%.o, $(SRC:.c=.o)))
DEP = $(OBJ:.o=.o.d)

all: $(OUTDIR)/$(TARGET).bin $(OUTDIR)/$(TARGET).lst

$(OUTDIR)/$(TARGET).bin: $(OUTDIR)/$(TARGET).elf
	@echo "    OBJCOPY "$@
	@$(OBJCOPY) -Obinary $< $@

$(OUTDIR)/$(TARGET).lst: $(OUTDIR)/$(TARGET).elf
	@echo "    LIST    "$@
	@$(OBJDUMP) -S $< > $@

$(OUTDIR)/$(TARGET).elf: $(OBJ)
	@echo "    LD      "$@
	@echo "    MAP     "$(OUTDIR)/$(TARGET).map
	@$(CC) $(CFLAGS) -Wl,-Map=$(OUTDIR)/$(TARGET).map -o $@ $^

$(OUTDIR)/%.o: %.c
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CC) $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

$(OUTDIR)/%.o: %.s
	@mkdir -p $(dir $@)
	@echo "    CC      "$@
	@$(CC) $(CFLAGS) -MMD -MF $@.d -o $@ -c $(INCLUDES) $<

clean:
	rm -rf $(OUTDIR)

flash: $(OUTDIR)/$(TARGET).bin
	st-flash write $< 0x8000000
