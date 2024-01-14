# TechAge digiline converter

TA3 mesecons converter exist in techage. What about the digiline converter?

"TA4 Digiline Converter" can send messages to any TA block via digiline:

```lua
-- Enable block
digiline_send("converter", {number = 27, command = "on"})
-- Read in chest
digiline_send("converter", {number = 32, command = "count", data = 1})
-- Chest's response comes as a digiline message (if the target block responds):
-- {type = "digiline", channel = "converter", msg = {number = 32, command = "count", data = 1, result = 20}}
```

Or TA message can be send in chat command format: `<number> <command> [<data>]`:

```lua
-- Enable block
digiline_send("converter", "27 on")
-- Read in chest
digiline_send("converter", "32 count 1")
-- Chest's response comes as a digiline message (if the target block responds):
--  {type = "digiline", channel = "converter", msg = {number = 32, command = "count", data = 1, result = 20}}
```

The block can process incoming messages (but cannot respond to them):

```lua
-- Event format:  {type = "digiline", channel = "converter", msg = {number = <src block number>, command = "<command>", data = <data>}}
-- Src block number always income as a number
if event.type == "digiline" and event.channel == "converter" and event.msg.number == 27 and event.msg.command == "on" then
  port.a = true
end
```
