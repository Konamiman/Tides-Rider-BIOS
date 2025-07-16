ifeq ($(strip $(N80)),)
N80=N80
endif

export N80_ARGS=--no-show-banner --verbosity 1 --output-file-case lower

ifeq ($(strip $(LK80)),)
LK80=LK80
endif

export LK80_ARGS=--no-show-banner --verbosity 1 --output-file-case lower --output-format bin --fill FFh

define assemble
	@printf "\n\033[0;36mAssembling %s\033[0m\n\n" $(1)
	@$(N80) $(1) $(2)
endef

RELFILES := header.rel boot.rel unapi.rel alloc.rel utils.rel dummy.rel

all: tides_bios.rom

bios: tides_bios.rom

tides_bios.rom: $(RELFILES)
	@$(LK80) -vb 3 --output-file tides_bios.rom --code 8000h header.rel boot.rel unapi.rel alloc.rel utils.rel --code BFFFh dummy.rel

.SECONDEXPANSION:
$(RELFILES): msx.inc $$(patsubst %.rel,%.asm,$$@)
	$(call assemble,$(patsubst %.rel,%.asm,$@))
