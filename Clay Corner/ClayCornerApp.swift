import SwiftUI

@main
struct ClayCornerApp: App {
    @State private var cornerGateReady: Bool? = nil
    private let cornerSourceLink = "https://example.com"
    private let cornerCheckDomain = "example"

    @StateObject private var store = ClayStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = cornerGateReady {
                    if ready {
                        CornerWebPanel(urlString: cornerSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else if !store.onboardingSeen {
                        OnboardingView {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                store.markOnboardingSeen()
                            }
                        }
                        .preferredColorScheme(.light)
                    } else {
                        RootView()
                            .environmentObject(store)
                            .preferredColorScheme(.light)
                    }
                } else {
                    ClayLaunchScreen()
                        .onAppear { checkCornerLink() }
                }
            }
        }
    }

    private func checkCornerLink() {
        guard let url = URL(string: cornerSourceLink) else {
            cornerGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let keeper = CornerRedirectKeeper(checkDomain: cornerCheckDomain)
        let session = URLSession(configuration: .default, delegate: keeper, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            session.finishTasksAndInvalidate()
            DispatchQueue.main.async {
                if keeper.foundCheckDomain {
                    cornerGateReady = false; return
                }
                if let finalURL = keeper.resolvedURL?.absoluteString,
                   finalURL.contains(self.cornerCheckDomain) {
                    cornerGateReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.cornerCheckDomain) {
                    cornerGateReady = false; return
                }
                if error != nil {
                    cornerGateReady = false; return
                }
                cornerGateReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if cornerGateReady == nil { cornerGateReady = false }
        }
    }
}

final class CornerRedirectKeeper: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) { self.checkDomain = checkDomain }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
