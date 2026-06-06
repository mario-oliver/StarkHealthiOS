import SwiftUI

struct DashboardShellView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        @Bindable var session = session

        VStack(spacing: 0) {
            DashboardHeaderView()

            Group {
                switch session.selectedTab {
                case .care:
                    CareTabView()
                case .exercises:
                    ExercisesView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(StarkTheme.background)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DashboardBottomBarView()
                .background(StarkTheme.background)
        }
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
