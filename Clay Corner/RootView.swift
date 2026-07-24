import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: ClayStore
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        WheelStudioView(selectedTab: $selectedTab)
                    case 1:
                        NavigationView { KilnView().navigationBarHidden(true) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { GalleryView().navigationBarHidden(true) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { JourneyView(selectedTab: $selectedTab) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { MoreView().navigationBarHidden(true) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
        .background(Studio.cream.ignoresSafeArea())
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, label: "Studio", icon: .wheel)
            tabButton(index: 1, label: "Kiln", icon: .kiln, badge: kilnBadge)
            tabButton(index: 2, label: "Gallery", icon: .shelf)
            tabButton(index: 3, label: "Journey", icon: .flag)
            tabButton(index: 4, label: "More", icon: .dots)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Studio.card.edgesIgnoringSafeArea(.bottom))
        .overlay(
            Rectangle()
                .fill(Studio.ink.opacity(0.08))
                .frame(height: 1),
            alignment: .top
        )
    }

    private var kilnBadge: Bool {
        store.firingJob != nil || !store.kilnQueue.isEmpty
    }

    private func tabButton(index: Int, label: String, icon: ClayIconKind, badge: Bool = false) -> some View {
        let selected = selectedTab == index
        return Button(action: { selectedTab = index }) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    ClayIcon(kind: icon, size: 24,
                             color: selected ? Studio.terracotta : Studio.ink.opacity(0.38))
                    if badge {
                        Circle()
                            .fill(Studio.ember)
                            .frame(width: 8, height: 8)
                            .offset(x: 5, y: -2)
                    }
                }
                Text(label)
                    .font(.clayBody(10, .bold))
                    .foregroundColor(selected ? Studio.terracotta : Studio.ink.opacity(0.38))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
