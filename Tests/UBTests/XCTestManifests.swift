#if !canImport(ObjectiveC)
import XCTest

extension NodeTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__NodeTests = [
        ("testAddTransport", testAddTransport),
        ("testDoesNotSendWhenNoPeerOrServiceInMessage", testDoesNotSendWhenNoPeerOrServiceInMessage),
        ("testRemoveTransport", testRemoveTransport),
        ("testSendsToAllPeersExceptOriginWhenExactMatchNotFound", testSendsToAllPeersExceptOriginWhenExactMatchNotFound),
        ("testSendsToAllPeersWithSameServiceId", testSendsToAllPeersWithSameServiceId),
        ("testSendToSinglePeer", testSendToSinglePeer),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(NodeTests.__allTests__NodeTests),
    ]
}
#endif
