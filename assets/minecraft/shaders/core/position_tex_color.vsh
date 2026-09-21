#version 330

// Animated tooltip frame: vanilla 26.2 core/position_tex_color.vsh plus the
// two values the fragment stage needs to place and gate the effect.
//
// This file cannot #moj_import. It is compiled during startup, before resource
// packs exist, which is why vanilla pastes its uniform blocks in by hand here
// and nowhere else. The effect configuration in position_tex_color.fsh is a
// copy of include/text_effects.glsl for the same reason.

layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
    mat4 TextureMat;
};
layout(std140) uniform Projection {
    mat4 ProjMat;
};

in vec3 Position;
in vec2 UV0;
in vec4 Color;

out vec2 texCoord0;
out vec4 vertexColor;
out float effectCoord;
flat out int guiPass;

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
