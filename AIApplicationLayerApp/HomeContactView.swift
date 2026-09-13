import SwiftUI

struct HomeView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Smart Supply Chain Optimization Dashboard")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                Text("A SwiftUI port of the ai-application-layer RAG dashboard, staged as a 3D Smart Supply Chain Optimization scene.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ContactView: View {
    @Environment(\.dismiss) private var dismiss

    // Replace these slugs with your actual handles.
    private let linkedInSlug = "nataliia-rudnikova"
    private let vimeoSlug = "186275325"
    private let githubSlug = "techplanshetyapps"

    var body: some View {
        NavigationStack {
            List {
                LinkRow(title: "LinkedIn", slug: linkedInSlug, url: "https://linkedin.com/in/\(linkedInSlug)")
                LinkRow(title: "Vimeo", slug: vimeoSlug, url: "https://vimeo.com/\(vimeoSlug)")
                LinkRow(title: "GitHub", slug: githubSlug, url: "https://github.com/\(githubSlug)")
            }
            .navigationTitle("Connect")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct LinkRow: View {
    let title: String
    let slug: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title).font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("/\(slug)").font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .contentShape(Rectangle()) // makes the ENTIRE row tappable, not just the text/icon glyphs
        }
        .buttonStyle(.plain)
    }
}
