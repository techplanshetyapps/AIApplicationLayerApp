import Foundation
import CoreMotion
import Combine

final class MotionManager: ObservableObject {

    @Published var leanAngle: Double = 0          // radians, negative = leaning left, positive = leaning right
    @Published var isMoving: Bool = false

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()

    // Tuning knobs
    private let updateInterval: TimeInterval = 1.0 / 60.0
    private let smoothing: Double = 0.15          // low-pass filter factor (0..1, higher = snappier)
    private let movementThreshold: Double = 0.015 // rad/update delta above which we consider it "moving"
    private let stillnessDelay: TimeInterval = 0.5 // how long it must be still before flipping back to "not moving"

    private var lastRoll: Double = 0
    private var stillnessTimer: Timer?

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            let roll = data.attitude.roll // tilting the tablet left/right on a table changes roll
            DispatchQueue.main.async {
                self.handle(roll: roll)
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        stillnessTimer?.invalidate()
    }

    private func handle(roll: Double) {
        // Low-pass filter so the scene doesn't jitter.
        leanAngle = leanAngle + (roll - leanAngle) * smoothing

        let delta = abs(roll - lastRoll)
        lastRoll = roll

        if delta > movementThreshold {
            if !isMoving { isMoving = true }
            // Reset the "settle down" timer every time we see real movement.
            stillnessTimer?.invalidate()
            stillnessTimer = Timer.scheduledTimer(withTimeInterval: stillnessDelay, repeats: false) { [weak self] _ in
                self?.isMoving = false
            }
        }
    }

    // Clamp helper used by the views that map leanAngle to a rotation/parallax offset.
    static func clamp(_ value: Double, min lo: Double, max hi: Double) -> Double {
        max(lo, min(hi, value))
    }
}
