#include "world.inc"
#include "light.inc"
#if OIT
#include "oit.inc"
#endif

cbuffer ConstantBufferMaterial : register( b2 )
{
	float Alpha;
	float4 BaseColor;
}


#ifndef ALPHAMAP
#define ALPHAMAP TEXTURE
#endif

#if TEXTURE
Texture2D ColorMap : register( t0 );
SamplerState ColorMapSampler : register( s0 );
#endif
#if ALPHAMAP
Texture2D AlphaMap : register( t1 );
SamplerState AlphaMapSampler : register( s1 );
#endif
#if NORMALMAP
Texture2D NormalMap : register( t2 );
SamplerState NormalMapSampler : register( s2 ) {
	Filter   = MIN_MAG_MIP_POINT;
	AddressU = Wrap;
	AddressV = Wrap;
};
#endif
#if SHADOW
Texture2D ShadowMap : register( t3 );
SamplerState ShadowMapSampler : register( s3 ) {
	Filter   = MIN_MAG_MIP_LINEAR;
	AddressU = Border;
	AddressV = Border;
	AddressW = Border;
	BorderColor = float4(1,1,1,0);
};
#endif
Texture2D MatcapMap : register( t4 );
SamplerState MatcapMapSampler {
	Filter   = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};

struct VS_INPUT
{
	float4 Pos : POSITION;
	float3 Normal : NORMAL;
#if 1 //always //TEXTURE || ALPHAMAP || NORMALMAP
	float2 TexCoord : TEXCOORD0;
#endif
#if VERTEXCOLOR
	float4 Col : COLOR0;
#endif
#if NORMALMAP
	float4 Tangent : TANGENT;
#endif
};

struct VS_OUTPUT
{
	float4 Pos : SV_POSITION;
	float4 Col : COLOR;
	float3 Normal : NORMAL;
#if TEXTURE || ALPHAMAP || NORMALMAP
	float2 TexCoord : TEXCOORD0;
#endif
#if NORMALMAP
	float3 Tangent : TANGENT;
	float3 Binormal : BINORMAL;
#endif
#if MULTILIGHT
	float4 WorldPos : TEXCOORD3;
#endif
#if SHADOW
	float4 SMPos : TEXCOORD4;
#endif
};

struct PS_INPUT
{
	float4 Pos : SV_POSITION;
	float4 Col : COLOR;
	float3 Normal : NORMAL;
#if TEXTURE || ALPHAMAP || NORMALMAP
	float2 TexCoord : TEXCOORD0;
#endif
#if NORMALMAP
	float3 Tangent : TANGENT;
	float3 Binormal : BINORMAL;
#endif
#if MULTILIGHT
	float4 WorldPos : TEXCOORD3;
#endif
#if SHADOW
	float4 SMPos : TEXCOORD4;
#endif
	bool IsBack : SV_IsFrontFace; // Why inverted?
#if MSAA
    uint Coverage : SV_COVERAGE;
#endif
};

struct PS_OUTPUT
{
	float4 Color    : SV_Target0;
};

#include "oit_store.inc"


// Vertex shader
VS_OUTPUT VS(const VS_INPUT In)
{
	VS_OUTPUT Out;
	Out.Pos = mul(In.Pos, WorldViewProj);
#if VERTEXCOLOR
	Out.Col.xyz = In.Col.xyz;	//RGB
	Out.Col.w = BaseColor.w * In.Col.w;
#else
	Out.Col = BaseColor;
#endif
	Out.Normal = In.Normal;
#if TEXTURE || ALPHAMAP || NORMALMAP
	Out.TexCoord = In.TexCoord;
#endif
#if NORMALMAP
	Out.Tangent = In.Tangent.xyz;
	Out.Binormal = normalize(cross(In.Tangent.xyz, In.Normal)) * In.Tangent.w;
#endif
#if MULTILIGHT
	Out.WorldPos = In.Pos;
#endif
#if SHADOW
	Out.SMPos = mul(In.Pos, ShadowMapProj);
#endif
	return Out;
}


