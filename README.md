# prism

A real-time 3D rendering engine built from scratch in Rust - no game engine, no shortcuts. Implements a deferred rendering pipeline with physically-based materials, running natively on Macs via the Metal backend.

## Features

- Deferred rendering pipeline - geometry pass writes to a G-buffer (albedo/metallic, normal/roughness, world position); a separate lighting pass computes per-pixel shading, decoupling lighting cost from scene complexity.
- Physically-based rendering (PBR) - full metallic-roughness workflow with a Cook-Torrance BRDF (GGX normal distribution, Smith geometry function, Fresnel-Schlick approximation), the same lighting model used by Unreal Engine and Blender.
- ECS-based scene graph - entities, transforms, and components managed via hecs, matching the architecture pattern used in Unity and Bevy.
- glTF model loading - imports real-world 3D assets (positions, normals, UVs, indices) via the gltf crate, alongside a procedural mesh generator for pipeline testing.
- Interactive camera - orbit controls via mouse drag, zoom via scroll wheel and trackpad pinch gestures.
- GPU-native - built on wgpu, targeting the Metal backend directly (the same graphics API layer used by Firefox and the Bevy engine).

## Architecture

Geometry Pass renders mesh data into a G-buffer with three render targets:
1. Albedo + Metallic
2. Normal + Roughness
3. World Position

The Lighting Pass then runs a single fullscreen triangle that samples the G-buffer and computes Cook-Torrance PBR shading per pixel.

Splitting geometry and lighting into separate passes means lighting complexity no longer scales with scene geometry - the same architecture used by Unreal Engine, CryEngine, and most modern AAA renderers.

## Tech Stack

- GPU API: wgpu (Metal backend)
- Windowing: winit
- Math: glam
- ECS: hecs
- Model loading: gltf
- GPU buffer casting: bytemuck
- Shading language: WGSL

## Getting Started

### Prerequisites
- Rust (2021 edition or later)
- macOS with Metal support (Intel or Apple Silicon)

### Build and Run

git clone https://github.com/compiledbyutkarsh/prism.git
cd prism
cargo run --release

## Controls

- Left-click + drag: Orbit camera
- Scroll wheel / trackpad pinch: Zoom in/out

## Roadmap

- [x] wgpu + Metal foundation
- [x] ECS scene graph
- [x] glTF mesh loading
- [x] Interactive orbit camera
- [x] PBR material system (Cook-Torrance BRDF)
- [x] Deferred rendering (G-buffer)
- [ ] Cascaded shadow maps
- [ ] Post-processing stack (bloom, tonemapping, gamma correction)
- [ ] Multiple dynamic lights (point, spot, directional)
- [ ] Texture mapping (albedo, normal, metallic-roughness maps)
- [ ] Skeletal animation

## License

MIT (c) compiledbyutkarsh
