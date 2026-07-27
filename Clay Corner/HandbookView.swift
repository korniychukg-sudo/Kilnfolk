import SwiftUI

// MARK: - Section detail

struct HandbookSectionView: View {
    let section: HandbookSection
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    var body: some View {
        ZStack {
            Studio.cream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        CornerArt(name: section.artName)
                            .scaledToFill()
                            .frame(height: ClayLayout.isPad(hSize, vSize) ? 240 : 170)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(22)
                            .overlay(
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(section.title)
                                        .font(.clayTitle(24))
                                        .foregroundColor(.white)
                                    Text(section.caption)
                                        .font(.clayBody(13))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                .background(
                                    LinearGradient(colors: [.clear, .black.opacity(0.5)],
                                                   startPoint: .center, endPoint: .bottom)
                                )
                                .cornerRadius(22)
                            )
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            HStack(spacing: 4) {
                                ClayIcon(kind: .chevronLeft, size: 13, color: .white)
                                Text("Handbook")
                                    .font(.clayBody(12, .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.black.opacity(0.35)))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(10)
                    }

                    Text(section.intro)
                        .font(.clayBody(14))
                        .foregroundColor(Studio.ink.opacity(0.85))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    ClaySectionHeader(title: section.itemsHeading)

                    ForEach(section.items) { item in
                        itemCard(item)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .clayReadable()
            }
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func itemCard(_ item: HandbookItem) -> some View {
        ClayCard(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                if let art = item.artName {
                    CornerArt(name: art)
                        .scaledToFill()
                        .frame(height: ClayLayout.isPad(hSize, vSize) ? 190 : 130)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(14)
                }
                HStack(spacing: 10) {
                    if let n = item.stepNumber {
                        ZStack {
                            Circle().fill(Studio.terracotta.opacity(0.15))
                                .frame(width: 30, height: 30)
                            Text("\(n)")
                                .font(.clayBody(14, .bold))
                                .foregroundColor(Studio.terracotta)
                        }
                    }
                    if let kind = item.clayKind {
                        ZStack {
                            Circle().fill(kind.wetTone.color).frame(width: 30, height: 30)
                            Circle().fill(kind.firedTone.color).frame(width: 14, height: 14)
                                .offset(x: 8, y: 8)
                        }
                        .frame(width: 34, height: 34)
                    }
                    if let glazeID = item.glazeID, let glaze = GlazeCatalog.recipe(glazeID) {
                        ZStack {
                            Circle().fill(glaze.fired.color).frame(width: 30, height: 30)
                            Circle().fill(glaze.wet.color).frame(width: 30, height: 30)
                                .mask(Rectangle().frame(width: 15).frame(maxWidth: .infinity, alignment: .leading))
                            Circle().stroke(Studio.ink.opacity(0.15), lineWidth: 1)
                                .frame(width: 30, height: 30)
                        }
                    }
                    Text(item.title)
                        .font(.clayBody(15, .bold))
                        .foregroundColor(Studio.ink)
                    Spacer()
                }
                Text(item.text)
                    .font(.clayBody(13))
                    .foregroundColor(Studio.ink.opacity(0.8))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
