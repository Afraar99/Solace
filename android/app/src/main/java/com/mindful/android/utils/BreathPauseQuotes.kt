/*
 *
 *  * Copyright (c) 2024 Solace
 *
 */

package com.mindful.android.utils

import com.mindful.android.AppConstants
import kotlin.random.Random

/**
 * Catchy / funny per-app advice lines for the breathing pause overlay.
 */
object BreathPauseQuotes {

    fun forPackage(packageName: String): String {
        val pool = quotesFor(packageName)
        return pool[Random.nextInt(pool.size)]
    }

    private fun quotesFor(packageName: String): List<String> {
        val p = packageName.lowercase()
        return when {
            p == AppConstants.FACEBOOK_PACKAGE ||
                    p.contains("facebook") ||
                    p == "com.facebook.lite" -> facebook

            p == AppConstants.INSTAGRAM_PACKAGE ||
                    p.contains("instagram") -> instagram

            p.contains("whatsapp") -> whatsapp

            p.contains("twitter") ||
                    p == "com.twitter.android" ||
                    p == "com.twitter.android.lite" ||
                    p.contains("com.x.") ||
                    p.endsWith(".x.android") ||
                    p == "com.x.android" -> twitter

            p == AppConstants.YOUTUBE_PACKAGE ||
                    p.contains(AppConstants.YOUTUBE_CLIENT_PACKAGE_SUFFIX) ||
                    p.contains("youtube") -> youtube

            p.contains("telegram") || p.contains("org.telegram") -> telegram

            p.contains("chrome") ||
                    p == "com.android.chrome" ||
                    p == "com.chrome.beta" ||
                    p == "com.sec.android.app.sbrowser" -> chrome

            p == AppConstants.SNAPCHAT_PACKAGE ||
                    p.contains("snapchat") -> snapchat

            p == AppConstants.REDDIT_PACKAGE ||
                    p.contains("reddit") -> reddit

            p.contains("tiktok") || p.contains("musical.ly") -> tiktok

            else -> generic
        }
    }

    private val facebook = listOf(
        "News feed or need feed? Choose wisely.",
        "That scroll isn’t free — it charges your focus.",
        "Aunties, ads, and arguments… still going in?",
        "One peek becomes one hour. You’ve been warned.",
        "Facebook called. It wants your afternoon.",
    )

    private val instagram = listOf(
        "Reels aren’t real life. You are.",
        "Explore page? Or explore your goals?",
        "Pretty pictures, sneaky time thief.",
        "Double-tap later. Deep breath first.",
        "Stories expire. Your focus shouldn’t.",
    )

    private val whatsapp = listOf(
        "Blue ticks can wait. You can’t rewind time.",
        "Group chat energy is contagious — and exhausting.",
        "Reply with intention, not impulse.",
        "That ‘quick check’ is never quick.",
        "Status update: you’re still breathing. Nice.",
    )

    private val twitter = listOf(
        "Timeline or doomscroll? Pick your fighter.",
        "Hot takes cool down. Your calm stays.",
        "The bird (or X) can wait 30 seconds.",
        "Outrage is a subscription — cancel it.",
        "Tweet later. Think now.",
    )

    private val youtube = listOf(
        "‘Just one video’ is YouTube’s favorite lie.",
        "Autoplay is not your life plan.",
        "Pause before the pause button disappears.",
        "Recommended: finishing what you started IRL.",
        "Thumbnails scream. You don’t have to listen.",
    )

    private val telegram = listOf(
        "Channels flood. You don’t have to sink.",
        "Forward later. Focus first.",
        "Secret chats, public time waste.",
        "Telegram isn’t going anywhere. Your hour might.",
        "Mute the noise. Unmute yourself.",
    )

    private val chrome = listOf(
        "New tab, new rabbit hole?",
        "The internet will still be there after this breath.",
        "Browsing isn’t free — pay with attention.",
        "Bookmarks don’t bookmark your time.",
        "One search… or one spiral?",
    )

    private val snapchat = listOf(
        "Snaps vanish. Regret doesn’t.",
        "Streaks aren’t personality traits.",
        "Camera roll can wait. Calm can’t.",
        "Bitmoji says hi. Goals say ‘later’.",
        "Spotlight is bright. So is your future.",
    )

    private val reddit = listOf(
        "Front page of the internet ≠ front page of your life.",
        "Threads never end. You can.",
        "Upvotes down, focus up.",
        "AMA: Are you mindfully opening this?",
    )

    private val tiktok = listOf(
        "For You page ≠ For Your goals.",
        "15 seconds becomes 15 minutes. Math checks out.",
        "Scroll slower than the algorithm wants.",
        "Catchy sounds, catchier time traps.",
    )

    private val generic = listOf(
        "Take a second. Your future self says thanks.",
        "Open with purpose, not habit.",
        "Breath first. App second.",
        "You pressed open — Solace pressed pause.",
        "Impulse in, intention out.",
        "Small pause. Big difference.",
    )
}
