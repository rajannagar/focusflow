import Foundation

enum JWTToken {
    /// Returns true if token is expired (or cannot be parsed safely).
    /// `leewaySeconds` helps avoid edge-of-expiry race conditions.
    static func isExpired(_ token: String, leewaySeconds: TimeInterval = 30) -> Bool {
        guard let exp = expTimestamp(token) else { return true }
        let expiryDate = Date(timeIntervalSince1970: TimeInterval(exp))
        print("expiryDate:", expiryDate )
        return Date().addingTimeInterval(leewaySeconds) >= expiryDate
    }

    /// Extracts `exp` (seconds since epoch) from JWT payload.
    private static func expTimestamp(_ token: String) -> Int? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        let payload = String(parts[1])
        guard let payloadData = base64URLDecode(payload) else { return nil }

        guard
            let json = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
            let exp = json["exp"]
        else { return nil }

        if let i = exp as? Int { return i }
        if let d = exp as? Double { return Int(d) }
        if let s = exp as? String, let i = Int(s) { return i }
        return nil
    }

    private static func base64URLDecode(_ input: String) -> Data? {
        var base64 = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
}
