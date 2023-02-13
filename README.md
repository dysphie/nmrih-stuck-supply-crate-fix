> ⚠️ This plugin is no longer needed as of NMRiH 1.13.2

# [NMRiH] Stuck Supply Crate Fix

Fixes an issue where players are permanently frozen after interacting with a supply crate. It does so by removing the movement lock altogether.

## Installation
- Install [Sourcemod](https://www.sourcemod.net/downloads.php?branch=stable)
- Extract the zip file in [releases](https://github.com/dysphie/nmrih-stuck-supply-crate-fix/releases) to your server's `addons/sourcemod` directory

## Cvars

To prevent abuse, a new cvar `sv_supply_crate_max_use_dist` is added to control the maximum distance at which players can interact with a crate.
(saved to `cfg/sourcemod/stuck-supply-crate-fix.cfg`)


