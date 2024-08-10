#include "stereokit.hlsli"
#include <stereokit_pbr.hlsli>

//--name = water_pbr2
//--color:color = 0, 0, 1, 0.4
//--tex_trans   = 0,0,1,1
//--time = 5
//--metallic    = 0.9
//--roughness   = 0.01
float4       color;
float4       tex_trans;
float        time;
float        metallic;
float        roughness;


//--diffuse   = white
//--normal    = white
//--metal     = white
//--occlusion = white
Texture2D    diffuse     : register(t0);
SamplerState diffuse_s   : register(s0);
Texture2D    normal      : register(t1);
SamplerState normal_s    : register(s1);
Texture2D    metal       : register(t2);
SamplerState metal_s     : register(s2);
Texture2D    occlusion   : register(t3);
SamplerState occlusion_s : register(s3);
struct vsIn {
    float4 pos    : SV_Position;
    float3 normal : NORMAL0;
    float2 uv     : TEXCOORD0;
    float4 col    : COLOR0;
};
struct psIn {
    float4 pos       : SV_Position;
    float2 uv        : TEXCOORD0;
    float3 normal    : NORMAL0;
    float4 color     : COLOR0;
    float3 irradiance: COLOR1;
	float3 world     : TEXCOORD1;    
    float3 view_dir  : TEXCOORD2;
    uint view_id     : SV_RenderTargetArrayIndex;
};

psIn vs(vsIn input, uint id : SV_InstanceID) {
    psIn o;
    o.view_id = id % sk_view_count;
    id        = id / sk_view_count;

	o.world     = mul(float4(input.pos.xyz, 1), sk_inst[id].world).xyz;
    o.pos       = mul(float4(o.world,   1), sk_viewproj[o.view_id]);

    o.normal     = normalize(mul(float4(input.normal, 0), sk_inst[id].world).xyz);
    o.uv        = (input.uv * tex_trans.zw) + tex_trans.xy;
    o.color     = input.col * color * sk_inst[id].color ;
    o.irradiance = sk_lighting(o.normal);
    o.view_dir   = sk_camera_pos[o.view_id].xyz - o.world;
    return o;
}


float4 ps(psIn input) : SV_TARGET {
    float2 uv = input.uv;
    float offset = time* sk_time/100;
    uv.x += sin (sk_time * time+ (uv.x + uv.y) * 25) * 0.01;
    uv.y += cos (sk_time * time+ (uv.x - uv.y) * 25) * 0.01;

    float4 albedo       = diffuse.  Sample(diffuse_s,  uv) * input.color;
    
    uv.x += offset;
    uv.y += offset;
    float3 normal       = normal   .Sample(normal_s,   uv).rgb ; //* input.normal;
	float2 metal_rough  = metal    .Sample(metal_s,    uv).gb; // rough is g, b is metallic
	float  ao           = occlusion.Sample(occlusion_s,uv).r;  // occlusion is sometimes part of the metal tex, uses r channel

	float metallic_final = metal_rough.y * metallic;
	float rough_final    = metal_rough.x * roughness;

    float4 color = sk_pbr_shade(albedo, input.irradiance, ao, metallic_final, rough_final, input.view_dir, normal);

    return color;
}