// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation
import IOKit
import IOKit.hid

/// Accessories that reach the Mac through their own USB receiver publish no
/// battery to macOS, so each supported receiver is asked in its vendor
/// protocol. Only status requests are sent; no setting is ever written.
enum ReceiverBatteryReader {
    static func readDevices() -> [PeripheralBatteryDevice] {
        let strings = FeatureStrings.usbReceivers(L10n.shared.language)
        return LarkReceiverProtocol.receivers.flatMap { receiver in
            services(vendorID: LarkReceiverProtocol.vendorID, productID: receiver.productID).flatMap { service in
                readLark(service: service, micName: {
                    String(format: strings.micNameFormat, receiver.name, $0)
                })
            }
        }
    }

    private static func services(vendorID: Int, productID: Int) -> [io_service_t] {
        guard let matching = IOServiceMatching(kIOHIDDeviceKey) as NSMutableDictionary? else { return [] }
        matching[kIOHIDVendorIDKey] = vendorID
        matching[kIOHIDProductIDKey] = productID
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }
        var services: [io_service_t] = []
        var service = IOIteratorNext(iterator)
        while service != 0 {
            services.append(service)
            service = IOIteratorNext(iterator)
        }
        return services
    }

    private static func readLark(service: io_service_t,
                                 micName: (Int) -> String) -> [PeripheralBatteryDevice] {
        defer { IOObjectRelease(service) }
        var registryID: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(service, &registryID)
        guard let device = IOHIDDeviceCreate(kCFAllocatorDefault, service),
              IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            return []
        }
        defer { IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone)) }

        let request = LarkReceiverProtocol.heartbeatRequest
        let reportID = CFIndex(LarkReceiverProtocol.reportID)
        guard IOHIDDeviceSetReport(device, kIOHIDReportTypeFeature, reportID,
                                   request, request.count) == kIOReturnSuccess else {
            return []
        }
        var reply = [UInt8](repeating: 0, count: LarkReceiverProtocol.reportSize)
        var length = CFIndex(reply.count)
        guard IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, reportID,
                                   &reply, &length) == kIOReturnSuccess else {
            return []
        }
        return LarkReceiverProtocol.devices(fromHeartbeatReply: Array(reply.prefix(length)),
                                            receiverID: "\(registryID)", micName: micName)
    }
}

/// Hollyland Lark receivers, protocol V2 of the vendor's HollyAudio app.
/// Frames travel in feature report 5:
///     request: 05 03 AA DD cmd lenHi lenLo payload... EF
///     reply:   05 03 BB DD cmd lenHi lenLo payload...
/// The heartbeat reply starts with each mic's link state, then its battery.
enum LarkReceiverProtocol {
    struct Receiver: Equatable {
        let productID: Int
        let name: String
    }

    static let vendorID = 0x3547
    static let receivers = [Receiver(productID: 0x0407, name: "Lark A1")]
    static let reportID = 5
    static let reportSize = 64
    static let heartbeatCommand: UInt8 = 0x1F
    private static let micCount = 2

    static var heartbeatRequest: [UInt8] {
        var frame = [UInt8](repeating: 0, count: reportSize)
        frame.replaceSubrange(0..<5, with: [UInt8(reportID), 0x03, 0xAA, 0xDD, heartbeatCommand])
        frame[7] = 0xEF
        return frame
    }

    /// Connected mics with their battery, or nothing when the reply is not a
    /// heartbeat. A mic that is off or out of range reports no battery.
    static func devices(fromHeartbeatReply reply: [UInt8], receiverID: String,
                        micName: (Int) -> String) -> [PeripheralBatteryDevice] {
        let headerLength = 7
        guard reply.count >= headerLength,
              reply[2] == 0xBB, reply[3] == 0xDD, reply[4] == heartbeatCommand else { return [] }
        let payloadLength = Int(reply[5]) << 8 | Int(reply[6])
        let payload = reply.dropFirst(headerLength).prefix(payloadLength).map { Int($0) }
        guard payload.count >= micCount * 2 else { return [] }
        return (0..<micCount).compactMap { index in
            let percent = payload[micCount + index]
            guard payload[index] == 1, (0...100).contains(percent) else { return nil }
            return PeripheralBatteryDevice(id: "HollylandLark:\(receiverID):\(index + 1)",
                                           name: micName(index + 1),
                                           percent: percent, kind: .microphone)
        }
    }
}
