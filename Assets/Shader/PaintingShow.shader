Shader "Unlit/PaintingShow"
{
	Properties
	{
		_MainTex ("Main", 2D) = "white" {}
		_Tooniness("Tooniness" , Range(0.1,20) ) = 4
		_CoverTex( "Cover" , 2D) = "white" {}
		_MainColor( "Color" , Color) = (1,1,1,1)
		_Thred("BlackWhiteThred" , Range(0.01,1)) = 0.25
		_black("black", 2D ) = "white" {}
		_blackScale("black scale" , float) = 2
		_OutColor( "OutColor" , Color) = (1,1,1,1)
		_White1("white1",2D)= "white" {}
		_White1Adjust("white1 adjust" , Vector) = (0,0,0,0)
		_White1Color( "White1 Color" , Color) = (1,1,1,1)
		_White2("white2",2D)= "white" {}
		_White2Adjust("white2 adjust" , Vector) = (0,0,0,0)
		_White2Color( "White2 Color" , Color) = (1,1,1,1)
		_White3("white3",2D)= "white" {}
		_White3Adjust("white3 adjust" , Vector) = (0,0,0,0)
		_White3Color( "White3 Color" , Color) = (1,1,1,1)
		_InColor( "InColor" , Color) = (1,1,1,1)
		[MaterialToggle]_IsOrigin("Show Original" , float ) = 0
		[MaterialToggle]_IsEdgeDetect("Show Edge Detect" , float ) = 0
		[MaterialToggle]_IsEdgeDetectOpt("Show Edge Detect Optimized" , float ) = 0
		[MaterialToggle]_IsEDAndText("Show Edge Detect And Texture" , float ) = 0
		[MaterialToggle]_IsDCS("Decrese Color Scale" , float ) = 0
		[MaterialToggle]_IsStyle("Style Color" , float ) = 0
		[MaterialToggle]_IsSimpleStyle("Show Simple Style" , float ) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Blend SrcAlpha OneMinusSrcAlpha , one one
		ZWrite Off

		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			    fixed3 normal : NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 worldPos : TEXCOORD1;
				UNITY_FOG_COORDS(4)
				float4 vertex : SV_POSITION;
				float vdotn : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _CoverTex;
			float4 _CoverTex_ST;
			fixed4 _MainColor;
			float _Thred;
			sampler2D _black;
			float4 _black_ST;
			float _blackScale;
			fixed4 _OutColor;
			fixed4 _InColor;
			sampler2D _White1;
			float4 _White1_ST;
			float4 _White1Adjust;
			fixed4 _White1Color;
			sampler2D _White2;
			float4 _White2_ST;
			float4 _White2Adjust;
			fixed4 _White2Color;
			sampler2D _White3;
			float4 _White3_ST;
			float4 _White3Adjust;
			fixed4 _White3Color;
			float _Tooniness;
			float _IsOrigin;
			float _IsEdgeDetect;
			float _IsEdgeDetectOpt;
			float _IsEDAndText;
			float _IsDCS;
			float _IsStyle;
			float _IsSimpleStyle;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _CoverTex);
				o.worldPos = mul(unity_ObjectToWorld , v.vertex);
				float3 viewDir = normalize( mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz - v.vertex);
				o.vdotn = dot(normalize(viewDir),v.normal);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 GetColorFromTexture( sampler2D tex , float2 uv, float4 adjust )
			{
			   	  float xx = cos(adjust.z) * ( uv.x ) + sin( adjust.z ) * uv.y;
			   	  float yy = - sin(adjust.z) * ( uv.x ) + cos( adjust.z ) * uv.y;
			   	  float2 index = float2( xx , yy ) / adjust.w + adjust.xy;
			   	  fixed4 res = tex2D( tex , index );
			   	  res.a = (res.r + res.g + res.b ) / 3;
			   	  return res;
			}


			fixed ScreenSingle( fixed t , fixed b )
			{
				return 1 - ( 1 - t ) * ( 1 - b );
			}


			fixed4 ScreenRGB( fixed4 col1 , fixed4 col2 )
			{
				fixed4 res;
				res.r = ScreenSingle( col1.r , col2.r);
				res.g = ScreenSingle( col1.g , col2.g);
				res.b = ScreenSingle( col1.b , col2.b);
				res.a = ScreenSingle( col1.a , col2.a);
				return res;
			}

			fixed OverlaySingle( fixed t , fixed b )
			{
				if ( t > 0.5 )
					return 1 - ( 1 - 2 * ( t - 0.5 )) * ( 1 - b );
				else
					return ( 2 * t ) * b;
			}

			fixed4 OverlayRGB( fixed4 col1 , fixed4 col2 )
			{
				fixed4 res;
				res.r = OverlaySingle( col1.r , col2.r);
				res.g = OverlaySingle( col1.g , col2.g);
				res.b = OverlaySingle( col1.b , col2.b);
				res.a = OverlaySingle( col1.a , col2.a);
				return res;
			}

			fixed4 MaxRGB( fixed4 col1, fixed4 col2 )
			{
				if ( col1.a > col2.a )
					return col1;
				else
					return col2;
			}

			fixed4 AddRGB( fixed4 col1 , fixed4 col2 )
			{
				fixed4 res;
				fixed sumA = col1.a + col2.a;
				res.rgb = col1.rgb * col1.a / sumA + col2.rgb * col2.a / sumA;
				res.a = 1 - ( 1 - col1.a ) * ( 1 - col2.a );
				return res;
			}

			fixed4 GetStylizedColor( half vdotn , half2 uv , fixed4 texCol , float isSimple )
			{
				float f = pow(vdotn,2);
				fixed4 outline = fixed4(1,1,1,1);

				if ( f < _Thred ) { // the edge
			      float2 findColor = float2(f*2.5f,uv.x/2.0f+uv.y/2.0f) / _blackScale;
			      outline = tex2D(_black, findColor);
			      outline.a = (outline.r + outline.g + outline.b ) / 3;
			      outline *= _OutColor;
			   	}
			   	else { // the inner part
				  fixed4 col1 = GetColorFromTexture( _White1 , uv , _White1Adjust );
				  col1.rgb = _White1Color.rgb * texCol.rgb;
				  col1.a *= _White1Color.a;

				  // only use one overlay texture
				  if ( isSimple > 0 )
				  	outline = col1;
				  else // use the other two overlay texture
				  {
					  fixed4 col2 = GetColorFromTexture( _White2 , uv , _White2Adjust );
					  col2.rgb = _White2Color.rgb;
					  fixed4 col3 = GetColorFromTexture( _White3 , uv , _White3Adjust ) * _White3Color;

					  outline = AddRGB( col2 , col3 );
				  }
			   	}

			   	return outline;
			}

			fixed4 GetEdgeDetect( float vdotn )
			{
					float f = pow(vdotn,2);
					if ( vdotn < _Thred )
						return fixed4( f , f , f , 1 );
					else 
						return fixed4( 1,1,1,1);
			}

			fixed4 GetTooninessColor( fixed4 col )
			{
				fixed4 res = col;
				return floor( col * _Tooniness ) / _Tooniness;
			}

//			fixed4 GetColorMatch( fixed4 col )
//			{
//				float match = dot( normalize( col ) , normalize(_MatchColor));
//				match = pow( match , 30 );
//				return fixed4( match, match , match , 1 );
//			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv) * _MainColor;
				if ( _IsOrigin > 0 )
					return col;

				if ( _IsEdgeDetect > 0 )
					return fixed4( i.vdotn , i.vdotn , i.vdotn , 1);

				if ( _IsEdgeDetectOpt > 0 )
				{
					return GetEdgeDetect( i.vdotn );
				}

				if ( _IsEDAndText > 0 )
				{
					return col * GetEdgeDetect( i.vdotn );
				}

				if ( _IsDCS > 0 )
				{
					return GetTooninessColor( col ) * GetEdgeDetect( i.vdotn );
				}

				if ( _IsStyle > 0 )
				{
					return GetStylizedColor( i.vdotn , i.uv , GetTooninessColor( col ) , _IsSimpleStyle);
				}

				col = GetTooninessColor( col );

				fixed4 style =  GetStylizedColor( i.vdotn , i.uv , col , _IsSimpleStyle);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return style;
			}
			ENDCG
		}
	}
}
