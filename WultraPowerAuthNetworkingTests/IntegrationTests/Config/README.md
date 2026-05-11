# Integration Tests Configuration

The `Config/` folder holds configuration for server-dependent integration tests.

## Setup

1. Copy `config-example.json` to `config.json`.
2. Fill in the values with your PowerAuth Cloud and Enrollment Server details.

| Key | Description |
|-----|-------------|
| `cloudServerUrl` | PowerAuth Cloud server URL used for activation management. |
| `cloudServerLogin` | Basic-auth login for the Cloud server API. |
| `cloudServerPassword` | Basic-auth password for the Cloud server API. |
| `cloudApplicationId` | Application identifier registered in PowerAuth Cloud. |
| `enrollmentServerUrl` | Enrollment server URL used as the PowerAuth SDK `baseEndpointUrl`. |
| `enrollmentServerOnboardingUrl` | Enrollment server onboarding URL used as the base URL for E2EE onboarding endpoints (e.g. `/api/onboarding/start`). |
| `operationsServerUrl` | Server URL used as the base URL for authenticated and token-authenticated operation endpoints. |

## Running

Some tests depend on a valid configuration. Such tests **will fail** without a valid `config.json` or when it contains placeholder values.

## Endpoint strategy

Integration tests leverage **existing endpoints from the Wultra ecosystem** (Enrollment Server, PowerAuth Cloud) rather than custom test-only endpoints. The endpoint definitions used in tests are reimplemented locally but mirror real endpoints from [digital-onboarding-apple](https://github.com/wultra/digital-onboarding-apple) and [mtoken-sdk-ios](https://github.com/wultra/mtoken-sdk-ios). This ensures the SDK is validated against the same server contracts it will encounter in production.

> **Note:** `config.json` is git-ignored to prevent committing credentials. Only `config-example.json` is tracked.
