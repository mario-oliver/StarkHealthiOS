import SwiftUI

struct DashboardShellView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        @Bindable var session = session

        VStack(spacing: 0) {
            DashboardHeaderView()

            TabView(selection: $session.selectedTab) {
                CareTabView()
                    .tag(DashboardTab.care)

                ExercisesView()
                    .tag(DashboardTab.exercises)

                ProfileView()
                    .tag(DashboardTab.profile)
            }
            .toolbar(.hidden, for: .tabBar)
        }
        .background(StarkTheme.background)
        .safeAreaInset(edge: .bottom) {
            DashboardBottomBarView()
        }
    }
}

struct CareTabView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        @Bindable var session = session

        VStack(spacing: 0) {
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
