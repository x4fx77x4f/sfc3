# sfc3
Provides chat commands in the form of a [StarfallEx](https://github.com/thegrb93/StarfallEx) chip. Remake of [sfc2](https://github.com/x4fx77x4f/sfc2). Inspired by [lutils](https://github.com/Oppossome/lutils) and [LuaDev](https://github.com/Metastruct/luadev).

## Usage
1. `git clone https://github.com/x4fx77x4f/sfc3 ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/starfall/sfc3`
2. Flash `sfc3/init.lua` to a chip.
3. (Optional) Connect a HUD component to the chip.

## Commands
- `help [command]`: Get documentation for command, or list all commands if none specified.
- `l <code>`: Run code on server. Chip owner only. ("Lua")
- `ls <code>`: Run code on server and your own client. Chip owner only. ("Lua Shared")
- `lm <code>`: Run code on your own client. ("Lua Myself")
- `lsc <targets> <code>`: Run code on specified targets. ("Lua Send Clients") Targets can be player names (e.g. `$psc sar 2+2` will run `return 2+2` on a player named "Sarah", so long as only one name matches), `#me` (yourself), `#all` (all clients), `#them` (every client except yours), `#this`/`#you` (the player you're looking at), or `#server`. Separated by commas.
- Replace `l` with `p` in previous 4 commands to also print output. ("Print")
- Prepend `s` to previous 5/8 commands to also only print in chat for yourself. ("Silent")
- `goto <target>`: Teleport yourself to specified target. Chip owner only. Target can be a player name, `#chip`, `#there` (the position you're looking at), `#seat` (the invisible seat used for teleportation), or `#` followed by an entity index.
- `return`: Teleport yourself to your previous position. Every `goto` adds your position before the teleport to the end of a stack, and `return` will pop the last element off the stack and teleport you there.
