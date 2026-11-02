import Foundation

/// Native Swift port of the Tokenizer, Homoglyph/Leetspeak De-Obfuscator,
/// Turkish ASCII Folder, BTK B-Code Parser, Threat Shields, Naive Bayes scorer,
/// and Rule Engine (Triple-Mirror Pattern).
public final class TrustFilterEngine {
    public static let shared = TrustFilterEngine()

    public static let urlToken = "__url__"
    public static let shortUrlToken = "__short_url__"
    public static let suspiciousTldToken = "__suspicious_tld__"
    public static let bCodeToken = "__bcode__"
    public static let fakeBCodeToken = "__fake_bcode__"
    public static let foreignNoBCodeToken = "__foreign_no_bcode__"
    public static let homoglyphToken = "__homoglyph__"
    public static let obfuscatedToken = "__obfuscated__"
    public static let codeToken = "__code__"
    public static let numToken = "__num__"

    private static let homoglyphMap: [Character: Character] = [
        // Cyrillic uppercase & lowercase
        "\u{0410}": "a", "\u{0430}": "a", // А, а
        "\u{0412}": "b", "\u{0432}": "b", // В, в
        "\u{0421}": "c", "\u{0441}": "c", // С, с
        "\u{0415}": "e", "\u{0435}": "e", // Е, е
        "\u{0401}": "e", "\u{0451}": "e", // Ё, ё
        "\u{0405}": "s", "\u{0455}": "s", // Ѕ, ѕ
        "\u{0406}": "i", "\u{0456}": "i", // І, і
        "\u{0407}": "i", "\u{0457}": "i", // Ї, ї
        "\u{0408}": "j", "\u{0458}": "j", // Ј, ј
        "\u{041A}": "k", "\u{043A}": "k", // К, к
        "\u{041C}": "m", "\u{043C}": "m", // М, м
        "\u{041D}": "h", "\u{043D}": "h", // Н, н
        "\u{041E}": "o", "\u{043E}": "o", // О, о
        "\u{0420}": "p", "\u{0440}": "p", // Р, р
        "\u{0422}": "t", "\u{0442}": "t", // Т, т
        "\u{0423}": "y", "\u{0443}": "y", // У, у
        "\u{0425}": "x", "\u{0445}": "x", // Х, х
        "\u{0417}": "z", "\u{0437}": "z", // З, з
        // Greek uppercase & lowercase
        "\u{0391}": "a", "\u{03B1}": "a", // Α, α
        "\u{0392}": "b", "\u{03B2}": "b", // Β, β
        "\u{0395}": "e", "\u{03B5}": "e", // Ε, ε
        "\u{0396}": "z", "\u{03B6}": "z", // Ζ, ζ
        "\u{0397}": "h", "\u{03B7}": "n", // Η, η
        "\u{0399}": "i", "\u{03B9}": "i", // Ι, ι
        "\u{039A}": "k", "\u{03BA}": "k", // Κ, κ
        "\u{039C}": "m", "\u{03BC}": "u", // Μ, μ
        "\u{039D}": "n", "\u{03BD}": "v", // Ν, ν
        "\u{039F}": "o", "\u{03BF}": "o", // Ο, ο
        "\u{03A1}": "p", "\u{03C1}": "p", // Ρ, ρ
        "\u{03A4}": "t", "\u{03C4}": "t", // Τ, τ
        "\u{03A5}": "y", "\u{03C5}": "u", // Υ, υ
        "\u{03A7}": "x", "\u{03C7}": "x"  // Χ, χ
    ]

    public struct BtkAnalysis {
        public let hasValidBCode: Bool
        public let bCode: String?
        public let hasMersis: Bool
        public let hasFakeBCodeTrap: Bool
        public let isForeignSender: Bool
        public let foreignCountryCode: String?
        public let isForeignSenderWithoutBCode: Bool
    }

    public struct Rule {
        let id: String
        let name: String
        let pattern: String
        let type: String // "keyword" or "regex"
        let target: String // "any", "sender", "body"
        let action: String // "spam", "ham", "transaction"
        let enabled: Bool
        let caseSensitive: Bool

