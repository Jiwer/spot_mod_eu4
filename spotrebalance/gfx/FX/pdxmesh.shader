## Includes

Includes = {
	"constants.fxh"
	"standardfuncsgfx.fxh"
}


## Samplers

PixelShader = 
{
	Samplers = 
	{
		DiffuseMap = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			MipMapLodBias = -1
			AddressU = "Wrap"
			Index = 0
			MipFilter = "Linear"
			MinFilter = "Anisotropic"
		}

		SpecularMap = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			MipMapLodBias = -1
			AddressU = "Wrap"
			Index = 1
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		NormalMap = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			MipMapLodBias = -1
			AddressU = "Wrap"
			Index = 2
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		FlagMap = 
		{
			AddressV = "Clamp"
			MagFilter = "Linear"
			MipMapLodBias = -1
			AddressU = "Clamp"
			Index = 3
			MipFilter = "None"
			MinFilter = "Linear"
		}

		FoWTexture = 
		{
			AddressV = "Clamp"
			MagFilter = "Linear"
			AddressU = "Clamp"
			Index = 4
			MipFilter = "Linear"
			MinFilter = "Linear"
		}

		FoWDiffuse = 
		{
			AddressV = "Wrap"
			MagFilter = "Linear"
			AddressU = "Wrap"
			Index = 5
			MipFilter = "Linear"
			MinFilter = "Linear"
		}


	}
}


## Vertex Structs

VertexStruct VS_INPUT_PDXMESHSTANDARD
{
    float3 vPosition	: POSITION;
	float3 vNormal      : TEXCOORD0;
	float4 vTangent		: TEXCOORD1;
	float2 vUV0			: TEXCOORD2;
	float2 vUV1			: TEXCOORD3;
	float4 vBoneIndex	: TEXCOORD4;
	float3 vBoneWeight	: TEXCOORD5;
};




VertexStruct VS_OUTPUT_PDXMESHSTANDARD
{
    float4 vPosition	: PDX_POSITION;
	float3 vNormal		: TEXCOORD0;
	float3 vTangent		: TEXCOORD1;
	float3 vBitangent	: TEXCOORD2;
	float2 vUV0			: TEXCOORD3;
	float2 vUV1			: TEXCOORD4;
	float4 vPos			: TEXCOORD5;
};



VertexStruct VS_INPUT_DEBUGNORMAL
{
    float3 vPosition	: POSITION;
	float3 vNormal      : TEXCOORD0;
	float4 vTangent		: TEXCOORD1;
	float2 vUV0			: TEXCOORD2;
	float2 vUV1			: TEXCOORD3;
	float4 vBoneIndex	: TEXCOORD4;
	float3 vBoneWeight	: TEXCOORD5;
	float  vOffset      : TEXCOORD6;
};




VertexStruct VS_OUTPUT_DEBUGNORMAL
{
    float4 vPosition : PDX_POSITION;
	float2 vUV0		 : TEXCOORD0;
};




VertexStruct VS_OUTPUT_PDXMESHSHADOW
{
    float4 vPosition	: PDX_POSITION;
	float4 vDepthUV0	: TEXCOORD0;
};



## Constant Buffers

ConstantBuffer( 1, 28 )
{
	float4x4 WorldMatrix;
	float4 PrimaryColor;
	float4 SecondaryColor;
	float4 TertiaryColor; 
	float4 TextureAtlasCoords;
	float4 AtlasHalfColor;
	float4 AtlasCutoff;
}

ConstantBuffer( 2, 41 )
{
	float4x4 matBones[50]; // : Bones :register( c41 ); // 50 * 4 registers 41 - 241 (never push above 256)
}

## Shared Code

Code
[[
static const int PDXMESH_MAX_INFLUENCE = 4;
]]


## Vertex Shaders

