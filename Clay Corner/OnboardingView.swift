import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    private struct Slide {
        let art: String
        let title: String
        let text: String
    }

    private let slides: [Slide] = [
        Slide(art: "onboarding_wheel",
              title: "Shape it with a finger",
              text: "Start the wheel, touch the spinning clay, and push the wall in or out. Sponge it smooth, rib it straight, lift it tall — just like the real thing."),
        Slide(art: "onboarding_glaze",
              title: "Glaze and fire",
              text: "Dip your pot in one of twelve glazes, paint bands, dust on speckles. Then load the kiln and wait for the reveal — the fire always changes the colors."),
        Slide(art: "onboarding_shelf",
              title: "Grow as a potter",
              text: "Throw the 12 classic forms — from Tea Bowl to Meiping — and earn stars for accuracy. Rank up to unlock glazes and clays, collect awards, and fill your gallery shelf."),
    ]

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    if page < slides.count - 1 {
                        Button(action: onDone) {
                            Text("Skip")
                                .font(.clayBody(14, .bold))
                                .foregroundColor(Studio.inkSoft)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Studio.card))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .frame(height: 48)

                Spacer(minLength: 0)

                CornerArt(name: slides[page].art)
                    .scaledToFit()
                    .frame(maxWidth: 420)
                    .frame(maxHeight: 340)
                    .cornerRadius(26)
                    .padding(.horizontal, 26)
                    .id(page)
                    .transition(.opacity)

                VStack(spacing: 10) {
                    Text(slides[page].title)
                        .font(.clayTitle(26))
                        .foregroundColor(Studio.ink)
                        .multilineTextAlignment(.center)
                    Text(slides[page].text)
                        .font(.clayBody(15))
                        .foregroundColor(Studio.inkSoft)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 34)
                }
                .padding(.top, 20)

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Studio.terracotta : Studio.inkFaint)
                            .frame(width: i == page ? 22 : 7, height: 7)
                    }
                }
                .padding(.bottom, 18)

                ClayPrimaryButton(title: page == slides.count - 1 ? "Into the studio" : "Next") {
                    if page == slides.count - 1 {
                        onDone()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 28)
                .frame(maxWidth: 480)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 25)
                .onEnded { value in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if value.translation.width < -40, page < slides.count - 1 { page += 1 }
                        if value.translation.width > 40, page > 0 { page -= 1 }
                    }
                }
        )
    }
}
