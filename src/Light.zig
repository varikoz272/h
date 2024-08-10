const rl = @import("raylib.zig");
const std = @import("std");

pub var lightCount: c_int = 0;
pub const MAX_LIGHTS: c_int = 5;

pub const LightType = enum(c_int) {
    LIGHT_DIRECTIONAL = 0,
    LIGHT_POINT = 1,
    LIGHT_SPOT = 2,

    pub fn value(self: LightType) c_int {
        return @intFromEnum(self);
    }
};

pub const Light = struct {
    const Self = Light;

    type: c_int,
    enabled: bool,
    position: rl.Vector3,
    target: rl.Vector3,
    color: [4]f32,
    intensity: f32,

    typeLoc: c_int,
    enabledLoc: c_int,
    positionLoc: c_int,
    targetLoc: c_int,
    colorLoc: c_int,
    intensityLoc: c_int,

    pub fn init(lightType: c_int, position: rl.Vector3, target: rl.Vector3, color: rl.Color, intensity: f32, shader: rl.Shader) !Self {
        var light = Light{
            .enabled = true,
            .type = lightType,
            .position = position,
            .target = target,
            .color = [4]f32{
                @as(f32, @floatFromInt(color.r)) / 255.0,
                @as(f32, @floatFromInt(color.g)) / 255.0,
                @as(f32, @floatFromInt(color.b)) / 255.0,
                @as(f32, @floatFromInt(color.a)) / 255.0,
            },
            .intensity = intensity,
            .enabledLoc = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].enabled", lightCount)),
            .typeLoc = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].type", lightCount)),
            .positionLoc = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].position", lightCount)),
            .targetLoc = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].target", lightCount)),
            .colorLoc = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].color", lightCount)),
            .intensityLoc = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].intensity", lightCount)),
        };

        // UpdateLight(shader, light);
        light.Update(shader);
        lightCount += 1;

        // try std.io.getStdOut().writer().print("{} | ", .{@TypeOf(Self)});
        // try std.io.getStdOut().writer().print("{}\n\n", .{@TypeOf(light)});

        return light;
    }

    pub fn UpdateLight(shader: rl.Shader, self: Self) void {
        rl.SetShaderValue(shader, self.enabledLoc, &self.enabled, rl.SHADER_UNIFORM_INT);
        rl.SetShaderValue(shader, self.typeLoc, &self.type, rl.SHADER_UNIFORM_INT);

        const position = [3]f32{ self.position.x, self.position.y, self.position.z };
        rl.SetShaderValue(shader, self.positionLoc, &position, rl.SHADER_UNIFORM_VEC3);

        const target = [3]f32{ self.target.x, self.target.y, self.target.z };
        rl.SetShaderValue(shader, self.targetLoc, &target, rl.SHADER_UNIFORM_VEC3);
        rl.SetShaderValue(shader, self.colorLoc, &self.color, rl.SHADER_UNIFORM_VEC4);
        rl.SetShaderValue(shader, self.intensityLoc, &self.intensity, rl.SHADER_UNIFORM_FLOAT);
    }

    pub fn Update(self: *Self, shader: rl.Shader) void {
        UpdateLight(shader, self.*);
    }

    pub fn Toggle(self: *Self) void {
        self.enabled = !self.enabled;
    }
};