VertexShader = 
{
	MainCode VertexPdxMeshStandardSkinned
	[[
		VS_OUTPUT_PDXMESHSTANDARD main( const VS_INPUT_PDXMESHSTANDARD v )
		{
		  	VS_OUTPUT_PDXMESHSTANDARD Out;
					
			float4 vPosition = float4( v.vPosition.xyz, 1.0 );
			float4 vSkinnedPosition = float4( 0, 0, 0, 0 );
			float3 vSkinnedNormal = float3( 0, 0, 0 );
			float3 vSkinnedTangent = float3( 0, 0, 0 );
			float3 vSkinnedBitangent = float3( 0, 0, 0 );
			float4 vWeight = float4( v.vBoneWeight.xyz, 1.0f - v.vBoneWeight.x - v.vBoneWeight.y - v.vBoneWeight.z );
			for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
		    {
				int nIndex = int( v.vBoneIndex[i] );
				float4x4 mat = matBones[nIndex];
				vSkinnedPosition += mul( mat, vPosition ) * vWeight[i];
				float3 vNormal = mul( CastTo3x3(mat), v.vNormal );
				float3 vTangent = mul( CastTo3x3(mat), v.vTangent.xyz );
				float3 vBitangent = cross( vNormal, vTangent ) * v.vTangent.w;
				vSkinnedNormal += vNormal * vWeight[i];
				vSkinnedTangent += vTangent * vWeight[i];
				vSkinnedBitangent += vBitangent * vWeight[i];
			}
			Out.vPosition = mul( WorldMatrix, vSkinnedPosition );
			Out.vPos = Out.vPosition;
			Out.vPosition = mul( ViewProjectionMatrix, Out.vPosition );
			Out.vNormal = normalize( mul( CastTo3x3(WorldMatrix), normalize( vSkinnedNormal ) ) );
			Out.vTangent = normalize( mul( CastTo3x3(WorldMatrix), normalize( vSkinnedTangent ) ) );
			Out.vBitangent = normalize( mul( CastTo3x3(WorldMatrix), normalize( vSkinnedBitangent ) ) );
			Out.vUV0 = v.vUV0;
			Out.vUV1 = v.vUV1;
			return Out;
		}
	]]

	MainCode VertexPdxMeshStandardShadow
	[[
		VS_OUTPUT_PDXMESHSHADOW main( const VS_INPUT_PDXMESHSTANDARD v )
		{
		  	VS_OUTPUT_PDXMESHSHADOW Out;
			float4 vPosition = float4( v.vPosition.xyz, 1.0 );
			Out.vPosition = mul( WorldMatrix, vPosition );
			Out.vPosition = mul( ViewProjectionMatrix, Out.vPosition );
			Out.vDepthUV0 = float4( Out.vPosition.zw, v.vUV0 );
			return Out;
		}
	]]

	MainCode VertexDebugNormalSkinned
	[[
		VS_OUTPUT_DEBUGNORMAL main( const VS_INPUT_DEBUGNORMAL v )
		{
		  	VS_OUTPUT_DEBUGNORMAL Out;
					
			float4 vPosition = float4( v.vPosition.xyz, 1.0 );
			float4 vSkinnedPosition = float4( 0, 0, 0, 0 );
			float3 vSkinnedNormal = float3( 0, 0, 0 );
			float4 vWeight = float4( v.vBoneWeight.xyz, 1.0f - v.vBoneWeight.x - v.vBoneWeight.y - v.vBoneWeight.z );
			for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
		    {
				int nIndex = int( v.vBoneIndex[i] );
				float4x4 mat = matBones[nIndex];
				vSkinnedPosition += mul( mat, vPosition ) * vWeight[i];	
				vSkinnedNormal += mul( CastTo3x3(mat), v.vNormal ) * vWeight[i];
			}
			Out.vPosition = mul( WorldMatrix, vSkinnedPosition );
			vSkinnedNormal = normalize( mul( CastTo3x3(WorldMatrix), vSkinnedNormal ) );
			Out.vPosition.xyz += vSkinnedNormal * v.vOffset * 0.3f;
			Out.vPosition = mul( ViewProjectionMatrix, Out.vPosition );	
			Out.vUV0 = v.vUV0;
			return Out;
		}
	]]

	MainCode VertexDebugNormal
	[[
		VS_OUTPUT_DEBUGNORMAL main( const VS_INPUT_DEBUGNORMAL v )
		{
		  	VS_OUTPUT_DEBUGNORMAL Out;
			Out.vPosition = mul( WorldMatrix, float4( v.vPosition.xyz, 1.0 ) );
			Out.vPosition.xyz += mul( CastTo3x3(WorldMatrix), v.vNormal ) * v.vOffset * 0.3f;
			Out.vPosition = mul( ViewProjectionMatrix, Out.vPosition );	
			Out.vUV0 = v.vUV0;
			return Out;
		}
	]]

	MainCode VertexPdxMeshStandardSkinnedShadow
	[[
		VS_OUTPUT_PDXMESHSHADOW main( const VS_INPUT_PDXMESHSTANDARD v )
		{
		  	VS_OUTPUT_PDXMESHSHADOW Out;
					
			float4 vPosition = float4( v.vPosition.xyz, 1.0 );
			float4 vSkinnedPosition = float4( 0, 0, 0, 0 );
			float4 vWeight = float4( v.vBoneWeight.xyz, 1.0f - v.vBoneWeight.x - v.vBoneWeight.y - v.vBoneWeight.z );
			for( int i = 0; i < PDXMESH_MAX_INFLUENCE; ++i )
		    {
				int nIndex = int( v.vBoneIndex[i] );
				float4x4 mat = matBones[nIndex];
				vSkinnedPosition += mul( mat, vPosition ) * vWeight[i];
			}
			Out.vPosition = mul( WorldMatrix, vSkinnedPosition );
			Out.vPosition = mul( ViewProjectionMatrix, Out.vPosition );
			Out.vDepthUV0 = float4( Out.vPosition.zw, v.vUV0 );
			return Out;
		}
	]]

	MainCode VertexPdxMeshStandard
	[[
		VS_OUTPUT_PDXMESHSTANDARD main( const VS_INPUT_PDXMESHSTANDARD v )
		{
		  	VS_OUTPUT_PDXMESHSTANDARD Out;
					
			float4 vPosition = float4( v.vPosition.xyz, 1.0f );
			Out.vNormal = normalize( mul( CastTo3x3( WorldMatrix ), v.vNormal ) );
			Out.vTangent = normalize( mul( CastTo3x3( WorldMatrix ), v.vTangent.xyz ) );
			Out.vBitangent = normalize( cross( Out.vNormal, Out.vTangent ) * v.vTangent.w );
			Out.vPosition = mul( WorldMatrix, vPosition );
			Out.vPos = Out.vPosition;
			Out.vPosition = mul( ViewProjectionMatrix, Out.vPosition );
			
			Out.vUV0 = v.vUV0;
			Out.vUV1 = v.vUV1;
			return Out;
		}
	]]
	
	MainCode VertexPdxMeshEmpty
	[[
		VS_OUTPUT_PDXMESHSTANDARD main( const VS_INPUT_PDXMESHSTANDARD v )
		{
		  	VS_OUTPUT_PDXMESHSTANDARD Out;
			
			float4 zero = float4(0,0,0,0);
					
			Out.vNormal = zero.rgb;
			Out.vTangent = zero.rgb;
			Out.vBitangent = zero.rgb;
			Out.vPos = zero;
			Out.vPosition = zero;
			
			Out.vUV0 = zero.rg;
			Out.vUV1 = zero.rg;
			return Out;
		}
	]]
	
}

