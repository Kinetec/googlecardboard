/////////////////////////////////////////////////////////////////
//
//  "Job Hunt" A Google Cardboard/Job Search Experiment
//
//  MICHAEL LOUIS RICCA, MPS
//
//  (917) 942-0281
//
//  http://linkedin.com/in/mikericca
//
//
//  Original code from Google Cardboard SDK. Based on
//  "Treasure Hunt" example. Code Assignment excercise prepared
//  for Verizon.
//
//  CC License 2016
//
/////////////////////////////////////////////////////////////////

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support. Compile with -fobjc-arc"
#endif

#define NUM_GRID_VERTICES 72
#define NUM_CUBE_VERTICES 108
#define NUM_CUBE_COLORS 144
#define NUM_GRID_COLORS 96
#define NUM_CUBE_VERTICES2 108
#define NUM_CUBE_COLORS2 144
#define NUM_CUBE_VERTICES3 108
#define NUM_CUBE_COLORS3 144
#define NUM_CUBE_VERTICES4 108
#define NUM_CUBE_COLORS4 144
#define NUM_CUBE_VERTICES5 108
#define NUM_CUBE_COLORS5 144

#import "JobHuntRenderer.h"

#import <AudioToolbox/AudioToolbox.h>
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#import "GVRAudioEngine.h"
#import "GVRHeadTransform.h"

// Vertex shader implementation.
static const char *kVertexShaderString =
    "#version 100\n"
    "\n"
    "uniform mat4 uMVP; \n"
    "uniform vec3 uPosition; \n"
    "attribute vec3 aVertex; \n"
    "attribute vec4 aColor;\n"
    "varying vec4 vColor;\n"
    "varying vec3 vGrid;  \n"
    "void main(void) { \n"
    "  vGrid = aVertex + uPosition; \n"
    "  vec4 pos = vec4(vGrid, 1.0); \n"
    "  vColor = aColor;"
    "  gl_Position = uMVP * pos; \n"
    "    \n"
    "}\n";

// Simple pass-through fragment shader.
static const char *kPassThroughFragmentShaderString =
    "#version 100\n"
    "\n"
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec4 vColor;\n"
    "\n"
    "void main(void) { \n"
    "  gl_FragColor = vColor; \n"
    "}\n";

// Fragment shader for the floorplan grid.
// Line patters are generated based on the fragment's position in 3d.
static const char* kGridFragmentShaderString =
    "#version 100\n"
    "\n"
    "#ifdef GL_ES\n"
    "precision mediump float;\n"
    "#endif\n"
    "varying vec4 vColor;\n"
    "varying vec3 vGrid;\n"
    "\n"
    "void main() {\n"
    "    float depth = gl_FragCoord.z / gl_FragCoord.w;\n"
    "    if ((mod(abs(vGrid.x), 10.0) < 0.1) ||\n"
    "        (mod(abs(vGrid.z), 10.0) < 0.1)) {\n"
    "      gl_FragColor = max(0.0, (90.0-depth) / 90.0) *\n"
    "                     vec4(1.0, 1.0, 1.0, 1.0) + \n"
    "                     min(1.0, depth / 90.0) * vColor;\n"
    "    } else {\n"
    "      gl_FragColor = vColor;\n"
    "    }\n"
    "}\n";

// Cube1 Vertices for uniform cube mesh centered at the origin.
static const float kCubeVertices[NUM_CUBE_VERTICES] = {
    // Front face
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    // Right face
    0.5f, 0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    // Back face
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    // Left face
    -0.5f, 0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    // Top face
    -0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    // Bottom face
    0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
};

// Cube2 Vertices for uniform cube mesh centered at the origin.
static const float kCubeVertices2[NUM_CUBE_VERTICES2] = {
    // Front face
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    // Right face
    0.5f, 0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    // Back face
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    // Left face
    -0.5f, 0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    // Top face
    -0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    // Bottom face
    0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
};

// Cube3 Vertices for uniform cube mesh centered at the origin.
static const float kCubeVertices3[NUM_CUBE_VERTICES2] = {
    // Front face
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    // Right face
    0.5f, 0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    // Back face
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    // Left face
    -0.5f, 0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    // Top face
    -0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    // Bottom face
    0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
};

// Cube4 Vertices for uniform cube mesh centered at the origin.
static const float kCubeVertices4[NUM_CUBE_VERTICES2] = {
    // Front face
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    // Right face
    0.5f, 0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    // Back face
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    // Left face
    -0.5f, 0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    // Top face
    -0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    // Bottom face
    0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
};

// Cube5 Vertices for uniform cube mesh centered at the origin.
static const float kCubeVertices5[NUM_CUBE_VERTICES2] = {
    // Front face
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    // Right face
    0.5f, 0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, -0.5f,
    0.5f, 0.5f, -0.5f,
    // Back face
    0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, -0.5f,
    // Left face
    -0.5f, 0.5f, -0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, 0.5f, 0.5f,
    // Top face
    -0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    -0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, 0.5f,
    0.5f, 0.5f, -0.5f,
    // Bottom face
    0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
    0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    -0.5f, -0.5f, -0.5f,
};

// Cube1 - Color of the cube's six faces.
static const float kCubeColors[NUM_CUBE_COLORS] = {
    // front, green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // right, blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // back, also green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // left, also blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // top, red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    // bottom, also red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
};

// Cube2 - Color of the cube's six faces.
static const float kCubeColors2[NUM_CUBE_COLORS2] = {
    // front, green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // right, blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // back, also green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // left, also blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // top, red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    // bottom, also red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
};

// Cube3 - Color of the cube's six faces.
static const float kCubeColors3[NUM_CUBE_COLORS3] = {
    // front, green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // right, blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // back, also green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // left, also blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // top, red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    // bottom, also red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
};

// Cube4 - Color of the cube's six faces.
static const float kCubeColors4[NUM_CUBE_COLORS4] = {
    // front, green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // right, blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // back, also green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // left, also blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // top, red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    // bottom, also red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
};

// Cube5 - Color of the cube's six faces.
static const float kCubeColors5[NUM_CUBE_COLORS5] = {
    // front, green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // right, blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // back, also green
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    0.0f, 0.5273f, 0.2656f, 1.0f,
    // left, also blue
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    0.0f, 0.3398f, 0.9023f, 1.0f,
    // top, red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    // bottom, also red
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
    0.8359375f, 0.17578125f, 0.125f, 1.0f,
};

// Cube1 - Color when looking at it: Yellow.
static const float kCubeFoundColors[NUM_CUBE_COLORS] = {
    // front, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // right, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // back, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // left, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // top, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // bottom, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
};

// Cube2 - Color when looking at it: Yellow.
static const float kCubeFoundColors2[NUM_CUBE_COLORS2] = {
    // front, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // right, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // back, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // left, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // top, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // bottom, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
};

