import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: FolkStore
    @EnvironmentObject var journey: JourneyStore
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize
    @State private var showPrivacy = false
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    FolkArt(name: "more_banner")
                        .scaledToFill()
                        .frame(height: FolkLayout.bannerHeight(hSize, vSize) - 10)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(22)
                        .overlay(
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kilnfolk")
                                    .font(.folkTitle(24))
                                    .foregroundColor(.white)
                                Text("A tiny pottery studio in your pocket")
                                    .font(.folkBody(13))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            .background(
                                LinearGradient(colors: [.clear, .black.opacity(0.45)],
                                               startPoint: .center, endPoint: .bottom)
                            )
                            .cornerRadius(22)
                        )
                        .padding(.top, 12)

                    FolkCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How your studio works")
                                .font(.folkBody(15, .bold))
                                .foregroundColor(Studio.ink)
                            flowRow(icon: .wheel, text: "Shape a pot with one finger while the wheel spins")
                            flowRow(icon: .flag, text: "Throw the 12 classic forms and earn stars for accuracy")
                            flowRow(icon: .drop, text: "Dip it in glaze, paint bands, dust on speckles")
                            flowRow(icon: .flame, text: "Fire it in the kiln — XP, ranks and new glazes await")
                            flowRow(icon: .shelf, text: "Place every finished piece on your gallery shelf")
                        }
                    }

                    FolkCard(padding: 14) {
                        VStack(spacing: 9) {
                            statRow(label: "Potter's rank", value: "\(journey.level) · \(journey.rankName)")
                            statRow(label: "Journey XP", value: "\(journey.state.xp)")
                            statRow(label: "Form stars", value: "\(journey.totalStars) of 36")
                            statRow(label: "Daily streak",
                                    value: "\(journey.state.dailyStreak) day\(journey.state.dailyStreak == 1 ? "" : "s")")
                            statRow(label: "Pieces thrown", value: "\(store.stats.thrown)")
                            statRow(label: "Pieces fired", value: "\(store.stats.fired)")
                            statRow(label: "On the shelf now", value: "\(store.galleryPots.count)")
                            statRow(label: "Crackle surprises", value: "\(store.galleryPots.filter { $0.crackle }.count)")
                        }
                    }

                    Button(action: { showPrivacy = true }) {
                        HStack(spacing: 12) {
                            FolkIcon(kind: .shield, size: 20, color: Studio.denim)
                            Text("Privacy Policy")
                                .font(.folkBody(15, .bold))
                                .foregroundColor(Studio.ink)
                            Spacer()
                            FolkIcon(kind: .chevronRight, size: 14, color: Studio.inkFaint)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Studio.card))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { confirmReset = true }) {
                        HStack(spacing: 12) {
                            FolkIcon(kind: .reset, size: 20, color: Studio.ember)
                            Text("Start the studio over")
                                .font(.folkBody(15, .bold))
                                .foregroundColor(Studio.ember)
                            Spacer()
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Studio.card))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text("Kilnfolk 1.0 · made with mud and love")
                        .font(.folkBody(12))
                        .foregroundColor(Studio.inkFaint)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
                .folkReadable()
            }
        }
        .sheet(isPresented: $showPrivacy) {
            FolkPrivacyView()
        }
        .alert(isPresented: $confirmReset) {
            Alert(title: Text("Start over?"),
                  message: Text("Every pot, the kiln queue, your rank, stars and awards will be cleared. This cannot be undone."),
                  primaryButton: .destructive(Text("Clear everything")) {
                      store.resetAll()
                      journey.resetAll()
                  },
                  secondaryButton: .cancel(Text("Keep my pots")))
        }
    }

    private func flowRow(icon: FolkIconKind, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            FolkIcon(kind: icon, size: 18, color: Studio.terracotta)
                .padding(.top, 1)
            Text(text)
                .font(.folkBody(13))
                .foregroundColor(Studio.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.folkBody(13))
                .foregroundColor(Studio.inkSoft)
            Spacer()
            Text(value)
                .font(.folkBody(14, .bold))
                .foregroundColor(Studio.ink)
        }
    }
}

private struct FolkPrivacyView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    policySection("Overview",
                                  "Kilnfolk works entirely on your device. The app does not require an account, does not connect to the internet and does not send any information anywhere.")
                    policySection("What is stored",
                                  "Your thrown pots, glazes, studio progress and settings are saved only in the app's private storage on this device. Nothing is uploaded or shared.")
                    policySection("Analytics & tracking",
                                  "Kilnfolk contains no analytics, no advertising and no third-party code that collects data. The app never tracks you across other apps or websites.")
                    policySection("Your control",
                                  "You can erase everything at any time with the reset option in More, or by deleting the app. Removing the app removes all of its data.")
                }
                .padding(18)
            }
            .background(Studio.cream.ignoresSafeArea())
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func policySection(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.folkBody(15, .semibold))
                .foregroundColor(Studio.ink)
            Text(text)
                .font(.folkBody(13))
                .foregroundColor(Studio.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
