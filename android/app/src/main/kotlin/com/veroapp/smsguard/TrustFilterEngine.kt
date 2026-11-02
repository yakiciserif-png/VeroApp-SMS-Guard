package com.veroapp.smsguard

import org.json.JSONArray
import org.json.JSONObject
import java.util.regex.Pattern

/**
 * Native Kotlin port of the Tokenizer, Homoglyph/Leetspeak De-Obfuscator,
 * Turkish ASCII Folder, BTK B-Code Parser, Threat Shields, Naive Bayes scorer,
 * and Rule Engine (Triple-Mirror Pattern).
 *
 * Operates in the background inside NotificationListenerService / BroadcastReceiver
 * without needing a running FlutterEngine or Dart VM.
 */
object TrustFilterEngine {

    const val URL_TOKEN = "__url__"
    const val SHORT_URL_TOKEN = "__short_url__"
    const val SUSPICIOUS_TLD_TOKEN = "__suspicious_tld__"
    const val BCODE_TOKEN = "__bcode__"
    const val FAKE_BCODE_TOKEN = "__fake_bcode__"
    const val FOREIGN_NO_BCODE_TOKEN = "__foreign_no_bcode__"
    const val HOMOGLYPH_TOKEN = "__homoglyph__"
    const val OBFUSCATED_TOKEN = "__obfuscated__"
    const val CODE_TOKEN = "__code__"
    const val NUM_TOKEN = "__num__"

    private val homoglyphMap: Map<Char, Char> = mapOf(
        // Cyrillic uppercase & lowercase
        '\u0410' to 'a', '\u0430' to 'a', // А, а
        '\u0412' to 'b', '\u0432' to 'b', // В, в
        '\u0421' to 'c', '\u0441' to 'c', // С, с
        '\u0415' to 'e', '\u0435' to 'e', // Е, е
        '\u0401' to 'e', '\u0451' to 'e', // Ё, ё
        '\u0405' to 's', '\u0455' to 's', // Ѕ, ѕ
        '\u0406' to 'i', '\u0456' to 'i', // І, і
        '\u0407' to 'i', '\u0457' to 'i', // Ї, ї
        '\u0408' to 'j', '\u0458' to 'j', // Ј, ј
        '\u041A' to 'k', '\u043A' to 'k', // К, к
        '\u041C' to 'm', '\u043C' to 'm', // М, м
        '\u041D' to 'h', '\u043D' to 'h', // Н, н
        '\u041E' to 'o', '\u043E' to 'o', // О, о
        '\u0420' to 'p', '\u0440' to 'p', // Р, р
        '\u0422' to 't', '\u0442' to 't', // Т, т
        '\u0423' to 'y', '\u0443' to 'y', // У, у
        '\u0425' to 'x', '\u0445' to 'x', // Х, х
        '\u0417' to 'z', '\u0437' to 'z', // З, з
        // Greek uppercase & lowercase
        '\u0391' to 'a', '\u03B1' to 'a', // Α, α
        '\u0392' to 'b', '\u03B2' to 'b', // Β, β
        '\u0395' to 'e', '\u03B5' to 'e', // Ε, ε
        '\u0396' to 'z', '\u03B6' to 'z', // Ζ, ζ
        '\u0397' to 'h', '\u03B7' to 'n', // Η, η
        '\u0399' to 'i', '\u03B9' to 'i', // Ι, ι
        '\u039A' to 'k', '\u03BA' to 'k', // Κ, κ
        '\u039C' to 'm', '\u03BC' to 'u', // Μ, μ
        '\u039D' to 'n', '\u03BD' to 'v', // Ν, ν
        '\u039F' to 'o', '\u03BF' to 'o', // Ο, ο
        '\u03A1' to 'p', '\u03C1' to 'p', // Ρ, ρ
        '\u03A4' to 't', '\u03C4' to 't', // Τ, τ
        '\u03A5' to 'y', '\u03C5' to 'u', // Υ, υ
        '\u03A7' to 'x', '\u03C7' to 'x'  // Χ, χ
    )

    private val zeroWidthRegex = Regex("[\\u200B-\\u200F\\u202A-\\u202E\\u2060-\\u2064\\uFEFF\\u00AD]")

