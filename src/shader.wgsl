struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    @location(0) color: vec3<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> VertexOutput {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(0.0, 0.6),
        vec2<f32>(-0.6, -0.5),
        vec2<f32>(0.6, -0.5)
    );

    var colors = array<vec3<f32>, 3>(
        vec3<f32>(0.9, 0.2, 0.4),
        vec3<f32>(0.2, 0.5, 0.9),
        vec3<f32>(0.3, 0.9, 0.4)
    );

    var out: VertexOutput;
    out.clip_position = vec4<f32>(positions[in_vertex_index], 0.0, 1.0);
    out.color = colors[in_vertex_index];
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return vec4<f32>(in.color, 1.0);
}
