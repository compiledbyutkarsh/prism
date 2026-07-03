use anyhow::{Context, Result};
use bytemuck::{Pod, Zeroable};

/// A single vertex as it will be uploaded to the GPU.
/// Layout matches what the vertex shader expects: position, normal (for
/// lighting), and UV coordinates (for texture sampling).
#[repr(C)]
#[derive(Debug, Clone, Copy, Pod, Zeroable)]
pub struct Vertex {
    pub position: [f32; 3],
    pub normal: [f32; 3],
    pub uv: [f32; 2],
}

impl Vertex {
    pub fn desc() -> wgpu::VertexBufferLayout<'static> {
        wgpu::VertexBufferLayout {
            array_stride: std::mem::size_of::<Vertex>() as wgpu::BufferAddress,
            step_mode: wgpu::VertexStepMode::Vertex,
            attributes: &[
                wgpu::VertexAttribute {
                    offset: 0,
                    shader_location: 0,
                    format: wgpu::VertexFormat::Float32x3,
                },
                wgpu::VertexAttribute {
                    offset: std::mem::size_of::<[f32; 3]>() as wgpu::BufferAddress,
                    shader_location: 1,
                    format: wgpu::VertexFormat::Float32x3,
                },
                wgpu::VertexAttribute {
                    offset: std::mem::size_of::<[f32; 6]>() as wgpu::BufferAddress,
                    shader_location: 2,
                    format: wgpu::VertexFormat::Float32x2,
                },
            ],
        }
    }
}

/// A CPU-side mesh: raw vertex and index data, before it's uploaded to the GPU.
pub struct MeshData {
    pub vertices: Vec<Vertex>,
    pub indices: Vec<u32>,
}

/// Loads the first mesh primitive found in a glTF/GLB file.
/// This is intentionally simple for now — it grabs positions, normals,
/// and UVs from the first mesh's first primitive. Multi-mesh scenes and
/// materials/textures come in a later pass.
pub fn load_gltf(path: &str) -> Result<MeshData> {
    let (document, buffers, _images) =
        gltf::import(path).with_context(|| format!("Failed to load glTF file at {}", path))?;

    let mesh = document
        .meshes()
        .next()
        .context("glTF file contains no meshes")?;

    let primitive = mesh
        .primitives()
        .next()
        .context("glTF mesh contains no primitives")?;

    let reader = primitive.reader(|buffer| Some(&buffers[buffer.index()]));

    let positions: Vec<[f32; 3]> = reader
        .read_positions()
        .context("Primitive has no position data")?
        .collect();

    let normals: Vec<[f32; 3]> = reader
        .read_normals()
        .map(|iter| iter.collect())
        .unwrap_or_else(|| vec![[0.0, 1.0, 0.0]; positions.len()]);

    let uvs: Vec<[f32; 2]> = reader
        .read_tex_coords(0)
        .map(|iter| iter.into_f32().collect())
        .unwrap_or_else(|| vec![[0.0, 0.0]; positions.len()]);

    let indices: Vec<u32> = reader
        .read_indices()
        .context("Primitive has no index data")?
        .into_u32()
        .collect();

    let vertices = positions
        .iter()
        .zip(normals.iter())
        .zip(uvs.iter())
        .map(|((&position, &normal), &uv)| Vertex {
            position,
            normal,
            uv,
        })
        .collect();

    log::info!(
        "Loaded glTF mesh: {} vertices, {} indices",
        positions.len(),
        indices.len()
    );

    Ok(MeshData { vertices, indices })
}
