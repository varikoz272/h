const rl = @import("raylib.zig");
const std = @import("std");

const GLSL_VERSION: c_int = 330;
const screenWidth: c_int = 1920;
const screenHeight: c_int = 1080;

const LightType = enum(c_int) {
    LIGHT_DIRECTIONAL = 0,
    LIGHT_POINT = 1,
    LIGHT_SPOT = 2,
};

const Light = struct {
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
};

var lightCount: c_int = 0;
pub const MAX_LIGHTS: c_int = 4;

pub fn main() !void {
    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);
    rl.InitWindow(screenWidth, screenHeight, "asdkvbhgj bhj,m nadshbjmn, ads");

    var camera = rl.Camera{
        .position = rl.Vector3{ .x = 2.0, .y = 2.0, .z = 6.0 },
        .target = rl.Vector3{ .x = 0.0, .y = 0.5, .z = 0.0 },
        .up = rl.Vector3{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = rl.CAMERA_PERSPECTIVE,
    };

    var shader = rl.LoadShader("./resources/shaders/glsl330/pbr.vs", "./resources/shaders/glsl330/pbr.fs");
    shader.locs[rl.SHADER_LOC_MAP_ALBEDO] = rl.GetShaderLocation(shader, "albedoMap");
    shader.locs[rl.SHADER_LOC_MAP_METALNESS] = rl.GetShaderLocation(shader, "mraMap");
    shader.locs[rl.SHADER_LOC_MAP_NORMAL] = rl.GetShaderLocation(shader, "normalMap");
    shader.locs[rl.SHADER_LOC_MAP_EMISSION] = rl.GetShaderLocation(shader, "emissiveMap");
    shader.locs[rl.SHADER_LOC_MAP_DIFFUSE] = rl.GetShaderLocation(shader, "albedoColor");
    shader.locs[rl.SHADER_LOC_VECTOR_VIEW] = rl.GetShaderLocation(shader, "viewPos");

    const lightCountLoc = rl.GetShaderLocation(shader, "numOfLights");
    var maxLightCount = MAX_LIGHTS;

    rl.SetShaderValue(shader, lightCountLoc, &maxLightCount, rl.SHADER_UNIFORM_INT);

    var ambientIntensity: f32 = 0.02;
    const ambientColor = rl.Color{ .r = 26, .g = 32, .b = 135, .a = 255 };
    var ambientColorNormalized = rl.Vector3{
        .x = @as(f32, @floatFromInt(ambientColor.r)) / 255.0,
        .y = @as(f32, @floatFromInt(ambientColor.g)) / 255.0,
        .z = @as(f32, @floatFromInt(ambientColor.b)) / 255.0,
    };
    rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "ambientColor"), &ambientColorNormalized, rl.SHADER_UNIFORM_VEC3);
    rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "ambient"), &ambientIntensity, rl.SHADER_UNIFORM_FLOAT);

    const emissiveIntensityLoc = rl.GetShaderLocation(shader, "emissivePower");
    const emissiveColorLoc = rl.GetShaderLocation(shader, "emissiveColor");
    const textureTilingLoc = rl.GetShaderLocation(shader, "tiling");

    var car = rl.LoadModel("./resources/models/old_car_new.glb");
    car.materials[0].shader = shader;
    car.materials[0].maps[rl.MATERIAL_MAP_ALBEDO].color = rl.WHITE;
    car.materials[0].maps[rl.MATERIAL_MAP_METALNESS].value = 0.0;
    car.materials[0].maps[rl.MATERIAL_MAP_ROUGHNESS].value = 0.0;
    car.materials[0].maps[rl.MATERIAL_MAP_OCCLUSION].value = 1.0;
    car.materials[0].maps[rl.MATERIAL_MAP_EMISSION].color = rl.Color{ .r = 255, .g = 162, .b = 0, .a = 255 };

    car.materials[0].maps[rl.MATERIAL_MAP_ALBEDO].texture = rl.LoadTexture("./resources/old_car_d.png");
    car.materials[0].maps[rl.MATERIAL_MAP_METALNESS].texture = rl.LoadTexture("./resources/old_car_mra.png");

    car.materials[0].maps[rl.MATERIAL_MAP_NORMAL].texture = rl.LoadTexture("./resources/old_car_n.png");
    car.materials[0].maps[rl.MATERIAL_MAP_EMISSION].texture = rl.LoadTexture("./resources/old_car_e.png");

    var floor = rl.LoadModel("./resources/models/plane.glb");

    floor.materials[0].shader = shader;

    floor.materials[0].maps[rl.MATERIAL_MAP_ALBEDO].color = rl.WHITE;
    floor.materials[0].maps[rl.MATERIAL_MAP_METALNESS].value = 0.0;
    floor.materials[0].maps[rl.MATERIAL_MAP_ROUGHNESS].value = 0.0;
    floor.materials[0].maps[rl.MATERIAL_MAP_OCCLUSION].value = 1.0;
    floor.materials[0].maps[rl.MATERIAL_MAP_EMISSION].color = rl.BLACK;

    floor.materials[0].maps[rl.MATERIAL_MAP_ALBEDO].texture = rl.LoadTexture("./resources/road_a.png");
    floor.materials[0].maps[rl.MATERIAL_MAP_METALNESS].texture = rl.LoadTexture("./resources/road_mra.png");
    floor.materials[0].maps[rl.MATERIAL_MAP_NORMAL].texture = rl.LoadTexture("./resources/road_n.png");

    var carTextureTiling = rl.Vector2{ .x = 0.5, .y = 0.5 };
    var floorTextureTiling = rl.Vector2{ .x = 0.5, .y = 0.5 };

    var lights = [MAX_LIGHTS]Light{
        CreateLight(@intFromEnum(LightType.LIGHT_POINT), rl.Vector3{ .x = -1.0, .y = 1.0, .z = -2.0 }, rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.YELLOW, 4.0, shader),
        CreateLight(@intFromEnum(LightType.LIGHT_POINT), rl.Vector3{ .x = 2.0, .y = 1.0, .z = 1.0 }, rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.RED, 3.3, shader),
        CreateLight(@intFromEnum(LightType.LIGHT_POINT), rl.Vector3{ .x = -2.0, .y = 1.0, .z = 1.0 }, rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.GREEN, 8.3, shader),
        CreateLight(@intFromEnum(LightType.LIGHT_POINT), rl.Vector3{ .x = 1.0, .y = 1.0, .z = -2.0 }, rl.Vector3{ .x = 0.0, .y = 0.0, .z = 0.0 }, rl.BLUE, 2.0, shader),
    };

    var usage: c_int = 1;
    rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "useTexAlbedo"), &usage, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "useTexNormal"), &usage, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "useTexMRA"), &usage, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "useTexEmissive"), &usage, rl.SHADER_UNIFORM_INT);

    rl.SetTargetFPS(60);
    rl.ToggleFullscreen();
    rl.DisableCursor();

    while (!rl.WindowShouldClose()) {
        rl.UpdateCamera(&camera, rl.CAMERA_FIRST_PERSON);

        const cameraPos = [3]f32{ camera.position.x, camera.position.y, camera.position.z };
        rl.SetShaderValue(shader, shader.locs[rl.SHADER_LOC_VECTOR_VIEW], &cameraPos, rl.SHADER_UNIFORM_VEC3);

        if (rl.IsKeyPressed(rl.KEY_ONE)) {
            lights[2].enabled = !lights[2].enabled;
        }

        if (rl.IsKeyPressed(rl.KEY_TWO)) {
            lights[1].enabled = !lights[1].enabled;
        }

        if (rl.IsKeyPressed(rl.KEY_THREE)) {
            lights[3].enabled = !lights[3].enabled;
        }

        if (rl.IsKeyPressed(rl.KEY_FOUR)) {
            lights[0].enabled = !lights[0].enabled;
        }

        for (0..MAX_LIGHTS) |i| {
            UpdateLight(shader, lights[i]);
        }

        rl.BeginDrawing();

        rl.ClearBackground(rl.BLACK);

        rl.BeginMode3D(camera);

        rl.SetShaderValue(shader, textureTilingLoc, &floorTextureTiling, rl.SHADER_UNIFORM_VEC2);
        var floorEmissiveColor = rl.ColorNormalize(floor.materials[0].maps[rl.MATERIAL_MAP_EMISSION].color);
        rl.SetShaderValue(shader, emissiveColorLoc, &floorEmissiveColor, rl.SHADER_UNIFORM_VEC4);

        rl.DrawModel(floor, rl.Vector3Zero(), 5.0, rl.WHITE);

        rl.SetShaderValue(shader, textureTilingLoc, &carTextureTiling, rl.SHADER_UNIFORM_VEC2);
        var carEmissiveColor = rl.ColorNormalize(car.materials[0].maps[rl.MATERIAL_MAP_EMISSION].color);
        rl.SetShaderValue(shader, emissiveColorLoc, &carEmissiveColor, rl.SHADER_UNIFORM_VEC4);
        var emissiveIntensity: f32 = 0.01;
        rl.SetShaderValue(shader, emissiveIntensityLoc, &emissiveIntensity, rl.SHADER_UNIFORM_FLOAT);

        rl.DrawModel(car, rl.Vector3Zero(), 0.25, rl.WHITE);

        for (0..MAX_LIGHTS) |i| {
            const lightColor = rl.Color{ .r = @as(u8, @intFromFloat(lights[i].color[0] * 255)), .g = @as(u8, @intFromFloat(lights[i].color[1] * 255)), .b = @as(u8, @intFromFloat(lights[i].color[2] * 255)), .a = @as(u8, @intFromFloat(lights[i].color[3] * 255)) };

            if (lights[i].enabled) {
                rl.DrawSphereEx(lights[i].position, 0.2, 8, 8, lightColor);
            } else {
                rl.DrawSphereWires(lights[i].position, 0.2, 8, 8, rl.ColorAlpha(lightColor, 0.3));
            }
        }

        rl.EndMode3D();

        rl.DrawFPS(10, 10);

        rl.EndDrawing();
    }

    rl.UnloadMaterial(car.materials[0]);
    car.materials[0].maps = null;
    rl.UnloadModel(car);

    rl.UnloadMaterial(floor.materials[0]);
    floor.materials[0].maps = null;
    rl.UnloadModel(floor);

    rl.UnloadShader(shader);

    rl.CloseWindow();
}

fn CreateLight(lightType: c_int, position: rl.Vector3, target: rl.Vector3, color: rl.Color, intensity: f32, shader: rl.Shader) Light {
    // if (lightCount >= MAX_LIGHTS) return null;

    const light = Light{
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

    UpdateLight(shader, light);
    lightCount += 1;

    return light;
}

fn UpdateLight(shader: rl.Shader, light: Light) void {
    rl.SetShaderValue(shader, light.enabledLoc, &light.enabled, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader, light.typeLoc, &light.type, rl.SHADER_UNIFORM_INT);

    const position = [3]f32{ light.position.x, light.position.y, light.position.z };
    rl.SetShaderValue(shader, light.positionLoc, &position, rl.SHADER_UNIFORM_VEC3);

    const target = [3]f32{ light.target.x, light.target.y, light.target.z };
    rl.SetShaderValue(shader, light.targetLoc, &target, rl.SHADER_UNIFORM_VEC3);
    rl.SetShaderValue(shader, light.colorLoc, &light.color, rl.SHADER_UNIFORM_VEC4);
    rl.SetShaderValue(shader, light.intensityLoc, &light.intensity, rl.SHADER_UNIFORM_FLOAT);
}
