const rl = @import("raylib.zig");

pub const ModelValues = struct {
    const Self = @This();

    albedo: f32,
    metalness: f32,
    roughness: f32,
    occlusion: f32,
    emission: f32,
    normal: f32,

    pub fn prepare(albedo: ?f32, metalness: ?f32, roughness: ?f32, occlusion: ?f32, emission: ?f32, normal: ?f32) Self {
        return Self{
            .albedo = albedo orelse 0.0,
            .metalness = metalness orelse 0.0,
            .roughness = roughness orelse 0.0,
            .occlusion = occlusion orelse 1.0,
            .emission = emission orelse 0.0,
            .normal = normal orelse 0.0,
        };
    }

    pub fn allnull() Self {
        return prepare(null, null, null, null, null, null);
    }
};

pub const ModelTextures = struct {
    const Self = @This();

    albedo: ?[*c]const u8,
    metalness: ?[*c]const u8,
    roughness: ?[*c]const u8,
    occlusion: ?[*c]const u8,
    emission: ?[*c]const u8,
    normal: ?[*c]const u8,

    pub fn prepare(albedo: ?[*c]const u8, metalness: ?[*c]const u8, roughness: ?[*c]const u8, occlusion: ?[*c]const u8, emission: ?[*c]const u8, normal: ?[*c]const u8) Self {
        return Self{
            .albedo = albedo,
            .metalness = metalness,
            .roughness = roughness,
            .occlusion = occlusion,
            .emission = emission,
            .normal = normal,
        };
    }

    pub fn allnull() Self {
        return prepare(null, null, null, null, null, null);
    }
};

pub fn RaylibModel(fileName: [*c]const u8, values: ?ModelValues, textures: ?ModelTextures, shader: ?rl.Shader) rl.Model {
    const model = rl.LoadModel(fileName);
    model.materials[0].shader = shader orelse model.materials[0].shader;

    applyValues(model, values orelse ModelValues.allnull());
    applyTextures(model, textures orelse ModelTextures.allnull());

    return model;
}

pub fn applyValues(model: rl.Model, values: ModelValues) void {
    model.materials[0].maps[rl.MATERIAL_MAP_ALBEDO].color = rl.WHITE;
    model.materials[0].maps[rl.MATERIAL_MAP_ALBEDO].value = values.albedo;
    model.materials[0].maps[rl.MATERIAL_MAP_METALNESS].value = values.metalness;
    model.materials[0].maps[rl.MATERIAL_MAP_ROUGHNESS].value = values.roughness;
    model.materials[0].maps[rl.MATERIAL_MAP_OCCLUSION].value = values.occlusion;
    model.materials[0].maps[rl.MATERIAL_MAP_EMISSION].value = values.emission;
    model.materials[0].maps[rl.MATERIAL_MAP_EMISSION].color = rl.BLACK;
}

pub fn applyTextures(model: rl.Model, textures: ModelTextures) void {
    if (textures.albedo != null) model.materials[0].maps[rl.MATERIAL_MAP_ALBEDO].texture = rl.LoadTexture(textures.albedo.?);
    if (textures.metalness != null) model.materials[0].maps[rl.MATERIAL_MAP_METALNESS].texture = rl.LoadTexture(textures.metalness.?);
    if (textures.roughness != null) model.materials[0].maps[rl.MATERIAL_MAP_ROUGHNESS].texture = rl.LoadTexture(textures.roughness.?);
    if (textures.occlusion != null) model.materials[0].maps[rl.MATERIAL_MAP_OCCLUSION].texture = rl.LoadTexture(textures.occlusion.?);
    if (textures.emission != null) model.materials[0].maps[rl.MATERIAL_MAP_EMISSION].texture = rl.LoadTexture(textures.emission.?);
    if (textures.normal != null) model.materials[0].maps[rl.MATERIAL_MAP_NORMAL].texture = rl.LoadTexture(textures.normal.?);
}
