-- for lazy programmers
local M = minetest.get_meta
local S = minetest.get_translator("techage_digiline_converter")

local logic = techage.logic
local OVER_LOAD_MAX = 10
local CYCLE_TIME = 2

local function formspec(meta)
	local channel = meta:get_string("channel") or ""
	return "size[7.5,3]" ..
		"field[0.5,1;7,1;channel;" .. S("Channel") .. ";" .. channel .. "]" .. "button_exit[2,2;3,1;exit;" .. S("Save") .. "]"
end

local function send_message(pos, number, topic, payload)
	local meta = M(pos)
	local mem = techage.get_mem(pos)
	mem.overload_cnt = (mem.overload_cnt or 0) + 1
	if mem.overload_cnt > OVER_LOAD_MAX then
		logic.infotext(M(pos), S("TA4 Digiline Converter"), "fault (overloaded)")
		techage.logic.swap_node(pos, "techage_digiline_converter:ta4_digiline_converter")
		minetest.get_node_timer(pos):stop()
		return false
	end
	local own_num = meta:get_string("node_number")
	return techage.send_single(own_num, number, topic, payload)
end

local function on_receive_fields(pos, _, fields, sender)
	local name = sender:get_player_name()
	if minetest.is_protected(pos, name) and not minetest.check_player_privs(name, {protection_bypass = true}) then
		return
	end
	if (fields.channel) then
		local meta = minetest.get_meta(pos)
		meta:set_string("channel", fields.channel)
		meta:set_string("formspec", formspec(meta))
	end

	minetest.get_node_timer(pos):start(CYCLE_TIME)
end

local function on_timer(pos, elapsed)
	local mem = techage.get_mem(pos)
	mem.overload_cnt = 0
	return true
end

local function techage_set_numbers(pos, numbers, player_name)
	local meta = M(pos)
	local res = logic.set_numbers(pos, numbers, player_name, S("TA4 Digiline Converter"))
	meta:set_string("formspec", formspec(meta))
	return res
end

local function after_dig_node(pos, oldnode, oldmetadata)
	techage.remove_node(pos, oldnode, oldmetadata)
	techage.del_mem(pos)
	mesecon.on_dignode(pos, oldnode)
end

local on_digiline_receive = function(pos, _, channel, msg)
	local setchan = minetest.get_meta(pos):get_string("channel")
	if channel == setchan and msg.number ~= nil and msg.topic ~= nil then
		local result = send_message(pos, msg.number, msg.topic, msg.payload)
		if result ~= nil then
			digilines.receptor_send(
				pos,
				digilines.rules.default,
				channel,
				{number = msg.number, topic = msg.topic, payload = msg.payload, result = result}
			)
		end
	end
end

minetest.register_node(
	"techage_digiline_converter:ta4_digiline_converter",
	{
		description = S("TA4 Digiline Converter"),
		tiles = {
			-- up, down, right, left, back, front
			"techage_filling_ta4.png^techage_frame_ta4_top.png",
			"techage_filling_ta4.png^techage_frame_ta4_top.png",
			"techage_filling_ta4.png^techage_frame_ta4.png^techage_appl_mesecons_converter.png"
		},
		after_place_node = function(pos, placer)
			local meta = M(pos)
			local mem = techage.get_mem(pos)
			logic.after_place_node(pos, placer, "techage_digiline_converter:ta4_digiline_converter", S("TA4 Digiline Converter"))
			logic.infotext(meta, S("TA4 Digiline Converter"))
			meta:set_string("formspec", formspec(meta))
			mem.overload_cnt = -OVER_LOAD_MAX -- to prevent overload after placing
			minetest.get_node_timer(pos):start(CYCLE_TIME)
			mesecon.on_placenode(pos, minetest.get_node(pos))
		end,
		on_receive_fields = on_receive_fields,
		on_timer = on_timer,
		techage_set_numbers = techage_set_numbers,
		after_dig_node = after_dig_node,
		digilines = {
			receptor = {},
			effector = {
				action = on_digiline_receive
			}
		},
		paramtype2 = "facedir",
		groups = {choppy = 2, cracky = 2, crumbly = 2},
		is_ground_content = false,
		sounds = default.node_sound_wood_defaults()
	}
)

minetest.register_craft(
	{
		output = "techage_digiline_converter:ta4_digiline_converter",
		recipe = {
			{"techage:ta3_mesecons_converter", "digilines:wire_std_00000000"}
		}
	}
)

techage.register_node(
	{"techage_digiline_converter:ta4_digiline_converter"},
	{
		on_recv_message = function(pos, src, topic, payload)
			local mem = techage.get_mem(pos)
			mem.overload_cnt = (mem.overload_cnt or 0) + 1
			if mem.overload_cnt > OVER_LOAD_MAX then
				logic.infotext(M(pos), S("TA4 Digiline Converter"), "fault (overloaded)")
				minetest.get_node_timer(pos):stop()
				return false
			end
			local channel = minetest.get_meta(pos):get_string("channel")
			digilines.receptor_send(pos, digilines.rules.default, channel, {number = src, topic = topic, payload = payload})
		end,
		on_node_load = function(pos)
			minetest.get_node_timer(pos):start(CYCLE_TIME)
		end
	}
)
