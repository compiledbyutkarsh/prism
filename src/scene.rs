use glam::{Mat4, Quat, Vec3};
use hecs::World;

/// Transform component — position, rotation, and scale of an entity in 3D space.
/// This is the core building block of the scene graph, matching the pattern
/// used by Unity's Transform and Unreal's SceneComponent.
#[derive(Debug, Clone, Copy)]
pub struct Transform {
    pub position: Vec3,
    pub rotation: Quat,
    pub scale: Vec3,
}

impl Default for Transform {
    fn default() -> Self {
        Self {
            position: Vec3::ZERO,
            rotation: Quat::IDENTITY,
            scale: Vec3::ONE,
        }
    }
}

impl Transform {
    pub fn from_position(position: Vec3) -> Self {
        Self {
            position,
            ..Default::default()
        }
    }

    /// Builds the model matrix (local-to-world transform) used by the GPU
    /// to place this entity's mesh correctly in the 3D scene.
    pub fn matrix(&self) -> Mat4 {
        Mat4::from_scale_rotation_translation(self.scale, self.rotation, self.position)
    }
}

/// Tag component to give entities a human-readable name (useful for
/// debugging and future scene-hierarchy UI/inspector tooling).
#[derive(Debug, Clone)]
pub struct Name(pub String);

/// Wraps the hecs World and provides scene-level convenience methods.
/// This is the entry point for spawning and querying all objects in prism.
pub struct Scene {
    pub world: World,
}

impl Scene {
    pub fn new() -> Self {
        Self {
            world: World::new(),
        }
    }

    /// Spawns a basic entity with a name and transform. Mesh/material
    /// components will be attached here once the glTF loader is in place.
    pub fn spawn_empty(&mut self, name: &str, transform: Transform) -> hecs::Entity {
        self.world.spawn((Name(name.to_string()), transform))
    }
}
