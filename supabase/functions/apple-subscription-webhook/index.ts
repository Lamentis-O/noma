import { createClient } from "npm:@supabase/supabase-js@2.49.8";
import {
  millisToISOString,
  statusFromAppleNotification,
  statusFromTransaction,
  validateTransaction,
  verifyNotificationPayload,
  verifySignedTransactionInfo,
} from "../_shared/app-store.ts";

const jsonHeaders = { "Content-Type": "application/json" };

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "Method not allowed." }, { status: 405, headers: jsonHeaders });
  }

  try {
    const body = await req.json() as { signedPayload?: string };
    if (!body.signedPayload) {
      return Response.json({ error: "signedPayload is required." }, { status: 400, headers: jsonHeaders });
    }

    const notification = await verifyNotificationPayload(body.signedPayload) as Record<string, unknown>;
    const data = notification.data as Record<string, unknown> | undefined;
    const signedTransactionInfo = data?.signedTransactionInfo as string | undefined;
    const transaction = signedTransactionInfo
      ? await verifySignedTransactionInfo(signedTransactionInfo)
      : null;

    if (transaction) {
      validateTransaction(transaction);
    }

    const supabase = adminClient();
    const entitlement = transaction ? await findEntitlement(supabase, transaction) : null;
    const eventID = notification.notificationUUID as string | undefined;
    const status = statusFromAppleNotification(data?.status) ?? (transaction ? statusFromTransaction(transaction) : "expired");

    const { error: eventError } = await supabase.from("subscription_events").upsert({
      environment: data?.environment ?? transaction?.environment ?? null,
      event_id: eventID ?? null,
      event_type: notification.notificationType ?? "apple_subscription_notification",
      original_transaction_id: transaction?.originalTransactionId ?? null,
      payload: notification,
      product_id: transaction?.productId ?? null,
      transaction_id: transaction?.transactionId ?? null,
      user_id: entitlement?.user_id ?? null,
    }, { onConflict: "event_id", ignoreDuplicates: true });
    if (eventError) {
      throw new Error("Failed to record Apple subscription notification.");
    }

    if (entitlement && transaction) {
      const { error: updateError } = await supabase
        .from("user_entitlements")
        .update({
          tier: "pro",
          status,
          product_id: transaction.productId ?? null,
          original_transaction_id: transaction.originalTransactionId ?? null,
          transaction_id: transaction.transactionId ?? null,
          expires_at: millisToISOString(transaction.expiresDate),
          last_verified_at: new Date().toISOString(),
        })
        .eq("user_id", entitlement.user_id);
      if (updateError) {
        throw new Error("Failed to update subscription entitlement from Apple notification.");
      }
    }

    return Response.json({ received: true }, { headers: jsonHeaders });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown Apple webhook error.";
    return Response.json({ error: message }, { status: 400, headers: jsonHeaders });
  }
});

function adminClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

async function findEntitlement(
  supabase: ReturnType<typeof adminClient>,
  transaction: { appAccountToken?: string; originalTransactionId?: string },
) {
  if (transaction.appAccountToken) {
    const { data } = await supabase
      .from("user_entitlements")
      .select("user_id")
      .eq("app_account_token", transaction.appAccountToken)
      .maybeSingle();

    if (data) {
      return data;
    }
  }

  if (transaction.originalTransactionId) {
    const { data } = await supabase
      .from("user_entitlements")
      .select("user_id")
      .eq("original_transaction_id", transaction.originalTransactionId)
      .maybeSingle();

    return data;
  }

  return null;
}
