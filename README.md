# sBTC Yield Farming Contract

A simplified Clarity smart contract for yield farming on the Stacks blockchain, designed for sBTC liquidity mining and rewards distribution.

## Overview

This contract allows users to stake sBTC tokens in farms and earn rewards over time. It provides essential yield farming functionality with gas-optimized operations.

### Key Features
- 🏭 **Multiple Farms**: Create and manage yield farming pools
- 💰 **Stake & Earn**: Deposit tokens to earn block-based rewards  
- 🎁 **Claim Rewards**: Withdraw accumulated earnings anytime
- ⚡ **Gas Efficient**: Minimal transaction costs
- 👑 **Owner Controls**: Administrative farm management

## Contract Structure

### Data Storage
```clarity
// Farm Information
{
    name: string,           // Farm identifier
    reward-rate: uint,      // Rewards per block per token
    total-staked: uint,     // Total staked in farm
    last-reward-block: uint,// Last reward calculation block
    active: bool           // Farm status
}

// User Positions  
{
    staked-amount: uint,    // User's staked tokens
    reward-debt: uint,      // Tracked reward debt
    entry-block: uint      // When user first staked
}
```

### Key Constants
- `REWARD-PRECISION`: 1000000000000 (12 decimal places)
- `BASE-APY-RATE`: 8% annual percentage yield
- `BLOCKS-PER-DAY`: 144 (Stacks network)

## Core Functions

### Read Functions
```clarity
;; Get farm details
(get-farm-info (farm-id uint)) -> (optional farm-data)

;; Get user position
(get-user-position (farm-id uint) (user principal)) -> (optional position-data)

;; Calculate pending rewards
(calculate-rewards (farm-id uint) (user principal)) -> (response uint uint)
```

### Write Functions
```clarity
;; Create new farm (owner only)
(create-farm (name string) (reward-rate uint)) -> (response uint uint)

;; Stake tokens in farm
(stake (farm-id uint) (amount uint)) -> (response bool uint)

;; Unstake tokens from farm  
(unstake (farm-id uint) (amount uint)) -> (response bool uint)

;; Claim accumulated rewards
(claim-rewards (farm-id uint)) -> (response uint uint)

;; Toggle farm status (owner only)
(toggle-farm (farm-id uint)) -> (response bool uint)
```

## How Rewards Work

### Calculation Formula
```
user_rewards = (staked_amount × blocks_passed × reward_rate) / total_staked
```

### Example
- Farm has 1000 sBTC total staked, 100 rewards per block
- User stakes 100 sBTC (10% of total)  
- After 144 blocks (1 day): 100 × 0.10 × 144 = 1,440 reward tokens

## Usage Examples

### Creating a Farm
```clarity
;; Owner creates farm with 50 rewards per block
(contract-call? .yield-farming create-farm "sBTC-STX Farm" u50)
```

### Staking Tokens
```clarity
;; Stake 1000 tokens in farm 0
(contract-call? .yield-farming stake u0 u1000)
```

### Checking Rewards
```clarity
;; View pending rewards
(contract-call? .yield-farming calculate-rewards u0 tx-sender)
```

### Claiming Rewards
```clarity
;; Claim all pending rewards
(contract-call? .yield-farming claim-rewards u0)
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u200 | `ERR-NOT-AUTHORIZED` | Insufficient permissions |
| u201 | `ERR-FARM-NOT-FOUND` | Invalid farm ID |
| u202 | `ERR-INSUFFICIENT-STAKE` | Not enough staked tokens |
| u203 | `ERR-INVALID-AMOUNT` | Invalid amount parameter |

## Deployment

### Prerequisites
- Clarinet CLI installed
- Stacks wallet with STX for gas
- Node.js 16+ for frontend integration

### Deploy Steps
```bash
# Initialize project
clarinet new sbtc-farming
cd sbtc-farming

# Add contract file
# Copy contract code to contracts/yield-farming.clar

# Test locally
clarinet test

# Deploy to testnet
clarinet deploy --testnet

# Deploy to mainnet  
clarinet deploy --mainnet
```

### Post-Deployment Setup
```clarity
;; Create your first farm
(contract-call? .yield-farming create-farm "Genesis Farm" u100)
```

## Integration Example

### Frontend Integration
```javascript
import { openContractCall } from '@stacks/connect';

// Stake tokens
const stakeTokens = async (farmId, amount) => {
  await openContractCall({
    contractAddress: 'YOUR_CONTRACT_ADDRESS',
    contractName: 'yield-farming',
    functionName: 'stake',
    functionArgs: [uintCV(farmId), uintCV(amount)],
  });
};

// Check rewards
const checkRewards = async (farmId, userAddress) => {
  const result = await callReadOnlyFunction({
    contractAddress: 'YOUR_CONTRACT_ADDRESS',
    contractName: 'yield-farming', 
    functionName: 'calculate-rewards',
    functionArgs: [uintCV(farmId), principalCV(userAddress)],
  });
  return result;
};
```

## Security Notes

### Access Control
- **Owner Functions**: Only contract deployer can create/toggle farms
- **User Functions**: Users can only manage their own positions
- **Input Validation**: All parameters validated before execution

### Known Limitations
- ⚠️ Token transfers must be implemented externally
- ⚠️ No built-in slashing or penalty mechanisms  
- ⚠️ Reward rates set manually by owner
- ⚠️ No automatic farm end dates

### Best Practices
- Start with small reward pools for testing
- Monitor farm performance regularly
- Implement proper token transfer logic
- Add emergency pause mechanisms for production

## Gas Costs

| Operation | Estimated Gas |
|-----------|---------------|
| Create Farm | ~1,500 |
| Stake | ~1,200 |
| Unstake | ~1,000 |
| Claim Rewards | ~800 |
| Check Rewards | ~200 |

## Support

- **Documentation**: [Clarity Language Docs](https://docs.stacks.co/clarity)
- **Community**: [Stacks Discord](https://discord.gg/stacks)
- **Issues**: Report bugs via GitHub issues


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This smart contract is provided as-is for educational and development purposes. Please conduct thorough testing and security audits before deploying to mainnet. The developers are not responsible for any loss of funds.
