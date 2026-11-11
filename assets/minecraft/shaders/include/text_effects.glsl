#ifndef TEXT_EFFECTS_GLSL
#define TEXT_EFFECTS_GLSL

// ============================================================================
//  Animated text effects - configuration
//  Imported by core/text.vsh and core/text.fsh. Edit values here, then press
//  F3+T in game to reload.
//
//  Five colours are watched for. One becomes a scrolling rainbow, the other
//  four keep their own colour and breathe from a bit lighter to a bit darker.
//  Every other colour is left alone.
// ============================================================================

// ---------------------------------------------------------------- rainbow ---

// The text colour that turns into a rainbow. Write the hex bytes of the
// colour, so #FF00FF becomes vec3(0xFF, 0x00, 0xFF).
#define RAINBOW_TARGET (vec3(0xFF, 0x00, 0xFF) / 255.0)

// Seconds for the pattern to travel one full wavelength. Smaller is faster.
// Pick a value that divides 1200 evenly (1, 2, 3, 4, 5, 6, 8, 10, ...) and
// the animation stays seamless when the in-game day counter wraps.
#define RAINBOW_CYCLE_SECONDS 4.0

// 1.0 moves the colours left to right, -1.0 moves them right to left.
#define RAINBOW_DIRECTION 1.0

// Width of one full red-to-red cycle for GUI text (chat, item names, titles,
// menus, the hotbar), in GUI pixels. Independent of window size and GUI scale.
#define RAINBOW_WAVELENGTH_GUI 120.0

// Width of one full cycle for text drawn in the world (signs, name tags,
// text displays), as a fraction of the screen width.
#define RAINBOW_WAVELENGTH_WORLD 0.35

// 1.0 is fully saturated. Lower values pull the colours toward white.
#define RAINBOW_SATURATION 1.0

// Overall brightness of the rainbow, 1.0 is full.
#define RAINBOW_BRIGHTNESS 1.0

// ----------------------------------------------------------------- pulses ---

// Four colours that shimmer between a lighter and a darker version of
// themselves. TARGET is the colour you type into the game, COLOR is what gets
// drawn. They are the same by default, so the text keeps the colour you wrote
// and only the brightness moves. Set TARGET to something you never use
// elsewhere if you would rather trigger the effect from a rare colour.

// Unreal.
#define PULSE_UNREAL_TARGET (vec3(0x86, 0x66, 0xE6) / 255.0)
#define PULSE_UNREAL_COLOR  PULSE_UNREAL_TARGET

// Transcendent.
#define PULSE_TRANSCENDENT_TARGET (vec3(0xC7, 0x0A, 0x17) / 255.0)
#define PULSE_TRANSCENDENT_COLOR  PULSE_TRANSCENDENT_TARGET

// Celestial.
#define PULSE_CELESTIAL_TARGET (vec3(0xF5, 0xBA, 0x0A) / 255.0)
#define PULSE_CELESTIAL_COLOR  PULSE_CELESTIAL_TARGET

// Omega.
#define PULSE_OMEGA_TARGET (vec3(0x3B, 0xB7, 0xFF) / 255.0)
#define PULSE_OMEGA_COLOR  PULSE_OMEGA_TARGET

// How far the bright half of the wave lifts the colour toward white, 0.0 to
// 1.0. 0.0 keeps the colour flat, 1.0 goes all the way to white.
#define PULSE_LIGHTEN 0.35

// How far the dark half of the wave pulls the colour toward black, 0.0 to 1.0.
#define PULSE_DARKEN 0.15

// Seconds for the wave to travel one full wavelength. Same rule as the
// rainbow: use a value that divides 1200 evenly.
#define PULSE_CYCLE_SECONDS 2.5

// 1.0 moves the wave left to right, -1.0 moves it right to left.
#define PULSE_DIRECTION 1.0

// Distance between two bright crests for GUI text, in GUI pixels. Make this
// large compared with your text and the whole line brightens together; make it
// small and the shimmer runs letter by letter.
#define PULSE_WAVELENGTH_GUI 160.0

// Same for text drawn in the world, as a fraction of the screen width.
#define PULSE_WAVELENGTH_WORLD 0.5

