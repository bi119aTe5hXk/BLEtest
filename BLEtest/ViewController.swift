//
//  ViewController.swift
//  BLEtest
//
//  Created by bi119aTe5hXk on 2019/11/26.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import CoreBluetooth
import UIKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    @IBOutlet var valueLablel: UILabel!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var batteryLabel: UILabel!
    @IBOutlet var modeLabel: UILabel!
    @IBOutlet var verifyLabel: UILabel!

    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var tempDecodeLabel: UILabel!
    @IBOutlet var batteryDecodeLabel: UILabel!

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var characteristic: CBCharacteristic!
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("state: \(central.state)")
        switch central.state {
        case CBManagerState.poweredOff:
            print("CoreBluetooth BLE hardware is powered off")
            break
        case CBManagerState.unauthorized:
            print("CoreBluetooth BLE state is unauthorized")
            break

        case CBManagerState.unknown:
            print("CoreBluetooth BLE state is unknown")
            break

        case CBManagerState.poweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")

            connectToDevice()
            break

        case CBManagerState.resetting:
            print("CoreBluetooth BLE hardware is resetting")
            break
        case CBManagerState.unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform")
            break
        @unknown default:
            print("unknow status.")
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func connectToDevice() {
        // scan peripheral
        // let serviceUUID:CBUUID = CBUUID(string:"7962E488-9EFA-6535-68EE-D95A247A0635")
        // let services: [CBUUID] = [serviceUUID]
        // let options = [CBCentralManagerScanOptionAllowDuplicatesKey : true,
        //               CBCentralManagerScanOptionSolicitedServiceUUIDsKey: services] as [String : Any]
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        if centralManager.isScanning {
            print("*******************************************************")
            print("Scaning Peripherals...")
        }
    }

    func isDeviceConnceting() -> Bool {
        return peripheral.state != .disconnected
    }

    // MARK: - Central

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("found peripheral: \(peripheral), advertisementData:\(advertisementData) RSSI:\(String(describing: RSSI))")
        // connect to peripheral
        if peripheral.identifier == UUID(uuidString: "7962E488-9EFA-6535-68EE-D95A247A0635") {
            centralManager.connect(peripheral, options: nil)
            self.peripheral = peripheral
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*******************************************************")
        print("connected! to \(peripheral)")
        centralManager.stopScan()
        self.peripheral = peripheral
        self.peripheral.delegate = self
        self.peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect to \(peripheral)")
    }

    // MARK: - Peripheral

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        if let error = error {
            print("error: \(error)")
            return
        }
        let services = peripheral.services
        print("Found \(services!.count) services! :\(services!) description:")

        print("*******************************************************")
        for service in services! {
            // discover characteristics
            print("peripheral:\(peripheral),ancsAuthorized:\(peripheral.ancsAuthorized),canSendWriteWithoutResponse:\(peripheral.canSendWriteWithoutResponse)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("*******************************************************")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("error: \(error)")
            return
        }
        self.peripheral = service.peripheral
        self.peripheral.delegate = self
        let characteristics = service.characteristics
        print("didDiscover \(characteristics!.count) characteristics! : \(characteristics!)")

        print("*******************************************************")
        for characteristic in characteristics! {
            var out = ""
            if characteristic.value != nil {
                out = Data(characteristic.value!).hexEncodedString()
            }
            print("characteristic.UUID:\(characteristic.uuid),value:\(out),notifying:\(characteristic.isNotifying),descriptors:\(String(describing: characteristic.descriptors)),properties:\(characteristic.properties.rawValue)")

            peripheral.readValue(for: characteristic)

            // peripheral.setNotifyValue(true, for: characteristic)
        }
        print("*******************************************************")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        if let error = error {
            print("didUpdateValueFordescriptor Failed with error: \(error)")
            return
        }
        // let out = String(data: characteristic.value!, encoding: .utf8)
        print("didUpdateValueFordescriptor Succeeded: descriptor: \(descriptor)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("*******************************************************")
            print("UpdateValueForCharacteristic Failed with error: \(error)")
            // let string = String(data: data, encoding: .utf8) //
            self.peripheral = peripheral
            self.characteristic = characteristic
            print("*******************************************************")
            peripheral.setNotifyValue(true, for: characteristic)
            return
        }
        let out = Data(characteristic.value!).hexEncodedString() // String(data: characteristic.value!, encoding: .utf8)
        print(out)
        valueLablel.text = out
        if out.count > 15 {
            displayResultFrom(string: out)
        }
        // print("didUpdateValueForCharacteristic Successed: service.uuid: \(characteristic.service.uuid), characteristic.uuid: \(characteristic.uuid), value: \(out), descriptors:\(String(describing: characteristic.descriptors))")
    }

    func displayResultFrom(string: String) {
        let head_hex = string[0 ..< 4] // 0,3
        let temp_hex = string[4 ..< 6] // 4,5
        let stat_hex = string[6 ..< 8] // 6,7
        let batt_hex = string[8 ..< 10] // 8,9
        let mode_hex = string[12 ..< 14] // 12,13
        let verif_hex = string[16 ..< string.count]
        if head_hex == "d35d" {
            tempLabel.text = temp_hex
            batteryLabel.text = batt_hex
            verifyLabel.text = verif_hex
            switch stat_hex {
            case "52":
                statusLabel.text = "Red"
                break
            case "76":
                statusLabel.text = "Green"
                break
            case "49":
                statusLabel.text = "Blue"
                break
            case "22":
                statusLabel.text = "Yellow"
                break
            case "59":
                statusLabel.text = "Off"
                break
            default:
                statusLabel.text = stat_hex
                break
            }

            if mode_hex == "9c" {
                modeLabel.text = "Manual"
            } else {
                modeLabel.text = mode_hex
            }
            tempDecodeLabel.text = decodeValue(hex: temp_hex)
            batteryDecodeLabel.text = decodeValue(hex: batt_hex)
        }
    }

    func decodeValue(hex: String) -> String {
        switch hex {
        case "a2":
            return "-24"
        case "ae":
            return "-23"
        case "0e":
            return "-22"
        case "36":
            return "-21"
        case "e8":
            return "-20"
        case "c6":
            return "-19"
        case "8d":
            return "-18"
        case "b1":
            return "-17"
        case "49":
            return "-16"
        case "e6":
            return "-15"
        case "2b":
            return "-14"
        case "98":
            return "-13"
        case "5b":
            return "-12"
        case "6e":
            return "-11"
        case "b8":
            return "-10"
        case "66":
            return "-9"
        case "57":
            return "-8"
        case "64":
            return "-7"
        case "5e":
            return "-6"
        case "09":
            return "-5"
        case "44":
            return "-4"
        case "25":
            return "-3"
        case "e1":
            return "-2"
        case "59":
            return "-1"
        case "9c":
            return "0"
        case "b6":
            return "1"
        case "ed":
            return "2"
        case "29":
            return "3"
        case "d8":
            return "4"
        case "c4":
            return "5"
        case "f6":
            return "6"
        case "85":
            return "7"
        case "81":
            return "8"
        case "b5":
            return "9"
        case "5d":
            return "10"
        case "97":
            return "11"
        case "06":
            return "12"
        case "f5":
            return "13"
        case "76":
            return "14"
        case "33":
            return "15"
        case "28":
            return "16"
        case "22":
            return "17"
        case "63":
            return "18"
        case "c2":
            return "19"
        case "14":
            return "20"
        case "7b":
            return "21"
        case "4d":
            return "22"
        case "9b":
            return "23"
        case "6b":
            return "24"
        case "41":
            return "25"
        case "a7":
            return "26"
        case "83":
            return "27"
        case "b2":
            return "28"
        case "4b":
            return "29"
        case "88":
            return "30"
        case "d1":
            return "31"
        case "3e":
            return "32"
        case "3d":
            return "33"
        case "37":
            return "34"
        case "75":
            return "35"
        case "6d":
            return "36"
        case "f8":
            return "37"
        case "96":
            return "38"
        case "3a":
            return "39"
        case "fc":
            return "40"
        case "92":
            return "41"
        case "08":
            return "42"
        case "91":
            return "43"
        case "47":
            return "44"
        case "ef":
            return "45"
        case "11":
            return "46"
        case "7d":
            return "47"
        case "05":
            return "48"
        case "db":
            return "49"
        case "52":
            return "50"
        case "f9":
            return "51"
        case "0c":
            return "52"
        case "cf":
            return "53"
        case "c1":
            return "54"
        case "ba":
            return "55"
        case "02":
            return "56"
        case "45":
            return "57"
        case "ec":
            return "58"
        case "eb":
            return "59"
        case "b3":
            return "60"
        case "d4":
            return "61"
        case "e4":
            return "62"
        case "21":
            return "63"
        case "23":
            return "64"
        case "17":
            return "65"
        case "42":
            return "66"
        case "f0":
            return "67"
        case "de":
            return "68"
        case "cb":
            return "69"
        case "71":
            return "70"
        case "c8":
            return "71"
        case "65":
            return "72"
        case "e7":
            return "73"
        case "40":
            return "74"
        case "8f":
            return "75"
        case "ca":
            return "76"
        case "67":
            return "77"
        case "dd":
            return "78"
        case "10":
            return "79"
        case "cc":
            return "80"
        case "9f":
            return "81"
        case "00":
            return "82"
        case "35":
            return "83"
        case "2a":
            return "84"
        case "69":
            return "85"
        case "dc":
            return "86"
        case "80":
            return "87"
        case "19":
            return "88"
        case "f7":
            return "89"
        case "0d":
            return "90"
        case "82":
            return "91"
        case "26":
            return "92"
        case "d0":
            return "93"
        case "a8":
            return "94"
        case "d9":
            return "95"
        case "fe":
            return "96"
        case "ac":
            return "97"
        case "ff":
            return "98"
        case "af":
            return "99"
        case "34":
            return "100"
        default:
            print("Unknown value found:\(hex)")
            return ""
        }
    }

    func sentCommandToDevice(hex: String) {
        if isDeviceConnceting() {
            peripheral.writeValue(
                Data(hex: hex),
                for: characteristic,
                type: .withoutResponse) //this characteristic DOES NOT support response, therefore didWriteValueFor will not called.
        } else {
            connectToDevice()
            // self.sentCommandToDevice(hex: hex)
        }
    }

    //this characteristic DOES NOT support response, therefore didWriteValueFor will not called.
//    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
//        if let error = error {
//            print("didWriteValueForDescriptor error: \(error)")
//            return
//        }
//        print("didWriteValueForDescriptor:\(descriptor)")
//    }
    //this characteristic DOES NOT support response, therefore didWriteValueFor will not called.
//    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        if let error = error {
//            print("didWriteValueForCharacteristic error: \(error)")
//            return
//        }
//        print("didWriteValueForCharacteristic:\(characteristic),value:\(String(describing: characteristic.value))")
//    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("didUpdateNotificationStateForcharacteristic failed...error: \(error)")
        } else {
            print("didUpdateNotificationStateForcharacteristic success! isNotifying: \(characteristic.isNotifying)")

            print("didUpdateNotificationStateForcharacteristic characteristic.descriptors.count: \(String(describing: characteristic.descriptors))")
        }
    }

    @IBAction func cmd1BTNPressed(_ sender: Any) { // pair
        sentCommandToDevice(hex: "135d146035dcd508a902")
    }

    @IBAction func cmd2BTNPressed(_ sender: Any) { // read write device name & type
        sentCommandToDevice(hex: "70140d3c2faca5f33a603e42de2a9c9c9c9c57e7") // "70140d3c2faca5f33a603e42de2a040404047fa8"
    }

    @IBAction func getStatusBTNPressed(_ sender: Any) {
        sentCommandToDevice(hex: "d3f62237f9bf62") // get status
    }

    @IBAction func getADVStatusBTNPressed(_ sender: Any) {
        sentCommandToDevice(hex: "86b5529c9c899c4880")
    }

    @IBAction func powerOffBTNPressed(_ sender: Any) {
        sentCommandToDevice(hex: "86b59c9c9c9c9c785a")
    }

    @IBAction func redBTNPressed(_ sender: Any) {
        sentCommandToDevice(hex: "86b5529c9c9c9c1f80")
    }

    @IBAction func greenBTNPressed(_ sender: Any) {
        sentCommandToDevice(hex: "86b5769c9c9c9c1b00")
    }

    @IBAction func blueBTNPressed(_ sender: Any) {
        sentCommandToDevice(hex: "86b5499c9c9c9ca03b")
    }

    @IBAction func yellowBTNPressed(_ sender: Any) {
        sentCommandToDevice(hex: "86b5229c9c9c9c3de0")
    }

    @IBAction func reconnectBTNPressed(_ sender: Any) {
        connectToDevice()
    }
}

extension UnicodeScalar {
    var hexNibble: UInt8 {
        let value = self.value
        if 48 <= value && value <= 57 {
            return UInt8(value - 48)
        } else if 65 <= value && value <= 70 {
            return UInt8(value - 55)
        } else if 97 <= value && value <= 102 {
            return UInt8(value - 87)
        }
        fatalError("\(self) not a legal hex nibble")
    }
}

extension Data {
    init(hex: String) {
        let scalars = hex.unicodeScalars
        var bytes = Array<UInt8>(repeating: 0, count: (scalars.count + 1) >> 1)
        for (index, scalar) in scalars.enumerated() {
            var nibble = scalar.hexNibble
            if index & 1 == 0 {
                nibble <<= 4
            }
            bytes[index >> 1] |= nibble
        }
        self = Data(_: bytes)
    }

    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(count, range.upperBound))
        return String(self[idx1 ..< idx2])
    }
}
