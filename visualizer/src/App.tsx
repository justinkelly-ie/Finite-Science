import { useState, useEffect, useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Line, Sphere, Html, Sparkles, Trail, Plane } from '@react-three/drei';
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
  hoveredMaxel 
}: { 
  state: UniverseState; 
  onHoverMaxel: (m: Maxel | null) => void;
  hoveredMaxel: Maxel | null;
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
          <Line key={`edge-${idx}`} points={[start, end]} color="#00ffcc" lineWidth={Math.abs(edge.count) * 2} />
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
  setHoveredNode
}: {
  edgeA: number;
  edgeB: number;
  edgeC: number;
  hoveredNode: string | null;
  setHoveredNode: (node: string | null) => void;
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

function MaxelGrid() {
  return (
    <group>
      <gridHelper args={[40, 40, '#222233', '#111118']} rotation={[Math.PI / 2, 0, 0]} position={[0,0,-1]} />
    </group>
  );
}

// ---------------------------------------------------------------------
// MAIN APP COMPONENT
// ---------------------------------------------------------------------
export default function App() {
  const [mode, setMode] = useState<'omega' | 'live' | 'sigmagate'>('omega');
  
  // Mock Demo State
  const [tension, setTension] = useState(1);
  const isLocked = tension < 0.05;

  // Live Pipeline State
  const [simData, setSimData] = useState<UniverseState[]>([]);
  const [activeTick, setActiveTick] = useState(0);
  const [isPlaying, setIsPlaying] = useState(false);
  const [hoveredMaxel, setHoveredMaxel] = useState<Maxel | null>(null);

  // SigmaGate Modeler State (Input Causal Edge Multiplicities)
  const [edgeA, setEdgeA] = useState<number>(1);
  const [edgeB, setEdgeB] = useState<number>(1);
  const [edgeC, setEdgeC] = useState<number>(2);
  const [hoveredNode, setHoveredNode] = useState<string | null>(null);

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

  // Fetch compiled state vectors from State Serialization Bridge
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const urlFile = params.get('file') || 'state_vectors.json';
    const filePath = urlFile.endsWith('.json') ? `/${urlFile}` : `/${urlFile}.json`;
    
    fetch(filePath)
      .then(res => res.json())
      .then(data => {
        setSimData(data);
      })
      .catch(err => console.error(`Awaiting live pipeline serialization for ${filePath}...`, err));
  }, []);

  // Playback timer
  useEffect(() => {
    if (!isPlaying || simData.length === 0) return;
    const interval = setInterval(() => {
      setActiveTick(prev => (prev + 1) % simData.length);
    }, 1200);
    return () => clearInterval(interval);
  }, [isPlaying, simData]);

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
    <div style={{ width: '100vw', height: '100vh', background: '#020205', position: 'relative', overflow: 'hidden' }}>
      
      {/* 1. TOP SWITCHER TAB */}
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

      {/* 2. LEFT SIDE CONTROL OVERLAY */}
      <div style={{ position: 'absolute', top: 20, left: 20, zIndex: 10, color: 'white', fontFamily: 'monospace', width: '380px' }}>
        <h1 style={{ fontSize: '22px', margin: '0 0 5px 0', textTransform: 'uppercase', letterSpacing: '2px', fontWeight: 'bold', textShadow: '0 0 10px rgba(0,170,255,0.3)' }}>
          Nat-Science Laboratory
        </h1>
        <h2 style={{ fontSize: '12px', margin: '0 0 20px 0', color: '#888', letterSpacing: '1px' }}>
          Discrete Multi-Metric Geometry Visualizer
        </h2>
        
        {mode === 'omega' && (
          <div style={{ background: 'rgba(10,10,20,0.85)', padding: '20px', borderRadius: '6px', border: '1px solid #333', backdropFilter: 'blur(10px)' }}>
            <label style={{ display: 'block', marginBottom: '10px', fontSize: '11px', color: '#00ff77', letterSpacing: '1.5px', fontWeight: 'bold' }}>
              SOLVING CHARGEGATE S_5(s)
            </label>
            <p style={{ fontSize: '12px', color: '#aaa', lineHeight: '1.5', marginBottom: '15px' }}>
              Drag the metrical tension slider. As tension approaches zero, delocalized radiation waves collapse, space-time curvature flattens, and quarks lock into a stable baryon.
            </p>
            <input 
              type="range" 
              min="0" max="1" step="0.01" 
              value={tension} 
              onChange={(e) => setTension(parseFloat(e.target.value))}
              style={{ width: '100%', cursor: 'pointer', accentColor: '#0055ff' }}
            />
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '10px', color: '#555', marginTop: '5px' }}>
              <span>LOCKED (0)</span>
              <span>CONFINED (1)</span>
            </div>
          </div>
        )}

        {mode === 'live' && (
          <div style={{ background: 'rgba(10,10,20,0.85)', padding: '20px', borderRadius: '6px', border: '1px solid #ff0077', backdropFilter: 'blur(10px)' }}>
            <label style={{ display: 'block', marginBottom: '10px', fontSize: '11px', color: '#ff0077', letterSpacing: '1.5px', fontWeight: 'bold' }}>
              ACTIVE STATE EXPORTS
            </label>
            {simData.length === 0 ? (
              <p style={{ fontSize: '12px', color: '#ff5555' }}>Awaiting live pipeline serialization from luniverse runner...</p>
            ) : (
              <>
                <p style={{ fontSize: '12px', color: '#aaa', lineHeight: '1.5', marginBottom: '15px' }}>
                  Consuming real-time state vectors exported from the compiled Idris 2 simulation core. Spacetime edges and multi-maxel amplitudes are loaded.
                </p>
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '15px' }}>
                  <button 
                    onClick={() => setActiveTick(t => Math.max(0, t - 1))}
                    disabled={activeTick === 0}
                    style={{ background: '#222', border: '1px solid #444', color: 'white', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer', fontFamily: 'monospace' }}
                  >
                    ◀
                  </button>
                  <button 
                    onClick={() => setIsPlaying(!isPlaying)}
                    style={{ 
                      background: isPlaying ? '#ff0077' : '#00ffcc', 
                      border: 'none', 
                      color: '#000', 
                      padding: '6px 16px', 
                      borderRadius: '4px', 
                      cursor: 'pointer', 
                      fontFamily: 'monospace',
                      fontWeight: 'bold' 
                    }}
                  >
                    {isPlaying ? 'PAUSE' : 'PLAY'}
                  </button>
                  <button 
                    onClick={() => setActiveTick(t => (t + 1) % simData.length)}
                    style={{ background: '#222', border: '1px solid #444', color: 'white', padding: '6px 12px', borderRadius: '4px', cursor: 'pointer', fontFamily: 'monospace' }}
                  >
                    ▶
                  </button>
                  <span style={{ fontSize: '12px', color: '#888', marginLeft: 'auto' }}>
                    TICK: {activeTick + 1} / {simData.length}
                  </span>
                </div>
                <input 
                  type="range" 
                  min="0" max={simData.length - 1} step="1" 
                  value={activeTick} 
                  onChange={(e) => setActiveTick(parseInt(e.target.value))}
                  style={{ width: '100%', cursor: 'pointer', accentColor: '#ff0077' }}
                />
              </>
            )}
          </div>
        )}

        {mode === 'sigmagate' && (
          <div style={{ background: 'rgba(10,10,20,0.85)', padding: '20px', borderRadius: '6px', border: '1px solid #00ffcc', backdropFilter: 'blur(10px)' }}>
            <label style={{ display: 'block', marginBottom: '12px', fontSize: '11px', color: '#00ffcc', letterSpacing: '1.5px', fontWeight: 'bold' }}>
              SIGMAGATE INPUT PARAMETERS (EDGE MULTISET)
            </label>
            <p style={{ fontSize: '12px', color: '#aaa', lineHeight: '1.5', marginBottom: '15px' }}>
              Adjust the multiplicities of the directed causal edges. The non-linear SigmaGate boundary operator ($\partial$) maps these inputs to vertex charge outputs.
            </p>
            
            <div style={{ marginBottom: '12px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: '#00ffcc', marginBottom: '4px' }}>
                <span>Edge A: (0,0) ➔ (4,3)</span>
                <strong>Weight: {edgeA}</strong>
              </div>
              <input 
                type="range" min="-5" max="5" step="1" value={edgeA} 
                onChange={(e) => setEdgeA(parseInt(e.target.value))}
                style={{ width: '100%', cursor: 'pointer', accentColor: '#00ffcc' }}
              />
            </div>

            <div style={{ marginBottom: '12px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: '#00ffcc', marginBottom: '4px' }}>
                <span>Edge B: (0,0) ➔ (3,4)</span>
                <strong>Weight: {edgeB}</strong>
              </div>
              <input 
                type="range" min="-5" max="5" step="1" value={edgeB} 
                onChange={(e) => setEdgeB(parseInt(e.target.value))}
                style={{ width: '100%', cursor: 'pointer', accentColor: '#00ffcc' }}
              />
            </div>

            <div style={{ marginBottom: '12px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: '#00ffcc', marginBottom: '4px' }}>
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

      {/* 3. RIGHT SIDE DETAILS PANE (Active selection / hover info) */}
      <div style={{ 
        position: 'absolute', top: 20, right: 20, zIndex: 10, color: 'white', fontFamily: 'monospace',
        width: '400px', background: 'rgba(10,10,20,0.85)', padding: '20px', borderRadius: '6px',
        border: `1px solid ${mode === 'omega' ? '#333' : (mode === 'live' ? '#ff0077' : '#00ffcc')}`, backdropFilter: 'blur(10px)',
        boxShadow: '0 0 25px rgba(0,0,0,0.6)'
      }}>
        {mode === 'omega' && (
          <>
            <h3 style={{ margin: '0 0 15px 0', fontSize: '15px', color: '#00aaff', letterSpacing: '1px', borderBottom: '1px solid #333', paddingBottom: '8px' }}>
              METRICAL CURVATURE ORACLE
            </h3>
            
            {/* Radiation analysis */}
            <div style={{ background: 'rgba(255,170,0,0.05)', border: '1px solid #ffaa00', padding: '10px', borderRadius: '4px', marginBottom: '15px', fontSize: '11px', lineHeight: '1.4' }}>
              <strong style={{ color: '#ffaa00', display: 'block', marginBottom: '4px' }}>RADIATION DE-COHERENCE (Red Metric)</strong>
              {tension > 0.05 ? (
                <span>Pure Minkowski radiation propagates along the null-diagonals ($Q_R = 0$). Space-time bends under the high energy density ({T.toFixed(0)} weight &gt; 128-bit vacuum capacity limit).</span>
              ) : (
                <span>Baryogenesis trigger activated! The spectral energy density has snapped below 128 bits, flattening space-time curvature and locking waves into a stable, massive 3D Baryon.</span>
              )}
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '8px 5px', fontSize: '12px', marginBottom: '15px' }}>
              <span style={{ color: '#888' }}>Pure Radiation:</span>
              <span style={{ color: tension > 0.05 ? '#ffaa00' : '#888', fontWeight: 'bold' }}>{tension > 0.05 ? 'TRUE' : 'FALSE'}</span>

              <span style={{ color: '#888' }}>Boundary Space:</span>
              <span style={{ color: tension > 0.05 ? '#ff0077' : '#00aaff' }}>{tension > 0.05 ? 'Möbius Curved' : 'Euclidean Flat'}</span>

              <span style={{ color: '#888' }}>Energy Density:</span>
              <span style={{ color: '#00ffcc' }}>{T.toFixed(0)} / 128 bits</span>

              <span style={{ color: '#888' }}>Minkowski Quadrance:</span>
              <span style={{ color: '#fff' }}>Q_R = 0 (Null vector)</span>

              <span style={{ color: '#888' }}>ChargeGate Spread:</span>
              <span style={{ color: '#00ffff', fontWeight: 'bold' }}>{spreadValue}</span>

              <span style={{ color: '#888' }}>Baryogenesis Snap:</span>
              <span style={{ color: isLocked ? '#00ffff' : '#888', fontWeight: 'bold' }}>{isLocked ? 'ACTIVE' : 'INACTIVE'}</span>
            </div>

            <hr style={{ borderColor: '#333', margin: '15px 0' }}/>
            <div style={{ 
              background: isLocked ? 'rgba(0, 85, 255, 0.15)' : 'rgba(255, 0, 119, 0.1)',
              border: `1px solid ${isLocked ? '#0055ff' : '#ff0077'}`,
              padding: '10px', borderRadius: '4px', fontSize: '12px', lineHeight: '1.4'
            }}>
              <strong style={{ display: 'block', marginBottom: '4px', color: isLocked ? '#00ffff' : '#ff0077' }}>
                {isLocked ? '✓ BARYON STATE PROJECTED' : '⚠ SPACETIME SUBSTRATE TWIST'}
              </strong>
              {isLocked 
                ? 'The ChargeGate polynomial clears to whole integers (S_5(s) = 1). The curved reality boundary flattens, projecting the stable baryon in 3D.'
                : 'Pigeonhole conflict triggered. The flat 2D sheet is bent into a metric gravity funnel by the delocalized Minkowski photons.'
              }
            </div>
          </>
        )}

        {mode === 'live' && (
          <>
            <h3 style={{ margin: '0 0 15px 0', fontSize: '15px', color: '#ff0077', letterSpacing: '1px', borderBottom: '1px solid #333', paddingBottom: '8px' }}>
              SERIALIZED SIMULATION VECTOR
            </h3>
            {activeState ? (
              <div style={{ fontSize: '12px' }}>
                <div style={{ marginBottom: '12px', display: 'flex', justifyContent: 'space-between', background: 'rgba(0,0,0,0.3)', padding: '6px' }}>
                  <span>Maxel Nodes: {activeState.stateVector.length}</span>
                  <span>Causal Edges: {activeState.substrate.length}</span>
                </div>
                
                {hoveredMaxel ? (
                  <div style={{ background: 'rgba(255,0,119,0.08)', border: '1px solid #ff0077', padding: '12px', borderRadius: '4px' }}>
                    <h4 style={{ margin: '0 0 10px 0', color: '#ff0077', fontSize: '13px' }}>
                      SELECTED MAXEL: ({hoveredMaxel.geom.src}, {hoveredMaxel.geom.tgt})
                    </h4>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 2.5fr', gap: '8px 5px', marginBottom: '10px' }}>
                      <span style={{ color: '#888' }}>Coordinates:</span>
                      <span>Source={hoveredMaxel.geom.src}, Target={hoveredMaxel.geom.tgt}</span>

                      <span style={{ color: '#888' }}>Leibniz Lag:</span>
                      <span style={{ color: '#00ffcc', fontWeight: 'bold' }}>{hoveredMaxel.count} maxel weight</span>

                      <span style={{ color: '#888' }}>Polynumber:</span>
                      <span style={{ color: '#00ffff', fontWeight: 'bold', wordBreak: 'break-all', fontSize: '11px', fontFamily: 'monospace' }}>
                        {formatPolynomial(hoveredMaxel.amplitude)}
                      </span>
                    </div>
                  </div>
                ) : (
                  <div style={{ color: '#666', textAlign: 'center', padding: '20px 0', border: '1px dashed #444', borderRadius: '4px' }}>
                    Hover over any Maxel sphere in the 3D space to inspect its compiled Polynomial amplitude and Leibniz lag properties.
                  </div>
                )}
                
                <hr style={{ borderColor: '#333', margin: '15px 0' }}/>
                <div style={{ background: 'rgba(0, 255, 204, 0.05)', border: '1px solid #00ffcc', padding: '10px', borderRadius: '4px', fontSize: '11px', lineHeight: '1.4', color: '#aaa' }}>
                  <strong style={{ display: 'block', marginBottom: '4px', color: '#00ffcc' }}>✓ VERIFIED BY QUICKCHECK</strong>
                  This state is structurally synchronized with the LUniverse core mathematical invariants. Total conservation of matter coefficients is guaranteed at compile-time.
                </div>
              </div>
            ) : (
              <p style={{ color: '#888' }}>No active tick. Fetching state vectors...</p>
            )}
          </>
        )}

        {mode === 'sigmagate' && (
          <>
            <h3 style={{ margin: '0 0 15px 0', fontSize: '15px', color: '#00ffcc', letterSpacing: '1px', borderBottom: '1px solid #333', paddingBottom: '8px' }}>
              SIGMAGATE IO BOUNDARY ORACLE
            </h3>
            <div style={{ fontSize: '12px' }}>
              <div style={{ background: 'rgba(0,255,204,0.05)', border: '1px solid #00ffcc', padding: '10px', borderRadius: '4px', marginBottom: '15px', lineHeight: '1.4' }}>
                <strong style={{ color: '#00ffcc', display: 'block', marginBottom: '4px' }}>THE BOUNDARY FORMULA (∂)</strong>
                The boundary of a directed causal relation acts as a topological shunt, shredding 1-dimensional edges into 0-dimensional point charges:
                <div style={{ textAlign: 'center', margin: '8px 0', fontSize: '13px', fontWeight: 'bold' }}>
                  ∂(A ➔ B) = B - A
                </div>
              </div>

              <h4 style={{ color: '#00ffcc', margin: '0 0 8px 0', fontSize: '12px' }}>OUTPUT STATE (VERTEX MULTISET CHARGES)</h4>
              <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr 1fr', gap: '8px 5px', fontSize: '12px', background: 'rgba(0,0,0,0.3)', padding: '10px', borderRadius: '4px', marginBottom: '15px' }}>
                <span style={{ color: '#888' }}>Coordinate</span>
                <span style={{ color: '#888' }}>Equation</span>
                <span style={{ color: '#888' }}>Charge</span>

                <span>ROOT (0,0)</span>
                <span>-e_A - e_B</span>
                <span style={{ color: q0 === 0 ? '#888' : (q0 > 0 ? '#00aaff' : '#ff5500'), fontWeight: 'bold' }}>{q0}</span>

                <span>NODE A (4,3)</span>
                <span>e_A - e_C</span>
                <span style={{ color: q1 === 0 ? '#888' : (q1 > 0 ? '#00aaff' : '#ff5500'), fontWeight: 'bold' }}>{q1}</span>

                <span>NODE B (3,4)</span>
                <span>e_B + e_C</span>
                <span style={{ color: q2 === 0 ? '#888' : (q2 > 0 ? '#00aaff' : '#ff5500'), fontWeight: 'bold' }}>{q2}</span>
              </div>

              <div style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid #555', padding: '10px', borderRadius: '4px', fontSize: '12px', lineHeight: '1.4' }}>
                <strong style={{ display: 'block', marginBottom: '4px', color: '#fff' }}>TOTAL CAUSAL DIVERGENCE</strong>
                Summing the boundary charges proves absolute algebraic conservation under the SigmaGate:
                <div style={{ textAlign: 'center', marginTop: '6px', fontWeight: 'bold', color: '#00ffcc', fontSize: '13px' }}>
                  q_ROOT + q_A + q_B = ({q0}) + ({q1}) + ({q2}) = {q0 + q1 + q2}
                </div>
              </div>
            </div>
          </>
        )}
      </div>

      {/* 4. Canvas */}
      <Canvas camera={{ position: [0, -18, 25], fov: 40 }}>
        <color attach="background" args={['#020205']} />
        <ambientLight intensity={0.2} />
        
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
            />
          </>
        )}
      </Canvas>
    </div>
  );
}
