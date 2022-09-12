# sfc3
Provides chat commands in the form of a [StarfallEx](https://github.com/thegrb93/StarfallEx) chip. Remake of [sfc2](https://github.com/x4fx77x4f/sfc2). Inspired by [lutils](https://github.com/Oppossome/lutils) and [LuaDev](https://github.com/Metastruct/luadev).

## Usage
1. `git clone https://github.com/x4fx77x4f/sfc3 ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/starfall/sfc3`
2. Flash `sfc3/init.lua` to a chip.
3. (Optional) Connect a HUD component to the chip.

## Commands
- `help`: List all commands.
- `l <code>`: Run code on server. Chip owner only. ("Lua")
- `ls <code>`: Run code on server and your own client. Chip owner only. ("Lua Shared")
- `lm <code>`: Run code on your own client. ("Lua Myself")
- `lsc <targets> <code>`: Run code on specified targets. ("Lua Send Clients")
- Replace `l` with `p` in previous 4 commands to also print output. ("Print")
- Prepend `s` to previous 5/8 commands to also only print in chat for yourself. ("Silent")
