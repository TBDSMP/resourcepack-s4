#version 330
#extension GL_ARB_separate_shader_objects : require

// Animated tooltip frame: vanilla 26.3 core/position_tex_color.vsh plus the
// two values the fragment stage needs to place and gate the effect.
//
// This file cannot #include. It is compiled during startup, before resource
// packs exist, which is why vanilla pastes its uniform blocks in by hand here
// and nowhere else. The effect configuration in position_tex_color.fsh is a
// copy of include/text_effects.glsl for the same reason.

layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    mat4 TextureMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
};
layout(std140) uniform Projection {
    mat4 ProjMat;
};

layout(location = 0) in vec3 Position;
layout(location = 1) in vec2 UV0;
layout(location = 2) in vec4 Color;

layout(location = 0) out vec2 texCoord0;
layout(location = 1) out vec4 vertexColor;
layout(location = 2) out float effectCoord;
layout(location = 3) flat out int guiPass;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    texCoord0 = UV0;
    vertexColor = Color;

    // Ten pipelines share this shader. Nine are GUI ones and draw through an
    // orthographic projection, which puts 1 in the bottom right. The tenth is
    // the end sky, whose perspective projection puts 0 there.
    guiPass = (ProjMat[3][3] != 0.0) ? 1 : 0;

    // Position along the screen in GUI pixels, the same axis core/text.vsh
    // uses under IS_GUI, so a marked frame and rainbow text inside it stay in
    // phase at any window size or GUI scale.
    effectCoord = Position.x;
}
