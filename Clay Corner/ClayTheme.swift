import SwiftUI

// MARK: - Palette

enum Studio {
    static let cream = Color(red: 0.969, green: 0.941, blue: 0.898)
    static let linen = Color(red: 0.941, green: 0.902, blue: 0.839)
    static let card = Color(red: 1.0, green: 0.988, blue: 0.965)
    static let ink = Color(red: 0.271, green: 0.208, blue: 0.169)
    static let inkSoft = Color(red: 0.271, green: 0.208, blue: 0.169).opacity(0.62)
    static let inkFaint = Color(red: 0.271, green: 0.208, blue: 0.169).opacity(0.36)
    static let terracotta = Color(red: 0.769, green: 0.412, blue: 0.247)
    static let terracottaDeep = Color(red: 0.639, green: 0.310, blue: 0.173)
    static let sage = Color(red: 0.529, green: 0.612, blue: 0.482)
    static let denim = Color(red: 0.353, green: 0.475, blue: 0.573)
    static let honey = Color(red: 0.871, green: 0.665, blue: 0.298)
    static let wood = Color(red: 0.651, green: 0.506, blue: 0.353)
    static let woodDark = Color(red: 0.510, green: 0.376, blue: 0.247)
    static let ember = Color(red: 0.898, green: 0.443, blue: 0.204)
    static let shadow = Color(red: 0.29, green: 0.21, blue: 0.12).opacity(0.16)
}

// MARK: - Fonts

extension Font {
    static func clayTitle(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func clayBody(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Art loading (Art/ folder reference, cached)

final class CornerArtShelf {
    static let shared = CornerArtShelf()
    private var cache: [String: UIImage] = [:]
    private let lock = NSLock()

    func image(_ name: String) -> UIImage? {
        lock.lock(); defer { lock.unlock() }
        if let img = cache[name] { return img }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Art"),
              let img = UIImage(contentsOfFile: url.path) else { return nil }
        cache[name] = img
        return img
    }
}

/// Bundled painting; falls back to a tinted rectangle when a file is missing.
struct CornerArt: View {
    let name: String
    var fallback: Color = Studio.linen

    var body: some View {
        if let ui = CornerArtShelf.shared.image(name) {
            Image(uiImage: ui).resizable()
        } else {
            fallback
        }
    }
}

// MARK: - Shared components

struct ClayCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Studio.card)
                    .shadow(color: Studio.shadow, radius: 10, x: 0, y: 5)
            )
    }
}

struct ClaySectionHeader: View {
    let title: String
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.clayTitle(21))
                .foregroundColor(Studio.ink)
            if let caption = caption {
                Text(caption)
                    .font(.clayBody(13))
                    .foregroundColor(Studio.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ClayPrimaryButton: View {
    let title: String
    var tint: Color = Studio.terracotta
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .font(.clayBody(17, .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    Capsule().fill(enabled ? tint : Studio.inkFaint)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
    }
}

struct ClayChip: View {
    let text: String
    var tint: Color = Studio.terracotta

    var body: some View {
        Text(text)
            .font(.clayBody(12, .bold))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(tint.opacity(0.14)))
    }
}

enum ClayLayout {
    /// True only on iPad — an iPhone in landscape stays compact vertically.
    static func isPad(_ horizontal: UserInterfaceSizeClass?, _ vertical: UserInterfaceSizeClass?) -> Bool {
        horizontal == .regular && vertical == .regular
    }

    /// Banner art is cropped to its height, so give it more room on a wide iPad.
    static func bannerHeight(_ horizontal: UserInterfaceSizeClass?, _ vertical: UserInterfaceSizeClass?) -> CGFloat {
        isPad(horizontal, vertical) ? 210 : 150
    }
}

/// Readable width on iPad-class screens while staying full-bleed on iPhone.
struct ClayReadableWidth: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(maxWidth: 660)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func clayReadable() -> some View { modifier(ClayReadableWidth()) }
}
