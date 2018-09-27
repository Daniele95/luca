Shader "Cues/CircleBody"
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
		[Toggle] _ShowTopHalfOnly( "Show top half only", Float ) = 1
		[Toggle] _ShowResonance( "Show resonance", Float ) = 1
		[Toggle] _ShowFrost( "Show frost", Float ) = 1
		[Toggle] _ShowRing( "Show ring", Float ) = 1
		_FuzzAmount( "Fuzz amount", Range( 0, 1 ) ) = 0.6
		_FuzzPower( "Fuzz power", Range( 0, 10 ) ) = 6.0
		_FuzzLengthMultiplier( "Fuzz length multiplier", Range( 0, 10 ) ) = 2.5
		
		[Header( Time )]
		_FrostTime( "Frost time", Range( 0, 1 ) ) = 0
		_RingTime( "Ring time", Range( 0, 2 ) ) = 0
		
		[Header( Resonance )]
		_ResonanceWaveCenter( "Wave center", Vector ) = ( 1, 1, 1, 1 )
		_ResonanceWaveFront( "Wave front", Range( 0, 1 ) ) = 1
		_ResonanceRandoms( "Randoms", Vector ) = ( 1, 1, 1, 1 )
		_ResonanceWaveDensity( "Wave density", Range( 0, 100 ) ) = 1
		_ResonanceSpeed( "Wave speed", Range( 0, 100 ) ) = 1
		_ResonanceCircleDensity( "Circle density", Range( 0, 10 ) ) = 1
		_ResonanceAmplitude( "Amplitude", Range( 0, 1 ) ) = 1
		_ResonanceFrequency( "Frequency", Range( 0, 10 ) ) = 1
		_ResonancePitch( "Pitch", Range( 0, 127 ) ) = 1
		_ResonanceCircularity( "Circularity", Range( 0, 1 ) ) = 1
		_ResonanceSharpness( "Sharpness", Range( 0, 10 ) ) = 1
		_ResonanceStrength( "Strength", Range( 0, 10 ) ) = 1
		
		[Header( Frost )]
		_FrostWidth( "Width", Range( 0, 1 ) ) = 1
		_FrostHeight( "Height", Range( 0, 1 ) ) = 1
		_FrostMaxWidthTime( "Max width time", Range( 0, 1 ) ) = 1
		_FrostMaxHeightTime( "Max height time", Range( 0, 1 ) ) = 1
		_FrostSideHeightPercent( "Side height percent", Range( 0, 1 ) ) = 1		
		
		[Header( Ring )]
		_RingWidth( "Width", Range( 0, 1 ) ) = 1
		_RingFuzziness( "Fuzziness", Range( 0, 1 ) ) = 1
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
			fixed3 _BaseColor;
			fixed3 _ResonanceColor;
			fixed3 _FrostColor;
			
			// Visibility	
			fixed _Alpha;
			fixed _InvisibleBelow;
			bool _ShowTopHalfOnly;
			bool _ShowResonance;
			bool _ShowFrost;
			bool _ShowRing;
			fixed _FuzzAmount;			
			fixed _FuzzPower;			
			fixed _FuzzLengthMultiplier;			

			// Time
			fixed _FrostTime;
			fixed _RingTime;

			// Frost
			fixed _FrostWidth;
			fixed _FrostHeight;
			fixed _FrostMaxWidthTime;
			fixed _FrostMaxHeightTime;
			fixed _FrostSideHeightPercent;			
			
			// Ring
			fixed _RingWidth;
			fixed _RingFuzziness;
			
			// Frost functions
			fixed plotWithBorders( fixed func, fixed y, fixed x, fixed xWidth )
			{
				fixed plot = smoothstep( func + 0.025, func - 0.025, y ) * ( y > func - 0.5 );
				plot *= smoothstep( xWidth, xWidth - 0.1, x );
				plot *= smoothstep( -xWidth, -xWidth + 0.1, x );
				return plot;
			}			
			
			fixed squareRoot( fixed x, fixed xWidth, fixed ySize, fixed percent )
			{   
				fixed rightBorder = smoothstep( 0.47 + percent, 0.47 - percent, x - percent ) * ( percent > 0.0 ) + ( percent == 0.0 ); 
				fixed leftBorder = smoothstep( -0.47 - percent, -0.47 + percent, x + percent ) * ( percent > 0.0 ) + ( percent == 0.0 );				
				fixed output = ySize * sqrt( 1.0 - pow( x/xWidth, 2.0 ) ) * rightBorder * ( x < xWidth && x > 0.0 );
				output += ySize * sqrt( 1.0 - pow( x/xWidth, 2.0 ) ) * leftBorder * ( x > -xWidth && x < 0.0 );
				return output;
			}
			
			fixed frost( fixed2 uv, fixed t )
			{
				// Helpers
				fixed width = _FrostWidth * smoothstep( 0.0, _FrostMaxWidthTime, t );
				fixed height = smoothstep( 0.0, _FrostMaxHeightTime, t );
				height *= ( _FrostHeight/4.0 + 0.75) / 5.0;
				fixed percent = ( _FrostSideHeightPercent + 0.31 ) * 0.05;
				
				// Create frost
				fixed root = abs( squareRoot( uv.x, width, height/2.0, percent ) );
				return plotWithBorders( root, uv.y, uv.x, width );
			}

			fixed ring( fixed2 uv, fixed t )
			{	
				// Helpers
				fixed fuzziness = _RingFuzziness * 2.0 + 0.5;
				fixed width = _RingWidth * 2.0;
			
				// Time and space coordinates
				uv *= 2.0;
				fixed r = 0.7 * sqrt( uv.x * uv.x + uv.y * uv.y );
				t /= 1.2;
				fixed ring = step ( 0.03 , t ) ;

				// Create ring
				fixed arg =  20.0 * ( r - t ) / width / ( 1.0 + fuzziness );
				ring *= pow ( abs ( cos( arg ) ), fuzziness ) * step( -3.14159/2.0, arg ) * step( arg, 3.14159/2.0 );
				return ring;
			}			
			
			fixed4 frag( v2f i ) : SV_Target
			{	
				// How much to show vertically
				if ( i.uv.y < _InvisibleBelow || _ShowTopHalfOnly && i.uv.y < 0.5 )
					discard;
				
				fixed2 centeredUv = i.uv - 0.5;

				// Circle shape
				fixed ball = ( ( centeredUv.x * centeredUv.x + centeredUv.y * centeredUv.y ) < 0.25 );

				// Fuzz
				fixed d = length( centeredUv ) * _FuzzLengthMultiplier;
				fixed fuzzedAlpha = getFuzzedAlpha( d, _FuzzAmount, _FuzzPower, _Alpha );

				// Non-ring layers (not individually fuzzed/alphaed)
				fixed3 baseLayer = _BaseColor;
				fixed3 resonanceLayer = resonance( i.uv, i.waveCenter.xy, _Time.y ) * _ResonanceColor * _ShowResonance;  // Non-centered uv
				fixed3 frostLayer = frost( centeredUv, _FrostTime ) * _FrostColor * _ShowFrost;

				// Ring layer -- no fuzz/alpha
				fixed4 ringLayer = ring( centeredUv, _RingTime )  * fixed4( _FrostColor, 1.0 ) * _ShowRing;
				
				// Blending
				fixed4 layers = layer4( ringLayer, fixed4( resonanceLayer + layer3( frostLayer, baseLayer ), fuzzedAlpha ) );
				return layers * ball;
			}

			ENDCG
		}
	}
}