# TechAge digiline converter

TA3 mesecons converter exist in techage. What about the digiline converter?

"TA4 Digiline Converter" can send messages to any TA block via digiline:

```lua
-- Enable block
digiline_send("converter", {number = 27, topic = "on"})
-- Read in chest
digiline_send("converter", {number = 32, topic = "count", payload = 1})
-- Chest's response comes as a digiline message (if the target block responds):
-- {number = 32, topic = "count", payload = 1, result = 20}
```

The block can process incoming messages (but cannot respond to them):

```lua
-- Src block number can income as string
if event.type == "digiline" and event.channel == "converter" and tostring(event.msg.number) == "27" and event.msg.topic == "on" then
  port.a = true
end
```
