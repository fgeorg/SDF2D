Shader "Unlit/SDFShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float2 screenPos : TEXCOORD1;
            };


            StructuredBuffer<float2> points;
            int nPoints;

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                o.screenPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float sdSegment( float2 p, float2 a, float2 b )
            {
                float2 pa = p-a, ba = b-a;
                float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
                return length( pa - ba*h );
            }
            float smin( float a, float b, float k )
            {
                float h = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - h*h*k*(1.0/4.0);
            }
            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 pixelPos = i.screenPos * _ScreenParams.xy;

                float d = sdSegment(pixelPos, float2(200,200), float2(500,440)) - 5;
                float d2 = sqrt((pixelPos.x - 500) * (pixelPos.x - 500) + (pixelPos.y - 500) * (pixelPos.y - 500)) - 50;
                d = smin(d,d2, 20);
                
                for(int i = 0; i < nPoints; i++) {
                    float x = points[i].x;
                    float y = points[i].y;
                    float cd = sqrt((pixelPos.x - x) * (pixelPos.x - x) + (pixelPos.y - y) * (pixelPos.y - y)) - 5;
                    d = smin(d, cd, 20);
                }
                col.rgb *= clamp(smoothstep(0, 1.8, 1 - d),0,1);
                col.g = max(col.g, exp(-.005*abs(d)) * (smoothstep(0.5, 0.6, sin(d / 10))*0.3+0.3));
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
