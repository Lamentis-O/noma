import { createClient } from "npm:@supabase/supabase-js@2.49.8";
import {
  fetchVerifiedTransaction,
  millisToISOString,
  statusFromTransaction,
  validateTransaction,
} from "../_shared/app-store.ts";

type SyncRequest = {
  transaction_id?: string;
  transaction_json_representation?: string;
};

type EntitlementRow = {
  app_account_token: string;
  user_id: string;
};

const jsonHeaders = { "Content-Type": "application/json" };

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return Response.json({ error: "Method not allowed." }, { status: 405, headers: jsonHeaders });
  }

  try {
    const supabase = adminClient();
    const user = await authenticatedUserID(req, supabase);
    const body = await req.json() as SyncRequest;
    const transactionID = body.transaction_id?.trim();

    if (!transactionID) {
      return Response.json({ error: "transaction_id is required." }, { status: 400, headers: jsonHeaders });
    }

    const entitlement = await loadEntitlement(supabase, user.id);
    const transaction = await fetchVerifiedTransaction(transactionID);
    validateTransaction(transaction, entitlement.app_account_token);

    const updated = await applyEntitlement(supabase, {
      environment: transaction.environment ?? null,
      eventID: `client-sync:${transaction.transactionId}`,
      eventType: "client_sync",
      expiresAt: millisToISOString(transaction.expiresDate),
      originalTransactionID: transaction.originalTransactionId ?? null,
      productID: transaction.productId ?? null,
      status: statusFromTransaction(transaction),
      transactionID: transaction.transactionId ?? transactionID,
      userID: user.id,
      payload: {
        source: "client_sync",
        storeKitTransaction: safeJSONObject(body.transaction_json_representation),
        verifiedAppleTransaction: transaction,
      },
    });

    return Response.json(updated, { headers: jsonHeaders });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown subscription sync error.";
    const status = message.includes("Authorization") ? 401 : 400;
    return Response.json({ error: message }, { status, headers: jsonHeaders });
  }
});

function adminClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
}

async function authenticatedUserID(req: Request, supabase: ReturnType<typeof adminClient>) {
  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    throw new Error("Authorization header is required.");
  }

  const token = authorization.replace(/^Bearer\s+/i, "");
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    throw new Error("Authorization user could not be verified.");
  }

  return data.user;
}

async function loadEntitlement(supabase: ReturnType<typeof adminClient>, userID: string): Promise<EntitlementRow> {
  const { data, error } = await supabase
    .from("user_entitlements")
    .select("user_id, app_account_token")
    .eq("user_id", userID)
    .single();

  if (error || !data) {
    throw new Error("User entitlement row is missing.");
  }

  return data;
}

async function applyEntitlement(
  supabase: ReturnType<typeof adminClient>,
  input: {
    environment: string | null;
    eventID: string;
    eventType: string;
    expiresAt: string | null;
    originalTransactionID: string | null;
    payload: Record<string, unknown>;
    productID: string | null;
    status: string;
    transactionID: string;
    userID: string;
  },
) {
  const { data, error } = await supabase
    .from("user_entitlements")
    .update({
      tier: "pro",
      status: input.status,
      product_id: input.productID,
      original_transaction_id: input.originalTransactionID,
      transaction_id: input.transactionID,
      expires_at: input.expiresAt,
      last_verified_at: new Date().toISOString(),
    })
    .eq("user_id", input.userID)
    .select()
    .single();

  if (error || !data) {
    throw new Error("Failed to update subscription entitlement.");
  }

  const { error: eventError } = await supabase.from("subscription_events").upsert({
    environment: input.environment,
    event_id: input.eventID,
    event_type: input.eventType,
    original_transaction_id: input.originalTransactionID,
    payload: input.payload,
    product_id: input.productID,
    transaction_id: input.transactionID,
    user_id: input.userID,
  }, { onConflict: "event_id", ignoreDuplicates: true });
  if (eventError) {
    throw new Error("Failed to record subscription sync event.");
  }

  return data;
}

function safeJSONObject(value: string | undefined): Record<string, unknown> | null {
  if (!value) {
    return null;
  }

  try {
    return JSON.parse(value) as Record<string, unknown>;
  } catch {
    return null;
  }
}