// Cube3 - Color when looking at it: Yellow.
static const float kCubeFoundColors3[NUM_CUBE_COLORS3] = {
    // front, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // right, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // back, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // left, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // top, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // bottom, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
};

// Cube4 - Color when looking at it: Yellow.
static const float kCubeFoundColors4[NUM_CUBE_COLORS4] = {
    // front, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // right, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // back, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // left, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // top, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // bottom, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
};

// Cube5 - Color when looking at it: Yellow.
static const float kCubeFoundColors5[NUM_CUBE_COLORS5] = {
    // front, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // right, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // back, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // left, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // top, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    // bottom, yellow
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
    1.0f, 0.6523f, 0.0f, 1.0f,
};

// Cube1 - Color when sample is playing: White.
static const float kCubeOnColors[NUM_CUBE_COLORS] = {
    // front, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // right, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // back, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // left, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // top, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // bottom, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
};

// Cube2 - Color when sample is playing: White.
static const float kCubeOnColors2[NUM_CUBE_COLORS2] = {
    // front, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // right, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // back, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // left, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // top, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // bottom, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
};

// Cube3 - Color when sample is playing: White.
static const float kCubeOnColors3[NUM_CUBE_COLORS3] = {
    // front, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // right, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // back, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // left, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // top, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // bottom, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
};

// Cube4 - Color when sample is playing: White.
static const float kCubeOnColors4[NUM_CUBE_COLORS4] = {
    // front, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // right, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // back, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // left, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // top, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // bottom, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
};

// Cube5 - Color when sample is playing: White.
static const float kCubeOnColors5[NUM_CUBE_COLORS5] = {
    // front, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // right, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // back, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // left, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // top, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    // bottom, white
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
    1.0f, 1.0f, 1.0f, 1.0f,
};

// The grid lines on the floor are rendered procedurally and large polygons cause floating point
// precision problems on some architectures. So we split the floor into 4 quadrants.
static const float kGridVertices[NUM_GRID_VERTICES] = {
  // +X, +Z quadrant
  200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 200.0f,
  200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 200.0f,
  200.0f, 0.0f, 200.0f,
  // -X, +Z quadrant
  0.0f, 0.0f, 0.0f,
  -200.0f, 0.0f, 0.0f,
  -200.0f, 0.0f, 200.0f,
  0.0f, 0.0f, 0.0f,
  -200.0f, 0.0f, 200.0f,
  0.0f, 0.0f, 200.0f,
  // +X, -Z quadrant
  200.0f, 0.0f, -200.0f,
  0.0f, 0.0f, -200.0f,
  0.0f, 0.0f, 0.0f,
  200.0f, 0.0f, -200.0f,
  0.0f, 0.0f, 0.0f,
  200.0f, 0.0f, 0.0f,
  // -X, -Z quadrant
  0.0f, 0.0f, -200.0f,
  -200.0f, 0.0f, -200.0f,
  -200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, -200.0f,
  -200.0f, 0.0f, 0.0f,
  0.0f, 0.0f, 0.0f,
};

// Grid Color: Blue
static const float kGridColors[NUM_GRID_COLORS] = {
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
  0.0f, 0.3398f, 0.9023f, 1.0f,
};

// Grid size (scale).
static const float kGridSize = 1.0f;

// Samples sound File Names.
static const NSString *kSampleFilename = @"drone.wav";
static const NSString *kSampleFilename2 = @"drums.wav";
static const NSString *kSampleFilename3 = @"arp.wav";
static const NSString *kSampleFilename4 = @"arp2.wav";
static const NSString *kSampleFilename5 = @"arp3.wav";

// Cube Sizes (scale).
static const float kCubeSize = 3.0f;
static const float kCubeSize2 = 2.0f;
static const float kCubeSize3 = 3.0f;
static const float kCubeSize4 = 2.0f;
static const float kCubeSize5 = 3.0f;

// Cube focus angle threshold in radians.
static const float kFocusThresholdRadians = 0.5f;
static const float kFocusThresholdRadians2 = 0.5f;
static const float kFocusThresholdRadians3 = 0.5f;
static const float kFocusThresholdRadians4 = 0.5f;
static const float kFocusThresholdRadians5 = 0.5f;

static GLuint LoadShader(GLenum type, const char *shader_src) {
  GLint compiled = 0;

  // Create the shader object
    const GLuint shader = glCreateShader(type);
        if (shader == 0) {
            return 0;
        }
  // Load the shader source
    glShaderSource(shader, 1, &shader_src, NULL);

  // Compile the shader
    glCompileShader(shader);
  // Check the compile status
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

    if (!compiled) {
        GLint info_len = 0;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &info_len);

    if (info_len > 1) {
        char *info_log = ((char *)malloc(sizeof(char) * info_len));
        glGetShaderInfoLog(shader, info_len, NULL, info_log);
        NSLog(@"Error compiling shader:%s", info_log);
        free(info_log);
        }
    glDeleteShader(shader);
    return 0;
  }
  return shader;
}

// Checks the link status of the given program.
static bool checkProgramLinkStatus(GLuint shader_program) {
    GLint linked = 0;
    glGetProgramiv(shader_program, GL_LINK_STATUS, &linked);

    if (!linked) {
        GLint info_len = 0;
        glGetProgramiv(shader_program, GL_INFO_LOG_LENGTH, &info_len);

    if (info_len > 1) {
        char *info_log = ((char *)malloc(sizeof(char) * info_len));
        glGetProgramInfoLog(shader_program, info_len, NULL, info_log);
        NSLog(@"Error linking program: %s", info_log);
        free(info_log);
    }
    glDeleteProgram(shader_program);
    return false;
  }
  return true;
}

