Shader "Cues/QuadBody"
{
	Properties
	{		
		[Header( Size )]
		_ScaleY ( "Scale Y", Range( 0, 20 ) ) = 3

		[Header( Color )]
		_BaseColor( "Base color", Color ) = ( 1, 1, 1 )
		_ResonanceColor( "Resonance color", Color ) = ( 1, 1, 1 )
		_FrostColor( "Frost color", Color ) = ( 1, 1, 1 )
		
		[Header( Visibility )]
		_Alpha( "Alpha", Range( 0, 1 ) ) = 1
		_InvisibleBelow( "Invisible below", Range( 0, 1 ) ) = 1
		[Toggle] _ShowResonance( "Show resonance", Float ) = 1
		[Toggle] _ShowFrost( "Show frost", Float ) = 1
		_FuzzAmount( "Fuzz amount", Range( 0, 1 ) ) = 0.67
		_FuzzPower( "Fuzz power", Range( 0, 10 ) ) = 6.0
		_FuzzLengthMultiplier( "Fuzz length multiplier", Range( 0, 10 ) ) = 2.5
		
		[Header( Time )]		
		_FrostLeadingInTime( "Frost leading in time", Range( 0, 1 ) ) = 1
		_FrostRiseTime( "Frost rise time", Range( 0, 1 ) ) = 1
		
		[Header( Resonance )]
		_ResonanceWaveCenter( "Wave center", Vector ) = ( 0, 0, 0, 0 )
		_ResonanceWaveFront( "Wave front", Range( 0, 1 ) ) = 1
		_ResonanceRandoms( "Randoms", Vector ) = ( 1, 1, 1, 1 )
		_ResonanceWaveDensity( "Wave density", Range( 0, 100 ) ) = 14.26
		_ResonanceSpeed( "Wave speed", Range( 0, 100 ) ) = 7.78
		_ResonanceCircleDensity( "Circle density", Range( 0, 10 ) ) = 2
		_ResonanceAmplitude( "Amplitude", Range( 0, 1 ) ) = 0.232
		_ResonanceFrequency( "Frequency", Range( 0, 10 ) ) = 5
		_ResonancePitch( "Pitch", Range( 0, 127 ) ) = 1
		_ResonanceCircularity( "Circularity", Range( 0, 1 ) ) = 0  // Animated
		_ResonanceSharpness( "Sharpness", Range( 0, 10 ) ) = 2
		_ResonanceStrength( "Strength", Range( 0, 10 ) ) = 0  // Animated
		
		[Header( Frost )]
		_FrostTailCap( "Tail cap", Range( 0, 1 ) ) = 0.08
		_FrostTailSlope( "Tail slope", Range( 0, 5 ) ) = 1.31
		_FrostTailSmoothness( "Tail smoothness", Range( 0, 1 ) ) = 0.712
		_FrostStartTime( "Start time", Range( 0, 1 ) ) = 1
		_FrostT1( "Time head reaches max", Range( 0, 1 ) ) = 0.15
		_FrostT2( "Time sides reach max", Range( 0, 1 ) ) = 0.25
		_FrostT3( "Time whole tail reaches top", Range( 0, 1 ) ) = 0.9
		_FrostTailHeight( "Tail height", Range( 0, 1 ) ) = 0.158
		_FrostTailHeightOffset( "Tail height offset", Range( 0, 1 ) ) = 0.3
		_FrostTailFalloff( "Tail falloff", Range( 0, 10 ) ) = 2.1
	}

	SubShader
	{
		Blend SrcAlpha OneMinusSrcAlpha
		Tags { "Queue"="Transparent" }
		
		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "CueShared.cginc"

			// Color
			float3 _BaseColor;
			float3 _ResonanceColor;
			float3 _FrostColor;			

			// Visibility
			fixed _Alpha;
			float _InvisibleBelow;
			fixed _FuzzAmount;			
			fixed _FuzzPower;			
			fixed _FuzzLengthMultiplier;			
			bool _ShowResonance;
			bool _ShowFrost;

			// Frost
			fixed _FrostLeadingInTime;
			fixed _FrostRiseTime;
					
			fixed4 frag( v2f i ) : SV_Target
			{
				// Discard below
				if( i.uv.y < _InvisibleBelow )
				{
					discard;
				}

				// Fuzz
				fixed d = ( i.uv.x - 0.5 ) * _FuzzLengthMultiplier;
				fixed fuzzedAlpha = getFuzzedAlpha( d, _FuzzAmount, _FuzzPower, _Alpha );

				// Layers
				fixed3 baseLayer = _BaseColor;
				fixed3 resonanceLayer = resonance( i.uv, i.waveCenter.xy, _Time.y ) * _ResonanceColor * _ShowResonance;			
				fixed3 frostLayer = quadFrost( i.uv, _FrostLeadingInTime, _FrostRiseTime, i.screenPos, 1.0 ) * _FrostColor * _ShowFrost;

				// Everything
				return fixed4( resonanceLayer + layer3( frostLayer, baseLayer ), fuzzedAlpha );
			}
			ENDCG
		}
	}
}
				