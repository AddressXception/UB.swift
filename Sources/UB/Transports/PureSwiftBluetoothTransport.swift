import Bluetooth
import Foundation
import GATT

#if os(macOS) || os(iOS)
import DarwinGATT
import CoreBluetooth
#endif

#if os(Linux)
import BluetoothLinux
#endif

public class PureSwiftBluetoothTransport {

    enum Error : Swift.Error {
        case bluetoothUnavailible
    }

    private static let centralQueue = DispatchQueue(
            label: "com.ultralight-beam.bluetooth.centralQueue",
            attributes: .concurrent
    )

    private static let ubServiceUUID = BluetoothUUID(rawValue: "BEA3B031-76FB-4889-B3C7-000000000000")!

    private static let receiveCharacteristicUUID = BluetoothUUID(rawValue: "BEA3B031-76FB-4889-B3C7-000000000001")!

    private static let receiveCharacteristic = GATT.Characteristic(
            uuid: receiveCharacteristicUUID,
            value: Data(),
            permissions: [.write, .read],
            properties: [.read, .writeWithoutResponse, .notify]
    )

    private static let ubService = GATT.Service(
            uuid: ubServiceUUID,
            primary: true,
            characteristics: [ receiveCharacteristic ])

    // MARK: - Properties
    /// :nodoc:
    public weak var delegate: TransportDelegate?

    /// :nodoc:
    public fileprivate(set) var peers = [Peer]()

    #if os(Linux)
    let peripheral: GATTPeripheral<HostController, L2CAPSocket>
    #elseif os(macOS) || os(iOS)
    let peripheral: DarwinPeripheral
    #endif

    public init() throws {

        #if os(Linux)
        guard let hostController = HostController.default else {
            throw Error.bluetoothUnavailible
        }

        // Setup peripheral
        let address = try hostController.readDeviceAddress()
        let serverSocket = try L2CAPSocket.lowEnergyServer(controllerAddress: address, isRandom: false, securityLevel: .low)

        peripheral = GATTPeripheral<HostController, L2CAPSocket>(controller: hostController)

        peripheral.newConnection = {
            let socket = try serverSocket.waitForConnection()
            let central = Central(identifier: socket.address)
            print("BLE Peripheral: new connection")
            return (socket, central)
        }

        #elseif os(macOS) || os(iOS)
        peripheral = DarwinPeripheral()
        #endif

        peripheral.log = { print("Peripheral:", $0) }

        peripheral.didWrite = {
            [weak self] confirmation in

            guard let self = self else {
                return
            }

            self.delegate?.transport(self, didReceiveData: confirmation.value, from: Addr(confirmation.central.identifier.bytes))
        }

        #if os(macOS)
        while peripheral.state != .poweredOn { sleep(1) }
        #endif

        let _ = try! peripheral.add(service: PureSwiftBluetoothTransport.ubService)
        let _ = peripheral.characteristics(for: PureSwiftBluetoothTransport.receiveCharacteristicUUID)[0]

        #if os(Linux)
        try! peripheral.start()
        try hostController.advertise(name: "UB", services: [PureSwiftBluetoothTransport.ubService])
        #elseif os(macOS) || os(iOS)

        try! peripheral.start(options: DarwinPeripheral.AdvertisingOptions(localName: "UB", serviceUUIDs: [PureSwiftBluetoothTransport.ubServiceUUID]))
        #endif

        print("transport initialized")
    }
}

#if os(Linux)
extension HostController {
    public func advertise(name: String, services: [GATT.Service]) throws {
        // Advertise services and peripheral name
        let serviceUUIDs = GAPIncompleteListOf128BitServiceClassUUIDs(uuids: services.map { UUID(bluetooth: $0.uuid) })
        let encoder = GAPDataEncoder()
        let data = try encoder.encodeAdvertisingData(GAPCompleteLocalName(name: name), serviceUUIDs)
        try self.setLowEnergyScanResponse(data, timeout: .default)
        print("BLE Advertising started")
    }
}
#endif

extension PureSwiftBluetoothTransport: Transport {
    public func send(message: Data, to: Addr) {

    }

    public func listen() {

    }
}

