// DO NOT EDIT.
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: Packet.proto
//
// For information on using the generated types, please see the documenation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that your are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Packet {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var service: Data = SwiftProtobuf.Internal.emptyData

  var origin: Data = SwiftProtobuf.Internal.emptyData

  var recipient: Data = SwiftProtobuf.Internal.emptyData

  var body: Data = SwiftProtobuf.Internal.emptyData

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

extension Packet: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = "Packet"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "service"),
    2: .same(proto: "origin"),
    3: .same(proto: "recipient"),
    4: .same(proto: "body"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      switch fieldNumber {
      case 1: try decoder.decodeSingularBytesField(value: &self.service)
      case 2: try decoder.decodeSingularBytesField(value: &self.origin)
      case 3: try decoder.decodeSingularBytesField(value: &self.recipient)
      case 4: try decoder.decodeSingularBytesField(value: &self.body)
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.service.isEmpty {
      try visitor.visitSingularBytesField(value: self.service, fieldNumber: 1)
    }
    if !self.origin.isEmpty {
      try visitor.visitSingularBytesField(value: self.origin, fieldNumber: 2)
    }
    if !self.recipient.isEmpty {
      try visitor.visitSingularBytesField(value: self.recipient, fieldNumber: 3)
    }
    if !self.body.isEmpty {
      try visitor.visitSingularBytesField(value: self.body, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Packet, rhs: Packet) -> Bool {
    if lhs.service != rhs.service {return false}
    if lhs.origin != rhs.origin {return false}
    if lhs.recipient != rhs.recipient {return false}
    if lhs.body != rhs.body {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
