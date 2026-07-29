import SwiftUI

struct HandbookItem: Identifiable {
    let id: String
    let title: String
    let text: String
    var artName: String? = nil
    var glazeID: String? = nil
    var clayKind: ClayBodyKind? = nil
    var stepNumber: Int? = nil
}

struct HandbookSection: Identifiable {
    let id: String
    let title: String
    let caption: String
    let artName: String
    let intro: String
    let itemsHeading: String
    let items: [HandbookItem]
}

enum HandbookLibrary {
    static let sections: [HandbookSection] = [wheelCraft, meetTheClays, glazeAlmanac, insideTheKiln, shortHistory, careAndKeeping]

    // MARK: Wheel craft

    static let wheelCraft = HandbookSection(
        id: "wheel",
        title: "Throwing on the Wheel",
        caption: "The eight moves every potter learns",
        artName: "hb_wheel",
        intro: "Watching a potter work looks like magic: a spinning lump becomes a bowl in minutes. Underneath the magic is a sequence of small, patient moves — the same eight steps repeated for thousands of years. Here they are, the way a teacher would walk you through your first day at the wheel.",
        itemsHeading: "The eight moves",
        items: [
            HandbookItem(id: "wedge", title: "Wedging",
                         text: "Before the wheel ever spins, the clay is kneaded like bread dough. Wedging pushes out air bubbles and lines up the clay particles. A hidden bubble can burst in the kiln, so potters wedge with real devotion.",
                         artName: "tech_01", stepNumber: 1),
            HandbookItem(id: "center", title: "Centering",
                         text: "The lump is pressed onto the spinning wheel head and coaxed into the exact middle. When the clay runs true — no wobble under steady hands — it is centered. Most beginners spend their whole first lesson right here.",
                         artName: "tech_02", stepNumber: 2),
            HandbookItem(id: "open", title: "Opening",
                         text: "Thumbs press down into the centered mound to make the first hollow. The floor of the pot is set now: press too deep and the wheel head says hello through the bottom.",
                         artName: "tech_03", stepNumber: 3),
            HandbookItem(id: "pull", title: "Pulling up the walls",
                         text: "Fingertips inside and out squeeze the wall gently while the wheel turns, and the clay rises between them. Three good pulls can triple a pot's height. In Kilnfolk, the Lift tool does exactly this.",
                         artName: "tech_04", stepNumber: 4),
            HandbookItem(id: "shape", title: "Shaping",
                         text: "With the walls up, a light touch swells the belly outward or necks the rim inward. The pot finds its character here — this is the part you do with a fingertip on the glass.",
                         artName: "tech_05", stepNumber: 5),
            HandbookItem(id: "rib", title: "Ribbing",
                         text: "A rib — a flat blade of wood or metal — is held against the wall to smooth finger ridges and firm up curves. It leaves the surface clean and taut, like a made bed.",
                         artName: "tech_06", stepNumber: 6),
            HandbookItem(id: "wire", title: "Wiring off",
                         text: "A twisted wire slides under the foot to free the pot from the wheel head, the same way cheese leaves the block. Then comes the bravest moment: lifting a soft pot without squeezing it.",
                         artName: "tech_07", stepNumber: 7),
            HandbookItem(id: "dry", title: "Drying to leather-hard",
                         text: "The pot rests until it is firm but still cool to the touch — leather-hard. Now it can be trimmed, carved, and handled. Fully bone-dry clay is next, and then the fire.",
                         artName: "tech_08", stepNumber: 8),
        ]
    )

    // MARK: Clays

    static let meetTheClays = HandbookSection(
        id: "clays",
        title: "Meet the Clays",
        caption: "Four bodies, four personalities",
        artName: "hb_clay",
        intro: "Clay is not one thing. Every clay body is a recipe of minerals with its own color, temper and temperament. The four in your studio cover the classics — from garden-pot orange to gallery-white porcelain.",
        itemsHeading: "In your studio",
        items: ClayBodyKind.allCases.map { kind in
            HandbookItem(id: kind.rawValue, title: kind.displayName, text: fullClayStory(kind), clayKind: kind)
        }
    )

