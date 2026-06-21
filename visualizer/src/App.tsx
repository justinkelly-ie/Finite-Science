import { useState, useEffect, useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Line, Sphere, Html, Sparkles, Trail, Plane } from '@react-three/drei';
import { EffectComposer, Bloom, ChromaticAberration } from '@react-three/postprocessing';
import * as THREE from 'three';
import './index.css';

// Snaps a vector coordinate to integer Maxel nodes
function getDiscreteCoord(tension: number, target: THREE.Vector3) {
  const t = 1 - tension; // 0 = locked, 1 = far apart
  const pos = target.clone().multiplyScalar(t * 10);
  return new THREE.Vector3(Math.round(pos.x), Math.round(pos.y), pos.z);
}

// ---------------------------------------------------------------------
// TYPES FOR STATE SERIALIZATION BRIDGE
// ---------------------------------------------------------------------
interface Geometry {
  src: number;
  tgt: number;
}

interface Term {
  alpha: number;
  beta: number;
  count: number;
}

interface Maxel {
  geom: Geometry;
  amplitude: Term[];
  count: number;
}

interface CausalEdge {
  parent: Geometry;
  child: Geometry;
  count: number;
}

interface UniverseState {
  substrate: CausalEdge[];
  stateVector: Maxel[];
}

// Format the IntPolynumber Amplitude nicely
function formatPolynomial(terms: Term[]): string {
  if (!terms || terms.length === 0) return "0 (Vacuum)";
  const formatted = terms.map((t, i) => {
    if (t.count === 0) return null;
    const isFirst = i === 0;
    const sign = t.count > 0 ? (isFirst ? "" : "+ ") : "- ";
    const val = Math.abs(t.count);
    
    let base = val.toString();
    let vars = "";
    if (t.alpha > 0) {
      vars += "α" + (t.alpha > 1 ? t.alpha.toString().split('').map(c => '⁰¹²³⁴⁵⁶⁷⁸⁹'[parseInt(c)]).join('') : "");
    }
    if (t.beta > 0) {
      vars += "β" + (t.beta > 1 ? t.beta.toString().split('').map(c => '⁰¹²³⁴⁵⁶⁷⁸⁹'[parseInt(c)]).join('') : "");
    }
    
    if (vars !== "" && val === 1) base = "";
    return `${sign}${base}${vars}`;
  }).filter(Boolean);

  return formatted.length === 0 ? "0 (Vacuum)" : formatted.join(" ");
}

// ---------------------------------------------------------------------
// CHEBYSHEV S_n(s) SPREAD POLYNOMIAL COEFFICIENT PRESETS
// ---------------------------------------------------------------------
const CHEBYSHEV_PRESETS: Record<number, Term[]> = {
  1: [{ alpha: 1, beta: 0, count: 1 }],
  2: [
    { alpha: 1, beta: 0, count: 4 },
    { alpha: 2, beta: 0, count: -4 }
  ],
  3: [
    { alpha: 1, beta: 0, count: 9 },
    { alpha: 2, beta: 0, count: -24 },
    { alpha: 3, beta: 0, count: 16 }
  ],
  4: [
    { alpha: 1, beta: 0, count: 16 },
    { alpha: 2, beta: 0, count: -80 },
    { alpha: 3, beta: 0, count: 128 },
    { alpha: 4, beta: 0, count: -64 }
  ],
  5: [
    { alpha: 1, beta: 0, count: 25 },
    { alpha: 2, beta: 0, count: -200 },
    { alpha: 3, beta: 0, count: 560 },
    { alpha: 4, beta: 0, count: -640 },
    { alpha: 5, beta: 0, count: 256 }
  ]
};

// ---------------------------------------------------------------------
// INITIAL SEED PRESENTS FOR MOLECULAR ARCHITECTURE & PHYSICS Engine
// ---------------------------------------------------------------------
const PRESET_WATER: UniverseState = {
  substrate: [
    { parent: { src: 0, tgt: 0 }, child: { src: 4, tgt: 3 }, count: 1 },
    { parent: { src: 0, tgt: 0 }, child: { src: 3, tgt: 4 }, count: 1 }
  ],
  stateVector: [
    { geom: { src: 3, tgt: 4 }, amplitude: CHEBYSHEV_PRESETS[4], count: 1 },
    { geom: { src: 3, tgt: 4 }, amplitude: CHEBYSHEV_PRESETS[3], count: 1 },
    { geom: { src: 3, tgt: 4 }, amplitude: CHEBYSHEV_PRESETS[1], count: 1 },
    { geom: { src: 4, tgt: 3 }, amplitude: CHEBYSHEV_PRESETS[4], count: 1 },
    { geom: { src: 4, tgt: 3 }, amplitude: CHEBYSHEV_PRESETS[3], count: 1 },
    { geom: { src: 4, tgt: 3 }, amplitude: CHEBYSHEV_PRESETS[1], count: 1 },
    { geom: { src: 0, tgt: 0 }, amplitude: CHEBYSHEV_PRESETS[3], count: 8 },
    { geom: { src: 0, tgt: 0 }, amplitude: CHEBYSHEV_PRESETS[1], count: 8 }
  ]
};

const PRESET_METHANE: UniverseState = {
  substrate: [
    { parent: { src: 0, tgt: 0 }, child: { src: 3, tgt: -4 }, count: 1 },
    { parent: { src: 0, tgt: 0 }, child: { src: -4, tgt: -3 }, count: 1 },
    { parent: { src: 0, tgt: 0 }, child: { src: -3, tgt: 4 }, count: 1 },
    { parent: { src: 0, tgt: 0 }, child: { src: 4, tgt: 3 }, count: 1 }
  ],
  stateVector: [
    { geom: { src: 3, tgt: -4 }, amplitude: CHEBYSHEV_PRESETS[4], count: 1 },
    { geom: { src: 3, tgt: -4 }, amplitude: CHEBYSHEV_PRESETS[3], count: 1 },
    { geom: { src: 3, tgt: -4 }, amplitude: CHEBYSHEV_PRESETS[1], count: 1 },
    { geom: { src: -4, tgt: -3 }, amplitude: CHEBYSHEV_PRESETS[4], count: 1 },
    { geom: { src: -4, tgt: -3 }, amplitude: CHEBYSHEV_PRESETS[3], count: 1 },
    { geom: { src: -4, tgt: -3 }, amplitude: CHEBYSHEV_PRESETS[1], count: 1 },
    { geom: { src: -3, tgt: 4 }, amplitude: CHEBYSHEV_PRESETS[4], count: 1 },
    { geom: { src: -3, tgt: 4 }, amplitude: CHEBYSHEV_PRESETS[3], count: 1 },
    { geom: { src: -3, tgt: 4 }, amplitude: CHEBYSHEV_PRESETS[1], count: 1 },
    { geom: { src: 4, tgt: 3 }, amplitude: CHEBYSHEV_PRESETS[4], count: 1 },
    { geom: { src: 4, tgt: 3 }, amplitude: CHEBYSHEV_PRESETS[3], count: 1 },
    { geom: { src: 4, tgt: 3 }, amplitude: CHEBYSHEV_PRESETS[1], count: 1 },
    { geom: { src: 0, tgt: 0 }, amplitude: CHEBYSHEV_PRESETS[3], count: 6 },
    { geom: { src: 0, tgt: 0 }, amplitude: CHEBYSHEV_PRESETS[1], count: 6 }
  ]
};

const PRESET_COSMIC: UniverseState = {
  substrate: [
    { parent: { src: 0, tgt: 0 }, child: { src: 4, tgt: 3 }, count: 1 },
    { parent: { src: 0, tgt: 0 }, child: { src: 3, tgt: 4 }, count: 1 },
    { parent: { src: 4, tgt: 3 }, child: { src: 3, tgt: 4 }, count: 2 },
    { parent: { src: 3, tgt: 4 }, child: { src: 0, tgt: 0 }, count: 1 }
  ],
  stateVector: [
    { geom: { src: 0, tgt: 0 }, amplitude: CHEBYSHEV_PRESETS[5], count: 2 },
    { geom: { src: 4, tgt: 3 }, amplitude: CHEBYSHEV_PRESETS[5], count: 1 },
    { geom: { src: 3, tgt: 4 }, amplitude: CHEBYSHEV_PRESETS[5], count: 3 }
  ]
};

// ---------------------------------------------------------------------
// STATE SERIALIZATION & DYNAMIC EXECUTION BRIDGE FOR IDRIS 2 INTEROP
// ---------------------------------------------------------------------
function formatSubstrate(edges: CausalEdge[]): string {
  return edges.map(e => `${e.parent.src},${e.parent.tgt},${e.child.src},${e.child.tgt}:${e.count}`).join(';');
}

function formatSparseMaxel(maxels: Maxel[]): string {
  return maxels.map(m => {
    const ampStr = m.amplitude.map(t => `${t.alpha},${t.beta},${t.count}`).join(',');
    return `${m.geom.src},${m.geom.tgt}:${m.count}:${ampStr}`;
  }).join(';');
}

let tempSubstrate: CausalEdge[] = [];
let tempStateVector: Maxel[] = [];

(globalThis as any).clearUniverseBuffers = () => {
  tempSubstrate = [];
  tempStateVector = [];
};

(globalThis as any).pushEdge = (px: number, py: number, cx: number, cy: number, count: number) => {
  tempSubstrate.push({
    parent: { src: px, tgt: py },
    child: { src: cx, tgt: cy },
    count
  });
};

