# Phone Mirroring (`kphonemirroring`)

**macOS 27 "Golden Gate" iPhone Mirroring experience for Android on KDE Plasma 6 (Wayland / Qt6).**

Designed to deliver the seamless continuity experience of macOS Sequoia/Tahoe Phone Mirroring on Linux desktops with zero friction.

![Phone Mirroring Icon](src/resources/icons/kphonemirroring.svg)

---

## ✨ Features

### Golden Gate / Liquid Glass (CachyOS.UI)

- **Liquid Glass window frame**: translucent `CachyTheme.windowBackground`, KWin blur region (`CachyWindowBlur`), gloss sheen gradient and the continuous 1 px specular rim. No opaque colour overrides the glass.
- **Canonical macOS chrome**: 44 px title bar with the hard 1 px divider, traffic lights at 18 px with the specular crescent and the elastic 1.18× press, centred title, header actions anchored at 18 px and the **Preferences gear always last** (right-most).
- **Edge-to-edge sidebar** (`232 px`) with the brand block, the live device list (colourful squircle badges, bold selection, live battery counter), the session status card and the mirroring actions.
- **Unified 20 px squircle** (`CachyTheme.radiusWindow`) and 18 px canonical perimeter margin.
- **Light/Dark aware**: every chrome colour comes from the `CachyTheme` singleton; the glass tint follows the global *Liquid Glass Opacity* setting.

### Mirroring

- **Device chassis**: titanium bezel + punch-hole camera hosting the mirrored screen.
- **Host-side quick actions** (`SequoiaToolbar`): 🏠 Inicio · 🗂️ Multitarea · 🔒 Bloquear · 🔔 Avisos · ⚙️ Ajustes · 📸 Captura · 🔉/🔊 Volumen.
- **Golden Gate bezel cluster** (top-right): *Home Screen* `Ctrl+1`, *App Switcher* `Ctrl+2`, *Spotlight* `Ctrl+3`, *Control Center* `Ctrl+4`.
- **Control Center sheet** (`Ctrl+4`): audio, screen-off, screenshot and notifications as a floating glass panel.
- **Preferences sheet** (`Ctrl+,`): turn-screen-off, stay-awake, PipeWire audio, frame rate and bit-rate. The values live in `MirrorSession`, are persisted between sessions and feed the scrcpy command line.
- **Per-app dynamic window size memory**: every Android app remembers its own window geometry; *Home Screen* restores the compact portrait size.

### Connectivity & power

- **USB mode**: ultra-low latency, 60 FPS, battery charging.
- **Wi-Fi mode**: 100% wireless mirroring without cables via ADB TCP/IP.
- **Privacy & Power Saver**: keeps the physical phone screen turned off while interacting on the desktop (`--turn-screen-off`) and keeps the phone awake while connected (`--stay-awake`).
- **High-fidelity audio**: the stream is captured from the default PipeWire/WirePlumber source so the active **EasyEffects** DSP chain (noise cancellation, noise gate, EQ) and the configured virtual sinks are honoured. No physical `hw:*` device is ever hardcoded.


---

## 🚀 Requisitos

- **KDE Plasma 6** (Wayland)
- **Qt 6** (Core, Gui, Qml, Quick, QuickControls2)
- **scrcpy** (v2.0+)
- **android-tools** (`adb`)
- **android-udev**

---

## 🛠️ Compilación e Instalación

```bash
git clone https://github.com/cesarconte/kphonemirroring.git
cd kphonemirroring
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
ctest --test-dir build --output-on-failure
sudo cmake --install build
```

### Dependencia del sistema de diseño

La interfaz consume el módulo QML `CachyOS.UI` (Liquid Glass, `CachyWindow`,
`CachyTheme`…). Se instala con:

```bash
cd ../cachyos-ui
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build -j"$(nproc)"
DESTDIR=$HOME/.local cmake --install build
```

---

## 📄 Licencia

GPLv3. Desarrollado por César Conte.
