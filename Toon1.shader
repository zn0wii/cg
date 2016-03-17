﻿Shader "Custom/Toon" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" { }
		_RampTex ("Ramp", 2D) = "white"{}
		_Color("Main Color",color)=(1,1,1,1)//物体的颜色
		_Outline("Thick of Outline",range(0,0.1))=0.02//挤出描边的粗细
		_Factor("Factor",range(0,1))=0.5//挤出多远
		_ToonEffect("Toon Effect",range(0,1))=0.5//卡通化程度（二次元与三次元的交界线）
		_Steps("Steps of toon",range(0,9))=3//色阶层数
	}

	SubShader {

		/*
		pass{//处理光照前的pass渲染
			Tags{"LightMode"="Always"}
			Cull Front
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			float _Outline;
			float _Factor;
			float4 _Color;
			struct v2f {
				float4 pos:SV_POSITION;
			    half2 uv : TEXCOORD0;
			};

			v2f vert (appdata_full v) {
				v2f o;
				float3 dir=normalize(v.vertex.xyz);
				float3 dir2=v.normal;
				float D=dot(dir,dir2);
				dir=dir*sign(D);
				dir=dir*_Factor+dir2*(1-_Factor);
				v.vertex.xyz+=dir*_Outline;
				o.pos=mul(UNITY_MATRIX_MVP,v.vertex);
				return o;
			}
			float4 frag(v2f i):COLOR
			{
				float4 c= _Color / 5;
				return c;
			}
		ENDCG
		}
		*/

		pass{
			Tags{"LightMode"="ForwardBase"}
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float4 _LightColor0;
			float4 _Color;
			float _Steps;
			float _ToonEffect;

			sampler2D _MainTex;
			sampler2D _RampTex;  
			 float4 _MainTex_ST;
			 float4 _RampTex_ST;

			struct v2f {
				float4 pos:SV_POSITION;
				float3 lightDir:TEXCOORD0;
				float3 viewDir:TEXCOORD1;
				float3 normal:TEXCOORD2;
				float2 uv:TEXCOORD3;
				float2 uv2:TEXCOORD4;
			};

			v2f vert (appdata_full v) {
				v2f o;
				o.pos=mul(UNITY_MATRIX_MVP,v.vertex);//切换到世界坐标
				o.normal=v.normal;
				o.lightDir=ObjSpaceLightDir(v.vertex);
				o.viewDir=ObjSpaceViewDir(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);  
				o.uv2 = TRANSFORM_TEX(v.texcoord1, _RampTex);  


				return o;
			}
			float4 frag(v2f i):COLOR
			{
				float4 texcol = tex2D(_MainTex, i.uv);
				

				float4 c=1;
				float3 N=normalize(i.normal);
				i.lightDir = float3(0.5, 1, 0.5);
				float3 viewDir=normalize(i.viewDir);
				float3 lightDir=normalize(i.lightDir);


				float diff=max(0,dot(N,i.lightDir));//求出正常的漫反射颜色
				diff=(diff+1)/2;//做亮化处理

				diff=smoothstep(0,1,diff);//使颜色平滑的在[0,1]范围之内
				float toon=floor(diff*_Steps)/_Steps;//把颜色做离散化处理，把diffuse颜色限制在_Steps种（_Steps阶颜色），简化颜色，这样的处理使色阶间能平滑的显示
				diff = 1;
				diff=lerp(diff,toon,_ToonEffect);//根据外部我们可控的卡通化程度值_ToonEffect，调节卡通与现实的比重



				float diflight = max(0, dot(N, lightDir));
				float rimlight = max(0, dot(N, viewDir));
				diflight = (diflight+1)/2;

				float difhalf = diflight * 0.5 + 0.5;
				float rimhalf = rimlight * 0.5 + 0.5;

				// difhalf = lerp(difhalf, toon, _ToonEffect);
				// rimlight = lerp(difhalf, toon, _ToonEffect);

				float4 ramp = tex2D(_RampTex, float2(difhalf, rimhalf));

				//c= texcol * _Color * _LightColor0*(diff);//把最终颜色混合
				c = texcol * ramp;

				return c;
			}
			ENDCG
		}
}
}