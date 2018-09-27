#include "UnityCG.cginc"

// Cue properties
float _ScaleY;

// Resonance uniforms
float4 _ResonanceWaveCenter;
float _ResonanceWaveFront;
float4 _ResonanceRandoms;
float _ResonanceWaveDensity;
float _ResonanceSpeed;
float _ResonanceCircleDensity;
float _ResonanceAmplitude;
float _ResonanceFrequency;
float _ResonancePitch;
float _ResonanceCircularity;
float _ResonanceSharpness;
float _ResonanceStrength;
float _ResonanceTimeMultiplier;

// Frost uniforms
fixed _FrostTailCap;
fixed _FrostTailSlope;
fixed _FrostTailSmoothness;
fixed _FrostT1;
fixed _FrostT2;
fixed _FrostT3;
fixed _FrostTailHeight;
fixed _FrostTailHeightOffset;
fixed _FrostTailFalloff;

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

struct v2f
{
	fixed4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;  // Use float for uv because it is used in resonance, where fixed causes problems on mobile
	float4 waveCenter : TEXCOORD1;  // Ditto
	fixed4 screenPos : TEXCOORD2;
};

v2f vert( appdata v )
{
	v2f o;
	o.vertex = UnityObjectToClipPos( v.vertex );
	o.uv = v.uv;
	o.waveCenter = mul( _ResonanceWaveCenter, unity_WorldToObject );
	o.screenPos = ComputeScreenPos(o.vertex);
	return o;
}

fixed ratioFunc( fixed x , fixed cap , fixed slope , fixed smoothness )
{
	return 1.0 / ( cap + pow ( x / slope , smoothness ) );
}

fixed4 layer4( fixed4 top, fixed4 bottom )
{
	return top + bottom * ( 1 - top );
}

fixed3 layer3( fixed3 top, fixed3 bottom )
{
	return top + bottom * ( 1 - top );
}

fixed getFuzzedAlpha( fixed d, fixed amount, fixed power, fixed alpha )
{
	fixed fuzz = 1.0 - pow( abs( d ), power );
	fuzz += 1.0 - amount;
	return min( fuzz, alpha );
}

float resonance( float2 uv, float2 waveCenter, float time )
{
	// Using floats in this function because fixed caused problems on Android

	// Helpers
	float2 scaledUv = uv * float2( 1.0, _ScaleY/5.0 );		
	float speed = _ResonanceSpeed * 10.0;
	float frequency = _ResonanceFrequency * 10.0;
	float pitchMultiplier = pow( _ResonancePitch/100.0, 3.0 );
	
	// Time and space coordinates
	float2 r = ( scaledUv - waveCenter + _ResonanceRandoms.xy ) * _ResonanceWaveDensity;
	float t = time * speed * pitchMultiplier;
	
	// Create wave
	float linear1 = sin( r.x ) * sin( t );
	float linear2 = sin( r.y ) * sin( t );
	float radius = sqrt( r.x * r.x + r.y * r.y );
	float circular = sin( _ResonanceCircleDensity * ( _ResonanceRandoms.z + 0.5 ) * radius - t );
	float wave = ( 1 - _ResonanceCircularity ) * ( linear1 + linear2 ) + _ResonanceCircularity * circular
				 + 1; 

	// Pulsing
	float amplitude = _ResonanceAmplitude * sin( time * frequency * pitchMultiplier ) + 1.0;
	float pulsedWave = max( 0.0, 0.5 * amplitude * wave );				

	// Add in sharpness, strength, and random tuning factors
	float tunedWave = pow( pulsedWave, _ResonanceSharpness * ( _ResonanceRandoms.w + 0.5 ) ) * _ResonanceStrength;			

	// Reveal wave up to the "front"
	float waveFront = clamp( ( _ResonanceWaveFront - uv.y ) * 3.0, 0.0, 1.0 );

	return tunedWave * waveFront;
}

// Draws on the cue using a and b as outline
fixed quadDraw( fixed x , fixed a , fixed b, fixed ramp )
{
	// pow uses uneven exponent to avoid artifacts on top of cue
	fixed smoothLower = clamp( pow ( 1.0 +  ( x - a ), 3.0 ), 0.0, 1.0 );
	fixed smoothUpper = clamp( pow ( 1.0 -  ( x - b ), 3.0 ), 0.0, 1.0 );
	fixed s = smoothLower * ( x < 0.0 ) + smoothUpper * ( x > 0.0 );  // smoother
	return pow( s, _FrostTailFalloff ) * 2.5 * ramp * ( _FrostTailHeight + _FrostTailHeightOffset );
}

fixed quadFrost( fixed2 uv, fixed leadingInTime, fixed riseTime, fixed2 screenPos, fixed tailHeightPow )
{	
	// Helpers
	fixed scaleY = _ScaleY * 10.0;
	fixed tailCap = _FrostTailCap * 8.0 / scaleY * 60.0;
	fixed tailSlope = _FrostTailSlope * 0.058;
	fixed tailSmoothness = _FrostTailSmoothness * 7.6;

	// Time and space coordinates
	if ( leadingInTime != 1.0 )
	{
		riseTime = 0.0;
	}
	if ( riseTime != 0.0 )
	{
		leadingInTime = 1.0;
	}

	fixed posY = leadingInTime;				
	fixed tailHeadUp  = (fixed)smoothstep( 0.0, _FrostT1, posY );
	fixed tailSidesUp = (fixed)smoothstep( _FrostT1, _FrostT2, posY );
	fixed tailGoesUp  = (fixed)smoothstep( 0.0, _FrostT3, riseTime );
	fixed x = uv.x;
	if ( x > 0.5 )
	{
		x = 1.0 - x;
	}
	fixed shiftY = (fixed)( uv.y - tailGoesUp ) * scaleY / 20.0 ;
	fixed height = (fixed)( pow( _FrostTailHeight, tailHeightPow ) * tailHeadUp );		
	
	// Create frost
	fixed function = (fixed)ratioFunc( x, tailCap, tailSlope, tailSmoothness );
	fixed funcUp = height + ( tailSidesUp - tailGoesUp ) * function;
	fixed funcLow = -height - tailGoesUp * function;
	
	// To gain correct smooth transition in the first part
	funcUp += ( - 0.4 + tailHeadUp/4.0 ) * pow( posY - _FrostT3, 2 ) ;

	return quadDraw( shiftY, funcLow, funcUp, tailHeadUp );
}