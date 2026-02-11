//
//  OrbitSceneView.swift
//  artemis2
//
//  SceneKit-based 3D visualization of the Artemis II trajectory.
//  Renders Earth, Moon, Orion spacecraft, trajectory path, and starfield.
//

import SwiftUI
import SceneKit
import simd

// MARK: - SceneKit View Wrapper

struct OrbitSceneView: UIViewRepresentable {
    let viewModel: MissionViewModel

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = context.coordinator.scene
        scnView.backgroundColor = .black
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = false
        scnView.antialiasingMode = .multisampling4X
        scnView.preferredFramesPerSecond = 60

        // Add ambient light for base visibility
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 150
        ambientLight.light?.color = UIColor(white: 0.3, alpha: 1.0)
        context.coordinator.scene.rootNode.addChildNode(ambientLight)

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        context.coordinator.updateSpacecraftPosition(viewModel.spacecraftPosition)
        context.coordinator.updatePhase(viewModel.currentPhase)
        context.coordinator.updateCamera(for: viewModel)
    }

    func makeCoordinator() -> OrbitSceneCoordinator {
        OrbitSceneCoordinator()
    }
}

// MARK: - Scene Coordinator

class OrbitSceneCoordinator {
    let scene: SCNScene
    private let earthNode: SCNNode
    private let moonNode: SCNNode
    private let spacecraftNode: SCNNode
    private let trajectoryNode: SCNNode
    private let cameraNode: SCNNode
    private let sunLightNode: SCNNode
    private var currentPhase: MissionPhase = .prelaunch

    init() {
        scene = SCNScene()

        // Create all nodes
        earthNode = OrbitSceneCoordinator.createEarth()
        moonNode = OrbitSceneCoordinator.createMoon()
        spacecraftNode = OrbitSceneCoordinator.createSpacecraft()
        trajectoryNode = OrbitSceneCoordinator.createTrajectory()
        cameraNode = OrbitSceneCoordinator.createCamera()
        sunLightNode = OrbitSceneCoordinator.createSunLight()

        // Add to scene
        scene.rootNode.addChildNode(earthNode)
        scene.rootNode.addChildNode(moonNode)
        scene.rootNode.addChildNode(spacecraftNode)
        scene.rootNode.addChildNode(trajectoryNode)
        scene.rootNode.addChildNode(cameraNode)
        scene.rootNode.addChildNode(sunLightNode)

        // Create starfield
        OrbitSceneCoordinator.createStarfield(in: scene)

        // Background
        scene.background.contents = UIColor.black
    }

    // MARK: - Earth