// Treasure Hunt Renderer
@implementation JobHuntRenderer {
    
    // GL variables for the Cube 1.
    GLfloat _cube_vertices[NUM_CUBE_VERTICES];
    GLfloat _cube_position[3];
    GLfloat _cube_colors[NUM_CUBE_COLORS];
    GLfloat _cube_found_colors[NUM_CUBE_COLORS];
    GLfloat _cube_on_colors[NUM_CUBE_COLORS];
    // GL variables for the Cube 2.
    GLfloat _cube_vertices2[NUM_CUBE_VERTICES2];
    GLfloat _cube_position2[3];
    GLfloat _cube_colors2[NUM_CUBE_COLORS2];
    GLfloat _cube_found_colors2[NUM_CUBE_COLORS2];
    GLfloat _cube_on_colors2[NUM_CUBE_COLORS2];
    // GL variables for the Cube 3.
    GLfloat _cube_vertices3[NUM_CUBE_VERTICES3];
    GLfloat _cube_position3[3];
    GLfloat _cube_colors3[NUM_CUBE_COLORS3];
    GLfloat _cube_found_colors3[NUM_CUBE_COLORS3];
    GLfloat _cube_on_colors3[NUM_CUBE_COLORS3];
    // GL variables for the Cube 4.
    GLfloat _cube_vertices4[NUM_CUBE_VERTICES4];
    GLfloat _cube_position4[3];
    GLfloat _cube_colors4[NUM_CUBE_COLORS4];
    GLfloat _cube_found_colors4[NUM_CUBE_COLORS4];
    GLfloat _cube_on_colors4[NUM_CUBE_COLORS4];
    // GL variables for the Cube 5.
    GLfloat _cube_vertices5[NUM_CUBE_VERTICES5];
    GLfloat _cube_position5[3];
    GLfloat _cube_colors5[NUM_CUBE_COLORS5];
    GLfloat _cube_found_colors5[NUM_CUBE_COLORS5];
    GLfloat _cube_on_colors5[NUM_CUBE_COLORS5];
    // GL ints for Cube 1.
    GLuint _cube_program;
    GLint _cube_vertex_attrib;
    GLint _cube_position_uniform;
    GLint _cube_mvp_matrix;
    GLuint _cube_vertex_buffer;
    GLint _cube_color_attrib;
    GLuint _cube_color_buffer;
    GLuint _cube_found_color_buffer;
    GLuint _cube_on_color_buffer;
    // GL ints for Cube 2.
    GLuint _cube_program2;
    GLint _cube_vertex_attrib2;
    GLint _cube_position_uniform2;
    GLint _cube_mvp_matrix2;
    GLuint _cube_vertex_buffer2;
    GLint _cube_color_attrib2;
    GLuint _cube_color_buffer2;
    GLuint _cube_found_color_buffer2;
    GLuint _cube_on_color_buffer2;
    // GL ints for Cube 3.
    GLuint _cube_program3;
    GLint _cube_vertex_attrib3;
    GLint _cube_position_uniform3;
    GLint _cube_mvp_matrix3;
    GLuint _cube_vertex_buffer3;
    GLint _cube_color_attrib3;
    GLuint _cube_color_buffer3;
    GLuint _cube_found_color_buffer3;
    GLuint _cube_on_color_buffer3;
    // GL ints for Cube 4.
    GLuint _cube_program4;
    GLint _cube_vertex_attrib4;
    GLint _cube_position_uniform4;
    GLint _cube_mvp_matrix4;
    GLuint _cube_vertex_buffer4;
    GLint _cube_color_attrib4;
    GLuint _cube_color_buffer4;
    GLuint _cube_found_color_buffer4;
    GLuint _cube_on_color_buffer4;
    // GL ints for Cube 5.
    GLuint _cube_program5;
    GLint _cube_vertex_attrib5;
    GLint _cube_position_uniform5;
    GLint _cube_mvp_matrix5;
    GLuint _cube_vertex_buffer5;
    GLint _cube_color_attrib5;
    GLuint _cube_color_buffer5;
    GLuint _cube_found_color_buffer5;
    GLuint _cube_on_color_buffer5;
    // GL variables for the Grid.
    GLfloat _grid_vertices[NUM_GRID_VERTICES];
    GLfloat _grid_colors[NUM_GRID_COLORS];
    GLfloat _grid_position[3];
    // GL ints for the Grid.
    GLuint _grid_program;
    GLint _grid_vertex_attrib;
    GLint _grid_color_attrib;
    GLint _grid_position_uniform;
    GLint _grid_mvp_matrix;
    GLuint _grid_vertex_buffer;
    GLuint _grid_color_buffer;
    // Audio Engine, Sound Objects, and States.
    GVRAudioEngine *_gvr_audio_engine;
    int _sound_object_id;
    int _sound_object_id2;
    int _sound_object_id3;
    int _sound_object_id4;
    int _sound_object_id5;
    bool _is_cube_focused;
    bool _is_cube_focused2;
    bool _is_cube_focused3;
    bool _is_cube_focused4;
    bool _is_cube_focused5;
    bool _is_cube_on;
    bool _is_cube_on2;
    bool _is_cube_on3;
    bool _is_cube_on4;
    bool _is_cube_on5;
}

#pragma mark - GVRCardboardViewDelegate overrides

