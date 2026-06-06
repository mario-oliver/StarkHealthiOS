import ClerkKit
import Foundation
import Observation

enum AppFlow: Equatable {
    case bootstrap
    case onboarding
    case join
    case dashboard
}

enum DashboardTab: Hashable {
    case care
    case exercises
    case profile
}

enum CareSubTab: String, CaseIterable, Hashable {
    case today = "Today"
    case calendar = "Calendar"
    case history = "History"
}

@MainActor
@Observable
final class SessionStore {
    var flow: AppFlow = .bootstrap
    var dogs: [DogRecord] = []
    var activeDogId: String?
    var selectedTab: DashboardTab = .care
    var careSubTab: CareSubTab = .today
    var calendarSelectedDate: String?
    var isBootstrapping = false
    var bootstrapError: String?

    var apiClient = APIClient()

    var activeDog: DogRecord? {
        guard let activeDogId else { return nil }
        return dogs.first(where: { $0.id == activeDogId })
    }

    func configure(clerk: Clerk) {
        apiClient.tokenProvider = {
            try await clerk.auth.getToken()
        }
    }

    func bootstrap() async {
        isBootstrapping = true
        bootstrapError = nil
        defer { isBootstrapping = false }

        do {
            let loaded = try await apiClient.listDogs()
            dogs = loaded
            if loaded.isEmpty {
                flow = .onboarding
                activeDogId = nil
            } else {
                activeDogId = ActiveDogStore.resolveDogId(dogs: loaded)
                flow = .dashboard
            }
        } catch {
            bootstrapError = error.localizedDescription
        }
    }

    func refreshDogs() async {
        do {
            dogs = try await apiClient.listDogs()
            if dogs.isEmpty {
                flow = .onboarding
                activeDogId = nil
            } else if let activeDogId, !dogs.contains(where: { $0.id == activeDogId }) {
                self.activeDogId = ActiveDogStore.resolveDogId(dogs: dogs)
            }
        } catch {
            bootstrapError = error.localizedDescription
        }
    }

    func selectDog(_ dogId: String) {
        activeDogId = dogId
        ActiveDogStore.setActiveDogId(dogId)
    }

    func completeOnboarding(dog: DogRecord) {
        dogs.append(dog)
        selectDog(dog.id)
        flow = .dashboard
        selectedTab = .care
        careSubTab = .today
    }

    func completeJoin(dog: DogRecord) async {
        await refreshDogs()
        selectDog(dog.id)
        flow = .dashboard
        selectedTab = .care
        careSubTab = .today
    }

    func showJoinFlow() {
        flow = .join
    }

    func openCalendarDate(_ date: String) {
        calendarSelectedDate = date
        selectedTab = .care
        careSubTab = .calendar
    }
}
