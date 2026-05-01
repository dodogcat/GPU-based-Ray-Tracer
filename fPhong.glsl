#version 330

in vec3 N3; 
in vec3 L3; 
in vec3 V3; 
in vec3 wV;
in vec3 wP;
in vec3 wN;

out vec4 fColor;

struct Material {
	vec4  k_d;	// diffuse coefficient
	vec4  k_s;	// specular coefficient
	float n;	// specular exponent
};

struct Sphere {
	vec4     center;
	float    radius;
	Material mtl;
};

struct Ray {
	vec3 pos;
	vec3 dir;
};

struct HitInfo {
	float    t;
	vec4     position;
	vec3     normal;
	Material mtl;
};

uniform mat4 uModelMat; 
uniform mat4 uViewMat; 
uniform mat4 uProjMat; 
uniform vec4 uLPos; 
uniform vec4 uLIntensity;
uniform vec4 uAmb; 
uniform vec4 uDif; 
uniform vec4 uSpc; 
uniform float uShininess; 
uniform samplerCube uCube;
uniform vec4 uEPos;
uniform int uNumSphere;
uniform Sphere uSpheres[20];
uniform int uBounceLimit;
uniform int uDrawingMode;



bool IntersectRay( inout HitInfo hit, Ray ray );

// Shades the given point and returns the computed color.
vec4 Shade( Material mtl, vec4 position, vec3 normal, vec3 view )
{
	vec4 color = vec4(0,0,0,1);
	vec3 L = vec3(0,1,0);
	Ray r;
	r.dir = 2 * dot(L, normal) * normal - L;
	r.dir = normalize(r.dir);

	float RV = dot(r.dir, view);
	if(RV < 0){
		RV = 0;
	}
	float accum = pow(RV, mtl.n);

	// TO-DO: Check for shadows
	// TO-DO: If not shadowed, perform shading using the diffuse color only
	float LV = dot(L, normal);
	if(LV < 0){
		LV = 0;
	}

	// 위치가 공 아래면 검은색
	bool isHidden = false;	
	for ( int i=0; i<uNumSphere; ++i ) {
		float d = sqrt((uSpheres[i].center.x - position.x) * (uSpheres[i].center.x - position.x)
				+ (uSpheres[i].center.z - position.z) * (uSpheres[i].center.z - position.z));

		// 위에서 봤을 때 원 안에 들어가 있고 위치가 구의 중심보다 아래면 그림자로 판단
		if(d < uSpheres[i].radius && uSpheres[i].center.y > position.y){
			isHidden = true;
		}
	}

	if (isHidden == false){
		color += mtl.k_d * uLIntensity * LV + mtl.k_s * uLIntensity * accum;	// change this line
		// color += mtl.k_d * uLIntensity;	// change this line
	}

	return color;
}

// Intersects the given ray with all spheres in the scene
// and updates the given HitInfo using the information of the sphere
// that first intersects with the ray.
// Returns true if an intersection is found.
bool IntersectRay( inout HitInfo hit, Ray ray )
{
// 	hit.t = 1e30;
// 	bool foundHit = false;
// 	Material a = {vec4(1,1,1,1),vec4(1,1,1,1),5};
// 	hit.mtl = a;
// 	for ( int i=0; i<uNumSphere; ++i ) {
// 		// TO-DO: Test for ray-sphere intersection
// 		// TO-DO: If intersection is found, update the given HitInfo
// 		vec3 L = uSpheres[i].center.xyz - ray.pos;
		
// 		float tca = dot(L, ray.dir);

// 		if(tca < 0){
// 			continue;
// 		}

// 		float d = sqrt(dot(L, L) - dot(tca, tca));

// 		if (d < 0){
// 			continue;
// 		}

// 		float thc = sqrt((uSpheres[i].radius * uSpheres[i].radius) - (d * d));

// 		float t0 = tca - thc;
// 		float t1 = tca + thc;

// 		// float b = dot(ray.dir, o_c);
// 		// float c = dot(o_c, o_c) - uSpheres[i].radius;
		
// 		// if(b * b - c < 0){
// 		// 	continue;
// 		// }
		
// 		// float t1 = -b - sqrt(b*b - 4 * c) / 2.0f;
// 		// float t2 = -b + sqrt(b*b - 4 * c) / 2.0f;
// 		float short_d = t0 < t1 ? t0 : t1;

// 		if(short_d > hit.t){
// 			continue;
// 		}
// 		hit.t = short_d;
// 		hit.mtl = uSpheres[i].mtl;
// 		hit.position.xyz = ray.pos + ray.dir * hit.t;
// 		hit.normal = hit.position.xyz - uSpheres[i].center.xyz;
// 		hit.normal = normalize(hit.normal);

// 		foundHit = true;
// 	}
// 	return foundHit;

	hit.t = 1e30;
	bool foundHit = false;
	for ( int i=0; i<uNumSphere; ++i ) {
		vec3 L = uSpheres[i].center.xyz - ray.pos;
		
		float tca = dot(L, ray.dir);

		if(tca < 0){
			continue;
		}

		float d = sqrt(dot(L, L) - dot(tca, tca));		
		Sphere sphere = uSpheres[i];
		// TO-DO: Test for ray-sphere intersection
		float discriminant = pow(dot(ray.dir, (ray.pos - sphere.center.xyz)), 2.0) - 
			(dot(ray.dir, ray.dir) * (dot((ray.pos - sphere.center.xyz), (ray.pos - sphere.center.xyz)) - pow(sphere.radius, 2.0))); 
		if(discriminant >= 0.0){ // hit found
			// find the t value of closet ray-sphere intersection
			float t0 = (-(dot(ray.dir, (ray.pos-sphere.center.xyz))) - sqrt(discriminant)) / (dot(ray.dir, ray.dir));
			// TO-DO: If intersection is found, update the given HitInfo
			if( t0 > 0.0 && t0 <= hit.t){
				foundHit = true;
				hit.t = t0; 
				hit.position.xyz = ray.pos + (ray.dir * t0) ; 
				hit.normal = normalize((hit.position.xyz - sphere.center.xyz)/sphere.radius); 
	
				hit.mtl = sphere.mtl;
			}	
	
		}
		
	}
	return foundHit;


}