    private val urlPattern = Pattern.compile(
        "(https?://\\S+|www\\.\\S+|[a-z0-9-]+\\.(com|net|org|info|co|io|ly|me|xyz|top|cn|ru|tk|link|click|shop|vip|icu|buzz|win|loan|bet|casino|site|online|live)(/\\S*)?)",
        Pattern.CASE_INSENSITIVE
    )

    private val shortenerPattern = Pattern.compile(
        "(bit\\.ly|tinyurl\\.com|goo\\.gl|t\\.co/|cutt\\.ly|is\\.gd|ow\\.ly|rb\\.gy|shorturl\\.at|l24\\.im|ay\\.link|tr\\.ee|rebrand\\.ly)",
        Pattern.CASE_INSENSITIVE
    )

    private val suspiciousTldPattern = Pattern.compile(
        "\\b[a-z0-9-]+\\.(xyz|top|tk|link|click|shop|vip|icu|buzz|win|loan|bet|casino|online|live)\\b",
        Pattern.CASE_INSENSITIVE
    )

    private val validBCodePattern = Pattern.compile("\\b(B\\d{3})\\b", Pattern.CASE_INSENSITIVE)
    private val mersisPattern = Pattern.compile("(\\bmersis(\\s*no)?\\s*[:.]?\\s*(\\d{16})?|\\b0\\d{15}\\b)", Pattern.CASE_INSENSITIVE)
    private val fakeBCodePattern = Pattern.compile(
        "(?:(?<![a-zA-Z0-9])[B\\u0412b\\u0432][\\s._*-]+[0Oo][\\s._*-]*[0Oo1-9][\\s._*-]*[0-9OoIl](?![a-zA-Z0-9])|\\b[B\\u0412b\\u0432](?:[Oo]{2}[0-9]|[0-9][Oo][0-9]|[0-9]{2}[OoIl])\\b|\\b[\\u0412\\u0432\\u0392\\u03B2]\\d{3}\\b)"
    )

    private val spacedOrPunctuatedLetters = Regex(
        "(?<![\\p{L}\\p{N}])([a-zA-ZçğıöşüÇĞİÖŞÜ0134578!@$€])(?:[\\s.*_~+|/\\\\-]+([a-zA-ZçğıöşüÇĞİÖŞÜ0134578!@$€])){3,}(?![\\p{L}\\p{N}])"
    )

    private val inlineInjectedWord = Regex(
        "(?<![\\p{L}\\p{N}])[\\p{L}$!@€][\\p{L}\\p{Nd}.*_!@$€-]{2,}[\\p{L}\\p{Nd}!@$€](?![\\p{L}\\p{N}])"
    )

    private val codeRegex = Pattern.compile("(?<!\\d)(?:[a-z]-)?\\d{4,8}(?!\\d)", Pattern.CASE_INSENSITIVE)
    private val amountRegex = Pattern.compile("\\d+(?:[.,]\\d+)?")

    data class BtkAnalysis(
        val hasValidBCode: Boolean = false,
        val bCode: String? = null,
        val hasMersis: Boolean = false,
        val hasFakeBCodeTrap: Boolean = false,
        val isForeignSender: Boolean = false,
        val foreignCountryCode: String? = null,
        val isForeignSenderWithoutBCode: Boolean = false
    )

    data class Rule(
        val id: String,
        val name: String,
        val pattern: String,
        val type: String, // "keyword" or "regex"
        val target: String, // "any", "sender", "body"
        val action: String, // "spam", "ham", "transaction"
        val enabled: Boolean,
        val caseSensitive: Boolean
    ) {
        private var compiledRegex: Pattern? = null

        private fun matchesSingle(text: String): Boolean {
            if (text.isEmpty()) return false
            return if (type == "regex") {
                try {
                    if (compiledRegex == null) {
                        val cleaned = pattern.replace("(?i)", "")
                        val flags = if (caseSensitive && !pattern.contains("(?i)")) 0 else Pattern.CASE_INSENSITIVE
                        compiledRegex = Pattern.compile(cleaned, flags)
                    }
                    compiledRegex!!.matcher(text).find()
                } catch (e: Exception) {
                    false
                }
            } else {
                val keywords = pattern.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                val targetText = if (caseSensitive) text else text.replace('İ', 'i').lowercase()
                keywords.any { kw ->
                    val k = if (caseSensitive) kw else kw.replace('İ', 'i').lowercase()
                    targetText.contains(k)
                }
            }
        }

        fun matches(text: String, sender: String? = null): Boolean {
            if (!enabled || pattern.trim().isEmpty()) return false
            return when (target) {
                "body" -> matchesSingle(text)
                "sender" -> matchesSingle(sender ?: "")
                else -> {
                    if (!sender.isNullOrBlank() && matchesSingle(sender)) true
                    else matchesSingle(text)
                }
            }
        }
    }

