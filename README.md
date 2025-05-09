# **BitVault Protocol**

## Bitcoin-Backed Lending on Stacks Layer 2

## Overview

**BitVault** is a secure, decentralized Bitcoin-backed lending protocol built on the [Stacks Layer 2 blockchain](https://www.stacks.co/). It allows users to deposit **sBTC (Stacks Bitcoin)** as collateral, borrow assets against their deposits, and participate in liquidations. Designed with industry-standard safety mechanisms, BitVault is tailored for robustness, risk management, and decentralized finance innovation.

## Features

* **sBTC-Collateralized Loans**
  Users can deposit sBTC and borrow against it with enforced minimum collateralization.

* **Liquidation Mechanism**
  Under-collateralized positions are liquidated automatically to protect the protocol, with rewards for liquidators.

* **Dynamic Risk Parameters**
  Administrators can adjust collateralization ratios, interest rates, and liquidation thresholds.

* **Pause/Unpause Capabilities**
  Emergency controls allow administrators to pause and resume the protocol.

* **Compliant with SIP-010**
  Integrates with token contracts that adhere to the SIP-010 standard.

## Protocol Parameters

| Parameter               | Value / Description                        |
| ----------------------- | ------------------------------------------ |
| `MIN-COLLATERAL-RATIO`  | 150% minimum to borrow                     |
| `MAX-INTEREST-RATE`     | 100% APR (in basis points)                 |
| `MIN-INTEREST-RATE`     | 1% APR (in basis points)                   |
| `LIQUIDATION-THRESHOLD` | Default: 80% (Configurable between 70–95%) |
| `MAX-REWARD-MULTIPLIER` | 120% (caps liquidation rewards)            |

## Security & Safeguards

* **Authorization Controls**
  Administrative functions (like setting rates or pausing) are restricted to the contract owner.

* **Safe Math Operations**
  Internal arithmetic functions include overflow/underflow protection.

* **Validated Token Contracts**
  Token interactions are limited to the configured SIP-010 compliant token (default: sBTC).

## Contract Structure

### Authorization

* `is-contract-owner` — Checks if the caller is the protocol owner.
* `is-valid-token` — Verifies if the token used is the authorized SIP-010 token.

### Core Functions

* `initialize` — Sets the SIP-010 token contract used for collateral/repayments.
* `deposit-collateral` — Users deposit sBTC as loan collateral.
* `borrow` — Borrow against deposited collateral within protocol-defined limits.
* `repay` — Repay borrowed funds to reduce or close the loan.
* `liquidate` — Liquidate under-collateralized positions.
* `claim-rewards` — Claim liquidation rewards.

### Read-Only Functions

* `get-user-deposits` — View deposit amount for a user.
* `get-user-borrows` — View borrow and collateral details for a user.
* `get-protocol-stats` — View total deposits, borrows, and interest rate.

### Administrative Functions

* `set-interest-rate` — Adjust the protocol’s borrowing interest rate.
* `set-liquidation-threshold` — Modify when loans become eligible for liquidation.
* `pause-protocol` / `unpause-protocol` — Temporarily disable or resume protocol operations.

## Example Use Flow

1. **Initialize Protocol**
   Admin calls `initialize(token-contract)` with the SIP-010 token (e.g., sBTC).

2. **Deposit Collateral**
   User deposits sBTC via `deposit-collateral(token-contract, amount)`.

3. **Borrow Assets**
   User borrows using `borrow(token-contract, amount)` within collateral limits.

4. **Repay Loan**
   Loan can be repaid with `repay(token-contract, amount)`.

5. **Liquidation**
   If a user becomes under-collateralized, others can call `liquidate` to restore safety and earn rewards.

6. **Claim Rewards**
   Liquidators retrieve accumulated earnings via `claim-rewards`.

## Error Codes

| Error Code                    | Meaning                               |
| ----------------------------- | ------------------------------------- |
| `ERR-NOT-AUTHORIZED`          | Caller lacks required permissions     |
| `ERR-INSUFFICIENT-BALANCE`    | Not enough balance to complete action |
| `ERR-INSUFFICIENT-COLLATERAL` | Collateral below required threshold   |
| `ERR-INVALID-AMOUNT`          | Invalid or non-positive amount passed |
| `ERR-ALREADY-INITIALIZED`     | Protocol already set up               |
| `ERR-NOT-INITIALIZED`         | Protocol not initialized or paused    |
| `ERR-LIQUIDATION-FAILED`      | Cannot liquidate the target position  |

## Requirements

* SIP-010 compliant token (e.g., sBTC)
* Stacks 2.1 compatible Clarity smart contract environment

## Deployment & Testing

1. **Deploy the Contract** to the Stacks testnet or mainnet.
2. **Initialize** the contract with a valid SIP-010 token.
3. **Run Integration Tests** (optional: using Clarinet or similar frameworks).
4. **Use Read-Only Functions** to confirm state correctness.
