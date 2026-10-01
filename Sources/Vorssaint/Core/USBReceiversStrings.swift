// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

struct USBReceiversFeatureStrings {
    let title: String
    let hubDescription: String
    /// Receiver name, then the mic number: "Lark A1 Mic 1".
    let micNameFormat: String
}

extension FeatureStrings {
    static func usbReceivers(_ language: AppLanguage) -> USBReceiversFeatureStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .sk: return .sk
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .uk: return .uk
        case .zhHans: return .zhHans
        case .zhHK: return .zhHK
        case .zhTW: return .zhTW
        }
    }
}

private extension USBReceiversFeatureStrings {
    static let enUS = USBReceiversFeatureStrings(
        title: "USB Receivers",
        hubDescription: "Show the battery of accessories connected through their own USB receiver",
        micNameFormat: "%@ Mic %d"
    )

    static let ptBR = USBReceiversFeatureStrings(
        title: "Receptores USB",
        hubDescription: "Mostrar a bateria de acessórios conectados pelo próprio receptor USB",
        micNameFormat: "%@ Mic %d"
    )

    static let tr = USBReceiversFeatureStrings(
        title: "USB Alıcıları",
        hubDescription: "Kendi USB alıcısıyla bağlanan aksesuarların pil düzeyini göster",
        micNameFormat: "%@ Mikrofon %d"
    )

    static let ru = USBReceiversFeatureStrings(
        title: "USB-приёмники",
        hubDescription: "Показывать заряд аксессуаров, подключённых через собственный USB-приёмник",
        micNameFormat: "%@ Микрофон %d"
    )

    static let es = USBReceiversFeatureStrings(
        title: "Receptores USB",
        hubDescription: "Mostrar la batería de accesorios conectados por su propio receptor USB",
        micNameFormat: "%@ Micrófono %d"
    )

    static let sk = USBReceiversFeatureStrings(
        title: "USB prijímače",
        hubDescription: "Zobraziť batériu príslušenstva pripojeného cez vlastný USB prijímač",
        micNameFormat: "%@ Mikrofón %d"
    )

    static let de = USBReceiversFeatureStrings(
        title: "USB-Empfänger",
        hubDescription: "Akkustand von Zubehör anzeigen, das über einen eigenen USB-Empfänger verbunden ist",
        micNameFormat: "%@ Mikrofon %d"
    )

    static let fr = USBReceiversFeatureStrings(
        title: "Récepteurs USB",
        hubDescription: "Afficher la batterie des accessoires connectés par leur propre récepteur USB",
        micNameFormat: "%@ Micro %d"
    )

    static let it = USBReceiversFeatureStrings(
        title: "Ricevitori USB",
        hubDescription: "Mostra la batteria degli accessori collegati tramite il proprio ricevitore USB",
        micNameFormat: "%@ Microfono %d"
    )

    static let ja = USBReceiversFeatureStrings(
        title: "USBレシーバー",
        hubDescription: "専用USBレシーバーで接続したアクセサリのバッテリーを表示",
        micNameFormat: "%@ マイク %d"
    )

    static let ko = USBReceiversFeatureStrings(
        title: "USB 수신기",
        hubDescription: "전용 USB 수신기로 연결된 액세서리의 배터리 표시",
        micNameFormat: "%@ 마이크 %d"
    )

    static let uk = USBReceiversFeatureStrings(
        title: "USB-приймачі",
        hubDescription: "Показувати заряд аксесуарів, підключених через власний USB-приймач",
        micNameFormat: "%@ Мікрофон %d"
    )

    static let zhHans = USBReceiversFeatureStrings(
        title: "USB 接收器",
        hubDescription: "显示通过专用 USB 接收器连接的配件电量",
        micNameFormat: "%@ 麦克风 %d"
    )

    static let zhHK = USBReceiversFeatureStrings(
        title: "USB 接收器",
        hubDescription: "顯示透過專用 USB 接收器連接的配件電量",
        micNameFormat: "%@ 咪高峰 %d"
    )

    static let zhTW = USBReceiversFeatureStrings(
        title: "USB 接收器",
        hubDescription: "顯示透過專用 USB 接收器連接的配件電量",
        micNameFormat: "%@ 麥克風 %d"
    )
}