// ------------------------------------------------------------------- wave ---

// Text in the font tbdsmp:wave bobs up and down, one letter after another.
// It keeps its colour, so it stacks with the rainbow and pulse effects.
// Use it in a text component: {"text": "hello", "font": "tbdsmp:wave"}
// Only the vanilla bitmap glyphs (Latin, accented, Cyrillic, Greek, ...)
// move. Characters that fall back to Unifont stay still, and so does
// everything when "Force Unicode Font" is turned on.

// How far letters move up and down from their resting spot, in GUI pixels.
#define WAVE_AMPLITUDE_GUI 1.0

// Same for text drawn in the world, in blocks. A sign pixel is about 0.011
// blocks, a name tag pixel 0.025.
#define WAVE_AMPLITUDE_WORLD 0.012

// Seconds for one letter to go up, down and back. Same rule as the others:
// use a value that divides 1200 evenly.
#define WAVE_CYCLE_SECONDS 1.5

// 1.0 moves the wave left to right, -1.0 moves it right to left.
#define WAVE_DIRECTION 1.0

// Distance between two crests for GUI text, in GUI pixels. A normal letter
// is about 6 pixels wide.
#define WAVE_WAVELENGTH_GUI 40.0

// Same for text drawn in the world, as a fraction of the screen width.
#define WAVE_WAVELENGTH_WORLD 0.25

// ----------------------------------------------------------------- shared ---

// 1 also recolours the drop shadow (vanilla draws it at 25% brightness).
// 0 leaves the shadow as a plain dark colour.
#define TEXT_EFFECT_SHADOW 1

// ============================================================================
//  Implementation
// ============================================================================

#define EFFECT_NONE    0
#define EFFECT_RAINBOW 1
#define EFFECT_UNREAL 2
#define EFFECT_TRANSCENDENT 3
#define EFFECT_CELESTIAL 4
#define EFFECT_OMEGA 5

const float TEXT_EFFECT_TAU = 6.28318531;

// Vertex colours arrive as bytes, so any two distinct colours differ by at
// least 1/255. A tolerance below that matches exactly one colour.
const float TEXT_EFFECT_TOLERANCE = 0.002;

bool effect_matches(vec3 color, vec3 target) {
    return all(lessThan(abs(color - target), vec3(TEXT_EFFECT_TOLERANCE)));
}

// Vanilla shadow colour: each channel is (int)(channel * 0.25).
vec3 effect_shadow_of(vec3 target) {
    return floor(target * 255.0 * 0.25) / 255.0;
}

// The mode packs both answers into one integer: mode / 2 is the effect,
// mode % 2 is 1 for a drop shadow. 0 means "leave this text alone".
int effect_classify(vec3 color) {
    if (effect_matches(color, RAINBOW_TARGET)) return EFFECT_RAINBOW * 2;
    if (effect_matches(color, PULSE_UNREAL_TARGET)) return EFFECT_UNREAL * 2;
    if (effect_matches(color, PULSE_TRANSCENDENT_TARGET)) return EFFECT_TRANSCENDENT * 2;
    if (effect_matches(color, PULSE_CELESTIAL_TARGET)) return EFFECT_CELESTIAL * 2;
    if (effect_matches(color, PULSE_OMEGA_TARGET)) return EFFECT_OMEGA * 2;
#if TEXT_EFFECT_SHADOW
    if (effect_matches(color, effect_shadow_of(RAINBOW_TARGET))) return EFFECT_RAINBOW * 2 + 1;
    if (effect_matches(color, effect_shadow_of(PULSE_UNREAL_TARGET))) return EFFECT_UNREAL * 2 + 1;
    if (effect_matches(color, effect_shadow_of(PULSE_TRANSCENDENT_TARGET))) return EFFECT_TRANSCENDENT * 2 + 1;
    if (effect_matches(color, effect_shadow_of(PULSE_CELESTIAL_TARGET))) return EFFECT_CELESTIAL * 2 + 1;
    if (effect_matches(color, effect_shadow_of(PULSE_OMEGA_TARGET))) return EFFECT_OMEGA * 2 + 1;
#endif
    return EFFECT_NONE;
}

