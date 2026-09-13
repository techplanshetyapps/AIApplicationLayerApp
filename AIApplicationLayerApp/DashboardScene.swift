import SceneKit
import UIKit

final class DashboardScene {

    enum TimeOfDay: String, CaseIterable, Identifiable {
        case day, afternoon, night
        var id: String { rawValue }
        var label: String {
            switch self {
            case .day: return "Day"
            case .afternoon: return "Afternoon"
            case .night: return "Night"
            }
        }
    }

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private(set) var dashboardNode: SCNNode!
    private(set) var fountainNode: SCNNode!
    private(set) var fountainParticles: SCNParticleSystem!

    private var keyLight: SCNLight!
    private var ambientLight: SCNLight!
    private var rimLight: SCNLight!
    private var windowEmissiveMaterials: [SCNMaterial] = []

    init() {
        buildLighting()
        buildCamera()
        buildSkyline()
        buildDashboardPanel()
        buildFountain()
        setTimeOfDay(.day)
    }

    // MARK: - Camera

    private func buildCamera() {
        let camera = SCNCamera()
        camera.fieldOfView = 55
        camera.zNear = 0.1
        camera.zFar = 200
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 1.4, 6.2)
        cameraNode.eulerAngles.x = -0.05
        scene.rootNode.addChildNode(cameraNode)
    }

    // MARK: - Lighting

    private func buildLighting() {
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light!.type = .ambient
        scene.rootNode.addChildNode(ambientNode)
        ambientLight = ambientNode.light

        let keyNode = SCNNode()
        keyNode.light = SCNLight()
        keyNode.light!.type = .directional
        keyNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyNode)
        keyLight = keyNode.light

        let rimNode = SCNNode()
        rimNode.light = SCNLight()
        rimNode.light!.type = .directional
        rimNode.eulerAngles = SCNVector3(Float.pi / 6, -Float.pi / 1.5, 0)
        scene.rootNode.addChildNode(rimNode)
        rimLight = rimNode.light
    }

    // MARK: - Skyline (detailed procedural cartoon skyscrapers)

    private func buildSkyline() {
        let palette: [UIColor] = [
            UIColor(red: 0.86, green: 0.32, blue: 0.55, alpha: 1),
            UIColor(red: 0.30, green: 0.68, blue: 0.92, alpha: 1),
            UIColor(red: 0.98, green: 0.68, blue: 0.24, alpha: 1),
            UIColor(red: 0.45, green: 0.82, blue: 0.55, alpha: 1),
            UIColor(red: 0.62, green: 0.40, blue: 0.92, alpha: 1)
        ]

        var xPos: Float = -9.0
        var i = 0
        while xPos <= 9.0 {
            let width = CGFloat.random(in: 0.9...1.6)
            let height = CGFloat.random(in: 3.0...7.5)
            let depth = CGFloat.random(in: 0.9...1.6)
            let baseColor = palette[i % palette.count]
            let zPos: Float = -10.0 - Float.random(in: 0...4)

            buildTower(width: width, height: height, depth: depth,
                       position: SCNVector3(xPos, Float(height / 2) - 1.0, zPos),
                       baseColor: baseColor)

            xPos += Float.random(in: 1.6...2.6)
            i += 1
        }

        let ground = SCNFloor()
        ground.reflectivity = 0.03
        let groundMat = SCNMaterial()
        let stoneTexture = stonePavementTexture()
        groundMat.diffuse.contents = stoneTexture
        groundMat.diffuse.wrapS = .repeat
        groundMat.diffuse.wrapT = .repeat
        groundMat.diffuse.contentsTransform = SCNMatrix4MakeScale(14, 14, 1) // tile the texture across the plaza
        groundMat.roughness.contents = 0.9
        groundMat.specular.contents = UIColor.white.withAlphaComponent(0.15)
        ground.materials = [groundMat]
        let groundNode = SCNNode(geometry: ground)
        groundNode.position = SCNVector3(0, -1.0, 0)
        scene.rootNode.addChildNode(groundNode)
    }

    /// Procedural cobblestone/paving-slab texture: irregular stone blocks with mortar
    /// gaps and subtle per-stone shading, tiled across the plaza floor via wrapS/wrapT.
    private func stonePavementTexture() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        let mortarColor = UIColor(red: 0.22, green: 0.21, blue: 0.24, alpha: 1)
        let stoneColors: [UIColor] = [
            UIColor(red: 0.55, green: 0.53, blue: 0.52, alpha: 1),
            UIColor(red: 0.62, green: 0.60, blue: 0.58, alpha: 1),
            UIColor(red: 0.48, green: 0.47, blue: 0.49, alpha: 1),
            UIColor(red: 0.58, green: 0.55, blue: 0.50, alpha: 1)
        ]

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            mortarColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            let gap: CGFloat = 5
            var y: CGFloat = 0
            var rowIndex = 0
            while y < size.height {
                let rowHeight = CGFloat.random(in: 55...85)
                var x: CGFloat = rowIndex.isMultiple(of: 2) ? -30 : 0 // brick-style offset per row
                while x < size.width {
                    let stoneWidth = CGFloat.random(in: 70...120)
                    let rect = CGRect(x: x + gap / 2, y: y + gap / 2,
                                       width: max(10, stoneWidth - gap), height: max(10, rowHeight - gap))
                    let color = stoneColors.randomElement()!
                    color.setFill()
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
                    path.fill()

                    // Subtle top-left highlight edge for a bit of stone bevel.
                    color.withAlphaComponent(0.0).setStroke()
                    UIColor.white.withAlphaComponent(0.08).setStroke()
                    let highlight = UIBezierPath()
                    highlight.move(to: CGPoint(x: rect.minX, y: rect.maxY))
                    highlight.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
                    highlight.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
                    highlight.lineWidth = 1.5
                    highlight.stroke()

                    x += stoneWidth
                }
                y += rowHeight
                rowIndex += 1
            }
        }
    }

    /// One skyscraper: main tower with a window-grid texture, several floor ledge bands,
    /// four corner trim pillars, a smaller rooftop setback tier, and small rooftop props
    /// (antenna, AC units, water tank) — the "small elements" detail pass.
    private func buildTower(width: CGFloat, height: CGFloat, depth: CGFloat, position: SCNVector3, baseColor: UIColor) {
        let towerRoot = SCNNode()
        towerRoot.position = position
        scene.rootNode.addChildNode(towerRoot)

        // Window grid density scales with building size for a consistent floor height.
        let columns = max(4, Int(width * 8))
        let rows = max(8, Int(height * 6))

        let box = SCNBox(width: width, height: height, length: depth, chamferRadius: 0.04)
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = windowDiffuseTexture(baseColor: baseColor, columns: columns, rows: rows)
        sideMaterial.emission.contents = windowEmissiveTexture(columns: columns, rows: rows)
        sideMaterial.emission.intensity = 0
        sideMaterial.roughness.contents = 0.55
        windowEmissiveMaterials.append(sideMaterial)

        let capMaterial = SCNMaterial()
        capMaterial.diffuse.contents = baseColor.darker(by: 0.15)

        // SCNBox face order: front, right, back, left, top, bottom.
        box.materials = [sideMaterial, sideMaterial, sideMaterial, sideMaterial, capMaterial, capMaterial]
        let mainNode = SCNNode(geometry: box)
        towerRoot.addChildNode(mainNode)

        // Floor ledge bands — thin, slightly wider boxes banding the tower every few floors.
        let ledgeCount = max(1, Int(height / 1.8))
        for l in 1...ledgeCount {
            let ledge = SCNBox(width: width * 1.06, height: 0.05, length: depth * 1.06, chamferRadius: 0.01)
            let ledgeMat = SCNMaterial()
            ledgeMat.diffuse.contents = baseColor.darker(by: 0.3)
            ledge.materials = [ledgeMat]
            let ledgeNode = SCNNode(geometry: ledge)
            let t = Float(l) / Float(ledgeCount + 1)
            ledgeNode.position = SCNVector3(0, Float(-height / 2) + t * Float(height), 0)
            towerRoot.addChildNode(ledgeNode)
        }

        // Four corner trim pillars for crisper silhouette detail.
        let pillarInsetX = Float(width / 2) - 0.03
        let pillarInsetZ = Float(depth / 2) - 0.03
        for (dx, dz) in [(1, 1), (1, -1), (-1, 1), (-1, -1)] {
            let pillar = SCNBox(width: 0.05, height: height * 1.01, length: 0.05, chamferRadius: 0.01)
            let pillarMat = SCNMaterial()
            pillarMat.diffuse.contents = baseColor.darker(by: 0.35)
            pillar.materials = [pillarMat]
            let pillarNode = SCNNode(geometry: pillar)
            pillarNode.position = SCNVector3(Float(dx) * pillarInsetX, 0, Float(dz) * pillarInsetZ)
            towerRoot.addChildNode(pillarNode)
        }

        // Rooftop setback tier — a smaller second box for a stepped skyline profile.
        let tierWidth = width * 0.55
        let tierHeight = height * 0.18
        let tierDepth = depth * 0.55
        let tier = SCNBox(width: tierWidth, height: tierHeight, length: tierDepth, chamferRadius: 0.03)
        let tierMat = SCNMaterial()
        tierMat.diffuse.contents = baseColor.darker(by: 0.1)
        tier.materials = [tierMat]
        let tierNode = SCNNode(geometry: tier)
        tierNode.position = SCNVector3(0, Float(height / 2 + tierHeight / 2), 0)
        towerRoot.addChildNode(tierNode)

        // Small rooftop props: antenna mast + tip, one or two AC/vent boxes, water tank cylinder.
        let roofY = Float(height / 2 + tierHeight)

        let mast = SCNCylinder(radius: 0.02, height: 0.5)
        let mastMat = SCNMaterial(); mastMat.diffuse.contents = UIColor.lightGray
        mast.materials = [mastMat]
        let mastNode = SCNNode(geometry: mast)
        mastNode.position = SCNVector3(0, roofY + 0.25, 0)
        towerRoot.addChildNode(mastNode)

        let tip = SCNSphere(radius: 0.035)
        let tipMat = SCNMaterial(); tipMat.diffuse.contents = UIColor.red
        tipMat.emission.contents = UIColor.red
        tip.materials = [tipMat]
        let tipNode = SCNNode(geometry: tip)
        tipNode.position = SCNVector3(0, roofY + 0.5, 0)
        towerRoot.addChildNode(tipNode)

        for _ in 0..<Int.random(in: 1...2) {
            let vent = SCNBox(width: 0.12, height: 0.08, length: 0.12, chamferRadius: 0.01)
            let ventMat = SCNMaterial(); ventMat.diffuse.contents = baseColor.darker(by: 0.4)
            vent.materials = [ventMat]
            let ventNode = SCNNode(geometry: vent)
            ventNode.position = SCNVector3(
                Float.random(in: -Float(tierWidth) / 3...Float(tierWidth) / 3),
                roofY + 0.04,
                Float.random(in: -Float(tierDepth) / 3...Float(tierDepth) / 3)
            )
            towerRoot.addChildNode(ventNode)
        }

        if Bool.random() {
            let tank = SCNCylinder(radius: 0.09, height: 0.14)
            let tankMat = SCNMaterial(); tankMat.diffuse.contents = UIColor(white: 0.75, alpha: 1)
            tank.materials = [tankMat]
            let tankNode = SCNNode(geometry: tank)
            tankNode.position = SCNVector3(Float(tierWidth) / 4, roofY + 0.07, Float(tierDepth) / 4)
            towerRoot.addChildNode(tankNode)
        }
    }

    /// Base window-grid look: lit and unlit windows drawn as a flat diffuse texture.
    private func windowDiffuseTexture(baseColor: UIColor, columns: Int, rows: Int) -> UIImage {
        let cellSize: CGFloat = 24
        let size = CGSize(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            baseColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let inset: CGFloat = 4
            for row in 0..<rows {
                for col in 0..<columns {
                    let rect = CGRect(x: CGFloat(col) * cellSize + inset,
                                       y: CGFloat(row) * cellSize + inset,
                                       width: cellSize - inset * 2,
                                       height: cellSize - inset * 2)
                    baseColor.darker(by: 0.45).setFill()
                    ctx.fill(rect)
                }
            }
        }
    }

    /// Emissive-only overlay: black everywhere except lit-window rectangles, which glow
    /// warm yellow. `emission.intensity` (0 = off, higher = brighter) is what we animate
    /// between day/afternoon/night, so the "lights" only appear as it gets dark.
    private func windowEmissiveTexture(columns: Int, rows: Int) -> UIImage {
        let cellSize: CGFloat = 24
        let size = CGSize(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.black.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let inset: CGFloat = 4
            let litColor = UIColor(red: 1.0, green: 0.85, blue: 0.45, alpha: 1)
            for row in 0..<rows {
                for col in 0..<columns {
                    guard Double.random(in: 0...1) < 0.35 else { continue } // ~35% of windows are "lit" at night
                    let rect = CGRect(x: CGFloat(col) * cellSize + inset,
                                       y: CGFloat(row) * cellSize + inset,
                                       width: cellSize - inset * 2,
                                       height: cellSize - inset * 2)
                    litColor.setFill()
                    ctx.fill(rect)
                }
            }
        }
    }

    // MARK: - Dashboard panel

    private func buildDashboardPanel() {
        let panel = SCNPlane(width: 3.6, height: 5.2)
        panel.cornerRadius = 0.12
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.08, green: 0.09, blue: 0.16, alpha: 0.001)
        panel.materials = [material]

        let node = SCNNode(geometry: panel)
        node.position = SCNVector3(0, 0.6, 0)
        node.name = "dashboardPanel"
        scene.rootNode.addChildNode(node)
        dashboardNode = node
    }

    // MARK: - Fountain

    private func buildFountain() {
        let base = SCNCylinder(radius: 0.7, height: 0.25)
        let baseMaterial = SCNMaterial()
        baseMaterial.diffuse.contents = UIColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1)
        base.materials = [baseMaterial]

        let baseNode = SCNNode(geometry: base)
        baseNode.position = SCNVector3(0, -0.85, 1.6)
        scene.rootNode.addChildNode(baseNode)

        let spout = SCNCylinder(radius: 0.12, height: 0.6)
        let spoutMaterial = SCNMaterial()
        spoutMaterial.diffuse.contents = UIColor(red: 0.75, green: 0.85, blue: 0.98, alpha: 1)
        spout.materials = [spoutMaterial]
        let spoutNode = SCNNode(geometry: spout)
        spoutNode.position = SCNVector3(0, -0.55, 1.6)
        scene.rootNode.addChildNode(spoutNode)

        fountainNode = baseNode

        let water = SCNParticleSystem()
        water.particleColor = UIColor(red: 0.7, green: 0.9, blue: 1.0, alpha: 0.85)
        water.birthRate = 0
        water.particleLifeSpan = 1.1
        water.particleVelocity = 1.4
        water.spreadingAngle = 18
        water.particleSize = 0.03
        water.emitterShape = SCNCylinder(radius: 0.05, height: 0.02)
        water.emissionDuration = 0
        water.loops = true
        water.acceleration = SCNVector3(0, -2.0, 0)

        spoutNode.addParticleSystem(water)
        fountainParticles = water
    }

    // MARK: - Public updates

    func applyLean(angleRadians: Double) {
        let clamped = MotionManager.clamp(angleRadians, min: -0.35, max: 0.35)
        let rotation = Float(clamped)
        cameraNode.position.x = Float(-clamped) * 2.2
        dashboardNode.eulerAngles.z = -rotation * 0.6
        dashboardNode.eulerAngles.y = rotation * 0.3
    }

    func setFountainFlowing(_ flowing: Bool) {
        fountainParticles.birthRate = flowing ? 220 : 0
    }

    /// Switches sky color, key/ambient/rim light color+intensity, and building window glow
    /// to match Day / Afternoon / Night.
    func setTimeOfDay(_ time: TimeOfDay) {
        switch time {
        case .day:
            scene.background.contents = UIColor(red: 0.55, green: 0.80, blue: 0.98, alpha: 1) // light sky blue
            ambientLight.color = UIColor(white: 0.85, alpha: 1)
            keyLight.color = UIColor(red: 1.0, green: 0.97, blue: 0.9, alpha: 1)
            keyLight.intensity = 1300
            rimLight.color = UIColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1)
            rimLight.intensity = 250
            windowEmissiveMaterials.forEach { $0.emission.intensity = 0 }

        case .afternoon:
            scene.background.contents = UIColor(red: 0.95, green: 0.58, blue: 0.38, alpha: 1) // dusk orange/pink
            ambientLight.color = UIColor(red: 0.6, green: 0.5, blue: 0.55, alpha: 1)
            keyLight.color = UIColor(red: 1.0, green: 0.75, blue: 0.5, alpha: 1)
            keyLight.intensity = 850
            rimLight.color = UIColor(red: 0.5, green: 0.55, blue: 0.85, alpha: 1)
            rimLight.intensity = 350
            windowEmissiveMaterials.forEach { $0.emission.intensity = 0.7 }

        case .night:
            scene.background.contents = UIColor(red: 0.04, green: 0.05, blue: 0.14, alpha: 1) // deep night sky
            ambientLight.color = UIColor(red: 0.15, green: 0.15, blue: 0.28, alpha: 1)
            keyLight.color = UIColor(red: 0.5, green: 0.55, blue: 0.85, alpha: 1) // cool "moonlight"
            keyLight.intensity = 150
            rimLight.color = UIColor(red: 0.35, green: 0.25, blue: 0.55, alpha: 1)
            rimLight.intensity = 200
            windowEmissiveMaterials.forEach { $0.emission.intensity = 1.6 }
        }
    }
}

private extension UIColor {
    /// Returns a darker variant of this color by the given fraction (0...1).
    func darker(by fraction: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r * (1 - fraction), green: g * (1 - fraction), blue: b * (1 - fraction), alpha: a)
    }
}

