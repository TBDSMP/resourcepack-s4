#version 330
#extension GL_ARB_separate_shader_objects : require

// Animated text effects: vanilla 26.3 core/text.fsh plus the effect tint.
// Configuration lives in include/text_effects.glsl.

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#include <minecraft:fog.glsl>
#endif

#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>
#include <minecraft:globals.glsl>
#include <minecraft:text_effects.glsl>

uniform sampler2D Sampler0;

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#endif

layout(location = 2) in vec4 vertexColor;
layout(location = 3) in vec2 texCoord0;
layout(location = 4) flat in int effectMode;
layout(location = 5) in float effectCoord;

#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

// Position along the wave, measured in wavelengths.
float wave_coord(float wavelengthGui, float wavelengthWorld) {
#ifdef IS_GUI
    // GUI text: position along the screen in GUI pixels.
    return effectCoord / wavelengthGui;
#else
    // World text (signs, name tags): position across the window.
    return gl_FragCoord.x / (ScreenSize.x * wavelengthWorld);
#endif
}

vec4 calculateFinalColor(vec4 color) {
    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    #endif

    #if !defined(IS_SEE_THROUGH) && !defined(IS_GUI)

    #ifdef OIT_ACCUMULATE
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    color = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
    #endif

    return color;
}

void main() {
    #ifdef IS_GRAYSCALE
    vec4 texColor = texture(Sampler0, texCoord0).rrrr;
    #else
    vec4 texColor = texture(Sampler0, texCoord0);
    #endif

    vec4 tint = vertexColor;
    int effect = effectMode / 2;
    if (effect == EFFECT_RAINBOW) {
        tint.rgb *= rainbow_at(wave_coord(RAINBOW_WAVELENGTH_GUI, RAINBOW_WAVELENGTH_WORLD), GameTime);
    } else if (effect != EFFECT_NONE) {
        tint.rgb *= pulse_at(effect_base_color(effect),
                             wave_coord(PULSE_WAVELENGTH_GUI, PULSE_WAVELENGTH_WORLD),
                             GameTime);
    }

    vec4 color = texColor * tint * ColorModulator;

    if (color.a < 0.1) {
        discard;
    }

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color);
    #endif
}
