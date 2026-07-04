struct CameraUniform {
    view_proj: mat4x4<f32>,
    camera_pos: vec3<f32>,
};
@group(0) @binding(0)
var<uniform> camera: CameraUniform;

struct MaterialUniform {
    albedo: vec3<f32>,
    metallic: f32,
    roughness: f32,
};
@group(1) @binding(0)
var<uniform> material: MaterialUniform;

struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) normal: vec3<f32>,
    @location(2) uv: vec2<f32>,
};

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) world_position: vec3<f32>,
    @location(1) world_normal: vec3<f32>,
};

@vertex
fn vs_main(in: VertexInput) -> VertexOutput {
    var out: VertexOutput;
    out.clip_position = camera.view_proj * vec4<f32>(in.position, 1.0);
    out.world_position = in.position;
    out.world_normal = in.normal;
    return out;
}

const PI: f32 = 3.14159265359;

// Trowbridge-Reitz GGX normal distribution function — describes how
// microfacets are statistically oriented for a given roughness.
fn distribution_ggx(n_dot_h: f32, roughness: f32) -> f32 {
    let a = roughness * roughness;
    let a2 = a * a;
    let n_dot_h2 = n_dot_h * n_dot_h;
    let denom = n_dot_h2 * (a2 - 1.0) + 1.0;
    return a2 / (PI * denom * denom);
}

// Schlick-GGX geometry function — models microfacet self-shadowing/masking.
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

// Fresnel-Schlick approximation — how reflectivity increases at grazing angles.
fn fresnel_schlick(cos_theta: f32, f0: vec3<f32>) -> vec3<f32> {
    return f0 + (vec3<f32>(1.0) - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let n = normalize(in.world_normal);
    let v = normalize(camera.camera_pos - in.world_position);

    // Single directional light (sun-like) for now.
    let light_dir = normalize(vec3<f32>(0.5, 0.8, 0.3));
    let light_color = vec3<f32>(1.0, 1.0, 1.0) * 3.0;
    let l = light_dir;
    let h = normalize(v + l);

    // Dielectrics reflect ~4% of light at normal incidence; metals tint
    // the reflection with their albedo instead.
    let f0 = mix(vec3<f32>(0.04), material.albedo, material.metallic);

    let n_dot_v = max(dot(n, v), 0.0001);
    let n_dot_l = max(dot(n, l), 0.0001);
    let n_dot_h = max(dot(n, h), 0.0);
    let h_dot_v = max(dot(h, v), 0.0);

    let ndf = distribution_ggx(n_dot_h, material.roughness);
    let g = geometry_smith(n_dot_v, n_dot_l, material.roughness);
    let f = fresnel_schlick(h_dot_v, f0);

    let numerator = ndf * g * f;
    let denominator = 4.0 * n_dot_v * n_dot_l + 0.0001;
    let specular = numerator / denominator;

    // Energy conservation: metals have no diffuse component.
    let k_specular = f;
    let k_diffuse = (vec3<f32>(1.0) - k_specular) * (1.0 - material.metallic);

    let diffuse = k_diffuse * material.albedo / PI;
    let radiance_out = (diffuse + specular) * light_color * n_dot_l;

    let ambient = material.albedo * 0.03;
    let color = ambient + radiance_out;

    // Simple Reinhard tonemapping + gamma correction so bright highlights
    // don't clip harshly, matching standard real-time renderer output.
    let mapped = color / (color + vec3<f32>(1.0));
    let gamma_corrected = pow(mapped, vec3<f32>(1.0 / 2.2));

    return vec4<f32>(gamma_corrected, 1.0);
}
