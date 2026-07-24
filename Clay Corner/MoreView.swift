import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: ClayStore
    @State private var showPrivacy = false
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    CornerArt(name: "more_banner")
                        .scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(22)
                        .overlay(
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clay Corner")
                                    .font(.clayTitle(24))
                                    .foregroundColor(.white)
                                Text("A tiny pottery studio in your pocket")
                                    .font(.clayBody(13))
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

                    ClayCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How your studio works")
                                .font(.clayBody(15, .bold))
                                .foregroundColor(Studio.ink)
                            flowRow(icon: .wheel, text: "Shape a pot with one finger while the wheel spins")
                            flowRow(icon: .drop, text: "Dip it in glaze, paint bands, dust on speckles")
                            flowRow(icon: .flame, text: "Fire it in the kiln and wait for the reveal")
                            flowRow(icon: .shelf, text: "Place every finished piece on your gallery shelf")
                        }
                    }

                    ClayCard(padding: 14) {
                        VStack(spacing: 9) {
                            statRow(label: "Pieces thrown", value: "\(store.stats.thrown)")
                            statRow(label: "Pieces fired", value: "\(store.stats.fired)")
                            statRow(label: "On the shelf now", value: "\(store.galleryPots.count)")
                            statRow(label: "Crackle surprises", value: "\(store.galleryPots.filter { $0.crackle }.count)")
                        }
                    }

                    Button(action: { showPrivacy = true }) {
                        HStack(spacing: 12) {
                            ClayIcon(kind: .shield, size: 20, color: Studio.denim)
                            Text("Privacy Policy")
                                .font(.clayBody(15, .bold))
                                .foregroundColor(Studio.ink)
                            Spacer()
                            ClayIcon(kind: .chevronRight, size: 14, color: Studio.inkFaint)
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Studio.card))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: { confirmReset = true }) {
                        HStack(spacing: 12) {
                            ClayIcon(kind: .reset, size: 20, color: Studio.ember)
                            Text("Start the studio over")
                                .font(.clayBody(15, .bold))
                                .foregroundColor(Studio.ember)
                            Spacer()
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Studio.card))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text("Clay Corner 1.0 · made with mud and love")
                        .font(.clayBody(12))
                        .foregroundColor(Studio.inkFaint)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
                .clayReadable()
            }
        }
        .sheet(isPresented: $showPrivacy) {
            CornerWebPanel(urlString: "https://example.com")
        }
        .alert(isPresented: $confirmReset) {
            Alert(title: Text("Start over?"),
                  message: Text("Every pot, the kiln queue and your stats will be cleared. This cannot be undone."),
                  primaryButton: .destructive(Text("Clear everything")) { store.resetAll() },
                  secondaryButton: .cancel(Text("Keep my pots")))
        }
    }

    private func flowRow(icon: ClayIconKind, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ClayIcon(kind: icon, size: 18, color: Studio.terracotta)
                .padding(.top, 1)
            Text(text)
                .font(.clayBody(13))
                .foregroundColor(Studio.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.clayBody(13))
                .foregroundColor(Studio.inkSoft)
            Spacer()
            Text(value)
                .font(.clayBody(14, .bold))
                .foregroundColor(Studio.ink)
        }
    }
}