    private static func fullClayStory(_ kind: ClayBodyKind) -> String {
        switch kind {
        case .terracotta:
            return "The people's clay. Iron oxide gives terracotta its famous orange and keeps its firing temperature low, which is why it shows up everywhere from Roman roof tiles to your grandmother's flowerpots. It stays slightly porous after firing — plants love it for exactly that reason."
        case .speckledBuff:
            return "A warm sandy stoneware with crushed iron flecks kneaded through it. In the kiln the flecks melt into little freckles that burst through the glaze. No two speckled pots ever match, which is the whole point."
        case .porcelain:
            return "The aristocrat. Made from kaolin, porcelain fires bright white and can be thrown paper-thin until it glows against the light. It is also famously moody on the wheel — potters say it has a memory and holds grudges."
        case .midnight:
            return "A modern studio favorite: stoneware stained nearly black with manganese and iron. Glazes float on it like moonlight on dark water, and bare unglazed areas fire to a soft charcoal velvet."
        }
    }

    // MARK: Glazes

    static let glazeAlmanac = HandbookSection(
        id: "glazes",
        title: "The Glaze Almanac",
        caption: "Twelve finishes and their moods",
        artName: "hb_glaze",
        intro: "A glaze is glass in disguise: a powdery coat that melts in the kiln and freezes into a colored skin. The left half of each swatch shows the dull raw glaze as you brush it on; the right half shows what the fire makes of it. Trusting that transformation is half the craft.",
        itemsHeading: "The twelve",
        items: GlazeCatalog.all.map { glaze in
            HandbookItem(id: glaze.id, title: glaze.name, text: glaze.blurb + glazeExtra(glaze), glazeID: glaze.id)
        }
    )

    private static func glazeExtra(_ glaze: GlazeRecipe) -> String {
        var notes: [String] = []
        if glaze.gloss > 0.75 { notes.append("Fires high-gloss — expect mirror shine.") }
        else if glaze.gloss < 0.45 { notes.append("Fires satin-matte and soft to the touch.") }
        if glaze.speckled { notes.append("Carries speckles that bloom in the fire.") }
        return notes.isEmpty ? "" : " " + notes.joined(separator: " ")
    }

    // MARK: Kiln

    static let insideTheKiln = HandbookSection(
        id: "kiln",
        title: "Inside the Kiln",
        caption: "What the fire actually does",
        artName: "hb_kiln",
        intro: "A kiln is an oven that goes far beyond baking — at full temperature its walls glow the color of a sunset. Inside, clay stops being mud forever. The journey happens in stages, and skipping any of them ends in shards.",
        itemsHeading: "The firing journey",
        items: [
            HandbookItem(id: "bone", title: "Bone dry",
                         text: "Every drop of water must leave the clay before serious heat arrives. Water that stays behind turns to steam and pops the pot apart. Potters hold a piece to their cheek — if it feels cold, it is still damp.", stepNumber: 1),
            HandbookItem(id: "bisque", title: "The bisque fire",
                         text: "A first, gentler firing to about 950°C. The clay becomes hard, porous ceramic — permanent now, but thirsty enough to drink up glaze. Bisqueware sounds like a bell when you tap it.", stepNumber: 2),
            HandbookItem(id: "glazing", title: "Glazing day",
                         text: "Raw glaze looks like chalky soup and gives no hint of its fired color. Pieces are dipped, poured and banded — and the bottom is wiped clean, or the pot will weld itself to the kiln shelf.", stepNumber: 3),
            HandbookItem(id: "glazefire", title: "The glaze fire",
                         text: "The main event. Around 1220°C (potters call it cone 6) the glaze melts into liquid glass and fuses to the clay. Colors shift dramatically: dusty pink becomes deep red, chalk grey becomes ocean blue.", stepNumber: 4),
            HandbookItem(id: "cooldown", title: "The cool-down",
                         text: "Opening a hot kiln can crack a whole load, so potters wait — often a full day — while the kiln creaks and ticks. Some glazes keep changing as they cool. The reveal is pottery's best gift.", stepNumber: 5),
        ]
    )

