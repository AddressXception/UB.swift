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

    private static let scanningQueue = DispatchQueue(
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

    /// :nodoc:
    public weak var delegate: TransportDelegate?

    /// :nodoc:
    public fileprivate(set) var peers = [Peer]()

    #if os(Linux)
    typealias CentralPeripheral = Peripheral
    var central: GATTCentral<HostController, L2CAPSocket>
    let peripheral: GATTPeripheral<HostController, L2CAPSocket>
    #elseif os(macOS) || os(iOS)
    typealias CentralPeripheral = DarwinCentral.Peripheral
    let central: DarwinCentral
    let peripheral: DarwinPeripheral
    #endif

    /// Handle to the instantiated receiveCharacteristic
    private var characteristicHandle: UInt16
    private var peripherals = [Addr: Characteristic<CentralPeripheral>]()

    var mutex = AsyncLock("\(PureSwiftBluetoothTransport.self)")

    public init() throws {

        #if os(Linux)
        guard let hostController = HostController.default else {
            throw Error.bluetoothUnavailible
        }

        // Setup peripheral
        let address = try hostController.readDeviceAddress()

        let clientSocket = try L2CAPSocket.lowEnergyServer(controllerAddress: address, isRandom: false, securityLevel: .low)
        central = GATTCentral<HostController, L2CAPSocket>(hostController: hostController)
        central.newConnection = { (scanData, report) in
            let device = scanData.peripheral
            let advertisement = scanData.advertisementData
            let isConnectable = scanData.isConnectable
            print("BLE Central: new connection")
            //self.discoverServices(device)
            return clientSocket
        }

        let serverSocket = try L2CAPSocket.lowEnergyServer(controllerAddress: address, isRandom: false, securityLevel: .low)
        peripheral = GATTPeripheral<HostController, L2CAPSocket>(controller: hostController)
        peripheral.newConnection = {
            let socket = try serverSocket.waitForConnection()
            let central = Central(identifier: socket.address)
            print("BLE Peripheral: new connection")
            return (socket, central)
        }

        #elseif os(macOS) || os(iOS)

        central = DarwinCentral()
        peripheral = DarwinPeripheral()

        #endif

        central.log = { print("Central:", $0) }
        peripheral.log = { print("Peripheral:", $0) }

        #if os(macOS)
        while peripheral.state != .poweredOn { sleep(1) }
        #endif

        let _ = try! peripheral.add(service: PureSwiftBluetoothTransport.ubService)
        characteristicHandle = peripheral.characteristics(for: PureSwiftBluetoothTransport.receiveCharacteristicUUID)[0]

        #if os(Linux)
        try peripheral.start()
        try hostController.advertise(name: "UB", services: [PureSwiftBluetoothTransport.ubService])
        #elseif os(macOS) || os(iOS)
        try peripheral.start(options: DarwinPeripheral.AdvertisingOptions(localName: "UB", serviceUUIDs: [PureSwiftBluetoothTransport.ubServiceUUID]))
        #endif

        // register callbacks
        central.didDisconnect = {
            [weak self] peripheral in
            let id = Addr(peripheral.identifier.data)
            self?.remove(peer: id)
        }

        peripheral.didWrite = {
            [weak self] confirmation in

            guard let self = self else {
                return
            }
            self.delegate?.transport(self, didReceiveData: confirmation.value, from: Addr(confirmation.central.identifier.data))
        }

        scan()
    }

    deinit {
        self.peripheral.removeAllServices()
        self.peripheral.stop()

        self.central.disconnectAll()
    }

    private func add(_ characteristic: Characteristic<CentralPeripheral>) {
        let id = Addr(characteristic.peripheral.identifier.data)

        if peripherals[id] != nil {
            return
        }

        peripherals[id] = characteristic

        if peers.filter({ $0.id == id }).count != 0 {
            return
        }

        peers.append(Peer(id: id, services: [UBID]()))
    }

    private func remove(peer: Addr) {
        peripherals.removeValue(forKey: peer)
        peers.removeAll(where: { $0.id == peer })
    }

    private func scan() {
        PureSwiftBluetoothTransport.scanningQueue.async{
            [weak self] in

            do {

                #if os(macOS) || os(iOS)

                try self?.central.scan(filterDuplicates: true, with: [PureSwiftBluetoothTransport.ubServiceUUID]) {
                    [weak self] scanData in

                    let id = Addr(scanData.peripheral.identifier.data)
                    if self?.peripherals[id] != nil {
                        return // already connected
                    }

                    self?.connect(to: scanData.peripheral)
                }

                #elseif os(Linux)

                try self?.central.scan {
                    [weak self] scanData in

                    if scanData.advertisementData.serviceUUIDs?.contains(PureSwiftBluetoothTransport.ubServiceUUID) == true {

                        let id = Addr(scanData.peripheral.identifier.data)
                        if self?.peripherals[id] != nil {
                            return // already connected
                        }

                        self?.connect(to: scanData.peripheral)
                    }
                }

                #endif

            } catch {
                print("scan error: \n \(error)")
            }
        }
    }

    private func connect(to peripheral: CentralPeripheral) {
        mutex.lockAsync{
            [weak self] in
            do {
                try self?.central.connect(to: peripheral)
                if let services = try self?.central.discoverServices([ PureSwiftBluetoothTransport.ubServiceUUID ], for: peripheral) {
                    if let characteristics = try self?.central.discoverCharacteristics([PureSwiftBluetoothTransport.receiveCharacteristicUUID], for: services[0]) {
                        self?.add(characteristics[0])
                    }
                }
            } catch {
                print("connection error: \(peripheral.identifier) \n \(error)")
            }
        }
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
        print("Did start advertising")
    }
}
#endif

extension PureSwiftBluetoothTransport: Transport {
    public func send(message: Data, to: Addr) {
        if let peer = peripherals[to] {
            do {
                try central.writeValue(message, for: peer, withResponse: false)
            } catch {
                print("send error \(error)")
            }
        } else if peripherals.count > 0 {
            print("peer not found, broadcasting")
            peripheral[characteristic: characteristicHandle] = message
        }
    }

    public func listen() {

    }
}

