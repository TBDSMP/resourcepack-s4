#version 330

// Animated tooltip frame: vanilla 26.2 core/position_tex_color.fsh plus a
// marker test on the sampled texel.
//
// core/text.* keys off the vertex colour, which the game sets per glyph. A
// tooltip quad arrives white and carries nothing about the item, so the marker
// lives in the texture instead: a sprite painted in one of the effect colours
// at TOOLTIP_MARKER_ALPHA. tools/mark_tooltip_sprites.py writes those sprites.
//
// This file cannot #moj_import, so the uniform blocks and the effect settings
// below are pasted in. Anything changed in include/text_effects.glsl has to be
// changed here too.

layout(std140) uniform DynamicTransforms {
    mat4 ModelViewMat;
    vec4 ColorModulator;
    vec3 ModelOffset;
    mat4 TextureMat;
};

// Copy of include/globals.glsl.
layout(std140) uniform Globals {
    ivec3 CameraBlockPos;
    vec3 CameraOffset;
    vec2 ScreenSize;
    float GlintAlpha;
    float GameTime;
    int MenuBlurRadius;
    int UseRgss;
};

uniform sampler2D Sampler0;

in vec2 texCoord0;
in vec4 vertexColor;
in float effectCoord;
flat in int guiPass;

out vec4 fragColor;

// ============================================================================
//  Tooltip marker
// ============================================================================

// The alpha that marks a texel as ours. GUI art is opaque or fully transparent
// almost everywhere, so 254 is a value nothing else uses, and on screen it is
// indistinguishable from opaque. A texel only animates if it carries this
// alpha and one of the effect colours below.
#define TOOLTIP_MARKER_ALPHA (254.0 / 255.0)

// The alpha marked pixels are drawn with. 1.0 is a solid border. Vanilla's own
// tooltip frame is drawn at 80.0 / 255.0 if you want that weight instead.
#define TOOLTIP_DRAW_ALPHA 1.0

// ============================================================================
//  Copy of include/text_effects.glsl
// ============================================================================

#define RAINBOW_TARGET (vec3(0xFF, 0x00, 0xFF) / 255.0)
#define RAINBOW_CYCLE_SECONDS 4.0
#define RAINBOW_DIRECTION 1.0
#define RAINBOW_WAVELENGTH_GUI 120.0
#define RAINBOW_SATURATION 1.0
#define RAINBOW_BRIGHTNESS 1.0

#define PULSE_UNREAL_TARGET (vec3(0x86, 0x66, 0xE6) / 255.0)
#define PULSE_UNREAL_COLOR  PULSE_UNREAL_TARGET
#define PULSE_TRANSCENDENT_TARGET (vec3(0xC7, 0x0A, 0x17) / 255.0)
#define PULSE_TRANSCENDENT_COLOR  PULSE_TRANSCENDENT_TARGET
#define PULSE_CELESTIAL_TARGET (vec3(0xF5, 0xBA, 0x0A) / 255.0)
#define PULSE_CELESTIAL_COLOR  PULSE_CELESTIAL_TARGET
#define PULSE_OMEGA_TARGET (vec3(0x3B, 0xB7, 0xFF) / 255.0)
#define PULSE_OMEGA_COLOR  PULSE_OMEGA_TARGET

#define PULSE_LIGHTEN 0.35
#define PULSE_DARKEN 0.15
#define PULSE_CYCLE_SECONDS 2.5
#define PULSE_DIRECTION 1.0
#define PULSE_WAVELENGTH_GUI 160.0

#define EFFECT_NONE    0
#define EFFECT_RAINBOW 1
#define EFFECT_UNREAL 2
#define EFFECT_TRANSCENDENT 3
#define EFFECT_CELESTIAL 4
#define EFFECT_OMEGA 5

const float TEXT_EFFECT_TAU = 6.28318531;
const float TEXT_EFFECT_TOLERANCE = 0.002;

bool effect_matches(vec3 color, vec3 target) {
    return all(lessThan(abs(color - target), vec3(TEXT_EFFECT_TOLERANCE)));
}

// No shadow variants here. A texture has no drop shadow, so this returns the
// effect itself rather than the packed mode core/text.vsh passes along.
int marker_effect(vec3 color) {
    if (effect_matches(color, RAINBOW_TARGET)) return EFFECT_RAINBOW;
    if (effect_matches(color, PULSE_UNREAL_TARGET)) return EFFECT_UNREAL;
    if (effect_matches(color, PULSE_TRANSCENDENT_TARGET)) return EFFECT_TRANSCENDENT;
    if (effect_matches(color, PULSE_CELESTIAL_TARGET)) return EFFECT_CELESTIAL;
    if (effect_matches(color, PULSE_OMEGA_TARGET)) return EFFECT_OMEGA;
    return EFFECT_NONE;
}

vec3 effect_base_color(int effect) {
    if (effect == EFFECT_UNREAL) return PULSE_UNREAL_COLOR;
    if (effect == EFFECT_TRANSCENDENT) return PULSE_TRANSCENDENT_COLOR;
    if (effect == EFFECT_CELESTIAL) return PULSE_CELESTIAL_COLOR;
    if (effect == EFFECT_OMEGA) return PULSE_OMEGA_COLOR;
    return vec3(1.0);
}

vec3 rainbow_color(float hue) {
    vec3 rgb = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return mix(vec3(1.0), rgb, RAINBOW_SATURATION) * RAINBOW_BRIGHTNESS;
}

vec3 rainbow_at(float coord, float gameTime) {
    float seconds = gameTime * 1200.0;
    float hue = fract(coord - RAINBOW_DIRECTION * seconds / RAINBOW_CYCLE_SECONDS);
    return rainbow_color(hue);
}

vec3 pulse_color(vec3 color, float wave) {
    vec3 lighter = mix(color, vec3(1.0), PULSE_LIGHTEN);
    vec3 darker = color * (1.0 - PULSE_DARKEN);
    return mix(color, wave > 0.0 ? lighter : darker, abs(wave));
}

vec3 pulse_at(vec3 color, float coord, float gameTime) {
    float seconds = gameTime * 1200.0;
    float phase = coord - PULSE_DIRECTION * seconds / PULSE_CYCLE_SECONDS;
    return pulse_color(color, cos(phase * TEXT_EFFECT_TAU));
}

// ============================================================================

void main() {
    vec4 texel = texture(Sampler0, texCoord0);

    // Almost every fragment leaves here on the alpha test, one sample in.
    if (guiPass == 1 && abs(texel.a - TOOLTIP_MARKER_ALPHA) < TEXT_EFFECT_TOLERANCE) {
        int effect = marker_effect(texel.rgb);
        if (effect == EFFECT_RAINBOW) {
            texel.rgb = rainbow_at(effectCoord / RAINBOW_WAVELENGTH_GUI, GameTime);
            texel.a = TOOLTIP_DRAW_ALPHA;
        } else if (effect != EFFECT_NONE) {
            texel.rgb = pulse_at(effect_base_color(effect),
                                 effectCoord / PULSE_WAVELENGTH_GUI,
                                 GameTime);
            texel.a = TOOLTIP_DRAW_ALPHA;
        }
    }

    vec4 color = texel * vertexColor;
    if (color.a == 0.0) {
        discard;
    }
    fragColor = color * ColorModulator;
}
