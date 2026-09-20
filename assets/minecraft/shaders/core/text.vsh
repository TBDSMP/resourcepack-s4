#version 330

// Animated text effects: vanilla 26.2 core/text.vsh plus colour detection.
// Configuration lives in include/text_effects.glsl.

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#moj_import <minecraft:sample_lightmap.glsl>
#endif

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:projection.glsl>
#moj_import <minecraft:text_effects.glsl>

in vec3 Position;
in vec4 Color;
in vec2 UV0;
#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in ivec2 UV2;
#endif

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
uniform sampler2D Sampler2;
out float sphericalVertexDistance;
out float cylindricalVertexDistance;
#endif

out vec4 vertexColor;
out vec2 texCoord0;
flat out int effectMode;
out float effectCoord;

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
