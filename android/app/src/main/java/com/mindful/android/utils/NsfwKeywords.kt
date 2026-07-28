package com.mindful.android.utils

/**
 * NSFW text matching with fuzzy normalization (leetspeak, stripped punctuation).
 *
 * Blocks porn intent only — allowlist protects education/tech false positives.
 */
object NsfwKeywords {

    /** Unambiguous standalone tokens (matched after fuzzy normalize). */
    private val pornWholeWords = hashSetOf(
        "porn", "porno", "pornhub", "xxx", "xnxx", "xvideos", "xhamster",
        "hentai", "nsfw", "eporner", "eprner", "spankbang", "youporn", "redtube",
        "onlyfans", "brazzers", "bangbros", "chaturbate", "missav", "avgle",
        "javhd", "javlibrary", "javmost", "youjizz", "hqporner", "porntrex",
        "motherless", "porndig", "porndoe", "txxx", "tnaflix", "beeg",
        "nudevista", "literotica", "sexstories", "camgirl", "camsex",
        "blowjob", "handjob", "deepthroat", "creampie", "cumshot", "gangbang",
        "threesome", "stepmom", "stepsister", "fap", "hentai", "erotic",
        "stripchat", "livejasmin", "manyvids", "fansly", "realitykings",
        "naughtyamerica", "blacked", "vixen", "puretaboo", "digitalplayground",
        "bellesa", "xnudes", "fucktube", "pornhd", "tubegalore",
    )

    /** Strong multi-word / substring phrases (fuzzy-normalized at init). */
    private val pornPhrases = hashSetOf(
        "porn video", "porn videos", "porn movie", "porn movies", "porn site",
        "porn sites", "porn tube", "watch porn", "free porn", "xxx video",
        "xxx videos", "sex video", "sex videos", "nude video", "nude videos",
        "naked sex", "hot sex video", "adult video", "adult videos", "adult porn",
        "japanese porn", "japan porn", "jav video", "jav videos", "jav japan",
        "japan jav", "jav porn", "desi porn", "desi sex", "aunty sex",
        "aunty video", "aunty videos", "mms leak", "leaked sex", "noodle magazine",
        "noodlemagazine", "spank bank", "rule 34", "rule34", "hq porn",
        "step sister", "hookup sex", "penis porn", "pure taboo", "puretaboo",
        "incest porn", "teen porn", "milf porn", "lesbian porn", "gay porn",
        "hardcore porn", "amateur porn", "webcam sex", "live sex", "sex cam",
        "nsfw video", "nsfw videos", "erotic video", "erotic videos",
        "uncensored jav", "jav uncensored", "adult film", "adult movie",
        "xxx movie", "porn hub", "x videos", "x hamster", "spank bang",
        "only fans", "chat urbate", "fuck video", "fucking video",
        "masturbat", "strip chat", "cam girl", "porn star", "pornstar",
        "leaked nudes", "nude leak", "sex tape", "sextape",
    )

    /** Site / tube brands (also checked as fuzzy substrings). */
    private val siteBrands = hashSetOf(
        "eporner", "eprner", "pornhub", "xnxx", "xvideos", "xhamster",
        "spankbang", "noodlemagazine", "noodle magazine", "youporn", "redtube",
        "youjizz", "beeg", "txxx", "tnaflix", "hqporner", "porntrex",
        "motherless", "chaturbate", "onlyfans", "brazzers", "bangbros",
        "javhd", "missav", "avgle", "javmost", "javlibrary", "porndig",
        "porndoe", "porntube", "nudevista", "puretaboo", "stripchat",
        "livejasmin", "manyvids", "fansly", "realitykings", "naughtyamerica",
        "digitalplayground", "bellesa", "fucktube", "pornhd",
    )

    private val safeSearchAllowlist = listOf(
        "sex education", "same sex", "sexual health", "sexual harassment",
        "sexual assault", "sexually transmitted", "sex offender", "sex ratio",
        "sex determination", "sex linked", "sex chromosome", "sex pistols",
        "sex and the city", "unisex", "essex", "sussex", "middlesex", "wessex",
        "analgesic", "analytics", "analysis", "analog", "analogy", "analyst",
        "anal cancer", "anal fissure", "hardcore punk", "hardcore music",
        "adult education", "adult learning", "adult diapers", "adult adhd",
        "adult coloring", "breast cancer", "cocktail", "cockatoo", "peacock",
        "hancock", "dictionary", "predict", "dickens", "dickinson",
        "java", "javascript", "javac", "taboo tuesday", "pure taboo cooking",
    )

    /** Precomputed fuzzy forms for O(1)-ish contains checks. */
    private val fuzzyPhrases: Set<String> by lazy {
        pornPhrases.map { fuzzyNormalize(it) }.filter { it.length >= 3 }.toHashSet()
    }
    private val fuzzyBrands: Set<String> by lazy {
        siteBrands.map { fuzzyNormalize(it) }.filter { it.length >= 3 }.toHashSet()
    }
    private val fuzzyWholeWords: Set<String> by lazy {
        pornWholeWords.map { fuzzyNormalize(it) }.filter { it.length >= 3 }.toHashSet()
    }
    private val fuzzyAllowlist: List<String> by lazy {
        safeSearchAllowlist.map { fuzzyNormalize(it) }
    }

