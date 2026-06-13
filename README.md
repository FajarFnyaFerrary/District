<!--<h1 align="center">Violence District Hub</h1> -->

<!--
<picture>
    <source srcset="docs/banner-dark.webp" media="(prefers-color-scheme: dark)">
    <source srcset="docs/banner-light.webp" media="(prefers-color-scheme: light)">
    <img src="docs/banner-light.webp" alt="VDH Banner">
</picture>-->

<p align="center">
  <img src="https://img.shields.io/badge/Game-Violence%20District-red?style=for-the-badge&logo=roblox" alt="Game">
  <img src="https://img.shields.io/badge/UI-WindUI-blue?style=for-the-badge" alt="UI Library">
  <img src="https://img.shields.io/badge/Status-Working-brightgreen?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/Type-Script%20Hub-orange?style=for-the-badge" alt="Type">
</p>

> [!WARNING]
> **Script ini dibuat untuk tujuan edukasi dan pengembangan skill scripting Lua/Luau saja.**
> Penggunaan script di luar lingkungan pengembangan pribadi (seperti cheat di server publik) dapat melanggar [Terms of Service Roblox](https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use) dan berisiko **banned permanen** pada akun Roblox kamu. Gunakan dengan risiko sendiri.

> [!CAUTION]
> Script ini **TIDAK** bersifat undetectable. Roblox terus memperbarui sistem anti-cheat mereka (Byfron/Hyperion). Tidak ada jaminan bahwa script ini aman dari deteksi di masa depan. Selalu gunakan pada **alt account** dan **jangan** gunakan di akun utama yang memiliki Robux atau item berharga.

