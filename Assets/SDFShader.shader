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
                float4 vertex : SV_POSITION;
                float2 screenPos : TEXCOORD1;
                float4 worldPos : TEXCOORD0;
            };

            struct renderShape
            {
                int type;
                float2 vecA;
                float2 vecB;
                float3 color;
            };


            StructuredBuffer<renderShape> shapes;
            int nShapes;
            float smoothness;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                
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

            float sdBox( float2 p, float2 origin, float2 extent)
            {
                float2 d = abs(p - origin) - 0.5 * extent;
                return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
            }
            float sdEllipse( in float2 p, float2 origin, in float2 ab )
            {
                ab = ab/2;
                p = abs(p - origin); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
                float l = ab.y*ab.y - ab.x*ab.x;
                if (l == 0) {
                    return length(p) - ab.x;
                }
                float m = ab.x*p.x/l;      float m2 = m*m; 
                float n = ab.y*p.y/l;      float n2 = n*n; 
                float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
                float q = c3 + m2*n2*2.0;
                float d = c3 + m2*n2;
                float g = m + m*n2;
                float co;
                if( d<0.0 )
                {
                    float h = acos(q/c3)/3.0;
                    float s = cos(h);
                    float t = sin(h)*sqrt(3.0);
                    float rx = sqrt( -c*(s + t + 2.0) + m2 );
                    float ry = sqrt( -c*(s - t + 2.0) + m2 );
                    co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
                }
                else
                {
                    float h = 2.0*m*n*sqrt( d );
                    float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
                    float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
                    float rx = -s - u - c*4.0 + 2.0*m2;
                    float ry = (s - u)*sqrt(3.0);
                    float rm = sqrt( rx*rx + ry*ry );
                    co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
                }
                float2 r = ab * float2(co, sqrt(1.0-co*co));
                return length(r-p) * sign(p.y-r.y);
            }
            float smin( float a, float b, float k )
            {
                float h = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - h*h*k*(1.0/4.0);
            }
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = fixed4(1,1,1,1);
                float2 pixelPos = i.worldPos.xy;

                float d = 10000;
                float d2 = 10000;
                
                {

                    for (int i = 0; i < nShapes; i++) {
                        switch(shapes[i].type) {
                            case 0:
                            d2 = sdSegment(pixelPos, shapes[i].vecA, shapes[i].vecB) - 5;
                            break;
                            case 1:
                            d2 = sdBox(pixelPos, shapes[i].vecA, shapes[i].vecB - 20) - 10;
                            break;
                            case 2:
                            d2 = sdEllipse(pixelPos, shapes[i].vecA, shapes[i].vecB);
                            break;
                        }
                        if (d2 <= 0) {
                            col.rgb = shapes[i].color;
                        }
                        if (smoothness > 0) {
                        d = smin(d,d2, smoothness);
                        } else {
                            d = min(d,d2);
                        }
                    }
                }

                col.rgb *= clamp(smoothstep(0, 1.8, 1 - d),0,1);
                col.g = max(col.g, exp(-.01*abs(d)) * (smoothstep(0.5, 0.6, sin(d / 10))*0.3+0.3));
                return col;
            }
            ENDCG
        }
    }
}