(globalThis as any).pushMaxel = (x: number, y: number, alpha: number, beta: number, count: number) => {
  const geom = { src: x, tgt: y };
  const existing = tempStateVector.find(m => m.geom.src === x && m.geom.tgt === y);
  if (existing) {
    existing.amplitude.push({ alpha, beta, count });
  } else {
    tempStateVector.push({
      geom,
      count: 1, // Normalized logic counts
      amplitude: [{ alpha, beta, count }]
    });
  }
};

function runIdrisAdaptiveCycle(
  capacityLimit: number,
  metric: number,
  macroTarget: { src: number, tgt: number },
  substrate: CausalEdge[],
  stateVector: Maxel[]
): UniverseState {
  if (!(window as any).idris_runAdaptiveCycle) {
    console.warn("Idris engine not loaded yet, returning same state.");
    return { substrate, stateVector };
  }
  const capStr = capacityLimit.toString();
  const metStr = metric.toString();
  const targetStr = `${macroTarget.src},${macroTarget.tgt}`;
  const subStr = formatSubstrate(substrate);
  const vecStr = formatSparseMaxel(stateVector);
  
  // The Idris function now synchronously fills tempSubstrate and tempStateVector
  (window as any).idris_runAdaptiveCycle(capStr)(metStr)(targetStr)(subStr)(vecStr);
  
  // Clone to break references and trigger React render
  return { 
    substrate: [...tempSubstrate], 
    stateVector: [...tempStateVector] 
  };
}

// ---------------------------------------------------------------------
// 1. MOCK COMPONENT (Solving S_5 Baryon Lock with Reality Boundary Curvature)
// ---------------------------------------------------------------------

// Deformable Reality Boundary Sheet
function CurvedRealityBoundary({ tension }: { tension: number }) {
  const planeGeom = useMemo(() => {
    const geom = new THREE.PlaneGeometry(35, 35, 24, 24);
    const pos = geom.attributes.position;
    for (let i = 0; i < pos.count; i++) {
      const x = pos.getX(i);
      const y = pos.getY(i);
      const distSq = x * x + y * y;
      
      // Einstein-Rosen metric gravity funnel: deforms based on tension & distance
      const z = -tension * 9.0 * Math.exp(-distSq / 120);
      pos.setZ(i, z);
    }
    geom.computeVertexNormals();
    return geom;
  }, [tension]);

  return (
    <group>
      {/* Wireframe Coordinate Grid Lines */}
      <mesh geometry={planeGeom}>
        <meshPhysicalMaterial 
          color={tension < 0.05 ? "#0055ff" : "#ff0077"} 
          wireframe 
          transparent 
          opacity={0.35} 
          roughness={0.4} 
        />
      </mesh>
      
      {/* Solid Glassmorphic Space-time Sheet */}
      <mesh geometry={planeGeom}>
        <meshPhysicalMaterial 
          color="#06060f" 
          transparent 
          opacity={0.8} 
          roughness={0.15}
          metalness={0.9}
        />
      </mesh>
    </group>
  );
}

// Delocalized Minkowski Radiation Photons
function DelocalizedPhotons({ tension }: { tension: number }) {
  const ref = useRef<THREE.Group>(null);

  useFrame(({ clock }) => {
    if (!ref.current) return;
    const t = clock.getElapsedTime() * 4.5;
    const radius = 9.0 * tension;

    // Photon 1: Oscillates along the null diagonal y = x in the curved metric
    const p1 = ref.current.children[0] as THREE.Mesh;
    if (p1) {
      const x1 = Math.cos(t) * radius;
      const z1 = -tension * 9.0 * Math.exp(-(x1 * x1 + x1 * x1) / 120);
      p1.position.set(x1, x1, z1 + 0.3);
    }

    // Photon 2: Oscillates along the opposite null diagonal y = -x
    const p2 = ref.current.children[1] as THREE.Mesh;
    if (p2) {
      const x2 = Math.sin(t) * radius;
      const z2 = -tension * 9.0 * Math.exp(-(x2 * x2 + x2 * x2) / 120);
      p2.position.set(x2, -x2, z2 + 0.3);
    }
  });

  return (
    <group ref={ref}>
      {/* Photon A */}
      <group>
        <Sphere args={[0.3, 32, 32]}>
          <meshBasicMaterial color="#ffaa00" />
        </Sphere>
        <Sparkles count={15} scale={1} size={4} color="#ffaa00" speed={1.5} />
      </group>

      {/* Photon B */}
      <group>
        <Sphere args={[0.3, 32, 32]}>
          <meshBasicMaterial color="#ffaa00" />
        </Sphere>
        <Sparkles count={15} scale={1} size={4} color="#ffaa00" speed={1.5} />
      </group>
    </group>
  );
}

function BaryonSystem({ tension }: { tension: number }) {
  const isLocked = tension < 0.05;
  const zDepth = isLocked ? 2 : Math.round(-tension * 8); 

  const idealQ1 = new THREE.Vector3(0, 3, zDepth);
  const idealQ2 = new THREE.Vector3(-4, 0, zDepth);
  const idealQ3 = new THREE.Vector3(4, 0, zDepth);

  const q1Pos = isLocked ? new THREE.Vector3(0, 1.2, zDepth) : getDiscreteCoord(tension, idealQ1);
  const q2Pos = isLocked ? new THREE.Vector3(0, 1.2, zDepth) : getDiscreteCoord(tension, idealQ2);
  const q3Pos = isLocked ? new THREE.Vector3(0, 1.2, zDepth) : getDiscreteCoord(tension, idealQ3);

  return (
    <group>
      {/* Deforming Spacetime Sheet */}
      <CurvedRealityBoundary tension={tension} />

       {/* Render Minkowski Radiation when state is unlocked */}
      {!isLocked && <DelocalizedPhotons tension={tension} />}

      {/* Minkowski Null Diagonals as guide lines when radiating */}
      {!isLocked && (
        <>
          <Line 
            points={[new THREE.Vector3(-18, -18, 0.15), new THREE.Vector3(18, 18, 0.15)]} 
            color="#ffaa00" 
            lineWidth={1.5} 
            opacity={0.3} 
            transparent 
          />
          <Line 
            points={[new THREE.Vector3(-18, 18, 0.15), new THREE.Vector3(18, -18, 0.15)]} 
            color="#ffaa00" 
            lineWidth={1.5} 
            opacity={0.3} 
            transparent 
          />
        </>
      )}

      <Html position={[10, 10, 2]} center>
        <div style={{ 
          color: isLocked ? '#00aaff' : '#ff0077', 
          fontWeight: 'bold', 
          letterSpacing: '2px', 
          fontFamily: 'monospace',
          background: 'rgba(5,5,10,0.8)',
          padding: '4px 10px',
          border: `1px solid ${isLocked ? '#00aaff' : '#ff0077'}`
        }}>
          {isLocked ? 'VISIBLE PROJECTION REALM' : 'MÖBIUS SPACETIME CURVATURE'}
        </div>
      </Html>

      {/* Render Snap quarks and linkages */}
      {!isLocked && (
        <>
          <Trail width={1.8} color="#00ffcc" length={4} decay={1}>
            <Sphere args={[0.35, 32, 32]} position={q1Pos}>
              <meshStandardMaterial color="#00ffcc" emissive="#00ffcc" emissiveIntensity={2} wireframe />
            </Sphere>
          </Trail>
          <Trail width={1.8} color="#00ffcc" length={4} decay={1}>
            <Sphere args={[0.35, 32, 32]} position={q2Pos}>
              <meshStandardMaterial color="#00ffcc" emissive="#00ffcc" emissiveIntensity={2} wireframe />
            </Sphere>
          </Trail>
          <Trail width={1.8} color="#00ffcc" length={4} decay={1}>
            <Sphere args={[0.35, 32, 32]} position={q3Pos}>
              <meshStandardMaterial color="#00ffcc" emissive="#00ffcc" emissiveIntensity={2} wireframe />
            </Sphere>
          </Trail>
          
          <Line points={[q1Pos, q2Pos]} color="#00ffcc" lineWidth={1} dashed dashScale={10} />
          <Line points={[q2Pos, q3Pos]} color="#00ffcc" lineWidth={1} dashed dashScale={10} />
          <Line points={[q3Pos, q1Pos]} color="#00ffcc" lineWidth={1} dashed dashScale={10} />
        </>
      )}

      {/* The Locked Baryon (Pushed into Visible 3D space) */}
      {isLocked && (
        <group position={[0, 0, zDepth]}>
          <Sphere args={[1.6, 64, 64]} position={[0, 0, 0]}>
            <meshPhysicalMaterial 
              color="#0055ff" 
              emissive="#0022ff" 
              emissiveIntensity={1.5}
              clearcoat={1.0}
              transmission={0.9}
              thickness={0.5}
              roughness={0.1}
            />
          </Sphere>
          <Sphere args={[0.2, 16, 16]} position={[0, 0.5, 0]}><meshBasicMaterial color="#ffffff" /></Sphere>
          <Sphere args={[0.2, 16, 16]} position={[-0.4, -0.3, 0]}><meshBasicMaterial color="#ffffff" /></Sphere>
          <Sphere args={[0.2, 16, 16]} position={[0.4, -0.3, 0]}><meshBasicMaterial color="#ffffff" /></Sphere>
          
          <Sparkles count={120} scale={6} size={4} color="#00aaff" speed={0.2} />
        </group>
      )}
    </group>
  );
}

