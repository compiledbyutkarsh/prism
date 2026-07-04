struct CameraUniform {
    view_proj: mat4x4<f32>,
    camera_pos: vec3<f32>,
};
@group(0) @binding(0)
var<uniform> camera: CameraUniform;

@group(1) @binding(0)
var t_albedo_metallic: texture_2d<f32>;
@group(1) @binding(1)
var t_normal_roughness: texture_2d<f32>;
@group(1) @binding(2)
var t_position: texture_2d<f32>;
@group(1) @binding(3)
var gbuffer_sampler: sampler;

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

// Fullscreen triangle trick: 3 vertices covering the whole screen,
// no vertex buffer needed. Standard technique used by deferred renderers
// to avoid a redundant quad's extra two vertices/indices.
@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> VertexOutput {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0)
    );

    var out: VertexOutput;
    let pos = positions[in_vertex_index];
    out.clip_position = vec4<f32>(pos, 0.0, 1.0);
    out.uv = vec2<f32>(pos.x * 0.5 + 0.5, 1.0 - (pos.y * 0.5 + 0.5));
    return out;
}

const PI: f32 = 3.14159265359;

fn distribution_ggx(n_dot_h: f32, roughness: f32) -> f32 {
    let a = roughness * roughness;
    let a2 = a * a;
    let n_dot_h2 = n_dot_h * n_dot_h;
    let denom = n_dot_h2 * (a2 - 1.0) + 1.0;
    return a2 / (PI * denom * denom);
}

fn geometry_schlick_ggx(n_dot_v: f32, roughness: f32) -> f32 {
    let r = roughness + 1.0;
    let k = (r * r) / 8.0;
    return n_dot_v / (n_dot_v * (1.0 - k) + k);
}

fn geometry_smith(n_dot_v: f32, n_dot_l: f32, roughness: f32) -> f32 {
    let ggx_v = geometry_schlick_ggx(n_dot_v, roughness);
    let ggx_l = geometry_schlick_ggx(n_dot_l, roughness);
    return ggx_v * ggx_l;
}

fn fresnel_schlick(cos_theta: f32, f0: vec3<f32>) -> vec3<f32> {
    return f0 + (vec3<f32>(1.0) - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let albedo_metallic = textureSample(t_albedo_metallic, gbuffer_sampler, in.uv);
    let normal_roughness = textureSample(t_normal_roughness, gbuffer_sampler, in.uv);
    let position_sample = textureSample(t_position, gbuffer_sampler, in.uv);

    // position.w acts as a "was this pixel written by geometry" flag —
    // background pixels stay at 0 and are skipped (no lit surface there).
    if (position_sample.w < 0.5) {
        discard;
    }

    let albedo = albedo_metallic.rgb;
    let metallic = albedo_metallic.a;
    let normal = normalize(normal_roughness.rgb);
    let roughness = normal_roughness.a;
    let world_position = position_sample.rgb;

    let n = normal;
    let v = normalize(camera.camera_pos - world_position);

    let light_dir = normalize(vec3<f32>(0.5, 0.8, 0.3));
    let light_color = vec3<f32>(1.0, 1.0, 1.0) * 3.0;
    let l = light_dir;
    let h = normalize(v + l);

    let f0 = mix(vec3<f32>(0.04), albedo, metallic);

    let n_dot_v = max(dot(n, v), 0.0001);
    let n_dot_l = max(dot(n, l), 0.0001);
    let n_dot_h = max(dot(n, h), 0.0);
    let h_dot_v = max(dot(h, v), 0.0);

    let ndf = distribution_ggx(n_dot_h, roughness);
    let g = geometry_smith(n_dot_v, n_dot_l, roughness);
    let f = fresnel_schlick(h_dot_v, f0);

    let numerator = ndf * g * f;
    let denominator = 4.0 * n_dot_v * n_dot_l + 0.0001;
    let specular = numerator / denominator;

    let k_specular = f;
    let k_diffuse = (vec3<f32>(1.0) - k_specular) * (1.0 - metallic);

    let diffuse = k_diffuse * albedo / PI;
    let radiance_out = (diffuse + specular) * light_color * n_dot_l;

    let ambient = albedo * 0.03;
    let color = ambient + radiance_out;

    let mapped = color / (color + vec3<f32>(1.0));
    let gamma_corrected = pow(mapped, vec3<f32>(1.0 / 2.2));

    return vec4<f32>(gamma_corrected, 1.0);
}