- (void)cardboardView:(GVRCardboardView *)cardboardView
     willStartDrawing:(GVRHeadTransform *)headTransform {
  // Renderer must be created on GL thread before any call to drawFrame.
  // Load the vertex/fragment shaders.
    const GLuint vertex_shader = LoadShader(GL_VERTEX_SHADER, kVertexShaderString);
    NSAssert(vertex_shader != 0, @"Failed to load vertex shader");
    
    const GLuint fragment_shader = LoadShader(GL_FRAGMENT_SHADER, kPassThroughFragmentShaderString);
    NSAssert(fragment_shader != 0, @"Failed to load fragment shader");
    
    const GLuint grid_fragment_shader = LoadShader(GL_FRAGMENT_SHADER, kGridFragmentShaderString);
    NSAssert(grid_fragment_shader != 0, @"Failed to load grid fragment shader");
    
    
  /////// Create the program object for the cube.
    _cube_program = glCreateProgram();
    NSAssert(_cube_program != 0, @"Failed to create program");
    glAttachShader(_cube_program, vertex_shader);
    glAttachShader(_cube_program, fragment_shader);
    
    _cube_program2 = glCreateProgram();
    NSAssert(_cube_program2 != 0, @"Failed to create program");
    glAttachShader(_cube_program2, vertex_shader);
    glAttachShader(_cube_program2, fragment_shader);

    _cube_program3 = glCreateProgram();
    NSAssert(_cube_program3 != 0, @"Failed to create program");
    glAttachShader(_cube_program3, vertex_shader);
    glAttachShader(_cube_program3, fragment_shader);
    
    _cube_program4 = glCreateProgram();
    NSAssert(_cube_program4 != 0, @"Failed to create program");
    glAttachShader(_cube_program4, vertex_shader);
    glAttachShader(_cube_program4, fragment_shader);
    
    _cube_program5 = glCreateProgram();
    NSAssert(_cube_program5 != 0, @"Failed to create program");
    glAttachShader(_cube_program5, vertex_shader);
    glAttachShader(_cube_program5, fragment_shader);
    
  // Link the shader program.
    glLinkProgram(_cube_program);
    NSAssert(checkProgramLinkStatus(_cube_program), @"Failed to link _cube_program");
    
    glLinkProgram(_cube_program2);
    NSAssert(checkProgramLinkStatus(_cube_program2), @"Failed to link _cube_program2");
    
    glLinkProgram(_cube_program3);
    NSAssert(checkProgramLinkStatus(_cube_program3), @"Failed to link _cube_program3");

    glLinkProgram(_cube_program4);
    NSAssert(checkProgramLinkStatus(_cube_program4), @"Failed to link _cube_program4");

    glLinkProgram(_cube_program5);
    NSAssert(checkProgramLinkStatus(_cube_program5), @"Failed to link _cube_program5");
    
  // Get the location of our attributes so we can bind data to them later.
    _cube_vertex_attrib = glGetAttribLocation(_cube_program, "aVertex");
    NSAssert(_cube_vertex_attrib != -1, @"glGetAttribLocation failed for aVertex");
    _cube_color_attrib = glGetAttribLocation(_cube_program, "aColor");
    NSAssert(_cube_color_attrib != -1, @"glGetAttribLocation failed for aColor");
    
    _cube_vertex_attrib2 = glGetAttribLocation(_cube_program2, "aVertex");
    NSAssert(_cube_vertex_attrib2 != -1, @"glGetAttribLocation failed for aVertex");
    _cube_color_attrib2 = glGetAttribLocation(_cube_program2, "aColor");
    NSAssert(_cube_color_attrib2 != -1, @"glGetAttribLocation failed for aColor");
    
    _cube_vertex_attrib3 = glGetAttribLocation(_cube_program3, "aVertex");
    NSAssert(_cube_vertex_attrib3 != -1, @"glGetAttribLocation failed for aVertex");
    _cube_color_attrib3 = glGetAttribLocation(_cube_program3, "aColor");
    NSAssert(_cube_color_attrib3 != -1, @"glGetAttribLocation failed for aColor");
    
    _cube_vertex_attrib4 = glGetAttribLocation(_cube_program4, "aVertex");
    NSAssert(_cube_vertex_attrib4 != -1, @"glGetAttribLocation failed for aVertex");
    _cube_color_attrib4 = glGetAttribLocation(_cube_program4, "aColor");
    NSAssert(_cube_color_attrib4 != -1, @"glGetAttribLocation failed for aColor");
    
    _cube_vertex_attrib5 = glGetAttribLocation(_cube_program5, "aVertex");
    NSAssert(_cube_vertex_attrib5 != -1, @"glGetAttribLocation failed for aVertex");
    _cube_color_attrib5 = glGetAttribLocation(_cube_program5, "aColor");
    NSAssert(_cube_color_attrib5 != -1, @"glGetAttribLocation failed for aColor");
    

  // After linking, fetch references to the uniforms in our shader.
    _cube_mvp_matrix = glGetUniformLocation(_cube_program, "uMVP");
    _cube_position_uniform = glGetUniformLocation(_cube_program, "uPosition");
    NSAssert(_cube_mvp_matrix != -1 && _cube_position_uniform != -1,
             @"Error fetching uniform values for shader.");
    
    _cube_mvp_matrix2 = glGetUniformLocation(_cube_program2, "uMVP");
    _cube_position_uniform2 = glGetUniformLocation(_cube_program2, "uPosition");
    NSAssert(_cube_mvp_matrix2 != -1 && _cube_position_uniform2 != -1,
             @"Error fetching uniform values for shader.");
    
    _cube_mvp_matrix3 = glGetUniformLocation(_cube_program3, "uMVP");
    _cube_position_uniform3 = glGetUniformLocation(_cube_program3, "uPosition");
    NSAssert(_cube_mvp_matrix3 != -1 && _cube_position_uniform3 != -1,
             @"Error fetching uniform values for shader.");
    
    _cube_mvp_matrix4 = glGetUniformLocation(_cube_program4, "uMVP");
    _cube_position_uniform4 = glGetUniformLocation(_cube_program4, "uPosition");
    NSAssert(_cube_mvp_matrix4 != -1 && _cube_position_uniform4 != -1,
             @"Error fetching uniform values for shader.");
    
    _cube_mvp_matrix5 = glGetUniformLocation(_cube_program5, "uMVP");
    _cube_position_uniform5 = glGetUniformLocation(_cube_program5, "uPosition");
    NSAssert(_cube_mvp_matrix5 != -1 && _cube_position_uniform5 != -1,
             @"Error fetching uniform values for shader.");

    
  // Initialize the vertex data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_VERTICES; ++i) {
        _cube_vertices[i] = (GLfloat)(kCubeVertices[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_vertex_buffer);
    NSAssert(_cube_vertex_buffer != 0, @"glGenBuffers failed for vertex buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_vertices), _cube_vertices, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_VERTICES2; ++i) {
        _cube_vertices2[i] = (GLfloat)(kCubeVertices2[i] * kCubeSize2);
    }
    glGenBuffers(1, &_cube_vertex_buffer2);
    NSAssert(_cube_vertex_buffer2 != 0, @"glGenBuffers failed for vertex buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_vertices2), _cube_vertices2, GL_STATIC_DRAW);
    
    
    for (int i = 0; i < NUM_CUBE_VERTICES3; ++i) {
        _cube_vertices3[i] = (GLfloat)(kCubeVertices3[i] * kCubeSize3);
    }
    glGenBuffers(1, &_cube_vertex_buffer3);
    NSAssert(_cube_vertex_buffer3 != 0, @"glGenBuffers failed for vertex buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer3);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_vertices3), _cube_vertices3, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_VERTICES4; ++i) {
        _cube_vertices4[i] = (GLfloat)(kCubeVertices4[i] * kCubeSize4);
    }
    glGenBuffers(1, &_cube_vertex_buffer4);
    NSAssert(_cube_vertex_buffer4 != 0, @"glGenBuffers failed for vertex buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer4);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_vertices4), _cube_vertices4, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_VERTICES5; ++i) {
        _cube_vertices5[i] = (GLfloat)(kCubeVertices5[i] * kCubeSize5);
    }
    glGenBuffers(1, &_cube_vertex_buffer5);
    NSAssert(_cube_vertex_buffer5 != 0, @"glGenBuffers failed for vertex buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer5);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_vertices5), _cube_vertices5, GL_STATIC_DRAW);

    
  // Initialize the color data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
        _cube_colors[i] = (GLfloat)(kCubeColors[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_color_buffer);
    NSAssert(_cube_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_colors), _cube_colors, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS2; ++i) {
        _cube_colors2[i] = (GLfloat)(kCubeColors2[i] * kCubeSize2);
    }
    glGenBuffers(1, &_cube_color_buffer2);
    NSAssert(_cube_color_buffer2 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_colors2), _cube_colors2, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS3; ++i) {
        _cube_colors3[i] = (GLfloat)(kCubeColors3[i] * kCubeSize3);
    }
    glGenBuffers(1, &_cube_color_buffer3);
    NSAssert(_cube_color_buffer3 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer3);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_colors3), _cube_colors3, GL_STATIC_DRAW);

    for (int i = 0; i < NUM_CUBE_COLORS4; ++i) {
        _cube_colors4[i] = (GLfloat)(kCubeColors4[i] * kCubeSize4);
    }
    glGenBuffers(1, &_cube_color_buffer4);
    NSAssert(_cube_color_buffer4 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer4);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_colors4), _cube_colors4, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS5; ++i) {
        _cube_colors5[i] = (GLfloat)(kCubeColors5[i] * kCubeSize5);
    }
    glGenBuffers(1, &_cube_color_buffer5);
    NSAssert(_cube_color_buffer5 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer5);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_colors5), _cube_colors5, GL_STATIC_DRAW);
    
    
  // Initialize the found color data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
        _cube_found_colors[i] = (GLfloat)(kCubeFoundColors[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_found_color_buffer);
    NSAssert(_cube_found_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_found_colors), _cube_found_colors, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS2; ++i) {
        _cube_found_colors2[i] = (GLfloat)(kCubeFoundColors2[i] * kCubeSize2);
    }
    glGenBuffers(1, &_cube_found_color_buffer2);
    NSAssert(_cube_found_color_buffer2 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_found_colors2), _cube_found_colors2, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS3; ++i) {
        _cube_found_colors3[i] = (GLfloat)(kCubeFoundColors3[i] * kCubeSize3);
    }
    glGenBuffers(1, &_cube_found_color_buffer3);
    NSAssert(_cube_found_color_buffer3 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer3);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_found_colors3), _cube_found_colors3, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS4; ++i) {
        _cube_found_colors4[i] = (GLfloat)(kCubeFoundColors4[i] * kCubeSize4);
    }
    glGenBuffers(1, &_cube_found_color_buffer4);
    NSAssert(_cube_found_color_buffer4 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer4);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_found_colors4), _cube_found_colors4, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS5; ++i) {
        _cube_found_colors5[i] = (GLfloat)(kCubeFoundColors5[i] * kCubeSize5);
    }
    glGenBuffers(1, &_cube_found_color_buffer5);
    NSAssert(_cube_found_color_buffer5 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer5);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_found_colors5), _cube_found_colors5, GL_STATIC_DRAW);
    
    
  // Initialize the on color data for the cube mesh.
    for (int i = 0; i < NUM_CUBE_COLORS; ++i) {
        _cube_on_colors[i] = (GLfloat)(kCubeOnColors[i] * kCubeSize);
    }
    glGenBuffers(1, &_cube_on_color_buffer);
    NSAssert(_cube_on_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_on_colors), _cube_on_colors, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS2; ++i) {
        _cube_on_colors2[i] = (GLfloat)(kCubeOnColors2[i] * kCubeSize2);
    }
    glGenBuffers(1, &_cube_on_color_buffer2);
    NSAssert(_cube_on_color_buffer2 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer2);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_on_colors2), _cube_on_colors2, GL_STATIC_DRAW);

    for (int i = 0; i < NUM_CUBE_COLORS3; ++i) {
        _cube_on_colors3[i] = (GLfloat)(kCubeOnColors3[i] * kCubeSize3);
    }
    glGenBuffers(1, &_cube_on_color_buffer3);
    NSAssert(_cube_on_color_buffer3 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer3);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_on_colors3), _cube_on_colors3, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS4; ++i) {
        _cube_on_colors4[i] = (GLfloat)(kCubeOnColors4[i] * kCubeSize4);
    }
    glGenBuffers(1, &_cube_on_color_buffer4);
    NSAssert(_cube_on_color_buffer4 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer4);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_on_colors4), _cube_on_colors4, GL_STATIC_DRAW);
    
    for (int i = 0; i < NUM_CUBE_COLORS5; ++i) {
        _cube_on_colors5[i] = (GLfloat)(kCubeOnColors5[i] * kCubeSize5);
    }
    glGenBuffers(1, &_cube_on_color_buffer5);
    NSAssert(_cube_on_color_buffer5 != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer5);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_cube_on_colors5), _cube_on_colors5, GL_STATIC_DRAW);


  /////// Create the program object for the grid.
    _grid_program = glCreateProgram();
    NSAssert(_grid_program != 0, @"Failed to create program");
    glAttachShader(_grid_program, vertex_shader);
    glAttachShader(_grid_program, grid_fragment_shader);
    glLinkProgram(_grid_program);
    NSAssert(checkProgramLinkStatus(_grid_program), @"Failed to link _grid_program");

  // Get the location of our attributes so we can bind data to them later.
    _grid_vertex_attrib = glGetAttribLocation(_grid_program, "aVertex");
    NSAssert(_grid_vertex_attrib != -1, @"glGetAttribLocation failed for aVertex");
    _grid_color_attrib = glGetAttribLocation(_grid_program, "aColor");
    NSAssert(_grid_color_attrib != -1, @"glGetAttribLocation failed for aColor");

  // After linking, fetch references to the uniforms in our shader.
    _grid_mvp_matrix = glGetUniformLocation(_grid_program, "uMVP");
    _grid_position_uniform = glGetUniformLocation(_grid_program, "uPosition");
    NSAssert(_grid_mvp_matrix != -1 && _grid_position_uniform != -1,
           @"Error fetching uniform values for shader.");

  // Position grid below the camera.
    _grid_position[0] = 0;
    _grid_position[1] = -20.0f;
    _grid_position[2] = 0;

    for (int i = 0; i < NUM_GRID_VERTICES; ++i) {
    _grid_vertices[i] = (GLfloat)(kGridVertices[i] * kCubeSize);
    }
    glGenBuffers(1, &_grid_vertex_buffer);
    NSAssert(_grid_vertex_buffer != 0, @"glGenBuffers failed for vertex buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _grid_vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_grid_vertices), _grid_vertices, GL_STATIC_DRAW);

  // Initialize the color data for the grid mesh.
    for (int i = 0; i < NUM_GRID_COLORS; ++i) {
    _grid_colors[i] = (GLfloat)(kGridColors[i] * kGridSize);
    }
    glGenBuffers(1, &_grid_color_buffer);
    NSAssert(_grid_color_buffer != 0, @"glGenBuffers failed for color buffer");
    glBindBuffer(GL_ARRAY_BUFFER, _grid_color_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(_grid_colors), _grid_colors, GL_STATIC_DRAW);

  // Set Distance, Azimuth, Elevation Values.
    const float distance = -24.0f;
    const float azimuth = 0.0f;
    const float elevation = 0.5f;
    
    const float distance2 = 10.0f;
    const float azimuth2 = 24.0;
    const float elevation2 = 0.5f;
    
    const float distance3 = 18.0f;
    const float azimuth3 = -48.0f;
    const float elevation3 = 0.5f;
    
    const float distance4 = -10.0f;
    const float azimuth4 = 36.0;
    const float elevation4 = 0.5f;
    
    const float distance5 = 20.0f;
    const float azimuth5 = -24.0;
    const float elevation5 = 0.5f;
  
  // Calculate and Set Cube Positions
    _cube_position[0] = -cos(elevation) * sin(azimuth) * distance;
    _cube_position[1] = sin(elevation) * distance;
    _cube_position[2] = -cos(elevation) * cos(azimuth) * distance;
    
    const float cube_x = _cube_position[0];
    const float cube_y = _cube_position[1];
    const float cube_z = _cube_position[2];
    
    _cube_position2[0] = -cos(elevation2) * sin(azimuth2) * distance2;
    _cube_position2[1] = sin(elevation2) * distance2;
    _cube_position2[2] = -cos(elevation2) * cos(azimuth2) * distance2;
 
    const float cube2_x = _cube_position2[0];
    const float cube2_y = _cube_position2[1];
    const float cube2_z = _cube_position2[2];
    
    _cube_position3[0] = -cos(elevation3) * sin(azimuth3) * distance3;
    _cube_position3[1] = sin(elevation3) * distance3;
    _cube_position3[2] = -cos(elevation3) * cos(azimuth3) * distance3;
    
    const float cube3_x = _cube_position3[0];
    const float cube3_y = _cube_position3[1];
    const float cube3_z = _cube_position3[2];
    
    _cube_position4[0] = -cos(elevation4) * sin(azimuth4) * distance4;
    _cube_position4[1] = sin(elevation4) * distance4;
    _cube_position4[2] = -cos(elevation4) * cos(azimuth4) * distance4;
    
    const float cube4_x = _cube_position4[0];
    const float cube4_y = _cube_position4[1];
    const float cube4_z = _cube_position4[2];
    
    _cube_position5[0] = -cos(elevation5) * sin(azimuth5) * distance5;
    _cube_position5[1] = sin(elevation5) * distance5;
    _cube_position5[2] = -cos(elevation5) * cos(azimuth5) * distance5;
    
    const float cube5_x = _cube_position5[0];
    const float cube5_y = _cube_position5[1];
    const float cube5_z = _cube_position5[2];

  // Audio Engine Setup
    _gvr_audio_engine =
    [[GVRAudioEngine alloc] initWithRenderingMode:kRenderingModeBinauralHighQuality];
    // Enable Room Reverb
    [_gvr_audio_engine preloadSoundFile:kSampleFilename];
    [_gvr_audio_engine preloadSoundFile:kSampleFilename2];
    [_gvr_audio_engine preloadSoundFile:kSampleFilename3];
    [_gvr_audio_engine preloadSoundFile:kSampleFilename4];
    [_gvr_audio_engine preloadSoundFile:kSampleFilename5];
    [_gvr_audio_engine start];
    // Cube 1
    _sound_object_id = [_gvr_audio_engine createSoundObject:kSampleFilename];
    [_gvr_audio_engine setSoundVolume:_sound_object_id volume:0.75f];
    [_gvr_audio_engine setSoundObjectPosition:_sound_object_id x:cube_x y:cube_y z:cube_z];
    // Cube 2
    _sound_object_id2 = [_gvr_audio_engine createSoundObject:kSampleFilename2];
    [_gvr_audio_engine setSoundVolume:_sound_object_id2 volume:0.75f];
    [_gvr_audio_engine setSoundObjectPosition:_sound_object_id2 x:cube2_x y:cube2_y z:cube2_z];
    // Cube 3
    _sound_object_id3 = [_gvr_audio_engine createSoundObject:kSampleFilename3];
    [_gvr_audio_engine setSoundVolume:_sound_object_id3 volume:1.0f];
    [_gvr_audio_engine setSoundObjectPosition:_sound_object_id3 x:cube3_x y:cube3_y z:cube3_z];
    // Cube 4
    _sound_object_id4 = [_gvr_audio_engine createSoundObject:kSampleFilename4];
    [_gvr_audio_engine setSoundVolume:_sound_object_id4 volume:0.75f];
    [_gvr_audio_engine setSoundObjectPosition:_sound_object_id4 x:cube4_x y:cube4_y z:cube4_z];
    // Cube 5
    _sound_object_id5 = [_gvr_audio_engine createSoundObject:kSampleFilename5];
    [_gvr_audio_engine setSoundVolume:_sound_object_id5 volume:1.2f];
    [_gvr_audio_engine setSoundObjectPosition:_sound_object_id5 x:cube5_x y:cube5_y z:cube5_z];
}


