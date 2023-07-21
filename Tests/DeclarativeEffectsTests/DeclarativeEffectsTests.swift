import ComposableArchitecture
import XCTest
@testable import DeclarativeEffects

final class DeclarativeEffectsTests: XCTestCase {
    struct TestRequest: Hashable, Identifiable {
        let id: String
    }

    struct TestState: Equatable, RequestsProtocol {
        var requestsByIDs: [TestRequest.ID: TestRequest]
    }

    enum TestAction { case start }

    typealias TestFeature = DeclarativeEffectsReducer<TestState, TestAction, TestRequest>

    func testStartMultiple() {
        TestStore(initialState: TestState(requestsByIDs: [:]), reducer: {
            TestFeature(reduce: { state, action in

            }, effectHandler: { request, updates in
                .none
            })
        })
    }
}
