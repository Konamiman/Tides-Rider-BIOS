ifeq ($(strip $(N80)),)
N80=N80
endif

ifeq ($(strip $(DEBUGGING)),1)
DEBUGGING=--define-symbols DEBUGGING
endif

ifeq ($(strip $(FAKEZ280)),1)
FAKEZ280=--define-symbols FAKE_Z280
endif

ifeq ($(strip $(VB)),)
VB=0
endif

ifeq ($(strip $(LVB)),)
LVB=0
endif

export N80_ARGS=--no-show-banner --verbosity $(VB) --output-file-case lower $(DEBUGGING) $(FAKEZ280)

ifeq ($(strip $(LK80)),)
LK80=LK80
endif

export LK80_ARGS=--no-show-banner --verbosity $(LVB) --output-file-case lower --output-format bin --fill FFh

define assemble
	@printf "\n\033[0;36mAssembling %s\033[0m\n\n" $(1)
	@$(N80) $(1) $(2)
endef

RELFILES := header.rel boot.rel unapi.rel alloc.rel utils.rel chgcpu.rel z280_init.rel z280_resident.rel dummy.rel

#TODO: Somehow generate this in a loop, given the max system call number implemented.
SYSCALLS := sc_0.rel sc_1.rel sc_2.rel

all: tides_bios.rom

bios: tides_bios.rom

tides_bios.rom: $(RELFILES) $(SYSCALLS)
	@printf "\n\033[0;36mLinking\033[0m\n\n"
	@$(LK80) --output-file tides_bios.rom --code 8000h header.rel boot.rel unapi.rel alloc.rel utils.rel chgcpu.rel z280_init.rel --code A000h z280_resident.rel $(SYSCALLS) --code BFFFh dummy.rel

.SECONDEXPANSION:
$(RELFILES): msx.inc z280.inc tides.inc $$(patsubst %.rel,%.asm,$$@)
	$(call assemble,$(patsubst %.rel,%.asm,$@))

.SECONDEXPANSION:
$(SYSCALLS): msx.inc z280.inc tides.inc $$(patsubst %.rel,system_calls/%.asm,$$@)
	$(call assemble,$(patsubst %.rel,system_calls/%.asm,$@))

.PHONY: clean

clean:
	rm -f *.rel
	rm -f *.REL
	rm -f *.LST
	rm -f *.rom
