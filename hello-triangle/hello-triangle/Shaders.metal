//
//  Shaders.metal
//  hello-triangle
//
//  Created by Rhys Balevicius on 2021-01-10.
//

#include "ShaderDefinitions.h"
#include <metal_stdlib>
using namespace metal;

struct VertexOut
{
    float4 colour;
    float4 position [[position]];
};

// "Pass through" vertex shader
vertex VertexOut vertex_shader(const device Vertex *vertexArray [[buffer(0)]], unsigned int vid [[vertex_id]])
{
    // Get the data for the current vertex
    Vertex in = vertexArray[vid];
    
    VertexOut out;
    
    // Pass in the vertex color directly to the rasterzer
    out.colour = in.colour;
    
    // Pass the already normalized screen-space coordinates to the rasterizer
    out.position = float4(in.position.x, in.position.y, 0, 1);
    
    return out;
}

fragment float4 fragment_shader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]])
{
    return float4(uniforms.brightness * interpolated.colour.rgb, interpolated.colour.a);
}
