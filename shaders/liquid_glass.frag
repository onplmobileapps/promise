// Liquid glass, as iOS draws its selections: a clear drop of glass over
// what is behind it. The drop is a rounded rectangle whose edge curves down
// like a lens, so the backdrop bends at the rim and is drawn in from
// inside, a little magnified, with a fringe of colour where the light
// splits; a bright rim catches the light from the top left and, more
// faintly, from the bottom right.
//
// Runs as the filter of a backdrop (`ImageFilter.shader`), so the engine
// hands it the backdrop as its first sampler and that texture's size as
// its first uniform. Positions are physical pixels of the view.
//
// After the approach of liquid_glass_renderer (MIT, Tim Lehmann) and
// liquid_glass_widgets (MIT, Sebastian Degenaar); written for this app.

#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

// Set by the engine: the backdrop's size.
uniform vec2 uSize;
// The drop: left, top, right, bottom.
uniform vec4 uRect;
// Corner radius, depth of the curved rim, bend strength, colour split.
uniform vec4 uShape;
// How much the middle magnifies, rim light, ambient light, how much shows.
uniform vec4 uLight;
// A tint, its alpha how strong.
uniform vec4 uTint;
// Saturation, brightness lift, edge shade, the size of a logical pixel.
uniform vec4 uLook;
// Where the light comes from, y down: the top left at rest, swinging as
// the drop moves so its glint sweeps round the rim.
uniform vec2 uLightDir;

uniform sampler2D uBackdrop;

out vec4 fragColor;

const vec3 kLuma = vec3(0.299, 0.587, 0.114);
// Light from the top left, y down, when none is given.
const vec2 kLight = vec2(-0.5547, -0.8321);

// Until Flutter 3.46 the GLES backend kept textures bottom up.
#if defined(IMPELLER_TARGET_OPENGLES) && \
    !defined(IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED)
#define FLIP_SAMPLE_Y 1
#endif

vec4 sampleAt(vec2 px) {
  vec2 uv = clamp(px, vec2(0.5), uSize - 0.5) / uSize;
#ifdef FLIP_SAMPLE_Y
  uv.y = 1.0 - uv.y;
#endif
  return texture(uBackdrop, uv);
}

// Signed distance to a rounded rectangle with half size [b] and corner [r].
float roundedBox(vec2 p, vec2 b, float r) {
  vec2 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec4 behind = sampleAt(frag);

  vec2 centre = (uRect.xy + uRect.zw) * 0.5;
  vec2 halfSize = (uRect.zw - uRect.xy) * 0.5;
  float radius = min(uShape.x, min(halfSize.x, halfSize.y));
  float rim = max(uShape.y, 1.0);
  float px = uLook.w;

  vec2 p = frag - centre;
  float sd = roundedBox(p, halfSize, radius);
  float cover = (1.0 - smoothstep(-px, 0.0, sd)) * uLight.w;
  if (cover <= 0.001) {
    fragColor = behind;
    return;
  }

  // The outward direction across the edge, from the distance field.
  vec2 e = vec2(0.5, 0.0);
  vec2 grad = vec2(
    roundedBox(p + e.xy, halfSize, radius) - roundedBox(p - e.xy, halfSize, radius),
    roundedBox(p + e.yx, halfSize, radius) - roundedBox(p - e.yx, halfSize, radius));
  vec2 outward = length(grad) > 0.0001 ? normalize(grad) : vec2(0.0);

  // The rim curves down like a quarter circle [rim] deep: flat inside it,
  // steepest at the very edge.
  float x = clamp(-sd / rim, 0.0, 1.0);
  float edge = 1.0 - x;
  float height = sqrt(max(0.0, 1.0 - edge * edge));
  float slope = edge / max(height, 0.08);
  vec3 normal = normalize(vec3(outward * slope, 1.0));

  // Seen through the glass, the middle is magnified, and at the rim the
  // backdrop is drawn in from further inside as the light bends.
  vec2 seen = centre + p / max(uLight.x, 0.01);
  vec3 bent = refract(vec3(0.0, 0.0, -1.0), normal, 1.0 / 1.5);
  vec2 shift = bent.xy * rim * uShape.z * (1.0 - height * 0.6);
  vec3 colour;
  if (uShape.w > 0.001) {
    float split = uShape.w * edge * edge;
    colour.r = sampleAt(seen + shift * (1.0 + split)).r;
    colour.g = sampleAt(seen + shift).g;
    colour.b = sampleAt(seen + shift * (1.0 - split)).b;
  } else {
    colour = sampleAt(seen + shift).rgb;
  }

  // Glass makes what it shows a little richer and brighter.
  float luma = dot(colour, kLuma);
  colour = mix(vec3(luma), colour, uLook.x);
  colour += uLook.y;
  colour = mix(colour, uTint.rgb, uTint.a);

  // The curve of the rim gathers a little shade on the side away from the
  // light, so the drop reads even over a plain white page.
  vec2 light = length(uLightDir) > 0.001 ? normalize(uLightDir) : kLight;
  float facing = dot(outward, light);
  colour *= 1.0 - uLook.z * edge * edge * (0.75 - 0.35 * facing);

  // A thin bright rim, brightest where it faces the light, glowing again
  // at the opposite side, tinted by what is behind.
  float r = sd / (1.2 * px);
  float line = 1.0 / (1.0 + r * r);
  float lit = max(facing, 0.0);
  float kick = max(-facing, 0.0);
  float glint = lit * lit * 1.1 + kick * kick * 0.55 + uLight.z;
  vec3 shine = mix(vec3(1.0), colour / max(luma, 0.05), 0.15);
  colour += shine * line * glint * uLight.y;
  // A soft sheen inside the rim near the top.
  colour += vec3(1.0) * edge * edge * lit * 0.12 * uLight.y;

  colour = clamp(colour, 0.0, 1.0);
  fragColor = vec4(mix(behind.rgb, colour, cover), mix(behind.a, 1.0, cover));
}
