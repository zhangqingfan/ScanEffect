Shader "Unlit/DepthScan"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ProgressMax("Max scan range", Range(5, 20.0)) = 10
        _LineColor("LineColor", Color) = (1, 0, 0, 1)
        //_ScanWidth("ScanWidth", Range(0.1, 20.0)) = 0.1
        temp1("temp1", Range(60, 360)) = 90
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 rayVector : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };
            
            float _Progress;
            //float _ScanWidth;
            float4 _LineColor;
            float _ProgressMax;
            int temp1;

            float4x4 _InverseVPMatrix;
            float4x4 _InversePMatrix;
            float4x4 _InverseWMatrix;
            
            sampler2D _CameraDepthTexture;
            float3 _ClickPosition;
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                //easier calculation, but has the same result as the calculation below.
                //float4 ndcPos = float4(v.uv * 2 - 1, 1, 1);
                //float4 worldPos = mul(_InverseVPMatrix, ndcPos);
                //o.rayVector = worldPos.xyz / worldPos.w; //see deduce below

                float4 ndcPos = float4(v.uv * 2 - 1, 1, 1);
                float4 cameraSpacePos = mul(_InversePMatrix, ndcPos);
                cameraSpacePos = cameraSpacePos.xyzw / cameraSpacePos.w; //see deduce below

                //in cameraSpace, the camera postion is (0,0,0), so cameraSpacePos = cameraSpace direction vector if the w = 0
                o.rayVector = mul(_InverseWMatrix, cameraSpacePos).xyz; 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                depth = Linear01Depth(depth);

                float3 pixelWorldPos = _WorldSpaceCameraPos.xyz + depth * i.rayVector;
                float pixelDistance = distance(pixelWorldPos, _ClickPosition);
                
                float ringWidth = saturate(round(sin(pixelDistance * temp1)));
                float centerWidth = saturate(pow(pixelDistance / 5, 2));

                fixed4 col = tex2D(_MainTex, i.uv);

                if (_Progress - pixelDistance > 0 && depth < 1)
                {
                    float lerpValue = 1 - saturate(_Progress / _ProgressMax);
                    return pow(lerpValue, 2) * _LineColor * ringWidth + lerpValue * centerWidth * _LineColor + col;
                }

                return col;
            }
            ENDCG
        }
    }
}

/*
===============
P: projectionMatrix

NDC = Clip.xyzw / Clip.w = Clip / Clip.w
Clip = NDC * Clip.w
cameraWorldPos = P^-1 * Clip = P^-1 * NDC * Clip.w

cameraWorldPos.w = 1 = (P^-1 * NDC).w * Clip.w
Clip.w = 1 / (P^-1 * NDC).w

cameraWorldPos = P^-1 * NDC * 1 / ((PV)^-1 * NDC).w = P^-1 * NDC / ((PV)^-1 * NDC).w
===============
*/