## Pixel Shaders

PixelShader = 
{
	MainCode PixelDebugNormal
	[[
		float4 main( VS_OUTPUT_DEBUGNORMAL In ) : PDX_COLOR
		{
			float4 vColor = float4( 0.0f, 1.0f, 0.0f, 1.0f );
			return vColor;
		}
	]]

	MainCode PixelPdxMeshColor
	[[
		float4 main( VS_OUTPUT_PDXMESHSTANDARD In ) : PDX_COLOR
		{
			float3 vPos = In.vPos.xyz / In.vPos.w;
			
			float4 vFoWColor = GetFoWColor( vPos, FoWTexture);

			clip( 0.99f - vFoWColor.r );		
			
			float4 vColor = tex2D( DiffuseMap, In.vUV0 );
			float3 vNormal = In.vNormal;
			
			vColor.rgb = CalculateLighting( vColor.rgb, vNormal );
			float vFoW = GetFoW( vPos, vFoWColor, FoWDiffuse );

			vColor.rgb = ApplyDistanceFog( vColor.rgb, vPos ) * vFoW;
			return float4( vColor.rgb, 1.0f );
		}
	]]

	MainCode PixelPdxMeshStandardShadow
	[[
		float4 main( VS_OUTPUT_PDXMESHSHADOW In ) : PDX_COLOR
		{
			return float4( In.vDepthUV0.xxx / In.vDepthUV0.y, 1.0f );
		}
	]]

	MainCode PixelPdxMeshStandardSnow
	[[
		float3 ApplySnowMesh( float3 vColor, float3 vPos, inout float3 vNormal, float4 vFoWColor, in sampler2D FoWDiffuse )
		{
			float vIsSnow = GetSnow( vFoWColor )*saturate( (vNormal.y-0.1f) * 100.0f );	
			vColor = lerp( vColor, SNOW_COLOR, saturate( saturate(vIsSnow-0.1f) * 3.5f ) );
			
			vNormal.y += 1.0f * saturate( vIsSnow  );
			vNormal = normalize( vNormal );	
			
			return vColor;
		}
			
		float4 main( VS_OUTPUT_PDXMESHSTANDARD In ) : PDX_COLOR
		{
			float3 vPos = In.vPos.xyz / In.vPos.w;
			
			float4 vFoWColor = GetFoWColor( vPos, FoWTexture);
			//float TI = GetTI( vFoWColor );
			clip( 0.99f - vFoWColor.r );			
			
			float4 vColor = tex2D( DiffuseMap, In.vUV0 );
			//float4 vSpecColor = tex2D( SpecularMap, In.vUV0 );
			
			//float3 vNormalSample = UnpackNormal( NormalMap, In.vUV0 );
			//float3x3 TBN = Create3x3( normalize( In.vTangent ), normalize( In.vBitangent ), normalize( In.vNormal ) );
			//float3 vNormal = mul( vNormalSample, TBN );
			float3 vNormal = In.vNormal;
			
			vColor.rgb = ApplySnowMesh( vColor.rgb, vPos, vNormal, vFoWColor, FoWDiffuse );
			
			vColor.rgb = CalculateLighting( vColor.rgb, vNormal );
			float vFoW = GetFoW( vPos, vFoWColor, FoWDiffuse );
			vColor.rgb = ApplyDistanceFog( vColor.rgb, vPos ) * vFoW;
			//vColor.rgb = ComposeSpecular( vColor.rgb, CalculateSpecular( vPos, vNormal, (vSpecColor.a * 2.0 ) ) * vFoW );
			return vColor;
		}
	]]

	MainCode PixelPdxMeshAlphaBlendShadow
	[[
		float4 main( VS_OUTPUT_PDXMESHSHADOW In ) : PDX_COLOR
		{
			float4 vColor = tex2D( DiffuseMap, In.vDepthUV0.zw );
			clip( vColor.a - 0.5f );
			return float4( In.vDepthUV0.xxx / In.vDepthUV0.y, 1.0f );
		}
	]]

	MainCode PixelPdxMeshStandard_NoFoW_NoTI
	[[
		float4 main( VS_OUTPUT_PDXMESHSTANDARD In ) : PDX_COLOR
		{
			float3 vPos = In.vPos.xyz / In.vPos.w;
			float4 vColor = tex2D( DiffuseMap, In.vUV0 );
			/*float4 vSpecColor = tex2D( SpecularMap, In.vUV0 );
			
			float3 vNormalSample = UnpackNormal( NormalMap, In.vUV0 );
			float3x3 TBN = Create3x3( normalize( In.vTangent ), normalize( In.vBitangent ), normalize( In.vNormal ) );
			float3 vNormal = float3(0,1,0);// mul( vNormalSample, TBN );
			vColor.rgb = CalculateLighting( vColor.rgb, vNormal );
			vColor.rgb = ApplyDistanceFog( vColor.rgb, vPos );
			vColor.rgb = ComposeSpecular( vColor.rgb, CalculateSpecular( vPos, vNormal, ( vSpecColor.a * 2.0 ) ) );*/
			float3 vNormal = In.vNormal;
			vColor.rgb = CalculateLighting( vColor.rgb, vNormal );
			
			return vColor;
		}
	]]

	MainCode PixelPdxMeshStandard
	[[
		float4 main( VS_OUTPUT_PDXMESHSTANDARD In ) : PDX_COLOR
		{
			float3 vPos = In.vPos.xyz / In.vPos.w;
			float4 vFoWColor = GetFoWColor( vPos, FoWTexture);
			//float TI = GetTI( vFoWColor );
			
			//if( vFoWOpacity_Time.x < 0.0f ) {
			//	TI = 0.0;
			//}

			clip( 0.99f - vFoWColor.r );		
			float4 vColor = tex2D( DiffuseMap, In.vUV0 );
			//float4 vSpecColor = tex2D( SpecularMap, In.vUV0 );
			
			//float3 vNormalSample = UnpackNormal( NormalMap, In.vUV0 );
			//float3x3 TBN = Create3x3( normalize( In.vTangent ), normalize( In.vBitangent ), normalize( In.vNormal ) );
			//float3 vNormal = mul( vNormalSample, TBN );
			float3 vNormal = In.vNormal;
			vColor.rgb = CalculateLighting( vColor.rgb, vNormal );
			float vFoW = GetFoW( vPos, vFoWColor, FoWDiffuse );
			
			//if( vFoWOpacity_Time.x < 0.0f ) {
			//	vFoW = 1.0;
			//}
			
			vColor.rgb = ApplyDistanceFog( vColor.rgb, vPos ) * vFoW;
			//vColor.rgb = ComposeSpecular( vColor.rgb, CalculateSpecular( vPos, vNormal, (vSpecColor.a * 2.0 ) ) * vFoW );
			
			return vColor;
		}
	]]

	MainCode PixelPdxMeshTextureAtlas
	[[
		float4 GetAtlasColor( float2 TexCoord )
		{
			if( AtlasHalfColor.a > 0.0f && TexCoord.x > 0.5f )
				return AtlasHalfColor;

			if( AtlasCutoff.x >= 0.0f)
			{
				float2 vActualUV = float2( TexCoord.x / TextureAtlasCoords.x + TextureAtlasCoords.z, TexCoord.y / TextureAtlasCoords.y + TextureAtlasCoords.w );
				return tex2D( FlagMap, vActualUV );
			}
			else
			{
				float2 vActualUV = float2( TexCoord.x / TextureAtlasCoords.x + TextureAtlasCoords.z, TexCoord.y / TextureAtlasCoords.y + TextureAtlasCoords.w );

				float4 OutColor = tex2D( FlagMap, vActualUV );
				OutColor = OutColor.r * PrimaryColor + OutColor.g * SecondaryColor + OutColor.b * TertiaryColor;
				
				return OutColor;
			}
		}
			
		float4 main( VS_OUTPUT_PDXMESHSTANDARD In ) : PDX_COLOR
		{
			float3 vPos = In.vPos.xyz / In.vPos.w;
			
			float4 vFoWColor = GetFoWColor( vPos, FoWTexture);
			float TI = GetTI( vFoWColor );
			clip( 0.99f - TI );		
			
			float4 vColor = tex2D( DiffuseMap, In.vUV0 );
			
			vColor = lerp( vColor, GetAtlasColor( In.vUV1 ) * vColor, vColor.a );
			float4 vSpecColor = tex2D( SpecularMap, In.vUV0 );
			
			float3 vNormalSample = UnpackNormal( NormalMap, In.vUV0 );
			float3x3 TBN = Create3x3( normalize( In.vTangent ), normalize( In.vBitangent ), normalize( In.vNormal ) );
			float3 vNormal = mul( vNormalSample, TBN );
			
			vColor.rgb = CalculateLighting( vColor.rgb, vNormal );
			float vFoW = GetFoW( vPos, vFoWColor, FoWDiffuse );
			vColor.rgb = ApplyDistanceFog( vColor.rgb, vPos ) * vFoW;
			vColor.rgb = ComposeSpecular( vColor.rgb, CalculateSpecular( vPos, vNormal, (vSpecColor.a * 2.0 ) ) * vFoW );
			return vColor;
		}
	]]

	MainCode PixelPdxMeshWaterTransparent
	[[
		float4 main( VS_OUTPUT_PDXMESHSTANDARD In ) : PDX_COLOR
		{
			clip( -1);
			return vColor;
		}
	]]
	
	
	MainCode PixelPdxMeshEmpty
	[[
		float4 main( VS_OUTPUT_PDXMESHSTANDARD In ) : PDX_COLOR
		{
			clip(-1);
			return float4(0,0,0,0);
		}
	]]
	
}


