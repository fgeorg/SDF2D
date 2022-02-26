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

            struct renderShape
            {
                int type;
                float2 pointA;
                float2 pointB;
                float3 color;
            };


            StructuredBuffer<float2> points;
            StructuredBuffer<renderShape> shapes;
            int nPoints;
            int nShapes;

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

            float sdBox( float2 p, float2 a, float2 b)
            {
                float2 o = 0.5 * (a + b);
                float2 s = 0.5 * (b-a);
                float2 d = abs(p - o)-s;
                return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
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

                float d = 10000;
                float d2 = 10000;
                
                {

                    for(int i = 1; i < nPoints; i++) {
                        d2 = sdSegment(pixelPos, points[i-1], points[i] + float2(20,0)) - 2;

                        //float cd = sqrt((pixelPos.x - x) * (pixelPos.x - x) + (pixelPos.y - y) * (pixelPos.y - y)) - 5;
                        d = smin(d, d2,2);
                    }
                }
                d2 = sdSegment(pixelPos, float2(200,200), float2(500,440)) - 5;
                d = smin(d,d2, 50);
                d2 = sqrt((pixelPos.x - 500) * (pixelPos.x - 500) + (pixelPos.y - 500) * (pixelPos.y - 500)) - 50;
                d = smin(d,d2, 50);
                
                {

                    for (int i = 0; i < nShapes; i++) {
                        switch(shapes[i].type) {
                            case 0:
                            d2 = sdSegment(pixelPos, shapes[i].pointA, shapes[i].pointB) - 5;
                            break;
                            case 1:
                            d2 = sdBox(pixelPos, shapes[i].pointA, shapes[i].pointB) - 5;
                            break;
                        }
                        if (d2 <= 0) {
                            col.rgb = shapes[i].color;
                        }
                        d = smin(d,d2, 20);
                    }
                }

                col.rgb *= clamp(smoothstep(0, 1.8, 1 - d),0,1);
                col.g = max(col.g, exp(-.01*abs(d)) * (smoothstep(0.5, 0.6, sin(d / 10))*0.3+0.3));
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