    /**
     * Lowercase, decode URL spaces, strip punctuation, collapse whitespace,
     * apply basic leetspeak (0→o, 1→i, 3→e, 4→a, 5→s, @→a, $→s).
     */
    fun fuzzyNormalize(text: String): String {
        if (text.isBlank()) return ""
        val sb = StringBuilder(text.length)
        var prevSpace = false
        for (ch in text) {
            val c = when (ch) {
                '+', '\t', '\n', '\r' -> ' '
                else -> ch.lowercaseChar()
            }
            val mapped = when (c) {
                '0' -> 'o'
                '1' -> 'i'
                '3' -> 'e'
                '4' -> 'a'
                '5' -> 's'
                '@' -> 'a'
                '$' -> 's'
                else -> c
            }
            when {
                mapped.isLetterOrDigit() -> {
                    sb.append(mapped)
                    prevSpace = false
                }
                mapped.isWhitespace() -> {
                    if (!prevSpace && sb.isNotEmpty()) {
                        sb.append(' ')
                        prevSpace = true
                    }
                }
                // strip other punctuation
            }
        }
        // also strip spaces for compact form matching (p o r n → porn)
        return sb.toString().trim().replace("%20", " ")
    }

    /** Compact form with spaces removed — catches "p o r n" / "pure taboo". */
    fun fuzzyCompact(text: String): String = fuzzyNormalize(text).replace(" ", "")

    fun normalizeForMatch(text: String): String = fuzzyNormalize(text)

    fun isSafeNormalSearch(text: String): Boolean {
        val fuzzy = fuzzyNormalize(text)
        val compact = fuzzy.replace(" ", "")
        return fuzzyAllowlist.any { allow ->
            fuzzy.contains(allow) || compact.contains(allow.replace(" ", ""))
        }
    }

    fun isPornSearchQuery(text: String): Boolean {
        if (text.isBlank()) return false
        if (isSafeNormalSearch(text)) return false

        val fuzzy = fuzzyNormalize(text)
        val compact = fuzzy.replace(" ", "")
        if (fuzzy.length < 2) return false

        if (matchesAnyPhrase(fuzzy, compact)) return true
        if (matchesAnyBrand(fuzzy, compact)) return true
        if (matchesAnyWholeWord(fuzzy, compact)) return true

        // "jav" only with adult context
        if (containsToken(fuzzy, "jav") || compact.contains("jav")) {
            val adult = listOf(
                "video", "videos", "porn", "xxx", "japan", "japanese",
                "uncensored", "censored", "idol", "av",
            )
            if (adult.any { fuzzy.contains(it) || compact.contains(it) }) return true
        }

        return false
    }

    /**
     * Visible page / SERP / alt-text matcher — brands, phrases, domains-as-text.
     */
    fun isPornVisibleContent(text: String): Boolean {
        if (text.isBlank()) return false
        if (isSafeNormalSearch(text)) return false

        val fuzzy = fuzzyNormalize(text)
        val compact = fuzzy.replace(" ", "")
        if (fuzzy.length < 3) return false

        if (matchesAnyPhrase(fuzzy, compact)) return true
        if (matchesAnyBrand(fuzzy, compact)) return true
        if (matchesAnyWholeWord(fuzzy, compact)) return true

        // Domain-looking porn hosts in result titles/snippets
        if (NsfwDomainRepository.domainCount() > 0) {
            // Fast path: only check if text looks like it has a host fragment
            if (text.contains('.') && text.length < 4000) {
                extractLikelyHosts(text).forEach { host ->
                    if (NsfwDomainRepository.isBlocked(host)) return true
                }
            }
        }

        return false
    }

    private fun matchesAnyPhrase(fuzzy: String, compact: String): Boolean {
        for (phrase in fuzzyPhrases) {
            if (phrase.length < 4) continue
            if (fuzzy.contains(phrase) || compact.contains(phrase.replace(" ", ""))) {
                return true
            }
        }
        return false
    }

    private fun matchesAnyBrand(fuzzy: String, compact: String): Boolean {
        for (brand in fuzzyBrands) {
            if (brand.length < 4) continue
            if (fuzzy.contains(brand) || compact.contains(brand.replace(" ", ""))) {
                return true
            }
        }
        return false
    }

    private fun matchesAnyWholeWord(fuzzy: String, compact: String): Boolean {
        for (word in fuzzyWholeWords) {
            if (word.length < 3) continue
            if (containsToken(fuzzy, word) || compact.contains(word)) return true
        }
        return false
    }

    private fun containsToken(haystack: String, token: String): Boolean {
        var start = 0
        while (true) {
            val idx = haystack.indexOf(token, start)
            if (idx < 0) return false
            val beforeOk = idx == 0 || !haystack[idx - 1].isLetterOrDigit()
            val end = idx + token.length
            val afterOk = end >= haystack.length || !haystack[end].isLetterOrDigit()
            if (beforeOk && afterOk) return true
            start = idx + 1
        }
    }

    private fun extractLikelyHosts(text: String): List<String> {
        val result = ArrayList<String>(8)
        val regex = Regex(
            """(?i)\b(?:https?://)?(?:www\.)?([a-z0-9][a-z0-9\-.]{1,60}\.(?:com|net|org|tv|xxx|porn|to|cc|io|co))\b""",
        )
        regex.findAll(text.take(2000)).forEach { match ->
            match.groupValues.getOrNull(1)?.let { result.add(it) }
            if (result.size >= 12) return result
        }
        return result
    }
}
