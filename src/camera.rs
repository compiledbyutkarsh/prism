use bytemuck::{Pod, Zeroable};
use glam::{Mat4, Vec3};

/// Camera holds the parameters needed to build view and projection matrices.
/// Uses an orbit-style setup (target + distance + angles), same interaction
/// model as Blender's viewport camera or Unity's Scene view.
pub struct Camera {
    pub target: Vec3,
    pub distance: f32,
    pub yaw: f32,
    pub pitch: f32,
    pub fov_y_radians: f32,
    pub aspect: f32,
    pub z_near: f32,
    pub z_far: f32,
}

impl Camera {
    pub fn new(aspect: f32) -> Self {
        Self {
            target: Vec3::ZERO,
            distance: 3.0,
            yaw: std::f32::consts::FRAC_PI_4,
            pitch: 0.4,
            fov_y_radians: 45f32.to_radians(),
            aspect,
            z_near: 0.1,
            z_far: 100.0,
        }
    }

    pub fn eye_position(&self) -> Vec3 {
        let x = self.distance * self.pitch.cos() * self.yaw.sin();
        let y = self.distance * self.pitch.sin();
        let z = self.distance * self.pitch.cos() * self.yaw.cos();
        self.target + Vec3::new(x, y, z)
    }

    pub fn view_matrix(&self) -> Mat4 {
        Mat4::look_at_rh(self.eye_position(), self.target, Vec3::Y)
    }

    pub fn projection_matrix(&self) -> Mat4 {
        Mat4::perspective_rh(self.fov_y_radians, self.aspect, self.z_near, self.z_far)
    }

    /// Combined view-projection matrix, uploaded to the GPU each frame.
    pub fn view_projection_matrix(&self) -> Mat4 {
        self.projection_matrix() * self.view_matrix()
    }
}

/// GPU-side representation of the camera's view-projection matrix.
/// This is the uniform buffer layout the vertex shader will read from.
#[repr(C)]
#[derive(Debug, Clone, Copy, Pod, Zeroable)]
pub struct CameraUniform {
    pub view_proj: [[f32; 4]; 4],
}

impl CameraUniform {
    pub fn new() -> Self {
        Self {
            view_proj: Mat4::IDENTITY.to_cols_array_2d(),
        }
    }

    pub fn update(&mut self, camera: &Camera) {
        self.view_proj = camera.view_projection_matrix().to_cols_array_2d();
    }
}
