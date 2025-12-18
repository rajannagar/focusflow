// FocusSound.swift

import Foundation

enum FocusSound: String, CaseIterable, Identifiable {
    case angelsByMySide       = "angelsbymyside"
    case fireplace            = "fireplace"
    case floatingGarden       = "floatinggarden"
    case hearty               = "hearty"
    case lightRainAmbient     = "light-rain-ambient"
    case longNight            = "longnight"
    case soundAmbience        = "sound-ambience"
    case streetMarketFrance   = "street-market-gap-france"
    case theLightBetweenUs    = "thelightbetweenus"
    case underwater           = "underwater"
    case yesterday            = "yesterday"

    var id: String { rawValue }

    /// User-facing name in the UI
    var displayName: String {
        switch self {
        case .angelsByMySide:     return "Angels by My Side"
        case .fireplace:          return "Cozy Fireplace"
        case .floatingGarden:     return "Floating Garden"
        case .hearty:             return "Hearty"
        case .lightRainAmbient:   return "Light Rain (Ambient)"
        case .longNight:          return "Long Night"
        case .soundAmbience:      return "Soft Ambience"
        case .streetMarketFrance: return "French Street Market"
        case .theLightBetweenUs:  return "The Light Between Us"
        case .underwater:         return "Underwater"
        case .yesterday:          return "Yesterday"
        }
    }

    /// File name in the bundle (without .mp3)
    var fileName: String { rawValue }
}