// Given a ray, returns the shaded color where the ray intersects a sphere.
// If the ray does not hit a sphere, returns the environment color.
vec4 RayTracer( Ray ray )
{
	HitInfo hit;
	if ( IntersectRay( hit, ray ) ) {
		vec3 view = normalize( -ray.dir );

		// vec4 test = vec4(1,1,1,1);
		vec4 clr = Shade( hit.mtl, hit.position, hit.normal, view );	

		// float color_max = length(clr);
		// return clr;
		// Compute reflections
		vec4 k_s = hit.mtl.k_s;

		for ( int bounce=0; bounce<uBounceLimit; bounce++ ) {
			if ( hit.mtl.k_s.r + hit.mtl.k_s.g + hit.mtl.k_s.b <= 0.0 ) break;
			
			Ray r;	// this is the reflection ray
			HitInfo h;	// reflection hit info
						
			// TO-DO: Initialize the reflection ray
			r.pos = hit.position.xyz;
			r.dir = 2 * dot(-ray.dir, hit.normal) * hit.normal - (-ray.dir);
			r.dir = normalize(r.dir);
			// h = hit;
			
			float bias = (1.0f / (bounce + 1));
			bias = pow(bias, 2);
			
			// float a = 0.2f;
			if ( IntersectRay( h, r ) ) {
				// TO-DO: Hit found, so shade the hit point
				// TO-DO: Update the loop variables for tracing the next reflection ray
				vec4 n_color = Shade( h.mtl, h.position, h.normal, view );
				// float temp = bounce + 1;
				// float temp2 = bounce / temp;
				// clr = clr * temp2;
				// clr += n_color / temp;
				// clr = n_color * a + clr * (1 - a);
				// float prev_color = length(clr);
				// clr += n_color;
				// clr = clr * (prev_color / length(clr));

				clr += n_color * bias * hit.mtl.k_s;
				// clr += n_color * hit.mtl.k_s;

				// clr += n_color * bias;


				hit = h;
				ray = r;

			} else {
				// The refleciton ray did not intersect with anything,
				// so we are using the environment color
				// float a = 1.0f / (bounce + 1);
				// clr = k_s * texture(uCube, vec3(1,-1,1)*r.dir) * a + clr * (1 - a);
				clr += k_s * texture(uCube, vec3(1,-1,1)*r.dir) * bias;
				// clr += k_s * texture(uCube, vec3(1,-1,1)*r.dir);
				break;	// no more reflections
			}
		}
		// clr = clr * (color_max / length(clr));
		// clr = clr * (length(k_s * texture(uCube, vec3(1,-1,1)*ray.dir)) / length(clr));

		return clr;	// return the accumulated color, including the reflections
	} else {
		return texture(uCube, vec3(1,-1,1)*ray.dir);	// return the environment color
	}
}

void main()
{
	if(uDrawingMode == 0) 
	{
		vec3 N = normalize(N3); 
		vec3 L = normalize(L3); 
		vec3 V = normalize(V3); 
		vec3 H = normalize(V+L); 

		float NL = max(dot(N, L), 0); 
		float VR = pow(max(dot(H, N), 0), uShininess); 

		fColor = uAmb + uLIntensity*uDif*NL + uLIntensity*uSpc*VR; 
		fColor.w = 1; 

		vec3 viewDir = wP - wV;
		vec3 dir = reflect(viewDir, wN);

		fColor += uSpc*texture(uCube, vec3(1,-1,1)*dir);
	}
	else if(uDrawingMode == 1)
	{
		Ray r;
		r.pos = wV;
		r.dir = normalize(wP - wV);
		fColor = RayTracer (r);
	}
}
