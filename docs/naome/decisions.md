# Decisions

Record durable project decisions that future agents should preserve.

Only record decisions that apply to this target repository. Do not copy global
skills, previous workspace rules, or unrelated harness policy into this file
unless the user explicitly confirms that they should become local policy.

## Template

```md
## YYYY-MM-DD: Decision title

- Decision:
- Reason:
- Applies to:
- Verification or follow-up:
```

## 2026-05-15: Product direction and verification baseline

- Decision: Noma is an iPhone-first autonomous todo tracker with AI features
  and subscription-based SaaS monetization. The default simulator is the latest
  available `iPhone 17 Pro`, and PRs must pass the iOS simulator build.
- Reason: Confirmed by the repository owner during NAOME first-run intake.
- Applies to: Product planning, iOS simulator verification, AI feature work,
  subscription/payment work, premium entitlement work, and API usage tracking.
- Verification or follow-up: Future OpenAI API, subscription/payment, premium
  entitlement, and API usage features require strict targeted tests and human
  review before merge.
