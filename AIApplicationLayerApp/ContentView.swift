import SwiftUI
import SceneKit

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    @State private var scene = DashboardScene()
    @State private var showHome = false
    @State private var showContact = false
    @State private var timeOfDay: DashboardScene.TimeOfDay = .day

    var body: some View {
        ZStack {

            SceneView(scene: scene.scene, pointOfView: scene.cameraNode)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        
            VStack {
                Picker("Time of day", selection: $timeOfDay) {
                    ForEach(DashboardScene.TimeOfDay.allCases) { tod in
                        Text(tod.label).tag(tod)
                    }
                }
                .pickerStyle(.segmented)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.top, 12)
                Spacer()
            }

            DashboardPanelView()
                .frame(width: 340, height: 480)
                .rotation3DEffect(.radians(motion.leanAngle * 0.6), axis: (x: 0, y: 0, z: -1), perspective: 0.4)
                .rotation3DEffect(.radians(motion.leanAngle * 0.3), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
                .offset(x: -motion.leanAngle * 40)

            PosterVideoBillboard(isMoving: motion.isMoving)
                .rotation3DEffect(.radians(motion.leanAngle * 0.4), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                .offset(x: 160, y: -180)

            VStack {
                Spacer()
                HStack(spacing: 28) {
                    NavCircle(label: "home") { showHome = true }
                    NavCircle(label: "connect") { showContact = true }
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            motion.start()
            scene.setTimeOfDay(timeOfDay)
        }
        .onDisappear {
            motion.stop()
        }
        .onChange(of: timeOfDay) { newValue in
            scene.setTimeOfDay(newValue)
        }
        .onChange(of: motion.leanAngle) { newValue in
            scene.applyLean(angleRadians: newValue)
        }
        .onChange(of: motion.isMoving) { moving in

            scene.setFountainFlowing(moving)
        }
        .sheet(isPresented: $showHome) { HomeView() }
        .sheet(isPresented: $showContact) { ContactView() }
    }
}

private struct NavCircle: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                    .frame(width: 76, height: 76)
                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