    data class Decision(
        val category: String, // "spam", "ham", "transaction"
        val score: Double,
        val source: String, // "userRule", "threatShield", "otpDetector", "aiModel", "heuristic"
        val ruleName: String? = null
    )

    @Volatile var autoDismiss: Boolean = true
    @Volatile var lastDecisionLatencyMs: Double = 0.42
    @Volatile var spamThreshold: Double = 0.0
    @Volatile var shortUrlBoost: Double = 2.5
    @Volatile var spamPrior: Double = 0.0
    @Volatile var spamWeights: Map<String, Double> = emptyMap()
    @Volatile var otpKeywords: List<String> = emptyList()
    @Volatile var transactionKeywords: List<String> = emptyList()
    @Volatile var bettingShield: Boolean = true
    @Volatile var phishingShield: Boolean = true
    @Volatile var linkShield: Boolean = true
    @Volatile var marketingShield: Boolean = false
    @Volatile var bettingPhrases: List<String> = emptyList()
    @Volatile var govScamPhrases: List<String> = emptyList()
    @Volatile var deliveryScamPhrases: List<String> = emptyList()
    @Volatile var accountPhishingPhrases: List<String> = emptyList()
    @Volatile var marketingPhrases: List<String> = emptyList()
    @Volatile var rules: List<Rule> = emptyList()