- (void)cardboardView:(GVRCardboardView *)cardboardView
     prepareDrawFrame:(GVRHeadTransform *)headTransform {
    
  // Update audio listener's head rotation.
    const GLKQuaternion head_rotation =
    GLKQuaternionMakeWithMatrix4(GLKMatrix4Transpose([headTransform headPoseInStartSpace]));
    [_gvr_audio_engine setHeadRotation:head_rotation.q[0]
                                   y:head_rotation.q[1]
                                   z:head_rotation.q[2]
                                   w:head_rotation.q[3]];
  // Update the audio engine.
    [_gvr_audio_engine update];
    
  // Check if the cubes are focused.
    // Cube1
    GLKVector3 source_cube_position =
    GLKVector3Make(_cube_position[0], _cube_position[1], _cube_position[2]);
    _is_cube_focused = [self isLookingAtObject:&head_rotation sourcePosition:&source_cube_position];
    // Cube2
    GLKVector3 source_cube_position2 =
    GLKVector3Make(_cube_position2[0], _cube_position2[1], _cube_position2[2]);
    _is_cube_focused2 = [self isLookingAtObject:&head_rotation sourcePosition:&source_cube_position2];
    // Cube3
    GLKVector3 source_cube_position3 =
    GLKVector3Make(_cube_position3[0], _cube_position3[1], _cube_position3[2]);
    _is_cube_focused3 = [self isLookingAtObject:&head_rotation sourcePosition:&source_cube_position3];
    // Cube4
    GLKVector3 source_cube_position4 =
    GLKVector3Make(_cube_position4[0], _cube_position4[1], _cube_position4[2]);
    _is_cube_focused4 = [self isLookingAtObject:&head_rotation sourcePosition:&source_cube_position4];
    // Cube5
    GLKVector3 source_cube_position5 =
    GLKVector3Make(_cube_position5[0], _cube_position5[1], _cube_position5[2]);
    _is_cube_focused5 = [self isLookingAtObject:&head_rotation sourcePosition:&source_cube_position5];
    
  // Clear GL viewport.
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glEnable(GL_DEPTH_TEST);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_SCISSOR_TEST);
}