    private static func createEarth() -> SCNNode {
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 72

        let material = SCNMaterial()
        // Procedural Earth-like appearance
        material.diffuse.contents = UIColor(red: 0.1, green: 0.3, blue: 0.7, alpha: 1.0)
        material.specular.contents = UIColor(white: 0.3, alpha: 1.0)
        material.shininess = 25
        material.emission.contents = UIColor(red: 0.0, green: 0.05, blue: 0.15, alpha: 1.0)

        // Add a second material for land masses using a shader modifier
        material.shaderModifiers = [
            .surface: """
            float lat = asin(_surface.normal.y);
            float lon = atan2(_surface.normal.x, _surface.normal.z);
            float land = sin(lat * 5.0 + 0.5) * cos(lon * 7.0 + 1.0);
            land += sin(lat * 3.0 - 1.0) * cos(lon * 4.0 + 2.0) * 0.5;
            land = smoothstep(-0.1, 0.3, land);
            vec3 ocean = vec3(0.05, 0.15, 0.6);
            vec3 ground = vec3(0.15, 0.45, 0.12);
            vec3 ice = vec3(0.85, 0.9, 0.95);
            float polar = smoothstep(0.7, 0.9, abs(lat / 1.57));
            vec3 color = mix(ocean, ground, land);
            color = mix(color, ice, polar);
            _surface.diffuse.rgb = color;
            """
        ]

        sphere.firstMaterial = material

        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(0, 0, 0)

        // Atmosphere glow
        let atmosphereSphere = SCNSphere(radius: 1.06)
        atmosphereSphere.segmentCount = 48
        let atmosphereMaterial = SCNMaterial()
        atmosphereMaterial.diffuse.contents = UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 0.15)
        atmosphereMaterial.emission.contents = UIColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 0.1)
        atmosphereMaterial.isDoubleSided = true
        atmosphereMaterial.transparent.contents = UIColor(white: 1, alpha: 0.12)
        atmosphereMaterial.transparencyMode = .aOne
        atmosphereSphere.firstMaterial = atmosphereMaterial
        let atmosphereNode = SCNNode(geometry: atmosphereSphere)
        node.addChildNode(atmosphereNode)

        // Slow rotation
        let rotation = SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 120))
        node.runAction(rotation)

        return node
    }

    // MARK: - Moon

    private static func createMoon() -> SCNNode {
        let sphere = SCNSphere(radius: 0.4)
        sphere.segmentCount = 48

        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 0.65, alpha: 1.0)
        material.specular.contents = UIColor(white: 0.1, alpha: 1.0)
        material.shininess = 5

        // Crater-like surface detail
        material.shaderModifiers = [
            .surface: """
            float lat = asin(_surface.normal.y);
            float lon = atan2(_surface.normal.x, _surface.normal.z);
            float crater1 = 1.0 - smoothstep(0.1, 0.15, length(vec2(lat - 0.3, lon - 0.5)));
            float crater2 = 1.0 - smoothstep(0.08, 0.12, length(vec2(lat + 0.2, lon + 0.8)));
            float crater3 = 1.0 - smoothstep(0.12, 0.18, length(vec2(lat - 0.5, lon + 0.3)));
            float detail = sin(lat * 20.0) * cos(lon * 15.0) * 0.03;
            float maria = smoothstep(-0.1, 0.1, sin(lat * 3.0 + 1.0) * cos(lon * 2.5));
            float brightness = 0.65 - crater1 * 0.15 - crater2 * 0.12 - crater3 * 0.1 + detail - maria * 0.15;
            _surface.diffuse.rgb = vec3(brightness, brightness * 0.98, brightness * 0.95);
            """
        ]

        sphere.firstMaterial = material

        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(10, 0, 0) // Moon position in scene
        node.runAction(SCNAction.repeatForever(
            SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 300)
        ))

        return node
    }

    // MARK: - Spacecraft (Orion)

    private static func createSpacecraft() -> SCNNode {
        let parentNode = SCNNode()

        // Main capsule body - cone shape
        let capsule = SCNCone(topRadius: 0.02, bottomRadius: 0.06, height: 0.1)
        let capsuleMaterial = SCNMaterial()
        capsuleMaterial.diffuse.contents = UIColor(white: 0.85, alpha: 1.0)
        capsuleMaterial.specular.contents = UIColor.white
        capsuleMaterial.shininess = 50
        capsuleMaterial.metalness.contents = UIColor(white: 0.6, alpha: 1.0)
        capsule.firstMaterial = capsuleMaterial
        let capsuleNode = SCNNode(geometry: capsule)
        parentNode.addChildNode(capsuleNode)

        // Service module - cylinder
        let service = SCNCylinder(radius: 0.05, height: 0.12)
        let serviceMaterial = SCNMaterial()
        serviceMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        serviceMaterial.metalness.contents = UIColor(white: 0.7, alpha: 1.0)
        service.firstMaterial = serviceMaterial
        let serviceNode = SCNNode(geometry: service)
        serviceNode.position = SCNVector3(0, -0.11, 0)
        parentNode.addChildNode(serviceNode)

        // Solar panels - flat boxes
        for side: Float in [-1, 1] {
            let panel = SCNBox(width: 0.2, height: 0.005, length: 0.06, chamferRadius: 0)
            let panelMaterial = SCNMaterial()
            panelMaterial.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.4, alpha: 1.0)
            panelMaterial.emission.contents = UIColor(red: 0.0, green: 0.0, blue: 0.1, alpha: 1.0)
            panelMaterial.metalness.contents = UIColor(white: 0.8, alpha: 1.0)
            panel.firstMaterial = panelMaterial
            let panelNode = SCNNode(geometry: panel)
            panelNode.position = SCNVector3(side * 0.15, -0.11, 0)
            parentNode.addChildNode(panelNode)
        }

        // Engine glow (visible during burns)
        let glowSphere = SCNSphere(radius: 0.03)
        let glowMaterial = SCNMaterial()
        glowMaterial.emission.contents = UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 1.0)
        glowMaterial.diffuse.contents = UIColor.clear
        glowMaterial.transparency = 0
        glowSphere.firstMaterial = glowMaterial
        let glowNode = SCNNode(geometry: glowSphere)
        glowNode.name = "engineGlow"
        glowNode.position = SCNVector3(0, -0.17, 0)
        parentNode.addChildNode(glowNode)

        // Point light on spacecraft
        let light = SCNLight()
        light.type = .omni
        light.intensity = 200
        light.color = UIColor.white
        light.attenuationStartDistance = 0.5
        light.attenuationEndDistance = 3.0
        let lightNode = SCNNode()
        lightNode.light = light
        parentNode.addChildNode(lightNode)

        return parentNode
    }

    // MARK: - Trajectory Path

    private static func createTrajectory() -> SCNNode {
        let parentNode = SCNNode()
        let points = OrbitalMechanics.generateTrajectoryPoints(count: 600)

        // Create trajectory as a series of small segments with color gradient
        let segmentCount = points.count - 1
        for i in 0..<segmentCount {
            let start = points[i]
            let end = points[i + 1]

            let progress = Float(i) / Float(segmentCount)
            let phase = OrbitalMechanics.currentPhase(at: Double(progress) * MissionConstants.totalMissionDuration)

            // Create thin cylinder between points
            let segment = createLineSegment(from: start, to: end, color: phase.color.withOpacity(0.6))
            parentNode.addChildNode(segment)
        }

        return parentNode
    }

    private static func createLineSegment(from start: SIMD3<Float>, to end: SIMD3<Float>, color: Color) -> SCNNode {
        let vector = end - start
        let distance = length(vector)

        guard distance > 0.001 else {
            return SCNNode()
        }

        let cylinder = SCNCylinder(radius: 0.008, height: CGFloat(distance))
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(color)
        material.emission.contents = UIColor(color).withAlphaComponent(0.3)
        cylinder.firstMaterial = material

        let node = SCNNode(geometry: cylinder)

        // Position at midpoint
        let midpoint = (start + end) / 2
        node.position = SCNVector3(midpoint.x, midpoint.y, midpoint.z)

        // Orient along the vector
        let up = SIMD3<Float>(0, 1, 0)
        let dir = normalize(vector)
        let cross = simd.cross(up, dir)
        let dot = simd.dot(up, dir)

        if length(cross) > 0.001 {
            let angle = acos(min(1, max(-1, dot)))
            let axis = normalize(cross)
            node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        } else if dot < 0 {
            node.rotation = SCNVector4(1, 0, 0, Float.pi)
        }

        return node
    }

    // MARK: - Starfield

    private static func createStarfield(in scene: SCNScene) {
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 0
        particleSystem.loops = false
        particleSystem.emissionDuration = 0
        particleSystem.particleLifeSpan = .infinity

        // Create stars as small white spheres scattered in a sphere
        let starCount = 2000
        for _ in 0..<starCount {
            let node = SCNNode()
            let star = SCNSphere(radius: CGFloat.random(in: 0.01...0.04))
            let material = SCNMaterial()
            let brightness = CGFloat.random(in: 0.5...1.0)
            material.diffuse.contents = UIColor.clear
            material.emission.contents = UIColor(white: brightness, alpha: 1.0)
            star.firstMaterial = material
            node.geometry = star

            // Random position on a large sphere
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = acos(Float.random(in: -1...1))
            let r: Float = Float.random(in: 50...80)
            node.position = SCNVector3(
                r * sin(phi) * cos(theta),
                r * sin(phi) * sin(theta),
                r * cos(phi)
            )

            // Random subtle twinkle animation
            if Float.random(in: 0...1) > 0.7 {
                let twinkle = SCNAction.sequence([
                    SCNAction.fadeOpacity(to: CGFloat.random(in: 0.3...0.7), duration: Double.random(in: 1...4)),
                    SCNAction.fadeOpacity(to: 1.0, duration: Double.random(in: 1...4))
                ])
                node.runAction(SCNAction.repeatForever(twinkle))
            }

            scene.rootNode.addChildNode(node)
        }
    }

    // MARK: - Camera

    private static func createCamera() -> SCNNode {
        let camera = SCNCamera()
        camera.zFar = 200
        camera.zNear = 0.01
        camera.fieldOfView = 60
        camera.wantsHDR = true
        camera.bloomIntensity = 0.5
        camera.bloomThreshold = 0.8

        let node = SCNNode()
        node.camera = camera
        node.position = SCNVector3(0, 2, 8)
        node.look(at: SCNVector3(0, 0, 0))

        return node
    }

    // MARK: - Sun Light

    private static func createSunLight() -> SCNNode {
        let light = SCNLight()
        light.type = .directional
        light.intensity = 1200
        light.color = UIColor(white: 1.0, alpha: 1.0)
        light.castsShadow = true
        light.shadowMode = .deferred
        light.shadowSampleCount = 8

        let node = SCNNode()
        node.light = light
        node.position = SCNVector3(-20, 10, 15)
        node.look(at: SCNVector3(0, 0, 0))

        return node
    }

    // MARK: - Updates

    func updateSpacecraftPosition(_ position: SIMD3<Float>) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        spacecraftNode.position = SCNVector3(position.x, position.y, position.z)
        SCNTransaction.commit()
    }

    func updatePhase(_ phase: MissionPhase) {
        let isThrusting = phase == .launch || phase == .translunarInjection
        if let glow = spacecraftNode.childNode(withName: "engineGlow", recursively: true) {
            glow.geometry?.firstMaterial?.transparency = isThrusting ? 1.0 : 0.0
        }
        currentPhase = phase
    }

    func updateCamera(for viewModel: MissionViewModel) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 2.0

        let pos = viewModel.spacecraftPosition

        switch viewModel.currentPhase {
        case .prelaunch, .launch:
            // Close-up view during launch
            cameraNode.position = SCNVector3(pos.x + 2, pos.y + 1, pos.z + 3)
            cameraNode.look(at: SCNVector3(pos.x, pos.y, pos.z))

        case .earthOrbit:
            // Pull back to see orbit
            cameraNode.position = SCNVector3(0, 3, 5)
            cameraNode.look(at: SCNVector3(0, 0, 0))

        case .translunarInjection:
            // View the burn
            cameraNode.position = SCNVector3(pos.x + 1.5, pos.y + 1, pos.z + 2)
            cameraNode.look(at: SCNVector3(pos.x, pos.y, pos.z))

        case .translunarCoast:
            // Wide view showing path from Earth toward Moon
            let midX = pos.x / 2
            cameraNode.position = SCNVector3(midX, 5, 12)
            cameraNode.look(at: SCNVector3(5, 0, 0))

        case .lunarFlyby:
            // Close to Moon
            cameraNode.position = SCNVector3(pos.x + 1, pos.y + 1, pos.z + 2)
            cameraNode.look(at: SCNVector3(10, 0, 0))

        case .returnTransit:
            // Wide view showing return path
            let midX = pos.x / 2
            cameraNode.position = SCNVector3(midX, -5, 12)
            cameraNode.look(at: SCNVector3(5, 0, 0))

        case .reentry:
            // Close-up for reentry
            cameraNode.position = SCNVector3(pos.x + 1, pos.y + 0.5, pos.z + 2)
            cameraNode.look(at: SCNVector3(pos.x, pos.y, pos.z))
        }

        SCNTransaction.commit()
    }
}

// MARK: - Color Extension for Opacity

private extension Color {
    func withOpacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }
}
