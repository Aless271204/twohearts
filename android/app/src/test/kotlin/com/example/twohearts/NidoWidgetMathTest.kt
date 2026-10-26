package com.example.twohearts
import org.junit.Assert.*
import org.junit.Test
import java.time.LocalDate
class NidoWidgetMathTest {
 @Test fun dates() {
  val start=LocalDate.of(2024,2,29)
  assertEquals(LocalDate.of(2025,2,28),NidoWidgetMath.anniversary(start,LocalDate.of(2025,2,1)))
  assertEquals(LocalDate.of(2028,2,29),NidoWidgetMath.anniversary(start,LocalDate.of(2027,3,1)))
  assertNull(NidoWidgetMath.days(start,LocalDate.of(2024,1,1)))
  assertEquals(0L,NidoWidgetMath.days(start,start))
  assertEquals(LocalDate.of(2025,2,28),NidoWidgetMath.anniversary(start,start))
 }
 @Test fun cycle1000() {
  val results=(0L until 1000L).map { NidoWidgetMath.quoteIndex(listOf("b","a","a",""),it,1000) }
  assertEquals(1000,results.toSet().size)
  assertEquals(results[500],NidoWidgetMath.quoteIndex(listOf("a","b"),500L,1000))
 }
}