    // MARK: History

    static let shortHistory = HandbookSection(
        id: "history",
        title: "A Short History of Pots",
        caption: "Twenty thousand years in six shelves",
        artName: "hb_history",
        intro: "Pottery is the oldest craft we still practice nearly unchanged. Fired clay outlives empires — most of what we know about ancient kitchens, we know from their pots.",
        itemsHeading: "Six moments",
        items: [
            HandbookItem(id: "first", title: "The first vessels · ~18,000 BC",
                         text: "In caves in what is now China, someone pressed clay into a basket shape and left it near the fire. The oldest known pottery predates farming — we made pots before we planted wheat.", stepNumber: 1),
            HandbookItem(id: "wheelinv", title: "The wheel arrives · ~3,500 BC",
                         text: "Mesopotamian potters set clay on a turning platform, and suddenly a vessel that took an afternoon of coiling took minutes. The potter's wheel may be older than the cart wheel.", stepNumber: 2),
            HandbookItem(id: "greece", title: "Stories on clay · ~600 BC",
                         text: "Greek painters turned amphorae into comic strips of gods and heroes in red and black. Museums are full of them because fired clay simply refuses to rot.", stepNumber: 3),
            HandbookItem(id: "china", title: "The porcelain secret · ~700 AD",
                         text: "Tang dynasty kilns learned to fire kaolin white and translucent. Europe spent a thousand years and small fortunes trying to copy it — 'china' became the material's everyday name.", stepNumber: 4),
            HandbookItem(id: "japan", title: "Beauty in repair · ~1500 AD",
                         text: "Japanese tea masters prized humble, imperfect bowls — and mended broken ones with gold-dusted lacquer. Kintsugi made the crack part of the story instead of the end of it.", stepNumber: 5),
            HandbookItem(id: "studio", title: "The studio movement · ~1950",
                         text: "Potters like Bernard Leach and Lucie Rie pulled the craft out of factories and back to small workshops. The handmade mug on your desk is their doing.", stepNumber: 6),
        ]
    )

    // MARK: Care

    static let careAndKeeping = HandbookSection(
        id: "care",
        title: "Care & Keeping",
        caption: "Making handmade pots last",
        artName: "hb_care",
        intro: "A well-fired pot can outlast its potter by a few thousand years, but a little kindness helps. Six habits that keep handmade ceramics happy.",
        itemsHeading: "Six kind habits",
        items: [
            HandbookItem(id: "shock", title: "Avoid thermal shock",
                         text: "Clay hates surprises. Boiling water into a cold mug, or a hot dish onto cold stone, can crack even sturdy stoneware. Warm things gently and they will forgive you.", stepNumber: 1),
            HandbookItem(id: "wash", title: "Wash by hand when you can",
                         text: "Most stoneware survives dishwashers, but handmade glazes stay glossier with a soft sponge. Skip steel wool — it leaves grey pencil-like marks on matte glaze.", stepNumber: 2),
            HandbookItem(id: "stack", title: "Stack with padding",
                         text: "Rims chip when pots clatter together. A paper napkin between stacked bowls is the cheapest insurance in the kitchen.", stepNumber: 3),
            HandbookItem(id: "crazing", title: "Know your crackle",
                         text: "Fine web lines in the glaze — crazing — are usually a decorative feature, not damage. On purely decorative pieces, enjoy them; on daily-use tableware, prefer clean glaze.", stepNumber: 4),
            HandbookItem(id: "terracare", title: "Let terracotta breathe",
                         text: "Unglazed terracotta is porous: it drinks water, sweats it out and grows a lovely pale patina. For plants that is perfect; for the dinner table choose glazed ware.", stepNumber: 5),
            HandbookItem(id: "display", title: "Give pieces the light",
                         text: "Glazes were born in fire and love light. A shelf near a window brings out depth you will never see in a cupboard — museum curators fuss over lamp angles for a reason.", stepNumber: 6),
        ]
    )
}
