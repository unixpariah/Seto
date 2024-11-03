const std = @import("std");

const BorderTree = @import("BorderTree.zig");
const NormalTree = @import("NormalTree.zig");
const Config = @import("../Config.zig");
const Output = @import("../Output.zig");
const State = @import("../main.zig").State;

const Self = @This();

state_ptr: *State,
border_tree: BorderTree,
normal_tree: NormalTree,

pub fn init(alloc: std.mem.Allocator, config: *Config, outputs: *const []Output, state_ptr: *State) Self {
    return .{
        .state_ptr = state_ptr,
        .border_tree = BorderTree.init(alloc, config, outputs),
        .normal_tree = NormalTree.init(alloc, config, outputs),
    };
}

pub fn move(self: *Self, value: [2]f32) void {
    if (self.state_ptr.border_mode) return;
    self.normal_tree.move(value);
}

pub fn resize(self: *Self, value: [2]f32) void {
    if (self.state_ptr.border_mode) return;
    self.normal_tree.resize(value);
}

pub fn find(self: *Self, buffer: *[]u32) !?[2]f32 {
    if (self.state_ptr.border_mode) return self.border_tree.find(buffer) else return self.normal_tree.find(buffer);
}

pub fn updateCoordinates(self: *Self) void {
    self.normal_tree.updateCoordinates();
    self.border_tree.updateCoordinates();
}

pub fn drawText(self: *Self, output: *Output, buffer: []u32) void {
    if (self.state_ptr.border_mode) self.border_tree.drawText(output, buffer) else self.normal_tree.drawText(output, buffer);
}

pub fn deinit(self: *const Self) void {
    self.border_tree.deinit();
    self.normal_tree.deinit();
}
