//
//  ShaderDefinitions.h
//  hello-triangle
//
//  Created by 0x0000 on 2021-01-10.
//

#ifndef ShaderDefinitions_h
#define ShaderDefinitions_h

#include <simd/simd.h>

struct Vertex
{
    vector_float4 colour;
    vector_float2 position;
};

struct FragmentUniforms
{
    float brightness;
};

#endif /* ShaderDefinitions_h */