// Geometry shader
//   Convert LineAdjacent (with 4 vertices) to TriangleStrip(with 3 or 4 vertices).
[maxvertexcount(4)]
void GSpatch(lineadj VS_OUTPUT input[4], inout TriangleStream<VS_OUTPUT> stream)
{
	VS_OUTPUT output;

	output.Pos = input[1].Pos;
	output.Col = input[1].Col;
	output.Normal = input[1].Normal;
#if TEXTURE || ALPHAMAP || NORMALMAP
	output.TexCoord = input[1].TexCoord;
#endif
#if NORMALMAP
	output.Tangent = input[1].Tangent;
	output.Binormal = input[1].Binormal;
#endif
#if MULTILIGHT
	output.WorldPos = input[1].WorldPos;
#endif
#if SHADOW
	output.SMPos = input[1].SMPos;
#endif
	stream.Append(output);

	output.Pos = input[0].Pos;
	output.Col = input[0].Col;
	output.Normal = input[0].Normal;
#if TEXTURE || ALPHAMAP || NORMALMAP
	output.TexCoord = input[0].TexCoord;
#endif
#if NORMALMAP
	output.Tangent = input[0].Tangent;
	output.Binormal = input[0].Binormal;
#endif
#if MULTILIGHT
	output.WorldPos = input[0].WorldPos;
#endif
#if SHADOW
	output.SMPos = input[0].SMPos;
#endif
	stream.Append(output);

	output.Pos = input[2].Pos;
	output.Col = input[2].Col;
	output.Normal = input[2].Normal;
#if TEXTURE || ALPHAMAP || NORMALMAP
	output.TexCoord = input[2].TexCoord;
#endif
#if NORMALMAP
	output.Tangent = input[2].Tangent;
	output.Binormal = input[2].Binormal;
#endif
#if MULTILIGHT
	output.WorldPos = input[2].WorldPos;
#endif
#if SHADOW
	output.SMPos = input[2].SMPos;
#endif
	stream.Append(output);

	if(length(input[3].Normal) > 0.0){
		output.Pos = input[3].Pos;
		output.Col = input[3].Col;
		output.Normal = input[3].Normal;
#if TEXTURE || ALPHAMAP || NORMALMAP
		output.TexCoord = input[3].TexCoord;
#endif
#if NORMALMAP
		output.Tangent = input[3].Tangent;
		output.Binormal = input[3].Binormal;
#endif
#if MULTILIGHT
		output.WorldPos = input[3].WorldPos;
#endif
#if SHADOW
		output.SMPos = input[3].SMPos;
#endif
		stream.Append(output);
	}

	stream.RestartStrip();
}


float3 GetNormal(PS_INPUT In)
{
#if NORMALMAP
	float3 normal_col = NormalMap.Sample(NormalMapSampler, In.TexCoord).xyz * 2.0f - 1.0f;
	normal_col.y = -normal_col.y;

	float3x3 mtx = {In.Tangent, In.Binormal, In.Normal};
	float3 nv = normalize(mul(normal_col, mtx).xyz);
#else
	float3 nv = normalize(In.Normal);
#endif
	return nv;
}

float NormToUV(float n)
{
	return 0.5 + (n * 0.5);
}

// Pixel shader
PS_OUTPUT PS(PS_INPUT In)
{
	PS_OUTPUT output;

	float3 nv = GetNormal(In);
	nv = normalize(mul(nv, WorldView).xyz);
	nv.y = -nv.y;
	if(In.IsBack){
		nv = -nv;
		output.Color.rgba = float4(BackFaceColor.rgb, 1.0f);
	} else {
		float4 c = MatcapMap.Sample(MatcapMapSampler, saturate(0.5+nv.xy*0.5));
		c.a *= Alpha;
  	output.Color.rgba = c.rgba;
  }

#if OIT
    StoreOIT(In, output.Color);
    output.Color = float4(0,0,0,0);	// This does not affect anything because RenderTargetWriteMask is 0.
#endif

	return output;
}

