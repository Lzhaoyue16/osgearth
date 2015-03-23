#version 120

#pragma vp_entryPoint "oe_clamp_vertex"
#pragma vp_location   "vertex_view"
#pragma vp_order      "0.5"

#pragma include "GPUClamping.vert.lib.glsl"

attribute vec4 oe_clamp_anchor;
attribute float oe_clamp_offset;
uniform bool oe_clamp_hasAttrs;

uniform float oe_clamp_altitudeOffset;
uniform float oe_clamp_horizonDistance2;
varying float oe_clamp_alpha;

// From osgEarth::MapNode
uniform bool oe_isGeocentric;
uniform vec3 oe_ellipsoidFrame;
uniform vec3 oe_ellipsoidFrameInverse;

// clamp a vertex to the ground
void oe_clamp_vertex(inout vec4 vertexView)
{
    const float ClampToAnchor = 1.0;

    // check distance; alpha out if its beyone the horizon distance.
    oe_clamp_alpha = oe_isGeocentric ? 
        clamp(oe_clamp_horizonDistance2 - (vertexView.z*vertexView.z), 0.0, 1.0) :
        1.0;

    // if visible, calculate clamping.
    // note: no branch divergence in the vertex shader
    if ( oe_clamp_alpha > 0.0 )
    {
        bool relativeToAnchor = (oe_clamp_hasAttrs) && (oe_clamp_anchor.a == ClampToAnchor);

        // if we are using the anchor point, xform it into view space to prepare
        // for clamping.
        vec4 pointToClamp = relativeToAnchor?
            gl_ModelViewMatrix * vec4(oe_clamp_anchor.xyz, 1.0) :
            vertexView;

        // find the clamped point.
        vec4 clampedPoint;
        float depth;
        oe_getClampedViewVertex(pointToClamp, clampedPoint, depth);
        
        float dh = 0.0f;

        if ( relativeToAnchor )
        {
            // if we are clamping relative to the anchor point, just adjust the HAT
            // to account for the terrain height.
            dh = distance(pointToClamp, clampedPoint);
        }
        else
        {
            // if we are clamping to the terrain, the vertex becomes the
            // clamped point.
            vertexView.xyz = clampedPoint.xyz/clampedPoint.w;

            dh = gl_Vertex.z;

            if ( oe_isGeocentric )
            {
              #if 0 // right idea, but I cannot figure out how to properly get
                    // length(gl_Vertex.xy) into the ellipsoidal frame.
                vec3 vertXY2 = vec3(gl_Vertex.xy*gl_Vertex.xy,0.0) * oe_ellipsoidFrame;
                vec3 M = sqrt(1.0 - vertXY2); // R2 = 1
                vec3 curvatureOffset = (1.0 - M) * oe_ellipsoidFrameInverse; // R = 1
                dh += curvatureOffset.length();
              #else
                float vertXY2 = gl_Vertex.x*gl_Vertex.x + gl_Vertex.y*gl_Vertex.y;
                float R2   = oe_ellipsoidFrameInverse.x*oe_ellipsoidFrameInverse.x;
                float m    = sqrt(R2-vertXY2);
                float curvatureOffset = oe_ellipsoidFrameInverse.x - m;
                dh += curvatureOffset;
              #endif
            }
        }

        // apply the z-offset if there is one.
        float hOffset = dh + oe_clamp_altitudeOffset;
        if ( hOffset != 0.0 )
        {
            vec3 up;
            oe_getClampingUpVector(up);
            vertexView.xyz += up * hOffset;
        }

        // if the clamped depth value is near the far plane, suppress drawing
        // to avoid rendering anomalies.
        oe_clamp_alpha = 1.0-step(0.9999, depth);
    }
}