- (void)cardboardView:(GVRCardboardView *)cardboardView
              drawEye:(GVREye)eye
    withHeadTransform:(GVRHeadTransform *)headTransform {
    CGRect viewport = [headTransform viewportForEye:eye];
    glViewport(viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height);
    glScissor(viewport.origin.x, viewport.origin.y, viewport.size.width, viewport.size.height);

  // Get the head matrix.
    const GLKMatrix4 head_from_start_matrix = [headTransform headPoseInStartSpace];

  // Get this eye's matrices.
    GLKMatrix4 projection_matrix = [headTransform projectionMatrixForEye:eye near:0.1f far:100.0f];
    GLKMatrix4 eye_from_head_matrix = [headTransform eyeFromHeadMatrix:eye];

  // Compute the model view projection matrix.
    GLKMatrix4 model_view_projection_matrix = GLKMatrix4Multiply(
    projection_matrix, GLKMatrix4Multiply(eye_from_head_matrix, head_from_start_matrix));

  // Render from this eye.
    [self renderWithModelViewProjectionMatrix:model_view_projection_matrix.m];
}

- (void)renderWithModelViewProjectionMatrix:(const float *)model_view_matrix {
   
  // Cube 1
    // Select our shader.
    glUseProgram(_cube_program);
    // Set the uniform values that will be used by our shader.
    glUniform3fv(_cube_position_uniform, 1, _cube_position);
    // Set the uniform matrix values that will be used by our shader.
    glUniformMatrix4fv(_cube_mvp_matrix, 1, false, model_view_matrix);
    // Set the cube colors.
    if (_is_cube_focused) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer);
    }
    else if (_is_cube_on) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer);
    }
    glVertexAttribPointer(_cube_color_attrib, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
    glEnableVertexAttribArray(_cube_color_attrib);
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer);
    glVertexAttribPointer(_cube_vertex_attrib, 3, GL_FLOAT, GL_FALSE,
                          sizeof(float) * 3, 0);
    glEnableVertexAttribArray(_cube_vertex_attrib);
    glDrawArrays(GL_TRIANGLES, 0, NUM_CUBE_VERTICES / 3);
    glDisableVertexAttribArray(_cube_vertex_attrib);
    
  // Cube2
    // Select our shader.
    glUseProgram(_cube_program2);
    // Set the uniform values that will be used by our shader.
    glUniform3fv(_cube_position_uniform2, 1, _cube_position2);
    // Set the uniform matrix values that will be used by our shader.
    glUniformMatrix4fv(_cube_mvp_matrix2, 1, false, model_view_matrix);
    // Set the cube 2colors.
    if (_is_cube_focused2) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer2);
    }
    else if (_is_cube_on2) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer2);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer2);
    }
    glVertexAttribPointer(_cube_color_attrib2, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
    glEnableVertexAttribArray(_cube_color_attrib2);
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer2);
    glVertexAttribPointer(_cube_vertex_attrib2, 3, GL_FLOAT, GL_FALSE,
                          sizeof(float) * 3, 0);
    glEnableVertexAttribArray(_cube_vertex_attrib2);
    glDrawArrays(GL_TRIANGLES, 0, NUM_CUBE_VERTICES / 3);
    glDisableVertexAttribArray(_cube_vertex_attrib2);
   
  // Cube3
    // Select our shader.
    glUseProgram(_cube_program3);
    // Set the uniform values that will be used by our shader.
    glUniform3fv(_cube_position_uniform3, 1, _cube_position3);
    // Set the uniform matrix values that will be used by our shader.
    glUniformMatrix4fv(_cube_mvp_matrix3, 1, false, model_view_matrix);
    // Set the cube 3colors.
    if (_is_cube_focused3) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer3);
    }
    else if (_is_cube_on3) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer3);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer3);
    }
    glVertexAttribPointer(_cube_color_attrib3, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
    glEnableVertexAttribArray(_cube_color_attrib3);
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer3);
    glVertexAttribPointer(_cube_vertex_attrib3, 3, GL_FLOAT, GL_FALSE,
                          sizeof(float) * 3, 0);
    glEnableVertexAttribArray(_cube_vertex_attrib3);
    glDrawArrays(GL_TRIANGLES, 0, NUM_CUBE_VERTICES / 3);
    glDisableVertexAttribArray(_cube_vertex_attrib3);
    
  // Cube4
    // Select our shader.
    glUseProgram(_cube_program4);
    // Set the uniform values that will be used by our shader.
    glUniform3fv(_cube_position_uniform4, 1, _cube_position4);
    // Set the uniform matrix values that will be used by our shader.
    glUniformMatrix4fv(_cube_mvp_matrix4, 1, false, model_view_matrix);
    // Set the cube 3colors.
    if (_is_cube_focused4) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer4);
    }
    else if (_is_cube_on4) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer4);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer4);
    }
    glVertexAttribPointer(_cube_color_attrib4, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
    glEnableVertexAttribArray(_cube_color_attrib4);
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer4);
    glVertexAttribPointer(_cube_vertex_attrib4, 3, GL_FLOAT, GL_FALSE,
                          sizeof(float) * 3, 0);
    glEnableVertexAttribArray(_cube_vertex_attrib4);
    glDrawArrays(GL_TRIANGLES, 0, NUM_CUBE_VERTICES / 3);
    glDisableVertexAttribArray(_cube_vertex_attrib4);

    // Cube5
    // Select our shader.
    glUseProgram(_cube_program5);
    // Set the uniform values that will be used by our shader.
    glUniform3fv(_cube_position_uniform5, 1, _cube_position5);
    // Set the uniform matrix values that will be used by our shader.
    glUniformMatrix4fv(_cube_mvp_matrix5, 1, false, model_view_matrix);
    // Set the cube 3colors.
    if (_is_cube_focused5) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_found_color_buffer5);
    }
    else if (_is_cube_on5) {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_on_color_buffer5);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, _cube_color_buffer5);
    }
    glVertexAttribPointer(_cube_color_attrib5, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
    glEnableVertexAttribArray(_cube_color_attrib5);
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, _cube_vertex_buffer5);
    glVertexAttribPointer(_cube_vertex_attrib5, 3, GL_FLOAT, GL_FALSE,
                          sizeof(float) * 3, 0);
    glEnableVertexAttribArray(_cube_vertex_attrib5);
    glDrawArrays(GL_TRIANGLES, 0, NUM_CUBE_VERTICES / 3);
    glDisableVertexAttribArray(_cube_vertex_attrib5);

    
  // Grid
    // Select our shader.
    glUseProgram(_grid_program);
    // Set the uniform values that will be used by our shader.
    glUniform3fv(_grid_position_uniform, 1, _grid_position);
    // Set the uniform matrix values that will be used by our shader.
    glUniformMatrix4fv(_grid_mvp_matrix, 1, false, model_view_matrix);
    // Set the grid colors.
    glBindBuffer(GL_ARRAY_BUFFER, _grid_color_buffer);
    glVertexAttribPointer(_grid_color_attrib, 4, GL_FLOAT, GL_FALSE, sizeof(float) * 4, 0);
    glEnableVertexAttribArray(_grid_color_attrib);
    // Draw our polygons.
    glBindBuffer(GL_ARRAY_BUFFER, _grid_vertex_buffer);
    glVertexAttribPointer(_grid_vertex_attrib, 3, GL_FLOAT, GL_FALSE,
                        sizeof(float) * 3, 0);
    glEnableVertexAttribArray(_grid_vertex_attrib);
    glDrawArrays(GL_TRIANGLES, 0, NUM_GRID_VERTICES / 3);
    glDisableVertexAttribArray(_grid_vertex_attrib);
}

