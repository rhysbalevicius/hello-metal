//
//  Shaders.metal
//  hello-scnprogram
//

#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

struct NodeBuffer
{
    float4x4 modelTransform;
    float4x4 inverseModelTransform;
    float4x4 modelViewTransform;
    float4x4 inverseModelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 inverseModelViewProjectionTransform;
};

struct VertexInput
{
    float3 position      [[ attribute(SCNVertexSemanticPosition) ]];
    float3 normal        [[ attribute(SCNVertexSemanticNormal) ]];
    float2 textureCoords [[ attribute(SCNVertexSemanticTexcoord0) ]];
};

struct VertexOutput
{
    float4 position [[ position ]];
    float2 textureCoords;
};

// Map a position in model space to a texture coordinate for sampling from the background
// https://developer.apple.com/documentation/arkit/tracking_and_visualizing_faces
float2 getBackgroundCoordinate(
                      constant float4x4& displayTransform,
                      constant float4x4& modelViewTransform,
                      constant float4x4& projectionTransform,
                      float4 position) {
    // Transform the vertex to the camera coordinate system.
    float4 vertexCamera = modelViewTransform * position;
    
    // Camera projection and perspective divide to get normalized viewport coordinates (clip space).
    float4 vertexClipSpace = projectionTransform * vertexCamera;
    vertexClipSpace /= vertexClipSpace.w;
    
    // XY in clip space is [-1,1]x[-1,1], so adjust to UV texture coordinates: [0,1]x[0,1].
    // Image coordinates are Y-flipped (upper-left origin).
    float4 vertexImageSpace = float4(vertexClipSpace.xy * 0.5 + 0.5, 0.0, 1.0);
    vertexImageSpace.y = 1.0 - vertexImageSpace.y;
    
    // Apply ARKit's display transform (device orientation * front-facing camera flip).
    return (displayTransform * vertexImageSpace).xy;
}

vertex VertexOutput vertexShader(VertexInput in [[stage_in]],
                         constant SCNSceneBuffer& scn_frame [[buffer(0)]],
                         constant NodeBuffer& scn_node [[buffer(1)]],
                         constant float& u_time [[buffer(2)]],
                         constant float4x4& u_displayTransform [[buffer(3)]])
{
    VertexOutput out;
    
    out.textureCoords = getBackgroundCoordinate(
                            u_displayTransform,
                            scn_node.modelViewTransform,
                            scn_frame.projectionTransform,
                            float4(in.position, 1.0));
    
    // Distort the node geometry over time
    // Working example: 3d sin wave
    float waveHeight = 0.25;
    float waveFreq = 20.0;
    float len = length(in.position.xy);
    float blending = max(0.0, 0.5 - len);

    in.position.z += sin(len * waveFreq + u_time * 5) * waveHeight * blending;

    // Project the geometry
    out.position = scn_node.modelViewProjectionTransform * float4(in.position, 1.0);
    
    return out;
}

fragment float4 fragmentShader(VertexOutput in [[stage_in]],
        texture2d<float, access::sample> texture [[texture(0)]])
{
    // Read from the background frame
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    float3 colour = texture.sample(textureSampler, in.textureCoords).rgb;
    
    return float4(colour, 1);
}