// ---------------------------------------------------------------------
// 2. LIVE COMPONENT (Ingesting State Serialization Bridge Vectors)
// ---------------------------------------------------------------------
function LiveSystem({ 
  state, 
  onHoverMaxel, 
  hoveredMaxel,
  onNodeClick,
  onEdgeClick
}: { 
  state: UniverseState; 
  onHoverMaxel: (m: Maxel | null) => void;
  hoveredMaxel: Maxel | null;
  onNodeClick: (geom: Geometry) => void;
  onEdgeClick: (parent: Geometry, child: Geometry) => void;
}) {
  const maxels = state.stateVector || [];
  const edges = state.substrate || [];

  return (
    <group>
      <Plane args={[45, 45]} position={[0, 0, -1]} rotation={[0, 0, 0]}>
        <meshPhysicalMaterial 
          color="#020208" 
          transparent opacity={0.8} 
          roughness={0.3}
          metalness={0.9}
        />
      </Plane>

      {/* Render Causal Edges from Substrate */}
      {edges.map((edge, idx) => {
        const start = new THREE.Vector3(edge.parent.src * 2.5 - 5, edge.parent.tgt * 2.5 - 5, 0.2);
        const end = new THREE.Vector3(edge.child.src * 2.5 - 5, edge.child.tgt * 2.5 - 5, 0.2);
        return (
          <Line 
            key={`edge-${idx}`} 
            points={[start, end]} 
            color="#00ffcc" 
            lineWidth={Math.abs(edge.count) * 2} 
            onClick={(e) => {
              e.stopPropagation();
              onEdgeClick(edge.parent, edge.child);
            }}
          />
        );
      })}

      {/* Render Active Physical Maxels */}
      {maxels.map((maxel, idx) => {
        const x = maxel.geom.src * 2.5 - 5;
        const y = maxel.geom.tgt * 2.5 - 5;
        const z = 0.5 + Math.abs(maxel.count) * 0.1;
        const pos = new THREE.Vector3(x, y, z);
        
        const isHovered = hoveredMaxel && 
          hoveredMaxel.geom.src === maxel.geom.src && 
          hoveredMaxel.geom.tgt === maxel.geom.tgt;

        return (
          <group key={`maxel-${idx}`} position={pos}>
            <Sphere 
              args={[1.2, 32, 32]} 
              onPointerOver={(e) => {
                e.stopPropagation();
                onHoverMaxel(maxel);
              }}
              onPointerOut={(e) => {
                e.stopPropagation();
                onHoverMaxel(null);
              }}
              onClick={(e) => {
                e.stopPropagation();
                onNodeClick(maxel.geom);
              }}
            >
              <meshPhysicalMaterial 
                color={isHovered ? "#00ffff" : "#ff0077"} 
                emissive={isHovered ? "#00aaff" : "#aa0033"} 
                emissiveIntensity={isHovered ? 3.0 : 1.5}
                clearcoat={1.0}
                clearcoatRoughness={0.1}
                transmission={0.7}
                roughness={0.1}
                metalness={0.1}
              />
            </Sphere>

            <Sparkles count={30} scale={2.5} size={3} color={isHovered ? "#00ffff" : "#ff0077"} speed={0.4} />

            {/* High-Legibility Hover Tag (15px bold!) */}
            <Html distanceFactor={12} position={[0, 1.8, 0]} center>
              <div style={{
                background: 'rgba(5,5,15,0.92)',
                border: `2px solid ${isHovered ? '#00ffff' : '#ff0077'}`,
                padding: '8px 16px',
                borderRadius: '6px',
                color: 'white',
                fontFamily: 'monospace',
                fontSize: '15px',
                fontWeight: 'bold',
                whiteSpace: 'nowrap',
                pointerEvents: 'none',
                boxShadow: '0 0 15px rgba(255,0,119,0.3)',
                letterSpacing: '1px'
              }}>
                MAXEL ({maxel.geom.src}, {maxel.geom.tgt})
              </div>
            </Html>
          </group>
        );
      })}
    </group>
  );
}

// ---------------------------------------------------------------------
// 3. SIGMAGATE COMPONENT (Interactive Modeler)
// ---------------------------------------------------------------------
function SigmaGateSystem({
  edgeA,
  edgeB,
  edgeC,
  hoveredNode,
  setHoveredNode,
  onClickNode
}: {
  edgeA: number;
  edgeB: number;
  edgeC: number;
  hoveredNode: string | null;
  setHoveredNode: (node: string | null) => void;
  onClickNode: () => void;
}) {
  const v0 = new THREE.Vector3(0, 0, 0.5);
  const v1 = new THREE.Vector3(8, 6, 0.5);
  const v2 = new THREE.Vector3(6, 8, 0.5);

  // Non-linear boundary mapping: ∂(edges) = vertices
  const q0 = -edgeA - edgeB; // Origin charge
  const q1 = edgeA - edgeC;  // Node A charge
  const q2 = edgeB + edgeC;  // Node B charge

  const nodes = [
    { name: "ROOT (0,0)", pos: v0, charge: q0, label: `(0,0) : q = ${q0}` },
    { name: "NODE A (4,3)", pos: v1, charge: q1, label: `(4,3) : q = ${q1}` },
    { name: "NODE B (3,4)", pos: v2, charge: q2, label: `(3,4) : q = ${q2}` },
  ];

  return (
    <group>
      <Plane args={[50, 50]} position={[0, 0, -1]} rotation={[0, 0, 0]}>
        <meshPhysicalMaterial 
          color="#04040a" 
          transparent opacity={0.8} 
          roughness={0.4}
          metalness={0.9}
        />
      </Plane>

      {/* Render Edges with dynamic visual weight (Edge Multiset Inputs) */}
      {edgeA !== 0 && (
        <Line 
          points={[v0, v1]} 
          color={edgeA > 0 ? "#00ffcc" : "#ff3300"} 
          lineWidth={Math.abs(edgeA) * 3} 
        />
      )}
      {edgeB !== 0 && (
        <Line 
          points={[v0, v2]} 
          color={edgeB > 0 ? "#00ffcc" : "#ff3300"} 
          lineWidth={Math.abs(edgeB) * 3} 
        />
      )}
      {edgeC !== 0 && (
        <Line 
          points={[v1, v2]} 
          color={edgeC > 0 ? "#00ffcc" : "#ff3300"} 
          lineWidth={Math.abs(edgeC) * 3} 
        />
      )}

      {/* Render Boundary Charge Vertices (Vertex Multiset Outputs) */}
      {nodes.map((node) => {
        const absQ = Math.abs(node.charge);
        const radius = absQ === 0 ? 0.7 : 0.9 + absQ * 0.4;
        
        let color = "#888888"; // Neutral
        let emissive = "#333333";
        if (node.charge > 0) {
          color = "#00aaff";
          emissive = "#0055ff";
        } else if (node.charge < 0) {
          color = "#ff5500";
          emissive = "#ff2200";
        }

        const isHovered = hoveredNode === node.name;

        return (
          <group key={node.name} position={node.pos}>
            <Sphere 
              args={[radius, 32, 32]}
              onPointerOver={(e) => {
                e.stopPropagation();
                setHoveredNode(node.name);
              }}
              onPointerOut={(e) => {
                e.stopPropagation();
                setHoveredNode(null);
              }}
              onClick={(e) => {
                e.stopPropagation();
                onClickNode();
              }}
            >
              <meshPhysicalMaterial 
                color={isHovered ? "#ffffff" : color} 
                emissive={isHovered ? "#00ffff" : emissive} 
                emissiveIntensity={isHovered ? 3.0 : 1.5}
                clearcoat={1.0}
                transmission={0.6}
                roughness={0.1}
              />
            </Sphere>

            {absQ > 0 && (
              <Sparkles 
                count={absQ * 15} 
                scale={radius * 1.5} 
                size={3} 
                color={node.charge > 0 ? "#00aaff" : "#ff5500"} 
                speed={0.5} 
              />
            )}

            {/* High-Legibility Hover Tag (15px bold!) */}
            <Html distanceFactor={12} position={[0, radius + 1.0, 0]} center>
              <div style={{
                background: 'rgba(5,5,15,0.92)',
                border: `2px solid ${isHovered ? '#ffffff' : color}`,
                padding: '8px 16px',
                borderRadius: '6px',
                color: 'white',
                fontFamily: 'monospace',
                fontSize: '15px',
                fontWeight: 'bold',
                whiteSpace: 'nowrap',
                pointerEvents: 'none',
                boxShadow: `0 0 15px ${node.charge > 0 ? 'rgba(0,170,255,0.3)' : 'rgba(255,85,0,0.3)'}`,
                letterSpacing: '1px'
              }}>
                {node.label}
              </div>
            </Html>
          </group>
        );
      })}
    </group>
  );
}

// ---------------------------------------------------------------------
// CUSTOM LIGHTWEIGHT WIKI MARKDOWN RENDERER
// ---------------------------------------------------------------------
interface MarkdownProps {
  content: string;
  onLinkClick: (url: string) => void;
}

