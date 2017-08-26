﻿// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Extended Sprites/Palette shader by Alexander Dahmen, 2017. WTF License

Shader "Sprites/Palette"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		[PerRendererData] _PaletteTex ("Palette Texture", 2D) = "grey" {}
		[PerRendererData] _PaletteIndex ("Palette Index", Float) = 0
        _Color ("Tint", Color) = (1,1,1,1)
        [MaterialToggle] PixelSnap ("Pixel snap", Float) = 0
        [HideInInspector] _RendererColor ("RendererColor", Color) = (1,1,1,1)
        [HideInInspector] _Flip ("Flip", Vector) = (1,1,1,1)
        [PerRendererData] _AlphaTex ("External Alpha", 2D) = "white" {}
        [PerRendererData] _EnableExternalAlpha ("Enable External Alpha", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "IgnoreProjector"="True"
            "RenderType"="Transparent"
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }

        Cull Off
        Lighting Off
        ZWrite Off
        Blend One OneMinusSrcAlpha

        Pass
        {
        CGPROGRAM
            #pragma vertex SpriteVert
            #pragma fragment SpriteFrag
            #pragma target 2.0
            #pragma multi_compile_instancing
            #pragma multi_compile _ PIXELSNAP_ON
            #pragma multi_compile _ ETC1_EXTERNAL_ALPHA

			#include "UnityCG.cginc"

			#ifdef UNITY_INSTANCING_ENABLED
			UNITY_INSTANCING_CBUFFER_START(PerDrawSprite)
				fixed4 unity_SpritePerRendererColorArray[UNITY_INSTANCED_ARRAY_SIZE];
				float4 unity_SpriteFlipArray[UNITY_INSTANCED_ARRAY_SIZE];
			UNITY_INSTANCING_CBUFFER_END
			#define _RendererColor unity_SpriteRendererColorArray[unity_InstanceID]
			#define _Flip unity_SpriteFlipArray[unity_InstanceID]
			#endif

			CBUFFER_START(UnityPerDrawSprite)
			#ifndef UNITY_INSTANCING_ENABLED
			fixed4 _RendererColor;
			float4 _Flip;
			#endif
			float _EnableExternalAlpha;
			CBUFFER_END

			// Material Color
			fixed4 _Color;

			struct appdata_t {
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 texcoord : TEXCOORD0;
			};

			struct v2f {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f SpriteVert(appdata_t IN) {
				v2f OUT;

				UNITY_SETUP_INSTANCE_ID (IN);
			    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO (OUT);

				#ifdef UNITY_INSTANCING_ENABLED
				IN.vertex.xy *= _Flip.xy;
				#endif

				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				OUT.color = IN.color * _Color * _RendererColor;

				#ifdef PIXELSNAP_ON
				OUT.vertex = UnityPixelSnap(OUT.vertex);
				#endif

				return OUT;
			}

			sampler2D _MainTex;
			sampler2D _AlphaTex;
			sampler2D _PaletteTex;
			float _PaletteIndex;

			fixed4 SampleSpriteTexture(float2 uv) {
				fixed4 color = tex2D(_MainTex, uv);

				#if ETC1_EXTERNAL_ALPHA
				fixed4 alpha = tex2D(_AlphaTex, uv);
				color.a = lerp(color.a, alpha.r, _EnableExternalAlpha);
				#endif
				
				return color;
			}

			fixed4 SpriteFrag(v2f IN) : SV_Target {
				fixed4 c = SampleSpriteTexture(IN.texcoord) * IN.color;
				fixed4 p = tex2D(_PaletteTex, fixed2(c.r, _PaletteIndex));
				c.rgb = p.rgb;
				c.a = c.a * p.a;
				c.rgb *= c.a;
				return c;
			}


        ENDCG
        }
    }
}