- (void)cardboardView:(GVRCardboardView *)cardboardView
         didFireEvent:(GVRUserEvent)event {
   switch (event) {
       case kGVRUserEventBackButton:
           NSLog(@"User pressed back button");
           break;
       case kGVRUserEventTilt:
           NSLog(@"User performed tilt action");
           break;
       case kGVRUserEventTrigger:
           NSLog(@"User performed trigger action");
           // Checks Playback State: Triggers Cube1 Sample OR Turns Cube1 Off
           if ([_gvr_audio_engine isSoundPlaying:_sound_object_id]) {
               if (_is_cube_focused) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Stop Cube 1 Sample
                   [_gvr_audio_engine stopSound:_sound_object_id];
                   // Stops Room DSP for ALL Samples
                   [_gvr_audio_engine enableRoom:0];
                   [_gvr_audio_engine update];
                   _is_cube_on = NULL;
               }
           } else {
               if (_is_cube_focused) {
              // Vibrate the device on success.
              AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
              // Play Cube 1 Sample
              [_gvr_audio_engine playSound:_sound_object_id loopingEnabled:true];
              // Enable Room DSP
              [_gvr_audio_engine enableRoom:1];
              // Set Room DSP Material Properties
              [_gvr_audio_engine setRoomProperties:10.0f size_y:20.0f size_z:15.0f wall_material:kBrickBare ceiling_material:kAcousticCeilingTiles floor_material:kMarble];
              [_gvr_audio_engine update];
              _is_cube_on = 1;
               }}
           // Checks Playback State: Triggers Cube2 Sample OR Turns Cube1 Off
           if ([_gvr_audio_engine isSoundPlaying:_sound_object_id2]) {
               if (_is_cube_focused2) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Stop Cube 1 Sample
                   [_gvr_audio_engine stopSound:_sound_object_id2];
                   [_gvr_audio_engine update];
                   _is_cube_on2 = NULL;
               }
           } else {
               if (_is_cube_focused2) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Play Cube Sample
                   [_gvr_audio_engine playSound:_sound_object_id2 loopingEnabled:true];
                   [_gvr_audio_engine update];
                   _is_cube_on2 = 1;
               }}
           // Checks Playback State: Triggers Cube3 Sample OR Turns Cube1 Off
           if ([_gvr_audio_engine isSoundPlaying:_sound_object_id3]) {
               if (_is_cube_focused3) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Stop Cube 1 Sample
                   [_gvr_audio_engine stopSound:_sound_object_id3];
                   [_gvr_audio_engine update];
                   _is_cube_on3 = NULL;
               }
           } else {
               if (_is_cube_focused3) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Play Cube Sample
                   [_gvr_audio_engine playSound:_sound_object_id3 loopingEnabled:true];
                   [_gvr_audio_engine update];
                   _is_cube_on3 = 1;
               }}
           // Checks Playback State: Triggers Cube4 Sample OR Turns Cube1 Off
           if ([_gvr_audio_engine isSoundPlaying:_sound_object_id4]) {
               if (_is_cube_focused4) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Stop Cube 1 Sample
                   [_gvr_audio_engine stopSound:_sound_object_id4];
                   [_gvr_audio_engine update];
                   _is_cube_on4 = NULL;
               }
           } else {
               if (_is_cube_focused4) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Play Cube Sample
                   [_gvr_audio_engine playSound:_sound_object_id4 loopingEnabled:true];
                   [_gvr_audio_engine update];
                   _is_cube_on4 = 1;
               }}
           // Checks Playback State: Triggers Cube5 Sample OR Turns Cube5 Off
           if ([_gvr_audio_engine isSoundPlaying:_sound_object_id5]) {
               if (_is_cube_focused5) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Stop Cube 5 Sample
                   [_gvr_audio_engine stopSound:_sound_object_id5];
                   [_gvr_audio_engine update];
                   _is_cube_on5 = NULL;
               }
           } else {
               if (_is_cube_focused5) {
                   // Vibrate the device on success.
                   AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                   // Play Cube 5 Sample
                   [_gvr_audio_engine playSound:_sound_object_id5 loopingEnabled:true];
                   [_gvr_audio_engine update];
                   _is_cube_on5 = 1;
               }}
          break;
      }
  }

