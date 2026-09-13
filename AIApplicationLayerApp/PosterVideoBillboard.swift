import SwiftUI
import WebKit

struct PosterVideoBillboard: View {
    let isMoving: Bool
    let vimeoID: String = "186275325"

    var body: some View {
        ZStack {
            if isMoving {
                VimeoLoopingPlayer(vimeoID: vimeoID)
                    .transition(.opacity)
            } else {
                posterView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isMoving)
        .frame(width: 220, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.25), lineWidth: 2))
        .shadow(color: .black.opacity(0.5), radius: 10, y: 6)
    }

    private var posterView: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.44, green: 0.50, blue: 0.56),
                                     Color(red: 0.83, green: 0.87, blue: 0.89)],
                            startPoint: .top, endPoint: .bottom)
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "building.2.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundStyle(.white.opacity(0.9))
                Text("Gemma Sci/Tech RAG Assistant")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("Nowadays composing Smart Supply Chain Optimization Dashboard")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
            }
            .padding()
        }
    }
}

struct VimeoLoopingPlayer: UIViewRepresentable {
    let vimeoID: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        load(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    private func load(into webView: WKWebView) {

        let urlString = "https://player.vimeo.com/video/\(vimeoID)?background=1&autoplay=1&loop=1&muted=1&byline=0&title=0&portrait=0"
        guard let url = URL(string: urlString) else { return }
        webView.load(URLRequest(url: url))
    }
}
