import { AppStoreServerAPIClient, Environment, SignedDataVerifier } from "npm:@apple/app-store-server-library@3.1.0";
import { Buffer } from "node:buffer";

export type AppleTransaction = {
  appAccountToken?: string;
  bundleId?: string;
  environment?: string;
  expiresDate?: number;
  originalTransactionId?: string;
  productId?: string;
  revocationDate?: number;
  transactionId?: string;
};

export type EntitlementStatus = "active" | "billing_retry" | "expired" | "grace_period" | "revoked";

export function configuredProductIDs(): string[] {
  return (Deno.env.get("APPLE_PRODUCT_IDS") ?? "noma.pro.monthly,noma.pro.yearly")
    .split(",")
    .map((id) => id.trim())
    .filter(Boolean);
}

export function appleBundleID(): string {
  return Deno.env.get("APPLE_BUNDLE_ID") ?? "LAM.Noma";
}

export function appleEnvironment(): Environment {
  return (Deno.env.get("APPLE_ENVIRONMENT") ?? "SANDBOX").toUpperCase() === "PRODUCTION"
    ? Environment.PRODUCTION
    : Environment.SANDBOX;
}

export function makeAppleAPIClient(): AppStoreServerAPIClient {
  return new AppStoreServerAPIClient(
    requiredSecret("APPLE_IN_APP_PURCHASE_PRIVATE_KEY").replace(/\\n/g, "\n"),
    requiredSecret("APPLE_KEY_ID"),
    requiredSecret("APPLE_ISSUER_ID"),
    appleBundleID(),
    appleEnvironment(),
  );
}

export function makeSignedDataVerifier(): SignedDataVerifier {
  const appAppleID = Deno.env.get("APPLE_APP_APPLE_ID");

  return new SignedDataVerifier(
    appleRootCertificates(),
    true,
    appleEnvironment(),
    appleBundleID(),
    appAppleID ? Number(appAppleID) : undefined,
  );
}

export async function fetchVerifiedTransaction(transactionID: string): Promise<AppleTransaction> {
  const response = await makeAppleAPIClient().getTransactionInfo(transactionID);
  if (!response.signedTransactionInfo) {
    throw new Error("Apple response did not include signedTransactionInfo.");
  }

  return await makeSignedDataVerifier().verifyAndDecodeTransaction(response.signedTransactionInfo) as AppleTransaction;
}

export async function verifyNotificationPayload(signedPayload: string) {
  return await makeSignedDataVerifier().verifyAndDecodeNotification(signedPayload);
}

export async function verifySignedTransactionInfo(signedTransactionInfo: string): Promise<AppleTransaction> {
  return await makeSignedDataVerifier().verifyAndDecodeTransaction(signedTransactionInfo) as AppleTransaction;
}

export function statusFromTransaction(transaction: AppleTransaction): EntitlementStatus {
  if (transaction.revocationDate) {
    return "revoked";
  }

  const expiresDate = millisToDate(transaction.expiresDate);
  if (expiresDate && expiresDate.getTime() <= Date.now()) {
    return "expired";
  }

  return "active";
}

export function statusFromAppleNotification(status: unknown): EntitlementStatus | null {
  switch (status) {
  case 1:
    return "active";
  case 2:
    return "expired";
  case 3:
    return "billing_retry";
  case 4:
    return "grace_period";
  case 5:
    return "revoked";
  default:
    return null;
  }
}

export function millisToISOString(value: unknown): string | null {
  const date = millisToDate(value);
  return date ? date.toISOString() : null;
}

export function validateTransaction(transaction: AppleTransaction, expectedAppAccountToken?: string) {
  if (transaction.bundleId !== appleBundleID()) {
    throw new Error("Apple transaction bundle does not match this app.");
  }

  if (!transaction.productId || !configuredProductIDs().includes(transaction.productId)) {
    throw new Error("Apple transaction product is not a configured Noma subscription.");
  }

  if (expectedAppAccountToken && transaction.appAccountToken !== expectedAppAccountToken) {
    throw new Error("Apple transaction appAccountToken does not match the signed-in user.");
  }
}

function appleRootCertificates(): Buffer[] {
  const value = Deno.env.get("APPLE_ROOT_CERTIFICATES_PEM_JSON");
  if (!value) {
    throw new Error("APPLE_ROOT_CERTIFICATES_PEM_JSON is not configured.");
  }

  const certificates = JSON.parse(value) as string[];
  return certificates.map((certificate) => Buffer.from(certificate.replace(/\\n/g, "\n")));
}

function millisToDate(value: unknown): Date | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }

  return new Date(value);
}

function requiredSecret(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`${name} is not configured.`);
  }

  return value;
}
