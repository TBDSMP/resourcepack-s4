#version 330
#extension GL_ARB_separate_shader_objects : require

// Animated text effects: vanilla 26.3 core/text.vsh plus colour detection.
// Configuration lives in include/text_effects.glsl.

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#include <minecraft:fog.glsl>
#include <minecraft:sample_lightmap.glsl>
#endif

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:text_effects.glsl>

layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
layout(location = 3) in ivec2 UV2;
#endif

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
uniform sampler2D Sampler2;
layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;
#endif

layout(location = 2) out vec4 vertexColor;
layout(location = 3) out vec2 texCoord0;
layout(location = 4) flat out int effectMode;
layout(location = 5) out float effectCoord;

void main() {
    gl_Position = ProjMat * ModelViewMat * vec4(Position, 1.0);

    // Classify the raw vertex colour, before the lightmap darkens it.
    effectMode = effect_classify(Color.rgb);
    effectCoord = Position.x;

    vec4 color = Color;
    if (effectMode != EFFECT_NONE) {
        // The fragment stage multiplies the effect colour in, so start from
        // white, or from vanilla's drop-shadow brightness for a shadow.
        color.rgb = (effectMode % 2 == 1) ? vec3(0.25) : vec3(1.0);
    }

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
    sphericalVertexDistance = fog_spherical_distance(Position);
    cylindricalVertexDistance = fog_cylindrical_distance(Position);
    vertexColor = color * sample_lightmap(Sampler2, UV2);
#else
    vertexColor = color;
#endif
    texCoord0 = UV0;
}
