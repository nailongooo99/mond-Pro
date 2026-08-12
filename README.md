<p align="right">
  <img align="right" height="140" src="https://github.com/rooootdev/mond/blob/main/mond.png?raw=true" style="float: right;"/>
</p>

<div style="width: calc(100% - 180px);">
  <h1 style="margin-bottom: 0;">mond</h1>
</div>

<p align="left">Edit MobileGestalt on iOS 27.0 beta 1 - 4!</p>

> [!WARNING]  
> Some of the tweaks have the potential to brick your device! Use at your own risk.

**Planned:**<br>
&#45; HouseArrest file browser (iOS 18 - 27?)
&#45; Pocket Poster

**Known Issues:**<br>
&#45; Tweaks may disappear on reboot<br>
&#45; Apple Intelligence activation is broken<br>
&#45; Disable Region restrictions may be broken on some versions/devices<br>
&#45; iPadOS UI and related tweaks may not work and/or **bootloop** you!<br>
&#45; Dynamic Island artwork and display canvas are separate settings. On iPhone 16e, enable the optional **Dynamic Island Status Bar / Canvas Fix** when you want the selected subtype's native canvas geometry.

**Dynamic Island canvas fix:**<br>
The picker uses the Dynamic Island subtype as the source of truth for the optional `IOMobileGraphicsFamily.plist` update. The iPhone 14 Pro subtype is `2556` (canvas `1179 × 2556`); `2436` remains reserved for Disable Dynamic Island and iPhone X Gestures. Other supported profiles are `2796` (`1290 × 2796`), `2622` (`1206 × 2622`), `2868` (`1320 × 2868`), and `2736` (`1260 × 2736`). The canvas plist is backed up before the first change, and disabling the option restores that backup when available. A reboot may be required after changing resolution.

**Credits:**<br>
&#45; [forcequit](https://github.com/forcequitOS) for his work on bad_query<br>
&#45; [johnny](https://github.com/0xjohnnydev) for his work on the MCM bug class<br>
&#45; [jailbreak.party](https://github.com/jailbreakdotparty) for PartyUI, GestaltView and the implementation of [neon](https://github.com/neonmodder123)'s respring method<br>

<i>btw, you should like totally star this repo and stuff</i>