## Blend States

BlendState BlendState
{
	BlendEnable = no
	AlphaTest = no
}

BlendState BlendStateAlphaBlend
{
	SourceBlend = "SRC_ALPHA"
	AlphaTest = no
	BlendEnable = yes
	DestBlend = "INV_SRC_ALPHA"
}

## Rasterizer States

RasterizerState RasterizerState
{
	FrontCCW = no
	CullMode = "CULL_BACK"
	FillMode = "FILL_SOLID"
}

## Depth Stencil States

DepthStencilState DepthStencilNoZWrite
{
	DepthWriteMask = "DEPTH_WRITE_ZERO"
	DepthEnable = yes
}

## Effects

Effect PdxMeshEmpty
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshEmptyShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshSnow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAlphaBlend
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandardShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshTextureAtlas
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect DebugNormalSkinned
{
	VertexShader = "VertexDebugNormalSkinned"
	PixelShader = "PixelDebugNormal"
}

Effect EU4CanalMeshShadow
{
	VertexShader = "VertexPdxMeshStandardShadow"
	PixelShader = "PixelPdxMeshStandardShadow"
}

Effect PdxMeshAlphaBlendSkinned
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAlphaBlendSkinnedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect EU4CanalMesh
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAdvanced
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandard_NoFoW_NoTIShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAdvancedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAlphaBlendNoZWriteSkinned
{
	VertexShader = "VertexPdxMeshStandardSkinned"
	BlendState = "BlendStateAlphaBlend"
	DepthStencilState = "DepthStencilNoZWrite"
	PixelShader = "PixelPdxMeshStandard"
}