// The colour a pulse effect is built from.
vec3 effect_base_color(int effect) {
    if (effect == EFFECT_UNREAL) return PULSE_UNREAL_COLOR;
    if (effect == EFFECT_TRANSCENDENT) return PULSE_TRANSCENDENT_COLOR;
    if (effect == EFFECT_CELESTIAL) return PULSE_CELESTIAL_COLOR;
    if (effect == EFFECT_OMEGA) return PULSE_OMEGA_COLOR;
    return vec3(1.0);
}

// hue in [0, 1) -> fully saturated RGB.
vec3 rainbow_color(float hue) {
    vec3 rgb = clamp(abs(mod(hue * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return mix(vec3(1.0), rgb, RAINBOW_SATURATION) * RAINBOW_BRIGHTNESS;
}

// coord is in wavelengths. GameTime is (ticks % 24000 + partialTick) / 24000,
// so it advances by 1/1200 per real second.
vec3 rainbow_at(float coord, float gameTime) {
    float seconds = gameTime * 1200.0;
    float hue = fract(coord - RAINBOW_DIRECTION * seconds / RAINBOW_CYCLE_SECONDS);
    return rainbow_color(hue);
}

// wave runs from -1 (darkest) to 1 (lightest).
vec3 pulse_color(vec3 color, float wave) {
    vec3 lighter = mix(color, vec3(1.0), PULSE_LIGHTEN);
    vec3 darker = color * (1.0 - PULSE_DARKEN);
    return mix(color, wave > 0.0 ? lighter : darker, abs(wave));
}

// coord is in wavelengths, like rainbow_at.
vec3 pulse_at(vec3 color, float coord, float gameTime) {
    float seconds = gameTime * 1200.0;
    float phase = coord - PULSE_DIRECTION * seconds / PULSE_CYCLE_SECONDS;
    return pulse_color(color, cos(phase * TEXT_EFFECT_TAU));
}

// Glyphs in tbdsmp:wave carry marker pixels in their corners, colour
// (255, 255, B) with alpha 254 (was opaque) or 1 (was empty). B tells which
// corner it is. tools/make_wave_font.py writes them.
#define WAVE_MARK_BOTH  252
#define WAVE_MARK_LEFT  253
#define WAVE_MARK_RIGHT 254

// The marker at one texel, or 0 if there is none.
int wave_marker(sampler2D atlas, ivec2 texel) {
    ivec4 c = ivec4(round(texelFetch(atlas, texel, 0) * 255.0));
    if (c.r != 255 || c.g != 255 || (c.a != 1 && c.a != 254)) return 0;
    return (c.b >= WAVE_MARK_BOTH && c.b <= WAVE_MARK_RIGHT) ? c.b : 0;
}

// For a vertex of a wave glyph: how many texels its corner sits right of the
// glyph's left edge (0 for left corners, the glyph width for right corners).
// -1 for every other glyph.
//
// The glyph atlas UVs are inset by 0.01 texels, so flooring them lands on the
// texel just inside the corner, whatever corner this vertex is.
int wave_corner_offset(sampler2D atlas, vec2 uv) {
    ivec2 texel = ivec2(floor(uv * vec2(textureSize(atlas, 0))));
    int mark = wave_marker(atlas, texel);
    if (mark == WAVE_MARK_LEFT) return 0;
    if (mark == WAVE_MARK_BOTH) return (fract(uv.x * float(textureSize(atlas, 0).x)) > 0.5) ? 1 : 0;
    if (mark != WAVE_MARK_RIGHT) return -1;
    // Right corner: walk left along the same row to the left marker.
    for (int k = 1; k < 32; k++) {
        if (wave_marker(atlas, texel - ivec2(k, 0)) == WAVE_MARK_LEFT) return k + 1;
    }
    return -1;
}

// Vertical offset in units of the amplitude. coord is in wavelengths.
float wave_offset(float coord, float gameTime) {
    float seconds = gameTime * 1200.0;
    return sin((coord - WAVE_DIRECTION * seconds / WAVE_CYCLE_SECONDS) * TEXT_EFFECT_TAU);
}

#endif
