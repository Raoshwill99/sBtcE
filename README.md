# sBTC Enhancement Smart Contract

A comprehensive Bitcoin-Stacks bridge protocol enabling trustless Bitcoin wrapping, atomic swaps, and DeFi features on the Stacks blockchain.

## 🚀 Overview

The sBTC Enhancement project is a multi-phase smart contract system that brings Bitcoin liquidity to the Stacks ecosystem through synthetic Bitcoin (sBTC) tokens. The protocol enables users to wrap Bitcoin into sBTC, perform atomic swaps, provide liquidity, and engage in collateralized lending.

## 📋 Features

### Phase 1: Foundation
- Basic sBTC token framework
- User balance tracking
- Core data structures

### Phase 2: Atomic Swaps
- Trustless STX ↔ sBTC swaps
- Time-locked transactions
- Automatic cancellation and refunds
- Swap status tracking

### Phase 3: Complete DeFi Integration
- **Bitcoin Bridge**: Complete Bitcoin deposit/withdrawal system
- **Oracle Integration**: Real-time BTC/STX price feeds
- **Liquidity Pools**: Automated Market Maker (AMM) functionality
- **Collateralized Positions**: Over-collateralized sBTC minting
- **Advanced Trading**: Slippage protection and fee mechanisms
- **Risk Management**: Emergency controls and liquidation systems

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Bitcoin       │    │   Oracle         │    │   Stacks        │
│   Network       │◄──►│   Service        │◄──►│   Smart         │
│                 │    │                  │    │   Contract      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
        │                        │                        │
        │                        │                        │
        ▼                        ▼                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Bitcoin       │    │   Price Feeds    │    │   sBTC Tokens   │
│   Deposits      │    │   Validation     │    │   LP Tokens     │
│   Withdrawals   │    │   Confirmations  │    │   Positions     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🔧 Technical Specifications

### Constants
- **Swap Expiration**: 144 blocks (~24 hours)
- **Bitcoin Confirmations**: 6 minimum
- **Protocol Fee**: 0.3% (30 basis points)
- **Max Slippage**: 5% (500 basis points)
- **Liquidation Threshold**: 80% (8000 basis points)
- **Min Collateral Ratio**: 125%

### Error Codes
```clarity
ERR-NOT-AUTHORIZED (u100)        - Unauthorized access
ERR-INVALID-AMOUNT (u101)        - Invalid amount specified
ERR-INSUFFICIENT-BALANCE (u102)  - Insufficient balance
ERR-SWAP-ALREADY-EXISTS (u103)   - Swap ID already exists
ERR-SWAP-NOT-FOUND (u104)        - Swap not found
ERR-SWAP-EXPIRED (u105)          - Swap has expired
ERR-INVALID-STATUS (u106)        - Invalid operation status
ERR-TRANSFER-FAILED (u107)       - Transfer operation failed
ERR-ORACLE-NOT-AUTHORIZED (u108) - Oracle not authorized
ERR-INVALID-BITCOIN-TX (u109)    - Invalid Bitcoin transaction
ERR-WITHDRAWAL-NOT-FOUND (u110)  - Withdrawal request not found
ERR-INSUFFICIENT-COLLATERAL (u111) - Not enough collateral
ERR-ORACLE-PRICE-STALE (u112)    - Oracle price too old
ERR-SLIPPAGE-EXCEEDED (u113)     - Slippage tolerance exceeded
ERR-POOL-NOT-FOUND (u114)        - Liquidity pool not found
ERR-EMERGENCY-PAUSED (u115)      - Contract is paused
```

## 📚 Core Functions

### Bitcoin Operations
```clarity
;; Wrap Bitcoin into sBTC
(initiate-bitcoin-wrap (tx-hash (buff 32)) (amount uint) (user principal))

;; Confirm Bitcoin deposit
(confirm-bitcoin-wrap (tx-hash (buff 32)) (confirmations uint))

;; Request Bitcoin withdrawal
(initiate-bitcoin-withdrawal (sbtc-amount uint) (bitcoin-address (string-ascii 64)))

;; Process Bitcoin withdrawal
(process-bitcoin-withdrawal (withdrawal-id uint) (bitcoin-tx-hash (buff 32)))
```

