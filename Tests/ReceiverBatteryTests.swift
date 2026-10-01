// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

enum ReceiverBatteryTests {
    static func run(_ suite: TestSuite) {
        larkContracts(suite)
        samplerContracts(suite)
    }

    /// A heartbeat reply captured from a Lark A1 receiver with mic 1 on at
    /// 62% and mic 2 off, padded to the 64-byte report as the receiver sends it.
    private static let capturedReply: [UInt8] = {
        let bytes: [UInt8] = [0x05, 0x03, 0xBB, 0xDD, 0x1F, 0x00, 0x11,
                              0x01, 0x00, 0x3E, 0x00, 0x00, 0x00, 0x01, 0x02, 0x04,
                              0x00, 0x00, 0x00, 0x03, 0x00, 0x02, 0x00, 0x00, 0x51]
        return bytes + [UInt8](repeating: 0, count: 64 - bytes.count)
    }()

    private static func micName(_ number: Int) -> String { "Lark A1 Mic \(number)" }

    private static func larkContracts(_ suite: TestSuite) {
        let request = LarkReceiverProtocol.heartbeatRequest
        suite.expect(request.count == 64
                     && Array(request.prefix(8)) == [0x05, 0x03, 0xAA, 0xDD, 0x1F, 0x00, 0x00, 0xEF]
                     && request.dropFirst(8).allSatisfy { $0 == 0 },
                     "the heartbeat request is the app's framed status query in feature report 5")

        let devices = LarkReceiverProtocol.devices(fromHeartbeatReply: capturedReply, receiverID: "7",
                                                   micName: micName)
        suite.expect(devices == [PeripheralBatteryDevice(id: "HollylandLark:7:1", name: "Lark A1 Mic 1",
                                                         percent: 62, kind: .microphone)],
                     "a captured reply lists the connected mic with its battery and skips the one that is off")

        var both = capturedReply
        both[8] = 0x01
        both[10] = 0x64
        suite.expect(LarkReceiverProtocol.devices(fromHeartbeatReply: both, receiverID: "7", micName: micName)
                        .map(\.percent) == [62, 100],
                     "two connected mics are both listed in order")

        var otherCommand = capturedReply
        otherCommand[4] = 0x0D
        suite.expect(LarkReceiverProtocol.devices(fromHeartbeatReply: otherCommand, receiverID: "7",
                                                  micName: micName).isEmpty,
                     "a reply to another command is not read as a battery")

        var echoed = capturedReply
        echoed[2] = 0xAA
        suite.expect(LarkReceiverProtocol.devices(fromHeartbeatReply: echoed, receiverID: "7",
                                                  micName: micName).isEmpty,
                     "an echoed request is not read as a reply")

        suite.expect(LarkReceiverProtocol.devices(fromHeartbeatReply: Array(capturedReply.prefix(9)),
                                                  receiverID: "7", micName: micName).isEmpty,
                     "a truncated reply yields nothing")

        var outOfRange = capturedReply
        outOfRange[9] = 0xFF
        suite.expect(LarkReceiverProtocol.devices(fromHeartbeatReply: outOfRange, receiverID: "7",
                                                  micName: micName).isEmpty,
                     "a battery value above 100 is not shown")

        suite.expect(AppLanguage.allCases.allSatisfy {
                         let name = String(format: FeatureStrings.usbReceivers($0).micNameFormat, "Lark A1", 2)
                         return name.hasPrefix("Lark A1 ") && name.hasSuffix(" 2")
                     },
                     "every language names the receiver, then the mic number")
    }

    private static func samplerContracts(_ suite: TestSuite) {
        let queue = DispatchQueue(label: "com.vorssaint.tests.receiver-battery")
        var receiverReads = 0
        let mic = PeripheralBatteryDevice(id: "HollylandLark:7:1", name: "Lark A1 Mic 1", percent: 62, kind: .microphone)
        let sampler = PeripheralBatterySampler(bluetoothQueue: queue, readFast: { [] },
            readReceivers: { receiverReads += 1; return [mic] },
            readProfiler: { _ in Data() }, makeBluetoothRead: { _, _, completion in
                ImmediateReader(completion: completion)
            }, currentTime: { 0 })
        defer { sampler.setEnabled(false); queue.sync {} }
        sampler.setEnabled(true)

        suite.expect(sampler.sample(now: 0).devices.isEmpty && receiverReads == 0,
                     "receivers are never asked while the feature is not installed")

        sampler.setReceiversEnabled(true)
        suite.expect(sampler.sample(now: 1).devices == [mic] && receiverReads == 1,
                     "installing the feature adds the receiver's mics on the next sample")
        _ = sampler.sample(now: 2)
        suite.expect(receiverReads == 1, "receivers share the fast read's cache interval")

        sampler.setReceiversEnabled(false)
        suite.expect(sampler.sample(now: 3).devices.isEmpty && receiverReads == 1,
                     "removing the feature drops the mics at once without asking the receiver again")
    }

    private final class ImmediateReader: PeripheralBluetoothReading {
        let completion: ([BluetoothBatteryReading]) -> Void
        init(completion: @escaping ([BluetoothBatteryReading]) -> Void) { self.completion = completion }
        func start() { completion([]) }
        func cancel() {}
    }
}