    fun updateConfig(jsonString: String) {
        try {
            val root = JSONObject(jsonString)
            autoDismiss = root.optBoolean("autoDismiss", true)
            spamThreshold = root.optDouble("spamThreshold", 0.0)
            shortUrlBoost = root.optDouble("shortUrlBoost", 2.5)
            spamPrior = root.optDouble("spamPrior", 0.0)

            val weightsObj = root.optJSONObject("spamWeights")
            val weightsMap = mutableMapOf<String, Double>()
            if (weightsObj != null) {
                val keys = weightsObj.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    weightsMap[k] = weightsObj.optDouble(k, 0.0)
                }
            }
            spamWeights = weightsMap

            otpKeywords = jsonArrayToStringList(root.optJSONArray("otpKeywords"))
            transactionKeywords = jsonArrayToStringList(root.optJSONArray("transactionKeywords"))
            bettingPhrases = jsonArrayToStringList(root.optJSONArray("bettingPhrases"))
            govScamPhrases = jsonArrayToStringList(root.optJSONArray("govScamPhrases"))
            deliveryScamPhrases = jsonArrayToStringList(root.optJSONArray("deliveryScamPhrases"))
            accountPhishingPhrases = jsonArrayToStringList(root.optJSONArray("accountPhishingPhrases"))
            marketingPhrases = jsonArrayToStringList(root.optJSONArray("marketingPhrases"))

            val shieldsObj = root.optJSONObject("shields")
            if (shieldsObj != null) {
                bettingShield = shieldsObj.optBoolean("bettingShield", true)
                phishingShield = shieldsObj.optBoolean("phishingShield", true)
                linkShield = shieldsObj.optBoolean("linkShield", true)
                marketingShield = shieldsObj.optBoolean("marketingShield", false)
            }

            val rulesArr = root.optJSONArray("rules")
            val rulesList = mutableListOf<Rule>()
            if (rulesArr != null) {
                for (i in 0 until rulesArr.length()) {
                    val r = rulesArr.getJSONObject(i)
                    rulesList.add(
                        Rule(
                            id = r.optString("id", ""),
                            name = r.optString("name", ""),
                            pattern = r.optString("pattern", ""),
                            type = r.optString("type", "keyword"),
                            target = r.optString("target", "any"),
                            action = r.optString("action", "spam"),
                            enabled = r.optBoolean("enabled", true),
                            caseSensitive = r.optBoolean("caseSensitive", false)
                        )
                    )
                }
            }
            rules = rulesList
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun jsonArrayToStringList(arr: JSONArray?): List<String> {
        if (arr == null) return emptyList()
        val list = mutableListOf<String>()
        for (i in 0 until arr.length()) {
            list.add(arr.optString(i))
        }
        return list
    }

    private fun isLatinChar(c: Char): Boolean =
        c in 'A'..'Z' || c in 'a'..'z' || "çğıöşüÇĞİÖŞÜ".indexOf(c) >= 0

    fun hasHomoglyphAttack(text: String): Boolean {
        var hasHomo = false
        var hasLatin = false
        for (c in text) {
            val code = c.code
            if (code in 0xFF01..0xFF5E) return true
            if (homoglyphMap.containsKey(c)) hasHomo = true
            if (isLatinChar(c)) hasLatin = true
        }
        if (hasHomo && hasLatin) return true
        if (Regex("[\\u0412\\u0432\\u0392\\u03B2]\\d{3}").containsMatchIn(text)) return true
        return false
    }

    fun normalizeHomoglyphs(text: String, forceAll: Boolean = false): String {
        val cleaned = text.replace(zeroWidthRegex, "")
        val hasLatin = cleaned.any { isLatinChar(it) }
        val shouldMap = forceAll || hasLatin || Regex("[\\u0412\\u0432\\u0392\\u03B2]\\d{3}").containsMatchIn(cleaned)
        val sb = StringBuilder(cleaned.length)
        for (c in cleaned) {
            val code = c.code
            if (code in 0xFF01..0xFF5E) {
                sb.append((code - 0xFEE0).toChar())
            } else if (shouldMap && homoglyphMap.containsKey(c)) {
                sb.append(homoglyphMap[c]!!)
            } else {
                sb.append(c)
            }
        }
        return sb.toString()
    }

    fun foldTurkishAscii(text: String): String {
        return text
            .replace('İ', 'i')
            .replace('I', 'i')
            .replace('ı', 'i')
            .replace('Ş', 's')
            .replace('ş', 's')
            .replace('Ğ', 'g')
            .replace('ğ', 'g')
            .replace('Ü', 'u')
            .replace('ü', 'u')
            .replace('Ö', 'o')
            .replace('ö', 'o')
            .replace('Ç', 'c')
            .replace('ç', 'c')
            .replace('â', 'a')
            .replace('î', 'i')
            .replace('û', 'u')
    }

    private fun mapLeetSymbolsAndDigits(input: String, mapDigits: Boolean = true): String {
        var out = input
            .replace('!', 'i')
            .replace('¡', 'i')
            .replace('@', 'a')
            .replace('$', 's')
            .replace('€', 'e')
        if (mapDigits) {
            out = out
                .replace('0', 'o')
                .replace('1', 'i')
                .replace('3', 'e')
                .replace('4', 'a')
                .replace('5', 's')
                .replace('7', 't')
                .replace('8', 'b')
        }
        return out
    }

    private fun cleanInjectedToken(raw: String): String {
        if (Regex("^\\d+([.,:-]\\d+)*$").matches(raw)) return raw
        val stripped = raw.replace(Regex("[.*_-]+"), "")
        val mappedSymbols = mapLeetSymbolsAndDigits(stripped, mapDigits = false)
        val hasLetter = mappedSymbols.any { it.isLetter() }
        val hasDigit = mappedSymbols.any { it.isDigit() }
        if (hasLetter && hasDigit && mappedSymbols.length >= 3) {
            return mapLeetSymbolsAndDigits(mappedSymbols, mapDigits = true)
        }
        return mappedSymbols
    }

    fun normalizeObfuscation(text: String): String {
        var cleaned = normalizeHomoglyphs(text, forceAll = true)
            .replace('İ', 'i')
            .lowercase()

        cleaned = spacedOrPunctuatedLetters.replace(cleaned) { m ->
            val raw = m.value.replace(Regex("[\\s.*_~+|/\\\\-]+"), "")
            mapLeetSymbolsAndDigits(raw, mapDigits = true)
        }

        val urls = mutableListOf<String>()
        val urlMatcher = urlPattern.matcher(cleaned)
        val sb = StringBuffer()
        while (urlMatcher.find()) {
            urls.add(urlMatcher.group())
            urlMatcher.appendReplacement(sb, " __url_slot_${urls.size - 1}__ ")
        }
        urlMatcher.appendTail(sb)
        cleaned = sb.toString()

        cleaned = inlineInjectedWord.replace(cleaned) { m ->
            val tok = m.value
            if (tok.startsWith("__url_slot_")) tok else cleanInjectedToken(tok)
        }

        for (i in urls.indices) {
            cleaned = cleaned.replace("__url_slot_${i}__", urls[i])
        }

        val folded = foldTurkishAscii(cleaned)
        return if (folded != cleaned) "$cleaned $folded" else cleaned
    }

    fun analyzeBtk(text: String, sender: String? = null): BtkAnalysis {
        val trimmed = text.replace(zeroWidthRegex, "").trim()
        val cleanSender = sender?.replace(zeroWidthRegex, "")?.trim() ?: ""

        val hasMersis = mersisPattern.matcher(trimmed).find()
        var hasFakeBCodeTrap = fakeBCodePattern.matcher(trimmed).find()

        var validBCode: String? = null
        val bMatcher = validBCodePattern.matcher(trimmed)
        var lastEnd = -1
        var lastGroup: String? = null
        while (bMatcher.find()) {
            lastGroup = bMatcher.group(1)?.uppercase()
            lastEnd = bMatcher.end()
        }
        if (lastGroup != null && lastEnd >= 0) {
            val trailingLen = trimmed.length - lastEnd
            val trailingText = trimmed.substring(lastEnd)
            if (trailingLen <= 28 && !urlPattern.matcher(trailingText).find()) {
                validBCode = lastGroup
            } else {
                hasFakeBCodeTrap = true
            }
        }

        var isForeignSender = false
        var foreignCountryCode: String? = null
        if (cleanSender.isNotEmpty()) {
            val compact = cleanSender.replace(Regex("[\\s()-]"), "")
            if (Regex("^(\\+|00)\\d{6,}$").matches(compact)) {
                val digits = compact.replaceFirst(Regex("^(\\+|00)"), "")
                if (!digits.startsWith("90")) {
                    isForeignSender = true
                    val codeLen = if (digits.startsWith("1") || digits.startsWith("7")) 1 else minOf(2, digits.length)
                    foreignCountryCode = "+${digits.substring(0, codeLen)}"
                }
            }
        }

        val isForeignNoBCode = isForeignSender && validBCode == null && !hasMersis
        return BtkAnalysis(
            hasValidBCode = validBCode != null,
            bCode = validBCode,
            hasMersis = hasMersis,
            hasFakeBCodeTrap = hasFakeBCodeTrap,
            isForeignSender = isForeignSender,
            foreignCountryCode = foreignCountryCode,
            isForeignSenderWithoutBCode = isForeignNoBCode
        )
    }

    fun tokenize(text: String, sender: String? = null): Set<String> {
        val tokens = mutableSetOf<String>()
        val cleaned = text.replace(zeroWidthRegex, "")
        val homoNormalized = normalizeHomoglyphs(cleaned, forceAll = true)
        val lower = homoNormalized.replace('İ', 'i').lowercase()

        if (urlPattern.matcher(lower).find()) tokens.add(URL_TOKEN)
        if (shortenerPattern.matcher(lower).find()) tokens.add(SHORT_URL_TOKEN)
        if (suspiciousTldPattern.matcher(lower).find()) tokens.add(SUSPICIOUS_TLD_TOKEN)

        val btk = analyzeBtk(text, sender)
        if (btk.hasValidBCode || btk.hasMersis) tokens.add(BCODE_TOKEN)
        if (btk.hasFakeBCodeTrap) tokens.add(FAKE_BCODE_TOKEN)
        if (btk.isForeignSenderWithoutBCode) tokens.add(FOREIGN_NO_BCODE_TOKEN)
        if (hasHomoglyphAttack(text)) tokens.add(HOMOGLYPH_TOKEN)

        for (m in spacedOrPunctuatedLetters.findAll(homoNormalized)) {
            val raw = m.value.replace(Regex("[\\s.*_~+|/\\\\-]+"), "").lowercase()
            val collapsed = mapLeetSymbolsAndDigits(raw, mapDigits = true)
            if (collapsed.length >= 3) {
                tokens.add(collapsed)
                tokens.add(foldTurkishAscii(collapsed))
                tokens.add(OBFUSCATED_TOKEN)
            }
        }

        val stripped = urlPattern.matcher(lower).replaceAll(" ")

        for (m in inlineInjectedWord.findAll(stripped)) {
            val rawTok = m.value
            if (Regex("[.*_!@$€-]").containsMatchIn(rawTok)) {
                val deobf = cleanInjectedToken(rawTok)
                if (deobf.length >= 3 && deobf != rawTok) {
                    tokens.add(deobf)
                    tokens.add(foldTurkishAscii(deobf))
                    tokens.add(OBFUSCATED_TOKEN)
                }
            }
        }

        val wordMatcher = Pattern.compile("[\\p{L}\\p{Nd}]+").matcher(stripped)
        while (wordMatcher.find()) {
            val w = wordMatcher.group()
            if (w.length in 4..8 && w.all { it.isDigit() }) {
                tokens.add(CODE_TOKEN)
            } else if (w.all { it.isDigit() }) {
                tokens.add(NUM_TOKEN)
            } else if (w.length > 1) {
                tokens.add(w)
                val ascii = foldTurkishAscii(w)
                if (ascii != w) tokens.add(ascii)
                if (w.any { it.isLetter() } && w.any { it.isDigit() } && w.length >= 3) {
                    val deLeeted = mapLeetSymbolsAndDigits(w, mapDigits = true)
                    tokens.add(deLeeted)
                    tokens.add(foldTurkishAscii(deLeeted))
                }
            }
        }
        return tokens
    }

    fun classify(text: String, sender: String? = null): Decision {
        if (text.isBlank()) return Decision("ham", 0.0, "aiModel")

        // 1. Check custom user rules
        for (r in rules) {
            if (r.matches(text, sender)) {
                return Decision(r.action, 1.0, "userRule", r.name)
            }
        }

        val combined = if (!sender.isNullOrBlank()) "$sender: $text" else text
        val normalized = normalizeObfuscation(combined)
        val features = tokenize(text, sender)
        val btk = analyzeBtk(text, sender)
        val hasUrl = features.contains(URL_TOKEN)
        val lower = normalized

        // 2. Check OTP / Transaction (strictly without links or fake B-code/foreign traps)
        val hasOtpKw = otpKeywords.any { lower.contains(it.lowercase()) }
        val hasCode = codeRegex.matcher(text).find()
        if (hasOtpKw && hasCode && !hasUrl && !btk.hasFakeBCodeTrap && !btk.isForeignSenderWithoutBCode) {
            return Decision("transaction", 0.95, "otpDetector")
        }

        val hasTxnKw = transactionKeywords.any { lower.contains(it.lowercase()) }
        val hasAmount = amountRegex.matcher(text).find()
        if (hasTxnKw && hasAmount && !hasUrl && !btk.hasFakeBCodeTrap && !btk.isForeignSenderWithoutBCode) {
            return Decision("transaction", 0.85, "otpDetector")
        }

        // 3. Threat Intelligence Shields (on de-obfuscated text + BTK parser)
        if (bettingShield) {
            val bettingKeywords = listOf("bahis", "casino", "freespin", "bonanza", "jackpot", "slot")
            if (bettingPhrases.any { lower.contains(it) } ||
                bettingKeywords.count { features.contains(it) || lower.contains(it) } >= 2 ||
                (bettingKeywords.any { features.contains(it) || lower.contains(it) } &&
                    (hasUrl || lower.contains("bonus") || features.contains(OBFUSCATED_TOKEN) || features.contains(HOMOGLYPH_TOKEN)))
            ) {
                return Decision("spam", 0.98, "threatShield", "shieldBetting")
            }
        }
        if (phishingShield) {
            if (govScamPhrases.any { lower.contains(it) } ||
                deliveryScamPhrases.any { lower.contains(it) } ||
                accountPhishingPhrases.any { lower.contains(it) } ||
                btk.hasFakeBCodeTrap ||
                btk.isForeignSenderWithoutBCode
            ) {
                return Decision("spam", 0.97, "threatShield", "shieldPhishing")
            }
        }
        if (linkShield && hasOtpKw && hasCode && hasUrl) {
            return Decision("spam", 0.95, "heuristic", "shieldLink")
        }
        if (marketingShield && (btk.hasValidBCode || btk.hasMersis || marketingPhrases.any { lower.contains(it) })) {
            return Decision("spam", 0.90, "threatShield", "shieldMarketing")
        }

        // 3.5. FAZ 3: 6D Semantic Intent Vector & Combo Multiplier ("Dükkan & Hakan Abi")
        val urgencyHits = listOf("son 24 saat", "son gun", "hesabiniz kapatilacak", "hesabiniz askiya", "icra", "haciz", "uzlastirma", "ceza dosyasi", "bloke", "derhal", "urgent", "suspended").count { lower.contains(it) }
        val financialHits = listOf("para kazan", "borc kapatma", "yatirim firsati", "gunluk kazanc", "kefilsiz", "masrafsiz", "evden calisarak", "gumruk ucreti", "hgs borcu", "customs fee").count { lower.contains(it) }
        val rewardHits = listOf("bonus", "bedava", "kazandiniz", "freespin", "cevrimsiz", "yatirimsiz", "casino", "slot", "hediye ceki", "jackpot").count { lower.contains(it) }
        val actionHits = listOf("tikla", "tiklayin", "giris yap", "uye ol", "hemen katil", "aktif et", "click here", "claim now").count { lower.contains(it) } + (if (hasUrl) 1 else 0) + (if (features.contains(SHORT_URL_TOKEN)) 1 else 0)
        val personalHits = listOf("abi", "abla", "kardesim", "canim", "annem", "babam", "dukkan", "dukkana", "emaneti", "biraktim", "eve gelirken", "ekmek", "toplanti", "gorusuruz").count { lower.contains(it) }

        val comboBoost = if ((rewardHits >= 1 && actionHits >= 1) || (urgencyHits >= 1 && actionHits >= 1) || (financialHits >= 1 && (actionHits >= 1 || urgencyHits >= 1))) 1.65 else 1.0
        val semanticSpamScore = ((urgencyHits * 0.45) + (financialHits * 0.50) + (rewardHits * 0.55) + (actionHits * 0.30)) * comboBoost

        if (semanticSpamScore >= 1.15) {
            return Decision("spam", minOf(0.96, 0.55 + semanticSpamScore * 0.25), "semanticIntent")
        }

        // Hakan Abi / Dükkan conversational protection
        if (personalHits >= 1 && !hasUrl && urgencyHits == 0 && financialHits == 0 && rewardHits == 0 && !btk.hasFakeBCodeTrap && !btk.isForeignSenderWithoutBCode) {
            return Decision("ham", -1.5, "semanticIntent")
        }

        // 4. AI Model scoring
        var score = spamPrior
        for (f in features) {
            val w = spamWeights[f]
            if (w != null) {
                score += w
            }
        }

        var source = "aiModel"
        if (features.contains(SHORT_URL_TOKEN)) {
            score += shortUrlBoost
            source = "heuristic"
        }
        if (features.contains(FAKE_BCODE_TOKEN) || features.contains(FOREIGN_NO_BCODE_TOKEN)) {
            score += 3.0
            source = "heuristic"
        }
        if (features.contains(HOMOGLYPH_TOKEN) || features.contains(OBFUSCATED_TOKEN)) {
            score += 2.2
            source = "heuristic"
        }

        return if (score > spamThreshold) {
            Decision("spam", score, source)
        } else {
            Decision("ham", score, source)
        }
    }
}