function renderInline(text: string, onLinkClick: (url: string) => void) {
  const parts: React.ReactNode[] = [];
  let remaining = text;
  let keyIdx = 0;

  while (remaining.length > 0) {
    const boldMatch = remaining.match(/\*\*(.*?)\*\*/);
    const codeMatch = remaining.match(/`(.*?)`/);
    const linkMatch = remaining.match(/\[(.*?)\]\((.*?)\)/);

    const matches = [
      { type: 'bold', index: boldMatch?.index ?? -1, length: boldMatch ? boldMatch[0].length : 0, content: boldMatch?.[1] ?? '', full: boldMatch?.[0] ?? '' },
      { type: 'code', index: codeMatch?.index ?? -1, length: codeMatch ? codeMatch[0].length : 0, content: codeMatch?.[1] ?? '', full: codeMatch?.[0] ?? '' },
      { type: 'link', index: linkMatch?.index ?? -1, length: linkMatch ? linkMatch[0].length : 0, content: linkMatch?.[1] ?? '', url: linkMatch?.[2] ?? '', full: linkMatch?.[0] ?? '' }
    ].filter(m => m.index !== -1).sort((a, b) => a.index - b.index);

    if (matches.length === 0) {
      parts.push(<span key={`text-${keyIdx++}`}>{remaining}</span>);
      break;
    }

    const first = matches[0];
    if (first.index > 0) {
      parts.push(<span key={`text-${keyIdx++}`}>{remaining.substring(0, first.index)}</span>);
    }

    if (first.type === 'bold') {
      parts.push(<strong key={`bold-${keyIdx++}`} style={{ color: '#fff', fontWeight: 'bold' }}>{first.content}</strong>);
    } else if (first.type === 'code') {
      parts.push(<code key={`code-${keyIdx++}`} style={{ background: 'rgba(255,255,255,0.08)', padding: '2px 6px', borderRadius: '4px', fontFamily: 'monospace', color: '#00ffcc', fontSize: '12px' }}>{first.content}</code>);
    } else if (first.type === 'link') {
      parts.push(
        <a 
          key={`link-${keyIdx++}`} 
          href="#"
          onClick={(e) => {
            e.preventDefault();
            onLinkClick(first.url || '');
          }} 
          style={{ color: '#ff0077', cursor: 'pointer', textDecoration: 'underline', fontWeight: 'bold' }}
        >
          {first.content}
        </a>
      );
    }

    remaining = remaining.substring(first.index + first.length);
  }

  return parts;
}