### Atomic Swaps
```clarity
;; Create swap with slippage protection
(create-atomic-swap-with-slippage (stx-amount uint) (sbtc-amount uint) (slippage-tolerance uint))

;; Accept and execute swap
(accept-atomic-swap (swap-id uint))

;; Cancel pending swap
(cancel-atomic-swap (swap-id uint))
```

### Liquidity Pools
```clarity
;; Create new liquidity pool
(create-liquidity-pool (pool-name (string-ascii 20)) (stx-amount uint) (sbtc-amount uint))

;; Add liquidity to existing pool
(add-liquidity (pool-name (string-ascii 20)) (stx-amount uint) (sbtc-amount uint))
```

### Collateralized Positions
```clarity
;; Open collateralized position
(open-collateral-position (stx-collateral uint) (sbtc-to-mint uint))

;; Check liquidation price
(calculate-liquidation-price (user principal))
```

### Oracle Functions
```clarity
;; Update BTC/STX price
(update-btc-price (new-price uint))

;; Get current price info
(get-current-btc-price)
```

## 🔐 Security Features

### Multi-layer Security
- **Oracle Authorization**: Only authorized oracles can update prices and confirm transactions
- **Emergency Pause**: Contract owner can pause operations in emergencies
- **Slippage Protection**: Automatic protection against price manipulation
- **Collateral Requirements**: Over-collateralization prevents undercollateralized positions
- **Time Locks**: Built-in expiration for all time-sensitive operations

### Access Control
- **Contract Owner**: Administrative functions and emergency controls
- **Authorized Oracle**: Price updates and Bitcoin transaction confirmations
- **Users**: Standard trading and liquidity operations

## 🚦 Getting Started

### Prerequisites
- Stacks blockchain node or connection
- Clarity development environment
- Bitcoin testnet/mainnet access (for production)

### Deployment Steps

1. **Deploy Base Contract**
   ```bash
   clarinet deploy --network testnet
   ```

2. **Set Oracle**
   ```clarity
   (contract-call? .sbtc-enhancement set-oracle 'oracle-principal)
   ```

3. **Initialize First Pool**
   ```clarity
   (contract-call? .sbtc-enhancement create-liquidity-pool "STX-sBTC" u1000000 u100000000)
   ```

### Integration Examples

#### Wrap Bitcoin
```clarity
;; 1. User sends Bitcoin to bridge address
;; 2. Oracle detects deposit and initiates wrap
(contract-call? .sbtc-enhancement initiate-bitcoin-wrap 0x1234... u100000000 'user-principal)

;; 3. Oracle confirms sufficient confirmations
(contract-call? .sbtc-enhancement confirm-bitcoin-wrap 0x1234... u6)
```

#### Create Atomic Swap
```clarity
;; Create swap with 1% slippage tolerance
(contract-call? .sbtc-enhancement create-atomic-swap-with-slippage u1000000 u100000000 u100)
```

#### Add Liquidity
```clarity
;; Add liquidity to STX-sBTC pool
(contract-call? .sbtc-enhancement add-liquidity "STX-sBTC" u1000000 u100000000)
```

## 📊 Economics

### Fee Structure
- **Protocol Fee**: 0.3% on atomic swaps
- **Liquidity Pool Fees**: Configurable per pool
- **Withdrawal Fees**: Variable based on Bitcoin network conditions

### Collateralization
- **Minimum Ratio**: 125% (over-collateralized)
- **Liquidation Threshold**: 80%
- **Liquidation Penalty**: 5% (paid to liquidators)

## 🧪 Testing

### Unit Tests
```bash
clarinet test
```

### Integration Tests
```bash
clarinet test --coverage
```

### Test Scenarios
- Bitcoin deposit/withdrawal flows
- Atomic swap execution and cancellation
- Liquidity pool operations
- Collateral position management
- Oracle price updates
- Emergency pause functionality

## 🔮 Roadmap

### Phase 4 (Future)
- Cross-chain bridge integration
- Governance token (sBTC-DAO)
- Yield farming mechanisms
- Insurance fund
- Mobile SDK

### Phase 5 (Advanced)
- Layer 2 scaling solutions
- NFT collateralization
- Advanced derivatives
- Institutional features

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
```bash
git clone https://github.com/your-org/sbtc-enhancement
cd sbtc-enhancement
clarinet requirements
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This smart contract is provided as-is for educational and development purposes. Please conduct thorough testing and security audits before deploying to mainnet. The developers are not responsible for any loss of funds.
