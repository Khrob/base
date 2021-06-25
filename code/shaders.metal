#include <simd/simd.h>

using namespace metal;

vertex float4 vertex_func (
    constant packed_float3 *vertices  [[ buffer(0) ]], 
    constant packed_float2 *positions [[ buffer(1) ]],
    uint vid [[ vertex_id ]]) 
{
    return float4(vertices[vid], 1.0);
}

fragment float4 fragment_func () // (float4 vert [[stage_in]]) 
{
    return float4(0.7, 1, 1, 1);
}