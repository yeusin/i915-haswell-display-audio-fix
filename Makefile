KDIR ?= /lib/modules/$(shell uname -r)/build
MDIR ?= $(PWD)/src/sound/hda/controllers

all:
	$(MAKE) -C $(KDIR) M=$(MDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(MDIR) clean

install:
	@echo "To install the patched module, run with sudo:"
	@echo "  sudo cp $(MDIR)/snd-hda-intel.ko /lib/modules/\$$(uname -r)/kernel/sound/hda/controllers/snd-hda-intel.ko.zst"
	@echo "or use the provided install script."
