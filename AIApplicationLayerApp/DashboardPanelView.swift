import SwiftUI

/// Mirrors public/index.html from the Node app: trigger ingestion, ask a question,
/// see the Gemma-generated, source-cited answer — using the exact field names
/// index.js actually returns.
struct DashboardPanelView: View {
    @State private var question: String = ""
    @State private var limitText: String = "10"
    @State private var split: String = "test"

    @State private var answer: String = ""
    @State private var modelUsed: String = ""
    @State private var sources: [APIClient.QuerySource] = []

    @State private var isBusy = false
    @State private var statusText = "Checking status…"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SCI/TECH RAG DASHBOARD")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .purple.opacity(0.8), radius: 0, x: 2, y: 2)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 3)

            Text(statusText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 8) {
                Picker("Split", selection: $split) {
                    Text("test split (7.6k)").tag("test")
                    Text("train split (120k)").tag("train")
                }
                .pickerStyle(.menu)
                .tint(.white)

                TextField("Limit", text: $limitText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 70)
            }

            Button {
                Task { await runIngest() }
            } label: {
                Label("Ingest Sci/Tech Articles", systemImage: "tray.and.arrow.down.fill")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.98, green: 0.55, blue: 0.25), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .disabled(isBusy)

            // --- Query controls ---
            TextField("Ask about a Sci/Tech article…", text: $question)
                .textFieldStyle(.roundedBorder)
                .disabled(isBusy)

            Button {
                Task { await runQuery() }
            } label: {
                Label("Ask Gemma", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0.62, green: 0.40, blue: 0.92), in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .disabled(isBusy || question.isEmpty)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if !answer.isEmpty {
                        Text(answer)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(.white)
                        if !modelUsed.isEmpty {
                            Text("via \(modelUsed)")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    if !sources.isEmpty {
                        Text("Sources")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                        ForEach(Array(sources.enumerated()), id: \.offset) { i, s in
                            Text("[\(i + 1)] \(s.title ?? s.sourceId ?? "untitled")")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(.ultraThinMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.25), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 10)
        .task { await loadHealth() }
    }

    private func loadHealth() async {
        do {
            let health = try await APIClient.health()
            if health.ok {
                statusText = "Model: \(health.gemmaModel ?? "n/a") · Vectors: \(health.vectorCount.map(String.init) ?? "n/a")"
            } else {
                statusText = "Status error: \(health.error ?? "unknown")"
            }
        } catch {
            statusText = "Status unavailable"
        }
    }

    private func runIngest() async {
        isBusy = true
        statusText = "Fetching from Hugging Face and embedding…"
        do {
            let limit = Int(limitText) ?? 10
            let result = try await APIClient.ingest(limit: limit, split: split)
            statusText = result.message
        } catch {
            statusText = "Ingest error: \(error.localizedDescription)"
        }
        isBusy = false
        await loadHealth()
    }

    private func runQuery() async {
        isBusy = true
        statusText = "Retrieving context and asking Gemma…"
        do {
            let result = try await APIClient.query(question)
            answer = result.answer
            modelUsed = result.model ?? ""
            sources = result.sources
            statusText = "Ready"
        } catch {
            answer = "Error: \(error.localizedDescription)"
            sources = []
            statusText = "Query failed"
        }
        isBusy = false
    }
}
