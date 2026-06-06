import SwiftUI

struct DashboardShellView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        @Bindable var session = session

        VStack(spacing: 0) {
            DashboardHeaderView()

            TabView(selection: $session.selectedTab) {
                CareTabView()
                    .tabItem { Label("Care", systemImage: "heart.text.square") }
                    .tag(DashboardTab.care)

                ExercisesView()
                    .tabItem { Label("Exercises", systemImage: "list.clipboard") }
                    .tag(DashboardTab.exercises)

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "dog") }
                    .tag(DashboardTab.profile)
            }
            .tint(StarkTheme.primary)
        }
        .background(StarkTheme.background)
    }
}

struct CareTabView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        @Bindable var session = session

        VStack(spacing: 0) {
            CareSubNavView(selection: $session.careSubTab)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Group {
                switch session.careSubTab {
                case .today:
                    NavigationStack {
                        TodayView()
                    }
                case .calendar:
                    CalendarView()
                case .history:
                    HistoryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: session.calendarSelectedDate) { _, newDate in
            if newDate != nil {
                session.careSubTab = .calendar
            }
        }
    }
}
