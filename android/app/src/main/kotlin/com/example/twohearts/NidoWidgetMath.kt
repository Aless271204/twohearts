package com.example.twohearts

import java.time.LocalDate
import java.time.YearMonth

/** Date-only calculations; Feb 29 anniversaries fall on Feb 28 in common years. */
object NidoWidgetMath {
    fun days(start: LocalDate?, today: LocalDate): Long? =
        if (start == null || start.isAfter(today)) null else java.time.temporal.ChronoUnit.DAYS.between(start, today)
    fun anniversary(start: LocalDate?, today: LocalDate): LocalDate? {
        if (days(start, today) == null) return null
        fun date(year: Int) = LocalDate.of(year, start!!.monthValue,
            minOf(start.dayOfMonth, YearMonth.of(year, start.monthValue).lengthOfMonth()))
        val next = date(today.year)
        return if (next.isBefore(today)) date(today.year + 1) else next
    }
    // Matches lib/core/couple_daily_quote.dart on VM and web, including UTF-16 IDs.
    fun quoteIndex(members: List<String>, utcDay: Long, count: Int): Int {
        require(count > 0)
        var seed = 1L
        members.filter { it.isNotEmpty() }.distinct().sorted().joinToString(":").forEach {
            seed = (seed * 31 + it.code) % 2147483647L
        }
        val order = IntArray(count) { it }
        for (i in count - 1 downTo 1) {
            seed = (seed * 48271) % 2147483647L
            val j = (seed % (i + 1)).toInt()
            val old = order[i]; order[i] = order[j]; order[j] = old
        }
        return order[Math.floorMod(utcDay, count.toLong()).toInt()]
    }
}
