#version 330

// Animated text effects: vanilla 26.2 core/text.fsh plus the effect tint.
// Configuration lives in include/text_effects.glsl.

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
#moj_import <minecraft:fog.glsl>
#endif

#moj_import <minecraft:dynamictransforms.glsl>
#moj_import <minecraft:globals.glsl>
#moj_import <minecraft:text_effects.glsl>

uniform sampler2D Sampler0;

#if !defined(IS_GUI) && !defined(IS_SEE_THROUGH)
in float sphericalVertexDistance;
in float cylindricalVertexDistance;
#endif

in vec4 vertexColor;
in vec2 texCoord0;
flat in int effectMode;
in float effectCoord;

out vec4 fragColor;

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

#ifdef IS_SEE_THROUGH
    vec4 color = texColor * tint;
#else
    vec4 color = texColor * tint * ColorModulator;
#endif
    if (color.a < 0.1) {
        discard;
    }

#ifdef IS_SEE_THROUGH
    fragColor = color * ColorModulator;
#elif defined(IS_GUI)
    fragColor = color;
#else
    fragColor = apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, FogColor);
#endif
}
