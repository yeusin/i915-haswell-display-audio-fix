# i915 Haswell Display & Audio Fix for Linux

Fixes 4K@60Hz display output and eliminates HDMI audio jitter/stuttering on Intel Haswell graphics under Linux.

Tested on **MacBook Pro 15" Retina (Late 2013 / Mid 2014, MacBookPro11,2 / MacBookPro11,3)** running Linux Mint 22.3 / Ubuntu 24.04 (Kernel 7.0 / 6.8+).

---

## The Issues & Solutions

### 1. 4K@60Hz Display Unlock (CVT-RB Modeline)
* **Problem**: Intel Haswell's Core Display Clock (CDCLK) in the `i915` driver caps the maximum pixel clock at **540.00 MHz** (`max_dotclk = 540000 kHz`). Standard 4K@60Hz (CTA-861 VIC 97) requests 594.00 MHz, which `i915` rejects as `MODE_CLOCK_HIGH`, falling back to 30Hz (297 MHz).
* **Solution**: A custom VESA CVT-RB (Reduced Blanking) modeline running at **533.00 MHz** (3840x2160 @ 59.97 Hz). Because 533 MHz < 540 MHz, the driver and GPU accept it without overclocking or kernel bypasses.
* **Usage**: Run `./setup-4k60-display.sh` or copy `display-4k60.desktop` to `~/.config/autostart/`.

### 2. HDMI Audio Jitter & Dropouts (`snd-hda-intel` Patch)
* **Problem**: When routing audio over DisplayPort / HDMI through active adapters on Haswell (`0000:00:03.0`, `[8086:0d0c]`), sound suffers from severe popping, stuttering, and buffer underruns.
  * **Broken Position Buffer (POSBUF)**: Haswell's POSBUF drifts against LPIB, triggering `Unstable LPIB (... >= ...); disabling LPIB delay counting`.
  * **Workqueue Stall (`msleep(1)`)**: Once delay counting fails, early IRQs cause `azx_position_ok` to fail, activating `azx_irq_pending_work`. Inside this fallback loop, the driver executes **`msleep(1)`** on every period update, injecting massive periodic latency into the real-time audio thread.
  * **64-bit DMA IOMMU Fault**: Controller issues 64-bit DMA addresses triggering Intel VT-d (DMAR) PTE non-zero reserved field faults (`[DMA Read NO_PASID] Request device [00:03.0] fault addr 0xff800000 [fault reason 0x0c]`).
* **Solution**:
  * Apply `AZX_DCAPS_POSFIX_LPIB` to Haswell HDMI (matching the Broadwell HDMI fix) to read hardware LPIB directly.
  * Apply `AZX_DCAPS_NO_64BIT` to restrict DMA to 32-bit addressable memory, fixing DMAR PTE faults.
  * Set `bdl_pos_adj = 0` for Haswell HDMI devices (`0x0a0c`, `0x0c0c`, `0x0d0c`) to return `-1` on early IRQs instead of entering the blocking `msleep(1)` workqueue.

---

## Repository Contents

* [`haswell-hdmi-audio-fix.patch`](haswell-hdmi-audio-fix.patch): Unified diff patch for `sound/hda/controllers/intel.c`.
* [`install-patched-driver.sh`](install-patched-driver.sh): Script to back up the stock driver, install the patched module, and reload the audio subsystem.
* [`restore-stock-driver.sh`](restore-stock-driver.sh): 100% clean rollback script to restore the original stock driver.
* [`setup-4k60-display.sh`](setup-4k60-display.sh): Shell script to apply the 4K@60Hz CVT-RB modeline.
* [`display-4k60.desktop`](display-4k60.desktop): XDG autostart entry for automatic 4K@60Hz activation on login.
* [`Makefile`](Makefile): Compiles the patched module against your currently running kernel headers.

---

## Quick Start

### 1. Build and Install the Audio Fix
```bash
# Build the patched module against current kernel headers
make

# Compress the module with zstd
zstd -f -k src/sound/hda/controllers/snd-hda-intel.ko -o snd-hda-intel.ko.zst

# Install and reload driver (creates backup automatically)
sudo ./install-patched-driver.sh
```

### 2. Enable 4K@60Hz Display
```bash
# Test immediately
chmod +x setup-4k60-display.sh
./setup-4k60-display.sh

# Or enable permanently for user sessions
cp display-4k60.desktop ~/.config/autostart/
```

### 3. Rollback (If Needed)
```bash
sudo ./restore-stock-driver.sh
```

---

## License
GPL-2.0 (matching the Linux Kernel).