        private func matchesSingle(_ text: String) -> Bool {
            guard !text.isEmpty else { return false }
            if type == "regex" {
                let cleaned = pattern.replacingOccurrences(of: "(?i)", with: "")
                let options: NSRegularExpression.Options = (caseSensitive && !pattern.contains("(?i)")) ? [] : [.caseInsensitive]
                guard let regex = try? NSRegularExpression(pattern: cleaned, options: options) else { return false }
                let range = NSRange(location: 0, length: text.utf16.count)
                return regex.firstMatch(in: text, options: [], range: range) != nil
            } else {
                let keywords = pattern.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let targetText = caseSensitive ? text : text.replacingOccurrences(of: "İ", with: "i").lowercased()
                return keywords.contains { kw in
                    let k = caseSensitive ? kw : kw.replacingOccurrences(of: "İ", with: "i").lowercased()
                    return !k.isEmpty && targetText.contains(k)
                }
            }
        }

        func matches(text: String, sender: String? = nil) -> Bool {
            guard enabled && !pattern.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
            switch target {
            case "body":
                return matchesSingle(text)
            case "sender":
                return matchesSingle(sender ?? "")
            default:
                if let s = sender, !s.isEmpty, matchesSingle(s) {
                    return true
                }
                return matchesSingle(text)
            }
        }
    }

    public struct Decision {
        public let category: String // "spam", "ham", "transaction"
        public let subCategory: String // "promotion", "betting_gambling", "phishing_scam", "otp_code", etc.
        public let score: Double
        public let source: String
        public let ruleName: String?
    }

    private var autoDismiss: Bool = true
    private var lastConfigHash: Int = 0
    private var spamThreshold: Double = 0.0
    private var shortUrlBoost: Double = 2.5
    private var spamPrior: Double = 0.0
    private var spamWeights: [String: Double] = [:]
    private var otpKeywords: [String] = []
    private var transactionKeywords: [String] = []
    private var bettingShield: Bool = true
    private var phishingShield: Bool = true
    private var linkShield: Bool = true
    private var marketingShield: Bool = false
    private var bettingPhrases: [String] = []
    private var govScamPhrases: [String] = []
    private var deliveryScamPhrases: [String] = []
    private var accountPhishingPhrases: [String] = []
    private var marketingPhrases: [String] = []
    private var rules: [Rule] = []

    private let urlRegex = try? NSRegularExpression(
        pattern: "(https?://\\S+|www\\.\\S+|[a-z0-9-]+\\.(com|net|org|info|co|io|ly|me|xyz|top|cn|ru|tk|link|click|shop|vip|icu|buzz|win|loan|bet|casino|site|online|live)(/\\S*)?)",
        options: [.caseInsensitive]
    )

    private let shortenerRegex = try? NSRegularExpression(
        pattern: "(bit\\.ly|tinyurl\\.com|goo\\.gl|t\\.co/|cutt\\.ly|is\\.gd|ow\\.ly|rb\\.gy|shorturl\\.at|l24\\.im|ay\\.link|tr\\.ee|rebrand\\.ly)",
        options: [.caseInsensitive]
    )

    private let suspiciousTldRegex = try? NSRegularExpression(
        pattern: "\\b[a-z0-9-]+\\.(xyz|top|tk|link|click|shop|vip|icu|buzz|win|loan|bet|casino|online|live)\\b",
        options: [.caseInsensitive]
    )

    private let validBCodeRegex = try? NSRegularExpression(
        pattern: "\\b(B\\d{3})\\b",
        options: [.caseInsensitive]
    )

    private let mersisRegex = try? NSRegularExpression(
        pattern: "(\\bmersis(\\s*no)?\\s*[:.]?\\s*(\\d{16})?|\\b0\\d{15}\\b)",
        options: [.caseInsensitive]
    )

    private let fakeBCodeRegex = try? NSRegularExpression(
        pattern: "(?:(?<![a-zA-Z0-9])[B\\u0412b\\u0432][\\s._*-]+[0Oo][\\s._*-]*[0Oo1-9][\\s._*-]*[0-9OoIl](?![a-zA-Z0-9])|\\b[B\\u0412b\\u0432](?:[Oo]{2}[0-9]|[0-9][Oo][0-9]|[0-9]{2}[OoIl])\\b|\\b[\\u0412\\u0432\\u0392\\u03B2]\\d{3}\\b)",
        options: []
    )

    private let spacedLettersRegex = try? NSRegularExpression(
        pattern: "(?<![\\p{L}\\p{N}])([a-zA-ZçğıöşüÇĞİÖŞÜ0134578!@$€])(?:[\\s.*_~+|/\\\\-]+([a-zA-ZçğıöşüÇĞİÖŞÜ0134578!@$€])){3,}(?![\\p{L}\\p{N}])",
        options: []
    )