- (void)cardboardView:(GVRCardboardView *)cardboardView shouldPauseDrawing:(BOOL)pause {
  if ([self.delegate respondsToSelector:@selector(shouldPauseRenderLoop:)]) {
    [self.delegate shouldPauseRenderLoop:pause];
  }
}

- (bool)isLookingAtObject:(const GLKQuaternion *)head_rotation
           sourcePosition:(GLKVector3 *)position {
    GLKVector3 source_direction = GLKQuaternionRotateVector3(
                                                             GLKQuaternionInvert(*head_rotation), *position);
    return ABS(source_direction.v[0]) < kFocusThresholdRadians &&
    ABS(source_direction.v[1]) < kFocusThresholdRadians;
}

- (bool)isLookingAtObject2:(const GLKQuaternion *)head_rotation
           sourcePosition:(GLKVector3 *)position {
    GLKVector3 source_direction = GLKQuaternionRotateVector3(
                                                             GLKQuaternionInvert(*head_rotation), *position);
    return ABS(source_direction.v[0]) < kFocusThresholdRadians2 &&
    ABS(source_direction.v[1]) < kFocusThresholdRadians2;
}

- (bool)isLookingAtObject3:(const GLKQuaternion *)head_rotation
            sourcePosition:(GLKVector3 *)position {
    GLKVector3 source_direction = GLKQuaternionRotateVector3(
                                                             GLKQuaternionInvert(*head_rotation), *position);
    return ABS(source_direction.v[0]) < kFocusThresholdRadians3 &&
    ABS(source_direction.v[1]) < kFocusThresholdRadians3;
}

- (bool)isLookingAtObject4:(const GLKQuaternion *)head_rotation
            sourcePosition:(GLKVector3 *)position {
    GLKVector3 source_direction = GLKQuaternionRotateVector3(
                                                             GLKQuaternionInvert(*head_rotation), *position);
    return ABS(source_direction.v[0]) < kFocusThresholdRadians4 &&
    ABS(source_direction.v[1]) < kFocusThresholdRadians4;
}

- (bool)isLookingAtObject5:(const GLKQuaternion *)head_rotation
            sourcePosition:(GLKVector3 *)position {
    GLKVector3 source_direction = GLKQuaternionRotateVector3(
                                                             GLKQuaternionInvert(*head_rotation), *position);
    return ABS(source_direction.v[0]) < kFocusThresholdRadians5 &&
    ABS(source_direction.v[1]) < kFocusThresholdRadians5;
}

@end
