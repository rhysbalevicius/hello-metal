//
//  Shaders.metal
//  hello-3d-box
//
//  Created by Rhys Balevicius.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
    float4 position [[ position ]];
    float4 colour;
};

struct Uniforms
{
    float4x4 modelMatrix;
};

vertex Vertex vertex_shader(
    constant Vertex *vertices [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(1)]],
    uint vid [[vertex_id]])
{
    float4x4 matrix = uniforms.modelMatrix;
    Vertex in = vertices[vid];
    Vertex out;
    out.position = matrix * float4(in.position);
    out.colour = in.colour;
    
    return out;
}

fragment float4 fragment_shader(Vertex vert [[stage_in]])
{
    return vert.colour;
}