    private let inlineInjectedRegex = try? NSRegularExpression(
        pattern: "(?<![\\p{L}\\p{N}])[\\p{L}$!@€][\\p{L}\\p{Nd}.*_!@$€-]{2,}[\\p{L}\\p{Nd}!@$€](?![\\p{L}\\p{N}])",
        options: []
    )

    private let codeRegex = try? NSRegularExpression(
        pattern: "(?<!\\d)(?:[a-z]-)?\\d{4,8}(?!\\d)",
        options: [.caseInsensitive]
    )

    public func loadFromAppGroup(suiteName: String = "group.com.veroapp.smsguard.filter") {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName),
              let jsonString = sharedDefaults.string(forKey: "veroapp_filter_config") else {
            return
        }
        let h = jsonString.hashValue
        guard h != lastConfigHash, let data = jsonString.data(using: .utf8) else {
            return
        }
        lastConfigHash = h
        updateConfig(from: data)
    }

    public func updateConfig(from data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return
        }
        self.autoDismiss = json["autoDismiss"] as? Bool ?? true
        self.spamThreshold = json["spamThreshold"] as? Double ?? 0.0
        self.shortUrlBoost = json["shortUrlBoost"] as? Double ?? 2.5
        self.spamPrior = json["spamPrior"] as? Double ?? 0.0
        self.spamWeights = json["spamWeights"] as? [String: Double] ?? [:]
        self.otpKeywords = json["otpKeywords"] as? [String] ?? []
        self.transactionKeywords = json["transactionKeywords"] as? [String] ?? []
        self.bettingPhrases = json["bettingPhrases"] as? [String] ?? []
        self.govScamPhrases = json["govScamPhrases"] as? [String] ?? []
        self.deliveryScamPhrases = json["deliveryScamPhrases"] as? [String] ?? []
        self.accountPhishingPhrases = json["accountPhishingPhrases"] as? [String] ?? []
        self.marketingPhrases = json["marketingPhrases"] as? [String] ?? []

        if let shields = json["shields"] as? [String: Any] {
            self.bettingShield = shields["bettingShield"] as? Bool ?? true
            self.phishingShield = shields["phishingShield"] as? Bool ?? true
            self.linkShield = shields["linkShield"] as? Bool ?? true
            self.marketingShield = shields["marketingShield"] as? Bool ?? false
        }

        if let rulesArray = json["rules"] as? [[String: Any]] {
            self.rules = rulesArray.compactMap { dict in
                guard let id = dict["id"] as? String,
                      let pattern = dict["pattern"] as? String else { return nil }
                return Rule(
                    id: id,
                    name: dict["name"] as? String ?? "",
                    pattern: pattern,
                    type: dict["type"] as? String ?? "keyword",
                    target: dict["target"] as? String ?? "any",
                    action: dict["action"] as? String ?? "spam",
                    enabled: dict["enabled"] as? Bool ?? true,
                    caseSensitive: dict["caseSensitive"] as? Bool ?? false
                )
            }
        }
    }

    public func normalizeHomoglyphs(_ text: String, forceAll: Bool = false) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for ch in text {
            if let scalar = ch.unicodeScalars.first, ch.unicodeScalars.count == 1 {
                let v = scalar.value
                if (v >= 0x200B && v <= 0x200F) || (v >= 0x202A && v <= 0x202E) || v == 0xFEFF || v == 0x00AD {
                    continue
                }
                if v >= 0xFF01 && v <= 0xFF5E, let mapped = UnicodeScalar(v - 0xFEE0) {
                    out.append(Character(mapped))
                    continue
                }
            }
            if forceAll, let mapped = TrustFilterEngine.homoglyphMap[ch] {
                out.append(mapped)
            } else {
                out.append(ch)
            }
        }
        return out
    }

    public func foldTurkishAscii(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "İ", with: "i")
            .replacingOccurrences(of: "I", with: "i")
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "Ş", with: "s")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "Ğ", with: "g")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "Ü", with: "u")
            .replacingOccurrences(of: "ü", with: "u")
            .replacingOccurrences(of: "Ö", with: "o")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "Ç", with: "c")
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "â", with: "a")
            .replacingOccurrences(of: "î", with: "i")
            .replacingOccurrences(of: "û", with: "u")
    }

    private func mapLeetSymbolsAndDigits(_ input: String, mapDigits: Bool = true) -> String {
        var out = input
            .replacingOccurrences(of: "!", with: "i")
            .replacingOccurrences(of: "¡", with: "i")
            .replacingOccurrences(of: "@", with: "a")
            .replacingOccurrences(of: "$", with: "s")
            .replacingOccurrences(of: "€", with: "e")
        if mapDigits {
            out = out
                .replacingOccurrences(of: "0", with: "o")
                .replacingOccurrences(of: "1", with: "i")
                .replacingOccurrences(of: "3", with: "e")
                .replacingOccurrences(of: "4", with: "a")
                .replacingOccurrences(of: "5", with: "s")
                .replacingOccurrences(of: "7", with: "t")
                .replacingOccurrences(of: "8", with: "b")
        }
        return out
    }

    public func normalizeObfuscation(_ text: String) -> String {
        var cleaned = normalizeHomoglyphs(text, forceAll: true)
            .replacingOccurrences(of: "İ", with: "i")
            .lowercased()

        if let regex = spacedLettersRegex {
            let ns = cleaned as NSString
            let matches = regex.matches(in: cleaned, options: [], range: NSRange(location: 0, length: ns.length)).reversed()
            for m in matches {
                let raw = ns.substring(with: m.range)
                let collapsed = raw.replacingOccurrences(of: "[\\s.*_~+|/\\\\-]+", with: "", options: .regularExpression)
                let mapped = mapLeetSymbolsAndDigits(collapsed, mapDigits: true)
                cleaned = (cleaned as NSString).replacingCharacters(in: m.range, with: mapped)
            }
        }

        if let regex = inlineInjectedRegex {
            let ns = cleaned as NSString
            let matches = regex.matches(in: cleaned, options: [], range: NSRange(location: 0, length: ns.length)).reversed()
            for m in matches {
                let raw = ns.substring(with: m.range)
                if raw.contains("http") || raw.contains("www.") { continue }
                let stripped = raw.replacingOccurrences(of: "[.*_-]+", with: "", options: .regularExpression)
                let mapped = mapLeetSymbolsAndDigits(stripped, mapDigits: true)
                cleaned = (cleaned as NSString).replacingCharacters(in: m.range, with: mapped)
            }
        }

        let folded = foldTurkishAscii(cleaned)
        return folded != cleaned ? "\(cleaned) \(folded)" : cleaned
    }

    public func analyzeBtk(_ text: String, sender: String? = nil) -> BtkAnalysis {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let ns = trimmed as NSString
        let fullRange = NSRange(location: 0, length: ns.length)

        let hasMersis = (mersisRegex?.firstMatch(in: trimmed, options: [], range: fullRange) != nil)
        var hasFakeBCodeTrap = (fakeBCodeRegex?.firstMatch(in: trimmed, options: [], range: fullRange) != nil)

        var validBCode: String? = nil
        if let matches = validBCodeRegex?.matches(in: trimmed, options: [], range: fullRange), let last = matches.last {
            let candidate = ns.substring(with: last.range(at: 1)).uppercased()
            let trailingLen = ns.length - (last.range.location + last.range.length)
            if trailingLen <= 28 {
                validBCode = candidate
            } else {
                hasFakeBCodeTrap = true
            }
        }

        var isForeignSender = false
        var foreignCountryCode: String? = nil
        if let s = sender?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            let compact = s.replacingOccurrences(of: "[\\s()-]", with: "", options: .regularExpression)
            if compact.hasPrefix("+") || compact.hasPrefix("00") {
                let digits = compact.hasPrefix("+") ? String(compact.dropFirst()) : String(compact.dropFirst(2))
                if digits.count >= 6 && !digits.hasPrefix("90") && digits.allSatisfy({ $0.isNumber }) {
                    isForeignSender = true
                    let prefixLen = (digits.hasPrefix("1") || digits.hasPrefix("7")) ? 1 : min(2, digits.count)
                    foreignCountryCode = "+" + String(digits.prefix(prefixLen))
                }
            }
        }

        let isForeignNoBCode = isForeignSender && validBCode == nil && !hasMersis
        return BtkAnalysis(
            hasValidBCode: validBCode != nil,
            bCode: validBCode,
            hasMersis: hasMersis,
            hasFakeBCodeTrap: hasFakeBCodeTrap,
            isForeignSender: isForeignSender,
            foreignCountryCode: foreignCountryCode,
            isForeignSenderWithoutBCode: isForeignNoBCode
        )
    }

    public func tokenize(_ text: String, sender: String? = nil) -> Set<String> {
        var tokens = Set<String>()
        let homoNormalized = normalizeHomoglyphs(text, forceAll: true)
        let lower = homoNormalized.replacingOccurrences(of: "İ", with: "i").lowercased()
        let nsLower = lower as NSString
        let fullRange = NSRange(location: 0, length: nsLower.length)

        if let urlRegex = urlRegex, urlRegex.firstMatch(in: lower, options: [], range: fullRange) != nil {
            tokens.insert(TrustFilterEngine.urlToken)
        }
        if let shortenerRegex = shortenerRegex, shortenerRegex.firstMatch(in: lower, options: [], range: fullRange) != nil {
            tokens.insert(TrustFilterEngine.shortUrlToken)
        }
        if let suspiciousTldRegex = suspiciousTldRegex, suspiciousTldRegex.firstMatch(in: lower, options: [], range: fullRange) != nil {
            tokens.insert(TrustFilterEngine.suspiciousTldToken)
        }

        let btk = analyzeBtk(text, sender: sender)
        if btk.hasValidBCode || btk.hasMersis { tokens.insert(TrustFilterEngine.bCodeToken) }
        if btk.hasFakeBCodeTrap { tokens.insert(TrustFilterEngine.fakeBCodeToken) }
        if btk.isForeignSenderWithoutBCode { tokens.insert(TrustFilterEngine.foreignNoBCodeToken) }

        let deobfuscated = normalizeObfuscation(text)
        var stripped = deobfuscated
        if let urlRegex = urlRegex {
            stripped = urlRegex.stringByReplacingMatches(
                in: stripped,
                options: [],
                range: NSRange(location: 0, length: (stripped as NSString).length),
                withTemplate: " "
            )
        }

        let words = stripped.components(separatedBy: CharacterSet.alphanumerics.inverted)
        for w in words where !w.isEmpty {
            if w.count >= 4 && w.count <= 8 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: w)) {
                tokens.insert(TrustFilterEngine.codeToken)
            } else if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: w)) {
                tokens.insert(TrustFilterEngine.numToken)
            } else if w.count > 1 {
                tokens.insert(w)
                tokens.insert(foldTurkishAscii(w))
            }
        }
        return tokens
    }

    public func classify(_ text: String, sender: String? = nil) -> Decision {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Decision(category: "ham", subCategory: "personal", score: 0.0, source: "aiModel", ruleName: nil)
        }

        // 1. Custom user rules
        for r in rules {
            if r.matches(text: text, sender: sender) {
                return Decision(category: r.action, subCategory: "custom_rule", score: 1.0, source: "userRule", ruleName: r.name)
            }
        }

        let combined = (sender != nil && !(sender!.isEmpty)) ? "\(sender!): \(text)" : text
        let normalized = normalizeObfuscation(combined)
        let features = tokenize(text, sender: sender)
        let btk = analyzeBtk(text, sender: sender)
        let hasUrl = features.contains(TrustFilterEngine.urlToken)
        let lower = normalized

        // 2. Legitimate OTP / Transaction (strictly without links or fake B-code/foreign traps)
        let hasOtpKw = otpKeywords.contains { lower.contains($0.lowercased()) }
        let hasCode = (codeRegex?.firstMatch(in: text, options: [], range: NSRange(location: 0, length: (text as NSString).length)) != nil)
        if hasOtpKw && hasCode && !hasUrl && !btk.hasFakeBCodeTrap && !btk.isForeignSenderWithoutBCode {
            return Decision(category: "transaction", subCategory: "otp_code", score: 0.95, source: "otpDetector", ruleName: nil)
        }

        let hasTxnKw = transactionKeywords.contains { lower.contains($0.lowercased()) }
        if hasTxnKw && !hasUrl && !btk.hasFakeBCodeTrap && !btk.isForeignSenderWithoutBCode {
            return Decision(category: "transaction", subCategory: "bank_transaction", score: 0.85, source: "otpDetector", ruleName: nil)
        }

        // 3. Built-in Threat & Spam Intelligence Shields
        if bettingShield && (bettingPhrases.contains(where: { lower.contains($0) }) || (lower.contains("bahis") && (hasUrl || lower.contains("bonus"))) || lower.contains("freespin")) {
            return Decision(category: "spam", subCategory: "betting_gambling", score: 0.98, source: "threatShield", ruleName: "shieldBetting")
        }
        if phishingShield {
            if govScamPhrases.contains(where: { lower.contains($0) }) {
                return Decision(category: "spam", subCategory: "gov_scam", score: 0.96, source: "threatShield", ruleName: "shieldPhishing")
            }
            if deliveryScamPhrases.contains(where: { lower.contains($0) }) {
                return Decision(category: "spam", subCategory: "delivery_scam", score: 0.96, source: "threatShield", ruleName: "shieldPhishing")
            }
            if accountPhishingPhrases.contains(where: { lower.contains($0) }) || btk.hasFakeBCodeTrap || btk.isForeignSenderWithoutBCode {
                return Decision(category: "spam", subCategory: "phishing_scam", score: 0.97, source: "threatShield", ruleName: "shieldPhishing")
            }
        }
        if linkShield && hasOtpKw && hasCode && hasUrl {
            return Decision(category: "spam", subCategory: "phishing_scam", score: 0.95, source: "heuristic", ruleName: "shieldLink")
        }
        if marketingShield && (btk.hasValidBCode || btk.hasMersis || marketingPhrases.contains(where: { lower.contains($0) })) {
            return Decision(category: "spam", subCategory: "promotion", score: 0.90, source: "threatShield", ruleName: "shieldMarketing")
        }

        // 3.5. FAZ 3: 6D Semantic Intent Vector & Combo Multiplier ("Dükkan & Hakan Abi")
        let urgencyTerms = ["son 24 saat", "son gun", "hesabiniz kapatilacak", "hesabiniz askiya", "icra", "haciz", "uzlastirma", "ceza dosyasi", "bloke", "derhal", "urgent", "suspended"]
        let financialTerms = ["para kazan", "borc kapatma", "yatirim firsati", "gunluk kazanc", "kefilsiz", "masrafsiz", "evden calisarak", "gumruk ucreti", "hgs borcu", "customs fee"]
        let rewardTerms = ["bonus", "bedava", "kazandiniz", "freespin", "cevrimsiz", "yatirimsiz", "casino", "slot", "hediye ceki", "jackpot"]
        let actionTerms = ["tikla", "tiklayin", "giris yap", "uye ol", "hemen katil", "aktif et", "click here", "claim now"]
        let personalTerms = ["abi", "abla", "kardesim", "canim", "annem", "babam", "dukkan", "dukkana", "emaneti", "biraktim", "eve gelirken", "ekmek", "toplanti", "gorusuruz"]

        let urgencyHits = urgencyTerms.filter { lower.contains($0) }.count
        let financialHits = financialTerms.filter { lower.contains($0) }.count
        let rewardHits = rewardTerms.filter { lower.contains($0) }.count
        let actionHits = actionTerms.filter { lower.contains($0) }.count + (hasUrl ? 1 : 0) + (features.contains(TrustFilterEngine.shortUrlToken) ? 1 : 0)
        let personalHits = personalTerms.filter { lower.contains($0) }.count

        let comboBoost = ((rewardHits >= 1 && actionHits >= 1) || (urgencyHits >= 1 && actionHits >= 1) || (financialHits >= 1 && (actionHits >= 1 || urgencyHits >= 1))) ? 1.65 : 1.0
        let semanticSpamScore = ((Double(urgencyHits) * 0.45) + (Double(financialHits) * 0.50) + (Double(rewardHits) * 0.55) + (Double(actionHits) * 0.30)) * comboBoost

        if semanticSpamScore >= 1.15 {
            let sub = rewardHits >= 1 ? "betting_gambling" : (urgencyHits >= 1 ? "gov_scam" : "phishing_scam")
            return Decision(category: "spam", subCategory: sub, score: min(0.96, 0.55 + semanticSpamScore * 0.25), source: "semanticIntent", ruleName: nil)
        }

        if personalHits >= 1 && !hasUrl && urgencyHits == 0 && financialHits == 0 && rewardHits == 0 && !btk.hasFakeBCodeTrap && !btk.isForeignSenderWithoutBCode {
            return Decision(category: "ham", subCategory: "personal", score: -1.5, source: "semanticIntent", ruleName: nil)
        }

        // 4. AI Model scoring
        var score = spamPrior
        for f in features {
            if let w = spamWeights[f] {
                score += w
            }
        }

        var source = "aiModel"
        if features.contains(TrustFilterEngine.shortUrlToken) {
            score += shortUrlBoost
            source = "heuristic"
        }
        if features.contains(TrustFilterEngine.fakeBCodeToken) || features.contains(TrustFilterEngine.foreignNoBCodeToken) {
            score += 3.0
            source = "heuristic"
        }

        if score > spamThreshold {
            return Decision(category: "spam", subCategory: "general_spam", score: score, source: source, ruleName: nil)
        } else {
            return Decision(category: "ham", subCategory: "personal", score: score, source: source, ruleName: nil)
        }
    }
}
