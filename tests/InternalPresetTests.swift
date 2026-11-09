import Foundation

@main struct InternalPresetTests {
    static func main() throws {
        let internalPreset = Capability.all.first { $0.id == "internal" }!
        let expectedKeys: Set = ["Oji6HRoPi7rH7HPdWVakuw", "LBJfwOEzExRxzlAnSuI7eg", "EqrsVvjcYDdxHBiQmGhAWw"]
        precondition(Set(internalPreset.keys) == expectedKeys)
        precondition(Capability.all.allSatisfy { $0.id == "internal" || expectedKeys.isDisjoint(with: $0.keys) })
        for initiallyEnabled in [false, true] {
            var extra: [String: Any] = ["unrelated": "preserved"]
            if initiallyEnabled { for key in expectedKeys { extra[key] = NSNumber(value: 1) } }
            let fixture: [String: Any] = ["CacheExtra": extra, "CacheData": Data([1, 2])]
            let data = try PropertyListSerialization.data(fromPropertyList: fixture, format: .binary, options: 0)
            for choice in [PresetChoice.enable, .disable, .keep] {
                var document = try GestaltDocument(data: data)
                if choice != .keep {
                    for key in internalPreset.keys {
                        document.set(choice == .enable ? internalPreset.enabled : internalPreset.disabled, for: key)
                    }
                }
                let readback = try GestaltDocument(data: document.encoded())
                for key in expectedKeys {
                    if choice == .keep {
                        precondition(readback.extra[key] as? NSNumber == extra[key] as? NSNumber)
                    } else if choice == .enable {
                        precondition(PlistValueKind.detect(readback.extra[key]!) == .integer)
                        precondition(readback.extra[key] as? NSNumber == NSNumber(value: 1))
                    } else {
                        precondition(readback.extra[key] == nil)
                    }
                }
                precondition(readback.extra["unrelated"] as? String == "preserved")
                precondition(readback.root["CacheData"] as? Data == Data([1, 2]))
            }
        }
        for capability in Capability.all where capability.id != "internal" {
            let expected: Any = capability.id == "ipadApps" ? [1, 2] : NSNumber(value: 1)
            precondition(GestaltDocument.valuesEqual(capability.enabled, expected))
            let expectedDisabled: Any = capability.id == "ipadApps" ? [1] : NSNumber(value: 0)
            precondition(GestaltDocument.valuesEqual(capability.disabled!, expectedDisabled))
        }
        print("PASS: internal preset sets all three keys to 1 when enabled, removes them when disabled, keeps original values otherwise; other preset values verified.")
    }
}
