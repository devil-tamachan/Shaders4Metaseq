#include "world.inc"
#include "light.inc"
#if OIT
#include "oit.inc"
#endif

cbuffer ConstantBufferMaterial : register( b2 )
{
	float4 Alpha;
	float4 BaseColor;
	float  SpecularPower;
	int TileSize;
	float WidthScale;
	float HeightScale;
	int LightY;
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



float GetSpecular(PS_INPUT In, float3 nv, float3 light_dir)
{
	float3 Reflect = normalize(2 * dot(nv, light_dir) * nv - light_dir);
	float spc_coef = pow(saturate(dot(Reflect, ViewDir)), SpecularPower);
	return spc_coef;
}


// Pixel shader
#if OIT
[earlydepthstencil]
#endif
PS_OUTPUT PS(PS_INPUT In)
{
	PS_OUTPUT output;

	// Calculate a normal vector of the face.
	//float3 nv = GetNormal(In);
	if(In.IsBack){
		//nv = -nv;
		In.Col *= BackFaceColor;
	}

	// Lighting
//	float4 col = GetBaseColor(In);
#if MULTILIGHT
		float3 light_dir;
		if(LightPos[0].w == 0){
			light_dir = normalize(LightPos[0].xyz - In.WorldPos.xyz); // point light
		}else{
			light_dir = LightPos[0].xyz; // directional light
		}
#else
	float3 light_dir = LightDir;
#endif
//#if SHADOW
//	dif *= GetShadow(In);
//#endif
	//col.xyz = Ambient.xyz * GlobalAmbient.xyz + col.xyz * (Emissive.xyz + Diffuse * dif) + Specular.xyz * spc;
	
	light_dir=mul(light_dir, WorldView);
	//output.Color = saturate(col);
	float3 v1 = float3(0.0, 1.0, 0.0);
	if(LightY)v1 = float3(1.0, 0.0, 0.0);
	float maxIndex = TileSize-1.0;
	float angle = 1.0-((dot(v1, normalize(light_dir))+1.0)/2.0); //[0.0 - 1.0]
	float tileIndex = clamp(round(angle * maxIndex), 0.0, maxIndex);
	
	float4 c = float4(1,1,1,1);
#if TEXTURE
	float2 uv2 = In.TexCoord;
	uv2.y *= HeightScale;
	uv2.y += (1.0/TileSize)*tileIndex;
	uv2.x *= WidthScale;
	c = ColorMap.Sample(ColorMapSampler, uv2);
#endif
	c.a *= Alpha;
  output.Color = saturate(c);

#if OIT
    StoreOIT(In, output.Color);
    output.Color = float4(0,0,0,0);	// This does not affect anything because RenderTargetWriteMask is 0.
#endif

	return output;
}