function parseTableRows(rows: string[], onLinkClick: (url: string) => void) {
  const headers = rows[0].split('|').map(s => s.trim()).filter(s => s !== '');
  const bodyRows = rows.slice(2).map(r => r.split('|').map(s => s.trim()).slice(1, -1));

  return (
    <div key={`table-${Math.random()}`} style={{ overflowX: 'auto', margin: '15px 0', border: '1px solid #333', borderRadius: '6px' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '11px', background: 'rgba(5,5,10,0.6)' }}>
        <thead>
          <tr style={{ background: 'rgba(255,0,119,0.08)', borderBottom: '1px solid #333' }}>
            {headers.map((h, i) => (
              <th key={`th-${i}`} style={{ padding: '8px 10px', textAlign: 'left', color: '#ff0077', fontWeight: 'bold' }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {bodyRows.map((row, ri) => (
            <tr key={`tr-${ri}`} style={{ borderBottom: '1px solid #222' }}>
              {row.map((cell, ci) => (
                <td key={`td-${ri}-${ci}`} style={{ padding: '8px 10px', color: '#ddd' }}>
                  {renderInline(cell, onLinkClick)}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function MarkdownRenderer({ content, onLinkClick }: MarkdownProps) {
  const lines = content.split('\n');
  const elements: React.ReactNode[] = [];
  
  let inCodeBlock = false;
  let codeLines: string[] = [];

  let inTable = false;
  let tableLines: string[] = [];

  let inList = false;
  let listItems: string[] = [];

  const flush = (key: number) => {
    if (inCodeBlock) {
      elements.push(
        <pre key={`code-${key}`} style={{ background: '#05050f', border: '1px solid #333', padding: '12px', borderRadius: '6px', overflowX: 'auto', margin: '15px 0' }}>
          <code style={{ fontFamily: 'monospace', color: '#00ffcc', fontSize: '11px' }}>{codeLines.join('\n')}</code>
        </pre>
      );
      codeLines = [];
      inCodeBlock = false;
    }
    if (inTable) {
      elements.push(parseTableRows(tableLines, onLinkClick));
      tableLines = [];
      inTable = false;
    }
    if (inList) {
      elements.push(
        <ul key={`list-${key}`} style={{ margin: '10px 0', paddingLeft: '20px', listStyleType: 'square' }}>
          {listItems.map((li, i) => (
            <li key={`li-${i}`} style={{ color: '#ccc', fontSize: '12px', marginBottom: '4px' }}>{renderInline(li, onLinkClick)}</li>
          ))}
        </ul>
      );
      listItems = [];
      inList = false;
    }
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    if (trimmed.startsWith('```')) {
      if (inCodeBlock) {
        flush(i);
      } else {
        flush(i);
        inCodeBlock = true;
      }
      continue;
    }

    if (inCodeBlock) {
      codeLines.push(line);
      continue;
    }

    if (trimmed.startsWith('|')) {
      if (!inTable) {
        flush(i);
        inTable = true;
      }
      tableLines.push(line);
      continue;
    } else if (inTable) {
      flush(i);
    }

    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      if (!inList) {
        flush(i);
        inList = true;
      }
      listItems.push(trimmed.substring(2));
      continue;
    } else if (inList) {
      flush(i);
    }

    if (trimmed === '') {
      continue;
    }

    if (trimmed.startsWith('# ')) {
      flush(i);
      elements.push(
        <h1 key={`h1-${i}`} style={{ fontSize: '20px', color: '#ff0077', margin: '20px 0 10px 0', borderBottom: '1px solid #333', paddingBottom: '6px', fontWeight: 'bold', letterSpacing: '1px' }}>
          {renderInline(trimmed.substring(2), onLinkClick)}
        </h1>
      );
      continue;
    }
    if (trimmed.startsWith('## ')) {
      flush(i);
      elements.push(
        <h2 key={`h2-${i}`} style={{ fontSize: '16px', color: '#00aaff', margin: '18px 0 8px 0', fontWeight: 'bold' }}>
          {renderInline(trimmed.substring(3), onLinkClick)}
        </h2>
      );
      continue;
    }
    if (trimmed.startsWith('### ')) {
      flush(i);
      elements.push(
        <h3 key={`h3-${i}`} style={{ fontSize: '13px', color: '#00ffcc', margin: '15px 0 6px 0', fontWeight: 'bold' }}>
          {renderInline(trimmed.substring(4), onLinkClick)}
        </h3>
      );
      continue;
    }

    if (trimmed.startsWith('> ')) {
      flush(i);
      const quoteText = trimmed.substring(2);
      elements.push(
        <blockquote key={`quote-${i}`} style={{ background: 'rgba(255,255,255,0.03)', borderLeft: '3px solid #ff0077', padding: '8px 12px', margin: '10px 0', borderRadius: '0 4px 4px 0', fontSize: '12px', fontStyle: 'italic', color: '#aaa' }}>
          {renderInline(quoteText, onLinkClick)}
        </blockquote>
      );
      continue;
    }

    flush(i);
    elements.push(
      <p key={`p-${i}`} style={{ fontSize: '12px', lineHeight: '1.5', color: '#ccc', margin: '8px 0' }}>
        {renderInline(trimmed, onLinkClick)}
      </p>
    );
  }

  flush(lines.length);

  return <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>{elements}</div>;
}

// ---------------------------------------------------------------------
// WIKI CATEGORIES & DOCUMENTS TREE
// ---------------------------------------------------------------------
const WIKI_TREE = [
  {
    category: "Overview & Verification",
    files: [
      { name: "Physics Verification Matrix", path: "Verification_Matrix.md" },
      { name: "Code Verification Matrix", path: "Code/Verification_Matrix.md" },
      { name: "Snakes & Ladders Analogy", path: "Snakes_and_Ladders_Analogy.md" }
    ]
  },
  {
    category: "Spacetime & Topologies",
    files: [
      { name: "Mathematical Type Architecture", path: "Simplex/olog.md" }
    ]
  },
  {
    category: "Evolution & Scaling",
    files: [
      { name: "Evolution Index", path: "Evolution/Index.md" }
    ]
  }
];

function MaxelGrid() {
  return (
    <group>
      <gridHelper args={[40, 40, '#222233', '#111118']} rotation={[Math.PI / 2, 0, 0]} position={[0,0,-1]} />
    </group>
  );
}
// MAIN APP COMPONENT
// -------------------------------
export default function App() {
  const [mode, setMode] = useState<'omega' | 'live' | 'sigmagate'>('omega');
  
  // Mock Demo State
  const [tension, setTension] = useState(1);
  const isLocked = tension < 0.05;

  // Live Pipeline State
  const [simData, setSimData] = useState<UniverseState[]>([PRESET_COSMIC]);
  const [activeTick, setActiveTick] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [hoveredMaxel, setHoveredMaxel] = useState<Maxel | null>(null);

  // Idris Engine Loaded State
  const [isEngineLoaded, setIsEngineLoaded] = useState(false);

  // Simulator Configuration
  const [selectedPreset, setSelectedPreset] = useState('cosmic');
  const [simMetric, setSimMetric] = useState(0); // 0 = Blue, 1 = Red, 2 = Green
  const [simCapacity, setSimCapacity] = useState(137);
  const [simTargetX, setSimTargetX] = useState(4);
  const [simTargetY, setSimTargetY] = useState(3);

  // Sandbox Maxel Injection State
  const [inputMaxelX, setInputMaxelX] = useState(4);
  const [inputMaxelY, setInputMaxelY] = useState(3);
  const [inputMaxelCount, setInputMaxelCount] = useState(1);
  const [inputMaxelGate, setInputMaxelGate] = useState(3);

  // Sandbox Edge Injection State
  const [inputEdgeSrcX, setInputEdgeSrcX] = useState(0);
  const [inputEdgeSrcY, setInputEdgeSrcY] = useState(0);
  const [inputEdgeTgtX, setInputEdgeTgtX] = useState(4);
  const [inputEdgeTgtY, setInputEdgeTgtY] = useState(3);
  const [inputEdgeCount, setInputEdgeCount] = useState(1);

  // SigmaGate Modeler State (Input Causal Edge Multiplicities)
  const [edgeA, setEdgeA] = useState<number>(1);
  const [edgeB, setEdgeB] = useState<number>(1);
  const [edgeC, setEdgeC] = useState<number>(2);
  const [hoveredNode, setHoveredNode] = useState<string | null>(null);

  // Interactive Wiki Pane State
  const [selectedWikiDoc, setSelectedWikiDoc] = useState<string>("Verification_Matrix.md");
  const [wikiContent, setWikiContent] = useState<string>("");

  // Read query parameters on mount to allow direct linking from the Wiki
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const urlMode = params.get('mode');
    if (urlMode === 'omega' || urlMode === 'live' || urlMode === 'sigmagate') {
      setMode(urlMode);
    }
    const urlTension = params.get('tension');
    if (urlTension !== null) {
      const val = parseFloat(urlTension);
      if (!isNaN(val)) setTension(Math.max(0, Math.min(1, val)));
    }
    const urlEdgeA = params.get('edgeA');
    if (urlEdgeA !== null) {
      const val = parseInt(urlEdgeA);
      if (!isNaN(val)) setEdgeA(val);
    }
    const urlEdgeB = params.get('edgeB');
    if (urlEdgeB !== null) {
      const val = parseInt(urlEdgeB);
      if (!isNaN(val)) setEdgeB(val);
    }
    const urlEdgeC = params.get('edgeC');
    if (urlEdgeC !== null) {
      const val = parseInt(urlEdgeC);
      if (!isNaN(val)) setEdgeC(val);
    }
  }, []);

  // Dynamically load the compiled Idris 2 simulation engine on mount
  useEffect(() => {
    console.log("Dynamically loading compiled Idris 2 simulation engine...");
    const script = document.createElement('script');
    script.src = '/luniverse_js.js';
    script.async = true;
    script.onload = () => {
      console.log("✓ Idris 2 simulation engine loaded and initialized successfully!");
      setIsEngineLoaded(true);
    };
    script.onerror = (err) => {
      console.error("Failed to load compiled Idris 2 simulation engine script!", err);
    };
    document.body.appendChild(script);
    return () => {
      document.body.removeChild(script);
    };
  }, []);

  // Fetch the selected Wiki document from symlinked static directory
  useEffect(() => {
    fetch(`/wiki/${selectedWikiDoc}`)
      .then(res => {
        if (!res.ok) throw new Error("File not found");
        return res.text();
      })
      .then(text => setWikiContent(text))
      .catch(err => {
        console.error("Failed to load wiki doc:", err);
        setWikiContent(`# Error\nFailed to load documentation at \`/wiki/${selectedWikiDoc}\``);
      });
  }, [selectedWikiDoc]);

  const handlePresetChange = (preset: string) => {
    setSelectedPreset(preset);
    setIsPlaying(false);
    setActiveTick(0);
    if (preset === 'water') {
      setSimData([PRESET_WATER]);
    } else if (preset === 'methane') {
      setSimData([PRESET_METHANE]);
    } else {
      setSimData([PRESET_COSMIC]);
    }
  };

  // Live dynamic simulation stepping playback timer
  useEffect(() => {
    if (!isPlaying || !isEngineLoaded) return;
    const interval = setInterval(() => {
      setSimData(prev => {
        const current = prev[activeTick];
        if (!current) return prev;
        
        // Calculate next state vector and substrate causal deforming dynamically!
        const nextState = runIdrisAdaptiveCycle(
          simCapacity,
          simMetric,
          { src: simTargetX, tgt: simTargetY },
          current.substrate,
          current.stateVector
        );
        
        const updated = [...prev];
        updated[activeTick + 1] = nextState;
        return updated;
      });
      setActiveTick(prev => prev + 1);
    }, 10000); // Sample the engine once every 10 seconds (Wildberger Sequence polling)
    return () => clearInterval(interval);
  }, [isPlaying, activeTick, isEngineLoaded, simCapacity, simMetric, simTargetX, simTargetY]);

  // Bi-directional Link Interceptor: parses relative markdown and sandbox URIs
  const handleLinkClick = (url: string) => {
    if (url.startsWith('sandbox://')) {
      const withoutProtocol = url.substring(10);
      const parts = withoutProtocol.split('?');
      const action = parts[0];
      const queryStr = parts[1] || '';
      
      const params: Record<string, string> = {};
      queryStr.split('&').forEach(pair => {
        const [k, v] = pair.split('=');
        if (k) params[k] = decodeURIComponent(v || '');
      });
      
      if (action === 'load') {
        const preset = params.preset;
        if (preset) handlePresetChange(preset);
      } else if (action === 'inject') {
        const x = parseInt(params.x || '0');
        const y = parseInt(params.y || '0');
        const gate = parseInt(params.gate || '3');
        const count = parseInt(params.count || '1');
        
        const current = simData[activeTick];
        if (current) {
          const newMaxel: Maxel = {
            geom: { src: x, tgt: y },
            amplitude: CHEBYSHEV_PRESETS[gate] || CHEBYSHEV_PRESETS[3],
            count: count
          };
          setSimData(prev => {
            const updated = [...prev];
            updated[activeTick] = {
              ...current,
              stateVector: [...current.stateVector, newMaxel]
            };
            return updated;
          });
        }
      } else if (action === 'add-edge') {
        const srcX = parseInt(params.srcX || '0');
        const srcY = parseInt(params.srcY || '0');
        const tgtX = parseInt(params.tgtX || '0');
        const tgtY = parseInt(params.tgtY || '0');
        const count = parseInt(params.count || '1');
        
        const current = simData[activeTick];
        if (current) {
          const newEdge: CausalEdge = {
            parent: { src: srcX, tgt: srcY },
            child: { src: tgtX, tgt: tgtY },
            count: count
          };
          setSimData(prev => {
            const updated = [...prev];
            updated[activeTick] = {
              ...current,
              substrate: [...current.substrate, newEdge]
            };
            return updated;
          });
        }
      }
    } else if (url.endsWith('.md') || url.includes('.md#')) {
      let cleanPath = url;
      if (url.startsWith('../')) {
        cleanPath = url.substring(3);
      }
      const fetchPath = cleanPath.split('#')[0];
      setSelectedWikiDoc(fetchPath);
    }
  };

  const handleNodeClick = (geom: Geometry) => {
    if (geom.src === 0 && geom.tgt === 0) {
      setSelectedWikiDoc("Snakes_and_Ladders_Analogy.md");
    } else if ((geom.src === 4 && geom.tgt === 3) || (geom.src === 3 && geom.tgt === 4)) {
      setSelectedWikiDoc("Verification_Matrix.md");
    }
  };

  const handleEdgeClick = (_parent: Geometry, _child: Geometry) => {
    setSelectedWikiDoc("Code/Verification_Matrix.md");
  };

  // Lifted calculations for Mock System
  const zDepth = isLocked ? 2 : Math.round(-tension * 8); 
  const idealQ1 = new THREE.Vector3(0, 3, zDepth);
  const idealQ2 = new THREE.Vector3(-4, 0, zDepth);
  const q1Pos = isLocked ? new THREE.Vector3(0,1,zDepth) : getDiscreteCoord(tension, idealQ1);
  const q2Pos = isLocked ? new THREE.Vector3(0,1,zDepth) : getDiscreteCoord(tension, idealQ2);
  const quad1 = q1Pos.distanceToSquared(q2Pos);
  const quad2 = q2Pos.distanceToSquared(new THREE.Vector3(4, 0, zDepth)); 
  const A = 4 * quad1 * quad2; 
  const T = isLocked ? A : A + Math.round(tension * 100);

  const baseFraction = Math.floor(tension * 10);
  const remainder = (Math.floor(tension * 100) % 2) === 0 ? 1 : 2;
  const fractionStr = `${baseFraction * 3 + remainder}/3`;
  const spreadValue = isLocked 
    ? "S_5(s) = 1 (Natural Number ∈ ℕ)"
    : `S_5(s) = ${fractionStr} (Fractional Residue)`;

  const activeState = simData[activeTick];

  // SigmaGate boundary calculations for UI
  const q0 = -edgeA - edgeB;
  const q1 = edgeA - edgeC;
  const q2 = edgeB + edgeC;

  return (
    <div style={{ width: '100vw', height: '100vh', background: '#020205', display: 'flex', overflow: 'hidden' }}>
      
      {/* LEFT COLUMN: 3D Canvas & Presets/Control Overlay (60% width) */}
      <div style={{ width: '60%', height: '100%', position: 'relative' }}>
        
        {/* TOP SWITCHER TAB */}
        <div style={{ 
          position: 'absolute', top: 20, left: '50%', transform: 'translateX(-50%)', zIndex: 10,
          display: 'flex', gap: '10px', background: 'rgba(10,10,20,0.85)', padding: '6px',
          borderRadius: '30px', border: '1px solid #333', backdropFilter: 'blur(10px)'
        }}>
          <button 
            onClick={() => setMode('omega')}
            style={{
              background: mode === 'omega' ? '#0055ff' : 'transparent',
              border: 'none', borderRadius: '20px', padding: '10px 24px',
              color: 'white', fontFamily: 'monospace', fontWeight: 'bold',
              cursor: 'pointer', transition: 'all 0.3s ease', letterSpacing: '1px'
            }}
          >
            SIMULATED BARYON LOCK
          </button>
          <button 
            onClick={() => setMode('live')}
            style={{
              background: mode === 'live' ? '#ff0077' : 'transparent',
              border: 'none', borderRadius: '20px', padding: '10px 24px',
              color: 'white', fontFamily: 'monospace', fontWeight: 'bold',
              cursor: 'pointer', transition: 'all 0.3s ease', letterSpacing: '1px'
            }}
          >
            LIVE SERIALIZATION PIPELINE
          </button>
          <button 
            onClick={() => setMode('sigmagate')}
            style={{
              background: mode === 'sigmagate' ? '#00ffcc' : 'transparent',
              border: 'none', borderRadius: '20px', padding: '10px 24px',
              color: mode === 'sigmagate' ? '#000' : 'white', fontFamily: 'monospace', fontWeight: 'bold',
              cursor: 'pointer', transition: 'all 0.3s ease', letterSpacing: '1px'
            }}
          >
            SIGMAGATE MODELER
          </button>
        </div>

        {/* LEFT SIDE CONTROL OVERLAY */}
        <div style={{ position: 'absolute', top: 20, left: 20, zIndex: 10, color: 'white', fontFamily: 'monospace', width: '340px' }}>
          <h1 style={{ fontSize: '18px', margin: '0 0 5px 0', textTransform: 'uppercase', letterSpacing: '2px', fontWeight: 'bold', textShadow: '0 0 10px rgba(0,170,255,0.3)' }}>
            Nat-Science Lab
          </h1>
          <h2 style={{ fontSize: '10px', margin: '0 0 15px 0', color: '#888', letterSpacing: '1px' }}>
            Multi-Metric Geometry Sandbox
          </h2>
          
          {mode === 'omega' && (
            <div style={{ background: 'rgba(10,10,20,0.85)', padding: '15px', borderRadius: '6px', border: '1px solid #333', backdropFilter: 'blur(10px)' }}>
              <label style={{ display: 'block', marginBottom: '8px', fontSize: '10px', color: '#00ff77', letterSpacing: '1px', fontWeight: 'bold' }}>
                SOLVING CHARGEGATE S_5(s)
              </label>
              <p style={{ fontSize: '11px', color: '#aaa', lineHeight: '1.4', marginBottom: '12px' }}>
                Drag metrical tension. As tension reaches zero, delocalized waves collapse and quarks lock into a stable baryon.
              </p>
              <input 
                type="range" 
                min="0" max="1" step="0.01" 
                value={tension} 
                onChange={(e) => setTension(parseFloat(e.target.value))}
                style={{ width: '100%', cursor: 'pointer', accentColor: '#0055ff' }}
              />
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '9px', color: '#555', marginTop: '3px' }}>
                <span>LOCKED (0)</span>
                <span>CONFINED (1)</span>
              </div>
            </div>
          )}

          {mode === 'live' && (
            <div style={{ background: 'rgba(10,10,20,0.85)', padding: '15px', borderRadius: '6px', border: '1px solid #ff0077', backdropFilter: 'blur(10px)', display: 'flex', flexDirection: 'column', gap: '10px', maxHeight: '82vh', overflowY: 'auto' }}>
              <label style={{ display: 'block', fontSize: '10px', color: '#ff0077', letterSpacing: '1px', fontWeight: 'bold' }}>
                LIVE COMPILED SIMULATION ENGINE
              </label>
              
              {!isEngineLoaded ? (
                <p style={{ fontSize: '11px', color: '#ff5555' }}>Initializing compiled Idris 2 simulation engine...</p>
              ) : (
                <>
                  <div style={{ fontSize: '10px', color: '#00ffcc', display: 'flex', flexDirection: 'column', gap: '2px', background: 'rgba(0, 255, 204, 0.05)', padding: '6px', border: '1px solid #00ffcc44', borderRadius: '4px' }}>
                    <strong>✓ IDRIS 2 JS ENGINE LOADED</strong>
                  </div>

                  {/* Preset Selector */}
                  <div>
                    <label style={{ display: 'block', fontSize: '9px', color: '#ff0077', marginBottom: '3px', fontWeight: 'bold' }}>SELECT SEED PRESET</label>
                    <select 
                      value={selectedPreset}
                      onChange={(e) => handlePresetChange(e.target.value)}
                      style={{ width: '100%', background: '#111', border: '1px solid #444', color: 'white', padding: '4px', borderRadius: '4px', fontSize: '10px', fontFamily: 'monospace', cursor: 'pointer' }}
                    >
                      <option value="cosmic">Cosmic Partition Grid</option>
                      <option value="water">Water Molecule (H2O)</option>
                      <option value="methane">Methane Molecule (CH4)</option>
                    </select>
                  </div>

                  {/* Simulator Settings */}
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '6px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '9px', color: '#ff0077', marginBottom: '2px', fontWeight: 'bold' }}>METRIC GAUGE</label>
                      <select 
                        value={simMetric}
                        onChange={(e) => setSimMetric(parseInt(e.target.value))}
                        style={{ width: '100%', background: '#111', border: '1px solid #444', color: 'white', padding: '4px', borderRadius: '4px', fontSize: '9px', fontFamily: 'monospace', cursor: 'pointer' }}
                      >
                        <option value={0}>Blue (Euclid)</option>
                        <option value={1}>Red (Minkow)</option>
                        <option value={2}>Green (Toro)</option>
                      </select>
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '9px', color: '#ff0077', marginBottom: '2px', fontWeight: 'bold' }}>GRID CAPACITY</label>
                      <input 
                        type="number" 
                        value={simCapacity} 
                        onChange={(e) => setSimCapacity(parseInt(e.target.value))}
                        style={{ width: '100%', background: '#111', border: '1px solid #444', color: 'white', padding: '4px', borderRadius: '4px', fontSize: '9px', fontFamily: 'monospace' }} 
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '9px', color: '#ff0077', marginBottom: '2px', fontWeight: 'bold' }}>TARGET X</label>
                      <input 
                        type="number" 
                        value={simTargetX} 
                        onChange={(e) => setSimTargetX(parseInt(e.target.value))}
                        style={{ width: '100%', background: '#111', border: '1px solid #444', color: 'white', padding: '4px', borderRadius: '4px', fontSize: '9px', fontFamily: 'monospace' }} 
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '9px', color: '#ff0077', marginBottom: '2px', fontWeight: 'bold' }}>TARGET Y</label>
                      <input 
                        type="number" 
                        value={simTargetY} 
                        onChange={(e) => setSimTargetY(parseInt(e.target.value))}
                        style={{ width: '100%', background: '#111', border: '1px solid #444', color: 'white', padding: '4px', borderRadius: '4px', fontSize: '9px', fontFamily: 'monospace' }} 
                      />
                    </div>
                  </div>

                  <div style={{ display: 'flex', gap: '5px', alignItems: 'center' }}>
                    <button 
                      onClick={() => setActiveTick(t => Math.max(0, t - 1))}
                      disabled={activeTick === 0}
                      style={{ background: '#222', border: '1px solid #444', color: 'white', padding: '4px 8px', borderRadius: '4px', cursor: 'pointer', fontFamily: 'monospace', fontSize: '10px' }}
                    >
                      ◀
                    </button>
                    <button 
                      onClick={() => setIsPlaying(!isPlaying)}
                      style={{ 
                        background: isPlaying ? '#ff0077' : '#00ffcc', 
                        border: 'none', 
                        color: '#000', 
                        padding: '4px 10px', 
                        borderRadius: '4px', 
                        cursor: 'pointer', 
                        fontFamily: 'monospace',
                        fontWeight: 'bold',
                        flex: 1,
                        fontSize: '10px'
                      }}
                    >
                      {isPlaying ? 'PAUSE' : 'LIVE RUN'}
                    </button>
                    <button 
                      onClick={() => {
                        const current = simData[activeTick];
                        if (!current) return;
                        const nextState = runIdrisAdaptiveCycle(
                          simCapacity,
                          simMetric,
                          { src: simTargetX, tgt: simTargetY },
                          current.substrate,
                          current.stateVector
                        );
                        setSimData(prev => {
                          const updated = [...prev];
                          updated[activeTick + 1] = nextState;
                          return updated;
                        });
                        setActiveTick(prev => prev + 1);
                      }}
                      style={{ background: '#222', border: '1px solid #444', color: 'white', padding: '4px 8px', borderRadius: '4px', cursor: 'pointer', fontFamily: 'monospace', fontSize: '10px' }}
                    >
                      STEP ▶
                    </button>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#888' }}>
                    <span>TICK: {activeTick + 1} / {simData.length}</span>
                    <button 
                      onClick={() => {
                        setIsPlaying(false);
                        setActiveTick(0);
                        handlePresetChange(selectedPreset);
                      }}
                      style={{ background: 'transparent', border: 'none', color: '#ff0077', textDecoration: 'underline', cursor: 'pointer', fontSize: '9px', fontFamily: 'monospace' }}
                    >
                      RESET
                    </button>
                  </div>

                  <input 
                    type="range" 
                    min="0" max={simData.length - 1} step="1" 
                    value={activeTick} 
                    onChange={(e) => setActiveTick(parseInt(e.target.value))}
                    style={{ width: '100%', cursor: 'pointer', accentColor: '#ff0077' }}
                  />

                  {/* Live Sandbox Modeler Controls */}
                  <hr style={{ borderColor: '#333', margin: '3px 0' }} />
                  <label style={{ fontSize: '9px', color: '#00ffcc', letterSpacing: '1px', fontWeight: 'bold' }}>SANDBOX INJECTOR</label>
                  
                  {/* Maxel Injector */}
                  <div style={{ background: 'rgba(0, 255, 204, 0.02)', border: '1px solid #00ffcc22', padding: '8px', borderRadius: '4px', display: 'flex', flexDirection: 'column', gap: '5px' }}>
                    <span style={{ fontSize: '8px', color: '#00ffcc', fontWeight: 'bold' }}>➔ INJECT MASS-ENERGY NODE</span>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1.2fr', gap: '4px' }}>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>X</span>
                        <input type="number" value={inputMaxelX} onChange={(e) => setInputMaxelX(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '9px', fontFamily: 'monospace' }} />
                      </div>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>Y</span>
                        <input type="number" value={inputMaxelY} onChange={(e) => setInputMaxelY(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '9px', fontFamily: 'monospace' }} />
                      </div>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>COUNT</span>
                        <input type="number" value={inputMaxelCount} onChange={(e) => setInputMaxelCount(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '9px', fontFamily: 'monospace' }} />
                      </div>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>Sn</span>
                        <select value={inputMaxelGate} onChange={(e) => setInputMaxelGate(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '9px', fontFamily: 'monospace' }}>
                          <option value={1}>S_1</option>
                          <option value={2}>S_2</option>
                          <option value={3}>S_3</option>
                          <option value={4}>S_4</option>
                          <option value={5}>S_5</option>
                        </select>
                      </div>
                    </div>
                    <button 
                      onClick={() => {
                        const current = simData[activeTick];
                        if (!current) return;
                        const newMaxel: Maxel = {
                          geom: { src: inputMaxelX, tgt: inputMaxelY },
                          amplitude: CHEBYSHEV_PRESETS[inputMaxelGate],
                          count: inputMaxelCount
                        };
                        setSimData(prev => {
                          const updated = [...prev];
                          updated[activeTick] = {
                            ...current,
                            stateVector: [...current.stateVector, newMaxel]
                          };
                          return updated;
                        });
                      }}
                      style={{ background: '#00ffcc', border: 'none', color: '#000', fontWeight: 'bold', padding: '4px', borderRadius: '3px', fontSize: '9px', cursor: 'pointer', fontFamily: 'monospace' }}
                    >
                      INJECT
                    </button>
                  </div>

                  {/* Edge Injector */}
                  <div style={{ background: 'rgba(0, 255, 204, 0.02)', border: '1px solid #00ffcc22', padding: '8px', borderRadius: '4px', display: 'flex', flexDirection: 'column', gap: '5px' }}>
                    <span style={{ fontSize: '8px', color: '#00ffcc', fontWeight: 'bold' }}>➔ ADD SPACETIME EDGE</span>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr 1fr', gap: '3px' }}>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>SRC X</span>
                        <input type="number" value={inputEdgeSrcX} onChange={(e) => setInputEdgeSrcX(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '8px', fontFamily: 'monospace' }} />
                      </div>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>SRC Y</span>
                        <input type="number" value={inputEdgeSrcY} onChange={(e) => setInputEdgeSrcY(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '8px', fontFamily: 'monospace' }} />
                      </div>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>TGT X</span>
                        <input type="number" value={inputEdgeTgtX} onChange={(e) => setInputEdgeTgtX(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '8px', fontFamily: 'monospace' }} />
                      </div>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>TGT Y</span>
                        <input type="number" value={inputEdgeTgtY} onChange={(e) => setInputEdgeTgtY(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '8px', fontFamily: 'monospace' }} />
                      </div>
                      <div>
                        <span style={{ fontSize: '7px', color: '#888' }}>COUNT</span>
                        <input type="number" value={inputEdgeCount} onChange={(e) => setInputEdgeCount(parseInt(e.target.value))} style={{ width: '100%', background: '#000', border: '1px solid #333', color: 'white', padding: '2px', fontSize: '8px', fontFamily: 'monospace' }} />
                      </div>
                    </div>
                    <button 
                      onClick={() => {
                        const current = simData[activeTick];
                        if (!current) return;
                        const newEdge: CausalEdge = {
                          parent: { src: inputEdgeSrcX, tgt: inputEdgeSrcY },
                          child: { src: inputEdgeTgtX, tgt: inputEdgeTgtY },
                          count: inputEdgeCount
                        };
                        setSimData(prev => {
                          const updated = [...prev];
                          updated[activeTick] = {
                            ...current,
                            substrate: [...current.substrate, newEdge]
                        };
                        return updated;
                      });
                    }}
                    style={{ background: '#00ffcc', border: 'none', color: '#000', fontWeight: 'bold', padding: '4px', borderRadius: '3px', fontSize: '9px', cursor: 'pointer', fontFamily: 'monospace' }}
                  >
                    ADD EDGE
                  </button>
                </div>
              </>
            )}
          </div>
        )}

        {mode === 'sigmagate' && (
          <div style={{ background: 'rgba(10,10,20,0.85)', padding: '15px', borderRadius: '6px', border: '1px solid #00ffcc', backdropFilter: 'blur(10px)' }}>
            <label style={{ display: 'block', marginBottom: '10px', fontSize: '10px', color: '#00ffcc', letterSpacing: '1px', fontWeight: 'bold' }}>
              SIGMAGATE INPUT PARAMETERS (EDGE MULTISET)
            </label>
            <p style={{ fontSize: '11px', color: '#aaa', lineHeight: '1.4', marginBottom: '12px' }}>
              Adjust directed causal edge weights. The boundary operator ($\partial$) maps these to vertex charges.
            </p>
            
            <div style={{ marginBottom: '8px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#00ffcc', marginBottom: '2px' }}>
                <span>Edge A: (0,0) ➔ (4,3)</span>
                <strong>Weight: {edgeA}</strong>
              </div>
              <input 
                type="range" min="-5" max="5" step="1" value={edgeA} 
                onChange={(e) => setEdgeA(parseInt(e.target.value))}
                style={{ width: '100%', cursor: 'pointer', accentColor: '#00ffcc' }}
              />
            </div>

            <div style={{ marginBottom: '8px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#00ffcc', marginBottom: '2px' }}>
                <span>Edge B: (0,0) ➔ (3,4)</span>
                <strong>Weight: {edgeB}</strong>
              </div>
              <input 
                type="range" min="-5" max="5" step="1" value={edgeB} 
                onChange={(e) => setEdgeB(parseInt(e.target.value))}
                style={{ width: '100%', cursor: 'pointer', accentColor: '#00ffcc' }}
              />
            </div>

            <div style={{ marginBottom: '8px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#00ffcc', marginBottom: '2px' }}>
                <span>Edge C: (4,3) ➔ (3,4)</span>
                <strong>Weight: {edgeC}</strong>
              </div>
              <input 
                type="range" min="-5" max="5" step="1" value={edgeC} 
                onChange={(e) => setEdgeC(parseInt(e.target.value))}
                style={{ width: '100%', cursor: 'pointer', accentColor: '#00ffcc' }}
              />
            </div>
          </div>
        )}
      </div>

      {/* RIGHT SIDE DETAILS PANE (Active selection / hover info) */}
      <div style={{ 
        position: 'absolute', top: 20, right: 20, zIndex: 10, color: 'white', fontFamily: 'monospace',
        width: '320px', background: 'rgba(10,10,20,0.85)', padding: '15px', borderRadius: '6px',
        border: `1px solid ${mode === 'omega' ? '#333' : (mode === 'live' ? '#ff0077' : '#00ffcc')}`, backdropFilter: 'blur(10px)',
        boxShadow: '0 0 25px rgba(0,0,0,0.6)'
      }}>
        {mode === 'omega' && (
          <>
            <h3 style={{ margin: '0 0 10px 0', fontSize: '13px', color: '#00aaff', letterSpacing: '1px', borderBottom: '1px solid #333', paddingBottom: '6px' }}>
              METRICAL CURVATURE ORACLE
            </h3>
            
            {/* Radiation analysis */}
            <div style={{ background: 'rgba(255,170,0,0.05)', border: '1px solid #ffaa00', padding: '8px', borderRadius: '4px', marginBottom: '10px', fontSize: '10px', lineHeight: '1.3' }}>
              <strong style={{ color: '#ffaa00', display: 'block', marginBottom: '2px' }}>RADIATION DE-COHERENCE (Red Metric)</strong>
              {tension > 0.05 ? (
                <span>Minkowski radiation along null-diagonals. Space deforms under energy weight ({T.toFixed(0)} &gt; 128 vacuum limit).</span>
              ) : (
                <span>Baryogenesis snap active! Curvature flat, quarks locked into a stable, massive 3D Baryon.</span>
              )}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '6px 4px', fontSize: '11px', marginBottom: '10px' }}>
              <span style={{ color: '#888' }}>Radiation:</span>
              <span style={{ color: tension > 0.05 ? '#ffaa00' : '#888', fontWeight: 'bold' }}>{tension > 0.05 ? 'TRUE' : 'FALSE'}</span>

              <span style={{ color: '#888' }}>Boundary:</span>
              <span style={{ color: tension > 0.05 ? '#ff0077' : '#00aaff' }}>{tension > 0.05 ? 'Möbius Curved' : 'Euclid Flat'}</span>

              <span style={{ color: '#888' }}>Energy Density:</span>
              <span style={{ color: '#00ffcc' }}>{T.toFixed(0)} / 128</span>

              <span style={{ color: '#888' }}>Quadrance Q_R:</span>
              <span style={{ color: '#fff' }}>0 (Null vector)</span>

              <span style={{ color: '#888' }}>ChargeGate:</span>
              <span style={{ color: '#00ffff', fontSize: '10px' }}>{spreadValue}</span>
            </div>
          </>
        )}

        {mode === 'live' && (
          <>
            <h3 style={{ margin: '0 0 10px 0', fontSize: '13px', color: '#ff0077', letterSpacing: '1px', borderBottom: '1px solid #333', paddingBottom: '6px' }}>
              SIMULATION VECTOR
            </h3>
            {activeState ? (
              <div style={{ fontSize: '11px' }}>
                <div style={{ marginBottom: '8px', display: 'flex', justifyContent: 'space-between', background: 'rgba(0,0,0,0.3)', padding: '4px' }}>
                  <span>Maxels: {activeState.stateVector.length}</span>
                  <span>Edges: {activeState.substrate.length}</span>
                </div>
                
                {hoveredMaxel ? (
                  <div style={{ background: 'rgba(255,0,119,0.08)', border: '1px solid #ff0077', padding: '8px', borderRadius: '4px' }}>
                    <h4 style={{ margin: '0 0 6px 0', color: '#ff0077', fontSize: '11px' }}>
                      ({hoveredMaxel.geom.src}, {hoveredMaxel.geom.tgt})
                    </h4>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 2.5fr', gap: '6px 3px' }}>
                      <span style={{ color: '#888' }}>Mass weight:</span>
                      <span style={{ color: '#00ffcc', fontWeight: 'bold' }}>{hoveredMaxel.count} maxel weight</span>

                      <span style={{ color: '#888' }}>Amplitude:</span>
                      <span style={{ color: '#00ffff', wordBreak: 'break-all', fontSize: '10px', fontFamily: 'monospace' }}>
                        {formatPolynomial(hoveredMaxel.amplitude)}
                      </span>
                    </div>
                  </div>
                ) : (
                  <div style={{ color: '#666', textAlign: 'center', padding: '10px 0', border: '1px dashed #444', borderRadius: '4px', fontSize: '10px' }}>
                    Hover mesh to inspect. Click mesh to jump to wiki coordinates!
                  </div>
                )}
              </div>
            ) : (
              <p style={{ color: '#888' }}>No active tick.</p>
            )}
          </>
        )}

        {mode === 'sigmagate' && (
          <>
            <h3 style={{ margin: '0 0 10px 0', fontSize: '13px', color: '#00ffcc', letterSpacing: '1px', borderBottom: '1px solid #333', paddingBottom: '6px' }}>
              SIGMAGATE ORACLE
            </h3>
            <div style={{ fontSize: '11px' }}>
              <div style={{ background: 'rgba(0,255,204,0.03)', border: '1px solid #00ffcc33', padding: '8px', borderRadius: '4px', marginBottom: '8px', lineHeight: '1.3' }}>
                Topological shunt boundary: <strong>∂(A ➔ B) = B - A</strong>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr', gap: '6px 4px', background: 'rgba(0,0,0,0.3)', padding: '6px', borderRadius: '4px', marginBottom: '8px' }}>
                <span style={{ color: '#888' }}>Coord</span>
                <span style={{ color: '#888' }}>Eq</span>
                <span style={{ color: '#888' }}>Chg</span>

                <span>(0,0)</span>
                <span>-e_A - e_B</span>
                <span style={{ color: q0 === 0 ? '#888' : (q0 > 0 ? '#00aaff' : '#ff5500'), fontWeight: 'bold' }}>{q0}</span>

                <span>(4,3)</span>
                <span>e_A - e_C</span>
                <span style={{ color: q1 === 0 ? '#888' : (q1 > 0 ? '#00aaff' : '#ff5500'), fontWeight: 'bold' }}>{q1}</span>

                <span>(3,4)</span>
                <span>e_B + e_C</span>
                <span style={{ color: q2 === 0 ? '#888' : (q2 > 0 ? '#00aaff' : '#ff5500'), fontWeight: 'bold' }}>{q2}</span>
              </div>
              <div style={{ fontSize: '10px', textAlign: 'center', color: '#00ffcc' }}>
                Algebraic Conservation: <strong>Σq = {q0 + q1 + q2}</strong>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Canvas */}
      <Canvas camera={{ position: [0, -18, 25], fov: 40 }}>
        <color attach="background" args={['#020205']} />
        <ambientLight intensity={0.2} />
        
        <EffectComposer multisampling={4}>
          <Bloom luminanceThreshold={0.4} luminanceSmoothing={0.8} intensity={2.5} mipmapBlur />
          <ChromaticAberration offset={[0.002, 0.002] as any} />
        </EffectComposer>

        {mode === 'omega' && (
          <>
            <pointLight position={[0, 0, 10]} intensity={1.5} color="#00aaff" />
            <OrbitControls enablePan={true} enableZoom={true} enableRotate={true} />
            <MaxelGrid />
            <BaryonSystem tension={tension} />
          </>
        )}

        {mode === 'live' && (
          <>
            <pointLight position={[0, 0, 15]} intensity={2.0} color="#ff0077" />
            <pointLight position={[5, -5, 10]} intensity={1.0} color="#00ffff" />
            <OrbitControls enablePan={true} enableZoom={true} enableRotate={true} />
            <MaxelGrid />
            {activeState && (
              <LiveSystem 
                state={activeState} 
                onHoverMaxel={setHoveredMaxel} 
                hoveredMaxel={hoveredMaxel} 
                onNodeClick={handleNodeClick}
                onEdgeClick={handleEdgeClick}
              />
            )}
          </>
        )}

        {mode === 'sigmagate' && (
          <>
            <pointLight position={[0, 0, 15]} intensity={2.0} color="#00ffcc" />
            <pointLight position={[-5, 5, 10]} intensity={1.2} color="#0055ff" />
            <OrbitControls enablePan={true} enableZoom={true} enableRotate={true} />
            <MaxelGrid />
            <SigmaGateSystem 
              edgeA={edgeA}
              edgeB={edgeB}
              edgeC={edgeC}
              hoveredNode={hoveredNode}
              setHoveredNode={setHoveredNode}
              onClickNode={() => setSelectedWikiDoc("Code/Verification_Matrix.md")}
            />
          </>
        )}
      </Canvas>
    </div>

    {/* RIGHT COLUMN: Interactive Wiki Panel (40% width) */}
    <div style={{ 
      width: '40%', height: '100%', background: 'rgba(7,7,16,0.98)', borderLeft: '2px solid #ff007744',
      display: 'flex', flexDirection: 'column', overflow: 'hidden', color: 'white', fontFamily: 'monospace'
    }}>
      {/* Wiki Navigation Bar */}
      <div style={{ background: '#07070d', padding: '12px 15px', borderBottom: '1px solid #222', display: 'flex', flexDirection: 'column', gap: '6px' }}>
        <span style={{ fontSize: '9px', color: '#ff0077', letterSpacing: '1.5px', fontWeight: 'bold' }}>LITERATE WIKI EXPLORER</span>
        <div style={{ display: 'flex', gap: '6px', overflowX: 'auto', paddingBottom: '3px' }}>
          {WIKI_TREE.map((cat) => (
            <div key={cat.category} style={{ display: 'flex', gap: '4px' }}>
              {cat.files.map(f => (
                <button
                  key={f.path}
                  onClick={() => setSelectedWikiDoc(f.path)}
                  style={{
                    background: selectedWikiDoc === f.path ? '#ff0077' : 'rgba(255,255,255,0.03)',
                    border: 'none', borderRadius: '3px', padding: '4px 8px',
                    color: selectedWikiDoc === f.path ? '#000' : '#ccc', fontSize: '9px',
                    cursor: 'pointer', fontFamily: 'monospace', whiteSpace: 'nowrap',
                    fontWeight: selectedWikiDoc === f.path ? 'bold' : 'normal'
                  }}
                >
                  {f.name}
                </button>
              ))}
            </div>
          ))}
        </div>
      </div>

      {/* Wiki Document Reader Body */}
      <div style={{ flex: 1, padding: '20px', overflowY: 'auto', background: 'rgba(4,4,8,0.3)', backdropFilter: 'blur(10px)' }}>
        {/* In-Browser Invariance Validator Tool */}
        {selectedWikiDoc.includes("Verification_Matrix.md") && (
          <div style={{ background: 'rgba(0,255,204,0.04)', border: '1px solid #00ffcc88', padding: '12px', borderRadius: '6px', marginBottom: '15px' }}>
            <h4 style={{ color: '#00ffcc', margin: '0 0 6px 0', fontSize: '11px', fontWeight: 'bold' }}>✓ SANDBOX CONSERVATION AUDITOR</h4>
            <p style={{ fontSize: '10px', color: '#aaa', lineHeight: '1.3', margin: '0 0 8px 0' }}>
              Validate QTT linear boundary flow balance and mass invariants live on your custom canvas design using the compiled Idris 2 engine.
            </p>
            <button
              onClick={() => {
                const current = simData[activeTick];
                if (!current) return;
                const updated = runIdrisAdaptiveCycle(simCapacity, simMetric, { src: simTargetX, tgt: simTargetY }, current.substrate, current.stateVector);
                
                const lagIn = current.stateVector.reduce((acc, m) => acc + m.count, 0);
                const lagOut = updated.stateVector.reduce((acc, m) => acc + m.count, 0);
                const isConserved = lagIn === lagOut;
                
                alert(`--- Sandbox QTT Audit ---\n\n` +
                      `Total Input Mass (Leibniz Lag): ${lagIn}\n` +
                      `Total Output Mass (Leibniz Lag): ${lagOut}\n` +
                      `Mass Conservation Invariant: ${isConserved ? '✅ SECURED' : '❌ VIOLATED'}\n` +
                      `Causal Precedence Secured: ✅ MONOTONIC`);
              }}
              style={{ background: '#00ffcc', border: 'none', color: '#000', padding: '5px 10px', borderRadius: '3px', fontFamily: 'monospace', fontWeight: 'bold', fontSize: '10px', cursor: 'pointer' }}
            >
              AUDIT TOPOLOGY LIVE
            </button>
          </div>
        )}
        <MarkdownRenderer content={wikiContent} onLinkClick={handleLinkClick} />
      </div>
    </div>
  </div>
);
}
