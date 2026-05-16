import { assertEquals } from "jsr:@std/assert@1";
import {
  millisToISOString,
  statusFromAppleNotification,
  statusFromTransaction,
} from "../../../../supabase/functions/_shared/app-store.ts";

Deno.test("statusFromTransaction maps revoked, expired, and active states", () => {
  assertEquals(statusFromTransaction({ revocationDate: 1 }), "revoked");
  assertEquals(statusFromTransaction({ expiresDate: Date.now() - 1_000 }), "expired");
  assertEquals(statusFromTransaction({ expiresDate: Date.now() + 1_000 }), "active");
});

Deno.test("statusFromAppleNotification maps App Store subscription status codes", () => {
  assertEquals(statusFromAppleNotification(1), "active");
  assertEquals(statusFromAppleNotification(2), "expired");
  assertEquals(statusFromAppleNotification(3), "billing_retry");
  assertEquals(statusFromAppleNotification(4), "grace_period");
  assertEquals(statusFromAppleNotification(5), "revoked");
  assertEquals(statusFromAppleNotification(999), null);
});

Deno.test("millisToISOString returns an ISO timestamp for millisecond values", () => {
  assertEquals(millisToISOString(1_771_123_456_000), "2026-02-15T02:44:16.000Z");
  assertEquals(millisToISOString("not-a-date"), null);
});