> [!NOTE]
> Dibangun menggunakan [WindUI](https://github.com/FajarFnyaFerrary/District) oleh [Footagesus](https://github.com/Footagesus). Semua credit untuk library UI ada pada pembuat WindUI.

---

## Deskripsi

**Violence District Hub** adalah script hub untuk game Roblox **Violence District** (Distrik Kekerasan) yang dibangun di atas framework UI **WindUI**. Script ini menyediakan berbagai fitur untuk mode Survivor maupun Killer, dilengkapi dengan sistem ESP, Aimbot, Automation, dan lainnya.

## Fitur

### Tab VIP
| Fitur | Tipe | Deskripsi |
|-------|------|-----------|
| Auto Play (Smart AI) | Toggle | Bot AI otomatis mencari Generator & Gate, kabur dari Killer |
| Wiggle Master | Button | Memberontak dan lepas dari panggulan Killer secara instan |
| Flee Distance | Slider (20-80) | Jarak deteksi Killer untuk Auto Play kabur |
| Auto Dagger (Auto Parry) | Toggle | Menangkis serangan Killer secara instan |
| Dagger Parry Range | Slider (10-100) | Jarak deteksi Killer untuk Auto Parry |

### Tab Survivor
| Fitur | Tipe | Deskripsi |
|-------|------|-----------|
| Speed Boost | Toggle | Menambah kecepatan lari sesuai slider |
| Custom Speed | Slider (16-100) | Nilai kecepatan custom |
| No Slowdown | Toggle | Kebal terhadap semua efek perlambatan gerak |
| Silent Actions | Toggle | Anti-Noise: bergerak tanpa notifikasi ke Killer |
| Force Reset | Button | Reset state karakter (anti-stuck) |
| Anti Fall Damage | Toggle | Mencegah damage & animasi kaku saat jatuh |
| Client God Mode | Toggle | HP selalu penuh (client-side) |
| Anti Knock | Toggle | Mencegah knocked down saat dipukul |
| Instant Heal | Button | Memulihkan HP ke Max secara instan |
| Auto Heal Aura | Toggle | Menyembuhkan teman tim di sekitar otomatis |
| Heal Aura Range | Slider (10-50) | Jarak efek Auto Heal Aura |

### Tab Killer
| Fitur | Tipe | Deskripsi |
|-------|------|-----------|
| Drop Prediction | Toggle | Aimbot tombak otomatis untuk target jauh |
| No Gravity | Toggle | Tombak terbang lurus tanpa gravitasi |
| Anti-Blind | Toggle | Kebal efek Fog & Flash dari Survivor |
| Anti-Stun | Toggle | Kebal stun dari Pallet |
| Double Damage Generator | Toggle | Menendang generator berkali-kali (Multiplier) |
| Gen Damage Multiplier | Slider (2-10) | Jumlah kali damage per serangan ke Generator |
| Activate Power | Button | Mengaktifkan kekuatan spesial Killer |

### Tab Visuals
| Fitur | Tipe | Deskripsi |
|-------|------|-----------|
| Player ESP | Toggle | Menampilkan semua pemain (Killer=merah, Survivor=hijau) + jarak & HP |
| Object ESP | Toggle | Menampilkan Generator, Pallet, Exit Gate, dan Hook |
| Custom FOV | Toggle | Mengatur jarak pandang kamera |
| FOV Value | Slider (30-120) | Nilai Field of View |
| Show Crosshair | Toggle | Titik bidik di tengah layar |
| Remove Blur/Bloom | Toggle | Matikan efek buram & pantulan cahaya |
| Force Fullbright | Toggle | Map terang tanpa bayangan |
| Potato Mode | Toggle | Hapus semua efek untuk FPS maksimal |

### Tab Combat
| Fitur | Tipe | Deskripsi |
|-------|------|-----------|
| Enable Aimbot | Toggle | Mengunci bidikan kamera ke musuh terdekat |
| Aim Radius | Slider (50-500) | Radius pencarian target aimbot |
| Target Tracer | Toggle | Garis laser merah ke target aimbot |
| Lock-On Highlight | Toggle | Target bersinar Merah/Emas |
| FPP / TPP | Button | Toggle First Person / Third Person |
| Expand Hitbox | Toggle | Memperbesar hitbox musuh |
| Auto Attack | Toggle | Otomatis memukul musuh dalam jangkauan |
| Auto Attack Range | Slider (3-25) | Jarak auto attack |

### Tab Automation
| Fitur | Tipe | Deskripsi |
|-------|------|-----------|
| Auto Generator | Toggle | Menyelesaikan SkillCheck otomatis (Perfect/Neutral) |
| Mode: Perfect | Button | SkillCheck mode Perfect |
| Mode: Neutral | Button | SkillCheck mode Neutral |
| Instant Escape | Button | Teleport ke gerbang & buka gate |
| Boost All Gen | Button | Set semua Generator ke 100% |
| Self UnHook (100%) | Toggle | Manipulasi peluang 100% lepas dari Hook |

## Keybinds

| Key | Fungsi |
|-----|--------|
| `RightCtrl` | Toggle GUI |
| `H` | Instant Heal |
| `R` | Force Reset State |
| `G` | Toggle God Mode |
| `T` | Toggle FPP / TPP |

## Instalasi

### Metode 1 — Executor (Direkomendasikan)

1. Buka executor kamu (Synapse X, Fluxus, etc.)
2. Copy & paste kode dari `ViolenceDistrictHub.lua`
3. Execute

### Metode 2 — LoadString

```luau
loadstring(game:HttpGet('https://raw.githubusercontent.com/USERNAME/REPO-NAME/refs/heads/main/ViolenceDistrictHub.lua'))()
```

> Ganti `USERNAME/REPO-NAME` dengan username GitHub dan nama repository kamu.

### Metode 3 — Require (Local)

Pastikan folder `src/Init` dari [WindUI](https://github.com/FajarFnyaFerrary/District) sudah ada di workspace executor, lalu:

```luau
require("./src/Init")
```

Script akan otomatis fallback ke HTTP loader jika require gagal.

## Struktur Kode

```
ViolenceDistrictHub.lua
├── WindUI Loader          — require → ReplicatedStorage → HTTP fallback
├── Services & Config      — 30+ flag konfigurasi
├── Utility Helpers        — getCharacter, findRemotes, isPlayerKiller, dll
├── WindUI Window          — CreateWindow, Tag, Topbar
├── Tab VIP                — Auto Play, Auto Dagger, Wiggle Master
├── Tab Survivor           — Speed, God Mode, Heal, Anti-Knock
├── Tab Killer             — Spear mods, Anti-Blind/Stun, Gen Attack
├── Tab Visuals            — ESP, FOV, Crosshair, Fullbright, Potato
├── Tab Combat             — Aimbot, Tracer, Highlight, Hitbox, Auto Attack
├── Tab Automation         — Auto Generator, Escape, UnHook
├── ScreenGui Overlays     — Crosshair, Tracer Line, Aim Circle
├── ESP System             — Highlight + BillboardGui (Player & Object)
├── Heartbeat Loop         — Speed, NoSlowdown, GodMode, AntiKnock, HealAura
├── RenderStepped Loop     — ESP update, Aimbot, Tracer, Fullbright, Potato
├── Background Tasks       — 12 spawn loops (AutoPlay, Dagger, Wiggle, dll)
├── Character Handlers     — CharacterAdded, PlayerAdded, PlayerRemoving
└── Keybinds               — H, R, G, T
```

## Teknologi

| Komponen | Teknologi |
|----------|-----------|
| UI Framework | [WindUI](https://github.com/FajarFnyaFerrary/District) by Footagesus |
| Bahasa | Lua / Luau |
| Icon Set | Solar Icons, SF Symbols |
| Anti-Detection | `cloneref` pada semua service |
| ESP System | Roblox `Highlight` + `BillboardGui` |

## Credits

- **WindUI** — [Footagesus](https://github.com/Footagesus) ([Repository](https://github.com/FajarFnyaFerrary/District))
- **Icons** — [Lucide](https://github.com/lucide-icons/lucide), [Solar Icons](https://icones.js.org/collection/solar), [SF Symbols](https://sf-symbols-one.vercel.app/), [Craft Icons](https://www.figma.com/community/file/1415718327120418204), [Geist Icons](https://vercel.com/geist/icons)
- **Script** — Zetttify

## Disclaimer

> [!IMPORTANT]
> Script ini **gratis** dan **open-source**. Jika ada yang menjual script ini, itu **BUKAN** dari author asli.
>
> Script ini bersifat **edukasi**. Author tidak bertanggung jawab atas:
> - **Banned akun** Roblox akibat penggunaan script
> - **Kerusakan data** atau loss item dalam game
> - **Penyalahgunaan** script oleh pihak lain
>
> Gunakan dengan bijak. **Risk is yours.**
