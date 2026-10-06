KDIR ?= /lib/modules/$(shell uname -r)/build
MDIR ?= $(PWD)/src/sound/hda/controllers
KERNEL_VER ?= v$(shell uname -r | cut -d. -f1-2)

all: src/sound/hda/controllers/intel.c
	$(MAKE) -C $(KDIR) M=$(MDIR) modules
	zstd -f -k $(MDIR)/snd-hda-intel.ko -o snd-hda-intel.ko.zst

src/sound/hda/controllers/intel.c:
	@echo "==> Fetching sound/hda source tree for $(KERNEL_VER)..."
	@mkdir -p src
	git clone --depth 1 --filter=blob:none --sparse -b $(KERNEL_VER) https://github.com/torvalds/linux.git src/linux-sound
	cd src/linux-sound && git sparse-checkout set sound/hda
	cp -r src/linux-sound/sound src/
	rm -rf src/linux-sound
	@echo "==> Applying haswell-hdmi-audio-fix.patch..."
	patch -p0 -N < haswell-hdmi-audio-fix.patch

clean:
	@if [ -d "$(MDIR)" ]; then \
		$(MAKE) -C $(KDIR) M=$(MDIR) clean; \
	fi
	rm -f snd-hda-intel.ko.zst

distclean: clean
	rm -rf src

install:
	@echo "To install the patched module, run with sudo:"
	@echo "  sudo cp $(MDIR)/snd-hda-intel.ko /lib/modules/\$$(uname -r)/kernel/sound/hda/controllers/snd-hda-intel.ko.zst"
	@echo "or use the provided install script."
