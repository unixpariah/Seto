const std = @import("std");

const Text = @import("../Text.zig");
const BorderTree = @import("BorderTree.zig");
const NormalTree = @import("NormalTree.zig");
const Config = @import("../Config.zig");
const Output = @import("../Output.zig");
const OutputInfo = @import("../Output.zig").OutputInfo;
const State = @import("../State.zig");

const Self = @This();

state_ptr: *const State,
config_ptr: *const Config,
text_ptr: *Text,
border_tree: BorderTree,
normal_tree: NormalTree,

pub fn init(alloc: std.mem.Allocator, config: *const Config, state_ptr: *const State, text: *Text, outputs: []OutputInfo) Self {
    return .{
        .state_ptr = state_ptr,
        .config_ptr = config,
        .text_ptr = text,
        .border_tree = BorderTree.init(alloc, config.keys.search, config, text, outputs),
        .normal_tree = NormalTree.init(alloc, config.keys.search, config, text, state_ptr.total_dimensions),
    };
}

pub fn move(self: *Self, value: [2]f32) void {
    if (self.state_ptr.border_mode) return;

    // This is a bit hacky and wasteful but implementing it correctly would be very annoying
    // and not worth it considering most likely nobody will move sideways
    self.normal_tree.move(.{ value[0], 0 }, self.state_ptr.total_dimensions, self.config_ptr);
    self.normal_tree.move(.{ 0, value[1] }, self.state_ptr.total_dimensions, self.config_ptr);
}

pub fn resize(self: *Self, value: [2]f32) void {
    if (self.state_ptr.border_mode) return;

    // This is a bit hacky and wasteful but implementing it correctly would be very annoying
    // and not worth it considering most likely nobody will resize sideways
    self.normal_tree.resize(.{ value[0], 0 }, self.state_ptr.total_dimensions, self.config_ptr, self.text_ptr);
    self.normal_tree.resize(.{ 0, value[1] }, self.state_ptr.total_dimensions, self.config_ptr, self.text_ptr);
}

pub fn find(self: *const Self, buffer: *[]u32) !?[2]f32 {
    if (self.state_ptr.border_mode) return self.border_tree.find(buffer) else return self.normal_tree.find(buffer);
}

pub fn drawText(self: *Self, output: *Output, buffer: []u32) void {
    if (self.state_ptr.border_mode)
        self.border_tree.drawText(output, buffer, self.config_ptr, self.text_ptr)
    else
        self.normal_tree.drawText(output, buffer, self.config_ptr, self.text_ptr);
}

pub fn deinit(self: *const Self) void {
    self.border_tree.deinit();
    self.normal_tree.deinit();
}
