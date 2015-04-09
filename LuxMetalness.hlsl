#include "world.inc"
#include "light.inc"
#if OIT
#include "oit.inc"
#endif



cbuffer ConstantBufferMaterial : register( b2 )
{
	float Alpha;
	float4 BaseColor;
	float Metalness;
	float AO;
	float Spec;
	float Roughness;
}

#define LUX_METALNESS
#define LUX_LIGHTING_CT
#define LUX_GAMMA
#define DIFFCUBE_ON
#define SPECCUBE_ON

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
Texture2D MetallicMap : register( t4 );
SamplerState MetallicMapSampler {
	Filter   = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};
#ifdef DIFFCUBE_ON
Texture2D EnvSphereDiffMap : register( t5 );
SamplerState EnvSphereDiffMapSampler {
	Filter   = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
};
#endif
#ifdef SPECCUBE_ON
Texture2D EnvSphereSpecMap : register( t6 );
SamplerState EnvSphereSpecMapSampler {
	Filter   = MIN_MAG_MIP_LINEAR;
	AddressU = Wrap;
	AddressV = Wrap;
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

// for Cook Torrence spec or roughness has to be in linear space
float LuxAdjustSpecular(float spec) {
	#ifdef LUX_LIGHTING_CT
		return clamp(pow(spec, 1/2.2), 0.0, 0.996);
	#else
		return spec;
	#endif
}

#ifdef DIFFCUBE_ON
float4 GetEnvSphereDiff(float3 worldNormal)
{
  float2 uv;
  float Pi = 3.1415927410125732421875f;
  uv.x = (atan2(worldNormal.x, worldNormal.z)+Pi) / (Pi*2.0f);
  uv.y = (worldNormal.y + Pi) / (Pi*2.0f);
  return EnvSphereDiffMap.Sample(EnvSphereDiffMapSampler, saturate(uv));
}
#endif

#ifdef SPECCUBE_ON
float4 GetEnvSphereSpec(float3 worldNormal)
{
  float2 uv;
  float Pi = 3.1415927410125732421875f;
  uv.x = (atan2(worldNormal.x, worldNormal.z)+Pi) / (Pi*2.0f);
  uv.y = (worldNormal.y + Pi) / (Pi*2.0f);
  return EnvSphereSpecMap.Sample(EnvSphereSpecMapSampler, saturate(uv));
}
#endif

// Pixel shader
PS_OUTPUT PS(PS_INPUT In)
{
	PS_OUTPUT output;
	
  float Pi = 3.1415927410125732421875f;
  #ifdef LUX_LINEAR
    float DiffuseExposure = 1.0f;
		//if (diffuseIsHDR) {
		//	DiffuseExposure *= Mathf.Pow(Lux_HDR_Scale,2.2333333f);
		//}
		float SpecularExposure = 1.0f;
		//if (specularIsHDR) {
		//	SpecularExposure *= Mathf.Pow(Lux_HDR_Scale,2.2333333f);
		//}
  #else
		float DiffuseExposure = pow(1.0, 1.0f / 2.2333333f);
		
		//if (diffuseIsHDR) {
		//	DiffuseExposure *= Lux_HDR_Scale;
		//}
		float SpecularExposure = pow(1.0, 1.0f / 2.2333333f);
		//if (specularIsHDR) {
		//	SpecularExposure *= Lux_HDR_Scale;
		//}
  #endif
  float4 ExposureIBL = float4(DiffuseExposure, SpecularExposure, 1.0f, 1.0f);

#if TEXTURE
  float4 diff_albedo = ColorMap.Sample(ColorMapSampler, In.TexCoord);
	// Metal (R) AO (G) Spec (B) Roughness (A)
	float4 spec_albedo = MetallicMap.Sample(MetallicMapSampler, In.TexCoord);
	spec_albedo.r *= Metalness;
	spec_albedo.g *= AO;
	spec_albedo.b *= Spec;
	spec_albedo.a *= Roughness;
#else
  float4 diff_albedo = float4(1.0, 1.0, 1.0, 1.0);
  float4 spec_albedo = float4(Metalness, AO, Spec, Roughness);
#endif
	//	Diffuse Albedo
	// We have to "darken" diffuse albedo by metalness as it controls ambient diffuse lighting
	float3 oAlbedo = diff_albedo.rgb * BaseColor.rgb * (1.0 - spec_albedo.r);
		
	float oAlpha = diff_albedo.a * Alpha;
	float3 oNormal = GetNormal(In);
	
	//	Specular Color
	// Lerp between specular color (defined as shades of gray for dielectric parts in the blue channel )
	// and the diffuse albedo color based on "Metalness"
	float3 oSpecularColor = lerp(spec_albedo.bbb, diff_albedo.rgb, spec_albedo.r);
		
	// Roughness ? gamma for BlinnPhong / linear for CookTorrence
	float oSpecular = LuxAdjustSpecular(spec_albedo.a);
	
	
	
//	///////////////////////////////////////
// 	Further functions to keep the surf function rather simple
		
	#ifdef SPECCUBE_ON
		float NdotV = max(0, dot(oNormal, normalize(ViewDir.xyz)));
	#endif

	// Fake Fresnel effect using N dot V / only needed by deferred lighting	
	#ifdef UNITY_PASS_PREPASSFINAL
	  #ifdef SPECCUBE_ON
			#ifdef NO_DEFERREDFRESNEL
				oDeferredFresnel = 0;
			#else
				oDeferredFresnel = exp2(-OneOnLN2_x6 * NdotV);
			#endif
	  #endif
	#endif


//	///////////////////////////////////////
// 	Lux IBL / ambient lighting
		
	// set o.Emission = 0.0 to make diffuse shaders work correctly
	float3 oEmission = 0.0;

/*	#ifdef NORMAL_IS_WORLDNORMAL
		float3 worldNormal = IN.normal;
	#else
		#ifdef USE_BLURREDNORMAL
			float3 worldNormal = WorldNormalVector(IN, oNormalBlur);
		#else
			float3 worldNormal = WorldNormalVector(IN, oNormal);
		#endif
	#endif*/
	float3 worldNormal = oNormal;

	#ifdef USE_GLOBAL_DIFFIBL_SETTINGS
	  #ifdef GLDIFFCUBE_ON
  		#define DIFFCUBE_ON
  	#endif
	#endif

//	add diffuse IBL
	#ifdef DIFFCUBE_ON
	  float4 diff_ibl = GetEnvSphereDiff(worldNormal);
		//fixed4	diff_ibl = texCUBE (_DiffCubeIBL, worldNormal);
		#ifdef LUX_LINEAR
			// if colorspace = linear alpha has to be brought to linear too (rgb already is): alpha = pow(alpha,2.233333333).
			// approximation taken from http://chilliant.blogspot.de/2012/08/srgb-approximations-for-hlsl.html
			diff_ibl.a *= diff_ibl.a * (diff_ibl.a * 0.305306011 + 0.682171111) + 0.012522878;
		#endif
		diff_ibl.rgb = diff_ibl.rgb * diff_ibl.a;
		oEmission = diff_ibl.rgb * ExposureIBL.x * oAlbedo;
	#else
		#ifdef LIGHTMAP_OFF
		  #ifdef DIRLIGHTMAP_OFF
				//	otherwise add ambient light from Spherical Harmonics
				oEmission = ShadeSH9 ( float4(worldNormal.xyz, 1.0)) * oAlbedo;
			#endif
		#endif
		#ifdef LUX_LIGHTMAP_OFF
//	otherwise add ambient light from Spherical Harmonics
			oEmission = ShadeSH9 ( float4(worldNormal.xyz, 1.0)) * oAlbedo;
		#endif
	#endif
		
	float OneOnLN2_x6 = 8.656170f;
		
//	add specular IBL		
	#ifdef SPECCUBE_ON
		//#ifdef LUX_BOXPROJECTION
		//	half3 worldRefl;
		//#else
			float3 worldRefl = normalize(reflect(-ViewDir, worldNormal));
		//#endif
		//	Boxprojection / Rotation
		#ifdef LUX_BOXPROJECTION
			// Bring worldRefl and worldPos into Cube Map Space
			worldRefl = mul(_CubeMatrix_Trans, float4(worldRefl,1)).xyz;
			float3 PosCS = mul(_CubeMatrix_Inv,float4(IN.worldPos,1)).xyz;
			float3 FirstPlaneIntersect = _CubemapSize - PosCS;
			float3 SecondPlaneIntersect = -_CubemapSize - PosCS;
			float3 FurthestPlane = (worldRefl > 0.0) ? FirstPlaneIntersect : SecondPlaneIntersect;
			FurthestPlane /= worldRefl;
			float Distance = min(FurthestPlane.x, min(FurthestPlane.y, FurthestPlane.z));
			worldRefl = PosCS + worldRefl * Distance;
		#endif
		#ifdef LUX_LIGHTING_CT
			oSpecular *= oSpecular * (oSpecular * 0.305306011 + 0.682171111) + 0.012522878;
		#endif
		float mipSelect = 1.0f - oSpecular;
		mipSelect = mipSelect * mipSelect * 7; // but * 6 would look better...
		float4 spec_ibl = GetEnvSphereDiff(worldRefl);//texCUBElod (_SpecCubeIBL, float4(worldRefl, mipSelect));
		
		#ifdef LUX_LINEAR
			// if colorspace = linear alpha has to be brought to linear too (rgb already is): alpha = pow(alpha,2.233333333) / approximation taken from http://chilliant.blogspot.de/2012/08/srgb-approximations-for-hlsl.html
			spec_ibl.a *= spec_ibl.a * (spec_ibl.a * 0.305306011 + 0.682171111) + 0.012522878;
		#endif
		spec_ibl.rgb = spec_ibl.rgb * spec_ibl.a;
		// fresnel based on spec_albedo.rgb and roughness (spec_albedo.a) / taken from: http://seblagarde.wordpress.com/2011/08/17/hello-world/
		float3 FresnelSchlickWithRoughness = oSpecularColor + ( max(oSpecular, oSpecularColor ) - oSpecularColor) * exp2(-OneOnLN2_x6 * NdotV);
		// colorize fresnel highlights and make it look like marmoset:
		// float3 FresnelSchlickWithRoughness = o.SpecularColor + o.Specular.xxx * o.SpecularColor * exp2(-OneOnLN2_x6 * NdotV);	
		spec_ibl.rgb *= FresnelSchlickWithRoughness * ExposureIBL.y;
		// add diffuse and specular and conserve energy
		oEmission = (1 - spec_ibl.rgb) * oEmission + spec_ibl.rgb;
		
	#endif
	
	
	#ifdef LUX_AO_ON
		#ifndef LUX_AO_SAMPLED
			half ambientOcclusion = tex2D(_AO,IN.uv_AO).a;
			oEmission *= ambientOcclusion;
		#else
			oEmission *= ambientOcclusion.a;
		#endif
	#endif
	
	
	#ifdef LUX_METALNESS
		oEmission *= spec_albedo.g;
	#endif


	/////////////////////////////// forward lighting
	//float4 LightingLuxDirect (SurfaceOutputLux s, fixed3 lightDir, half3 viewDir, fixed atten){
	
	
  	// get base variables
  float3 viewDir = normalize(ViewDir);
  	// normalizing lightDir makes fresnel smoother
	float3 lightDir = normalize(LightDir);
	// normalizing viewDir does not help here, so we skip it
	float3 h = normalize (lightDir + viewDir);
	// dotNL has to have max
	float dotNL = max (0, dot (oNormal, lightDir));
	float dotNH = max (0, dot (oNormal, h));
	
	#ifndef LUX_LIGHTING_BP
	  #ifndef LUX_LIGHTING_CT
  		#define LUX_LIGHTING_BP
  	#endif
	#endif

//	////////////////////////////////////////////////////////////
//	Blinn Phong	
	#ifdef LUX_LIGHTING_BP
	// bring specPower into a range of 0.25 ? 2048
		float specPower = exp2(10 * oSpecular + 1) - 1.75;

//	Normalized Lighting Model:
	// L = (c_diff * dotNL + F_Schlick(c_spec, l_c, h) * ( (spec + 2)/8) * dotNH?spec * dotNL) * c_light
	
//	Specular: Phong lobe normal distribution function
	//float spec = ((specPower + 2.0) * 0.125 ) * pow(dotNH, specPower) * dotNL; // would be the correct term
	// we use late * dotNL to get rid of any artifacts on the backsides
		float spec = specPower * 0.125 * pow(dotNH, specPower);

//	Visibility: Schlick-Smith
	float alpha = 2.0 / sqrt( Pi * (specPower + 2) );
	float visibility = 1.0 / ( (dotNL * (1 - alpha) + alpha) * ( saturate(dot(oNormal, viewDir)) * (1 - alpha) + alpha) ); 
	spec *= visibility;
	#endif
	
//	////////////////////////////////////////////////////////////
//	Cook Torrrence like
//	from The Order 1886 // http://blog.selfshadow.com/publications/s2013-shading-course/rad/s2013_pbs_rad_notes.pdf

	#ifdef LUX_LIGHTING_CT
	float dotNV = max(0, dot(oNormal, viewDir ) );

//	Please note: s.Specular must be linear
	float alpha = (1.0 - oSpecular); // alpha is roughness
	alpha *= alpha;
	float alpha2 = alpha * alpha;

//	Specular Normal Distribution Function: GGX Trowbridge Reitz
	float denominator = (dotNH * dotNH) * (alpha2 - 1) + 1;
	denominator = Pi * denominator * denominator;
	float spec = alpha2 / denominator;

//	Geometric Shadowing: Smith
	float V_ONE = dotNL + sqrt(alpha2 + (1 - alpha2) * dotNL * dotNL );
	float V_TWO = dotNV + sqrt(alpha2 + (1 - alpha2) * dotNV * dotNV );
	spec /= V_ONE * V_TWO;
	#endif

	//	Fresnel: Schlick
	// fast fresnel approximation:
	float3 fresnel = oSpecularColor.rgb + ( 1.0 - oSpecularColor.rgb) * exp2(-OneOnLN2_x6 * dot(h, lightDir));
	// from here on we use fresnel instead of spec as it is fixed3 = color
	fresnel *= spec;
	
	// Final Composition
	// we only use fresnel here / and apply late dotNL
	float atten = 1.00f;
#if MULTILIGHT
	output.Color.rgb = (oAlbedo + fresnel) * LightCol[0].rgb * dotNL * (atten * 2) + oEmission;
#else
	output.Color.rgb = (oAlbedo + fresnel) * float3(1, 1, 1) * dotNL * (atten * 2) + oEmission;
#endif
	output.Color.a = oAlpha; // + _LightColor0.a * fresnel * atten;
	
	output.Color = saturate(output.Color);

#if OIT
    StoreOIT(In, output.Color);
    output.Color = float4(0,0,0,0);	// This does not affect anything because RenderTargetWriteMask is 0.
#endif

	return output;
}

