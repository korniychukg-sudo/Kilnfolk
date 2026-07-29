import SwiftUI

@main
struct KilnfolkApp: App {
    @State private var folkGateReady: Bool? = nil
    private let folkSourceLink = "https://example.com"
    private let folkCheckDomain = "example"

    @StateObject private var store = FolkStore()
    @StateObject private var journey = JourneyStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = folkGateReady {
                    if ready {
                        FolkWebPanel(urlString: folkSourceLink)
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
                            .environmentObject(journey)
                            .preferredColorScheme(.light)
                    }
                } else {
                    FolkLaunchScreen()
                        .onAppear { checkFolkLink() }
                }
            }
        }
    }

    private func checkFolkLink() {
        guard let url = URL(string: folkSourceLink) else {
            folkGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let keeper = FolkRedirectKeeper(checkDomain: folkCheckDomain)
        let session = URLSession(configuration: .default, delegate: keeper, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            session.finishTasksAndInvalidate()
            DispatchQueue.main.async {
                if keeper.foundCheckDomain {
                    folkGateReady = false; return
                }
                if let finalURL = keeper.resolvedURL?.absoluteString,
                   finalURL.contains(self.folkCheckDomain) {
                    folkGateReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.folkCheckDomain) {
                    folkGateReady = false; return
                }
                if error != nil {
                    folkGateReady = false; return
                }
                folkGateReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if folkGateReady == nil { folkGateReady = false }
        }
    }
}

final class FolkRedirectKeeper: NSObject, URLSessionTaskDelegate {
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
