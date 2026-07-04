use bytemuck::{Pod, Zeroable};

/// PBR material parameters using the metallic-roughness workflow —
/// the same model used by Unreal Engine, Unity URP, and glTF's default
/// material system. This struct is uploaded directly to the GPU as a
/// uniform buffer.
#[repr(C)]
#[derive(Debug, Clone, Copy, Pod, Zeroable)]
pub struct MaterialUniform {
    pub albedo: [f32; 3],
    pub metallic: f32,
    pub roughness: f32,
    pub _padding: [f32; 3], // keeps struct 16-byte aligned for WGSL uniform rules
}

impl MaterialUniform {
    pub fn new(albedo: [f32; 3], metallic: f32, roughness: f32) -> Self {
        Self {
            albedo,
            metallic,
            roughness,
            _padding: [0.0; 3],
        }
    }
}

impl Default for MaterialUniform {
    fn default() -> Self {
        Self::new([0.7, 0.7, 0.75], 0.1, 0.4)
    }
}
