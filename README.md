  AquaLedger Smart Contract

AquaLedger is a **Clarity smart contract** that introduces a **water conservation incentive system** using fungible tokens (`AQUA`).  
It rewards users for conserving water, tracked via oracle-reported usage data. The more a user saves relative to their baseline, the more AQUA tokens they earn.  

  Features

-  **Fungible Token (AQUA)** — Minted as rewards for water conservation.  
-  **User Registration** — Users register with sector info and water usage baseline.  
-  **Oracles** — Only approved oracles can record water consumption for users.  
-  **Reward System** — Tokens are minted when usage is below the registered baseline.  
-  **Ownership Controls** — Contract owner can:
  - Add/remove oracles  
  - Update reward rate  
  - Transfer ownership  
-  **Token Redemption** — Users can burn tokens (redeemable for off-chain benefits).  
-  **Transparency** — All actions (registration, usage record, minting, burning) are logged using `print` events.  

 Contract Structure

- **Fungible Token**: `aqua-token`
- **Key Data Variables**:
  - `owner`: Contract deployer, can manage oracles and reward settings.  
  - `reward-rate`: Defines how many AQUA tokens per liter saved.  

- **Data Maps**:
  - `users`: Stores registration details (sector, baseline usage).  
  - `allowed-oracles`: Tracks approved oracle addresses.  
  - `usage-records`: Stores reported water consumption per period.  

 Functions

 Admin
- `set-oracle (oracle principal) (allow bool)` → Add/remove oracles  
- `set-reward-rate (new-rate uint)` → Adjust reward rate  
- `transfer-ownership (new-owner principal)` → Transfer contract ownership  

 User
- `register-user (sector string) (baseline uint)` → Register with baseline usage  
- `get-user (u principal)` → View user info  
- `redeem-tokens (amount uint)` → Burn tokens  
- `get-aqua-balance (who principal)` → Get AQUA token balance  

 Oracle
- `record-usage (user principal) (period uint) (liters uint)` → Record usage data and mint rewards  
- `get-usage (user principal) (period uint)` → Retrieve usage record  

Read-only
- `is-oracle-approved (who principal)` → Check oracle status  
- `get-reward-rate ()` → Get current reward rate  
- `get-owner ()` → Get contract owner  

 Deployment

1. Clone this repository.  
   ```bash
   git clone https://github.com/your-username/aqualedger.git
   cd aqualedger
