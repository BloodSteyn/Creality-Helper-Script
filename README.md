# Creality Helper Script

## About

This script intended for use on Creality **K1 Series** and **Ender-3 V3 Series** printers allows to add more features.

If you don't know what you're doing, I don't recommend following this guide.

## Additions in this fork

This fork adds a **[Hardware Mods] Menu** for K1 Series printers:

- **Gantry Profile**: sets X/Y travel, nozzle wipe position, bed mesh area, input shaper probe point and bed size for linear rail conversions (HDM Full Linear Rail 235x235 / 235x226, BootyCall Jones X-Axis Linear Rail, stock, or custom values). Configuration files are saved before each change and can be restored.
- **Entware Git**: replaces the Git provided with the CFS Upgrade Kit firmware, which is not able to clone GitHub repositories.
- **CFS KAMP Integration**: installs [Creality-K1-CFS-KAMP](https://github.com/cmtergomes/Creality-K1-CFS-KAMP) by cmtergomes, so KAMP purges after the CFS has loaded the filament.
- **CFS Retrude Before Cut**: installs the [mod by FrederickAlt](https://github.com/FrederickAlt/CREALITY-K1-AND-K1-MAX-CFS-RETRUDE-BEFORE-CUT-MOD) to reduce purge waste, keeping your own `[box]` configuration.
- **CFS Toolhead Positions**: sets cutter, purge chute and nozzle wiper positions in `box.cfg` after a gantry conversion.

On CFS Upgrade Kit firmware (2.3.5.x), install the script with:

```
wget --no-check-certificate -O /tmp/cfs-bootstrap.sh https://raw.githubusercontent.com/BloodSteyn/Creality-Helper-Script/main/cfs-bootstrap.sh
sh /tmp/cfs-bootstrap.sh
```

CFS features are provided as is: they have not been validated on a printer by this fork yet.

### Compatibility notes

- The CFS only runs natively on the CFS Upgrade Kit firmware. **2.3.5.34** is the version the CFS KAMP Integration was tested on by its author; 2.3.5.33 is reported with broken Git and Python.
- Flashing the CFS firmware replaces the Klipper configuration. Do not copy a `printer.cfg` from an older firmware back: apply the Gantry Profile again instead.
- On CFS firmware, "Fix printing Gcode files from folder" is blocked because it replaces Creality's `gcode.py`.
- **Cartographer is not supported on the CFS firmware**, it needs a newer Klipper than the one provided by Creality. The known alternatives are a BTT Eddy Duo with [K1Max-Klipper-Eddy](https://github.com/mikeinredding/K1Max-Klipper-Eddy), or [Simple AF](https://pellcorp.github.io/creality-wiki/) with [afc-creality-cfs](https://github.com/mikeinredding/afc-creality-cfs), which does not use this script.

### Sources and credits

All credit for the Helper Script goes to [Guilouz](https://github.com/Guilouz/Creality-Helper-Script). The additions of this fork are based on the work and findings of:

- [cmtergomes/Creality-K1-CFS-KAMP](https://github.com/cmtergomes/Creality-K1-CFS-KAMP): KAMP with the CFS loading sequence (downloaded at install time).
- [FrederickAlt/CREALITY-K1-AND-K1-MAX-CFS-RETRUDE-BEFORE-CUT-MOD](https://github.com/FrederickAlt/CREALITY-K1-AND-K1-MAX-CFS-RETRUDE-BEFORE-CUT-MOD): retrude before cut mod (downloaded at install time).
- [gebauer/Creality-Helper-Script-K1-CFS](https://github.com/gebauer/Creality-Helper-Script-K1-CFS): Helper Script fork for the CFS firmware, Git workaround.
- [Helper Script Wiki discussion #787](https://github.com/Guilouz/Creality-Helper-Script-Wiki/discussions/787) and [#760](https://github.com/Guilouz/Creality-Helper-Script-Wiki/discussions/760): CFS firmware reports, Entware Git workaround by A-Void-Me.
- [crazyslicster/SLICK1MAX](https://github.com/crazyslicster/SLICK1MAX): reference `box.cfg` and `printer.cfg` for the CFS firmware.
- [hdm-utah/HDM-K1-235x235-330mm](https://github.com/hdm-utah/HDM-K1-235x235-330mm): HDM Full Linear Rail conversion and its configuration values.
- [tlace17/K1-Linear-Rail-Gantry](https://github.com/tlace17/K1-Linear-Rail-Gantry): BootyCall Jones X-Axis Linear Rail.
- [HDM left motor mount for CFS](https://www.printables.com/model/1230239-hdm-k1k1ck1sek1a-left-motor-mount-for-cfs): cutter block mount for the HDM gantry.
- [CrealityOfficial/K1_Series_Annex](https://github.com/CrealityOfficial/K1_Series_Annex): official root guide and Fluidd/Mainsail packages.
- [K1-Klipper/cartographer-klipper](https://github.com/K1-Klipper/cartographer-klipper) and [Simple AF Cartographer guide](https://pellcorp.github.io/creality-wiki/cartographer/): Cartographer requirements.
- [vsevolod-volkov/K1-Klipper-Eddy](https://github.com/vsevolod-volkov/K1-Klipper-Eddy), [mikeinredding/K1Max-Klipper-Eddy](https://github.com/mikeinredding/K1Max-Klipper-Eddy): Eddy probe on the CFS firmware.
- [mikeinredding/afc-creality-cfs](https://github.com/mikeinredding/afc-creality-cfs), [tomaspakosta/k1c-cfs-klipper](https://github.com/tomaspakosta/k1c-cfs-klipper): open CFS drivers.

## Wiki

Guide to use it is available here: [Wiki](https://guilouz.github.io/Creality-Helper-Script-Wiki/)

<br />