Effect PdxMeshTextureAtlasSkinned
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect DebugNormal
{
	VertexShader = "VertexDebugNormal"
	PixelShader = "PixelDebugNormal"
}

Effect PdxMeshColorSkinned
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshSnowSkinnedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshSnowSkinned
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandard
{
	VertexShader = "VertexPdxMeshStandard"
	PixelShader = "PixelPdxMeshStandard"
}

Effect PdxMeshTextureAtlasShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshColorShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAlphaBlendNoZWriteSkinnedShadow
{
	PixelShader = "PixelPdxMeshAlphaBlendShadow"
	DepthStencilState = "DepthStencilNoZWrite"
	VertexShader = "VertexPdxMeshStandardSkinnedShadow"
}

Effect PdxMeshAdvancedSkinned
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshSnowShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandard_NoFoW_NoTISkinnedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandardSkinnedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandard_NoFoW_NoTI
{
	VertexShader = "VertexPdxMeshStandard"
	PixelShader = "PixelPdxMeshStandard_NoFoW_NoTI"
}

Effect PdxMeshColorSkinnedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandardSkinned
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAlphaBlendShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshColor
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshStandard_NoFoW_NoTISkinned
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshAdvancedSkinnedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}

Effect PdxMeshTextureAtlasSkinnedShadow
{
	VertexShader = "VertexPdxMeshEmpty"
	PixelShader = "PixelPdxMeshEmpty"
}