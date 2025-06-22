;; sBTC Compact Yield Farming Contract
;; Simplified version focusing on core functionality

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-FARM-NOT-FOUND (err u201))
(define-constant ERR-INSUFFICIENT-STAKE (err u202))
(define-constant ERR-INVALID-AMOUNT (err u203))

;; Constants
(define-constant REWARD-PRECISION u1000000000000)
(define-constant BASE-APY-RATE u8) ;; 8% base APY
(define-constant BLOCKS-PER-DAY u144)

;; Data Variables
(define-data-var total-farms uint u0)
(define-data-var contract-owner principal tx-sender)

;; Farm Data Structure
(define-map yield-farms
    uint ;; farm-id
    {
        name: (string-ascii 32),
        reward-rate: uint,
        total-staked: uint,
        last-reward-block: uint,
        active: bool
    }
)

;; User Positions
(define-map user-positions
    { farm-id: uint, user: principal }
    {
        staked-amount: uint,
        reward-debt: uint,
        entry-block: uint
    }
)

;; Read-Only Functions
(define-read-only (get-farm-info (farm-id uint))
    (map-get? yield-farms farm-id)
)

(define-read-only (get-user-position (farm-id uint) (user principal))
    (map-get? user-positions { farm-id: farm-id, user: user })
)

(define-read-only (calculate-rewards (farm-id uint) (user principal))
    (let
        (
            (farm (unwrap! (map-get? yield-farms farm-id) (err u0)))
            (position (unwrap! (map-get? user-positions { farm-id: farm-id, user: user }) (err u0)))
            (blocks-passed (- block-height (get last-reward-block farm)))
            (rewards-per-token (if (> (get total-staked farm) u0)
                (/ (* blocks-passed (get reward-rate farm) REWARD-PRECISION) (get total-staked farm))
                u0))
            (user-rewards (/ (* (get staked-amount position) rewards-per-token) REWARD-PRECISION))
        )
        (ok user-rewards)
    )
)

;; Create new yield farm (owner only)
(define-public (create-farm (name (string-ascii 32)) (reward-rate uint))
    (let ((farm-id (var-get total-farms)))
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (> reward-rate u0) ERR-INVALID-AMOUNT)
        
        (map-set yield-farms
            farm-id
            {
                name: name,
                reward-rate: reward-rate,
                total-staked: u0,
                last-reward-block: block-height,
                active: true
            }
        )
        
        (var-set total-farms (+ farm-id u1))
        (ok farm-id)
    )
)

;; Stake tokens in farm
(define-public (stake (farm-id uint) (amount uint))
    (let
        (
            (farm (unwrap! (map-get? yield-farms farm-id) ERR-FARM-NOT-FOUND))
            (current-position (default-to 
                { staked-amount: u0, reward-debt: u0, entry-block: u0 }
                (map-get? user-positions { farm-id: farm-id, user: tx-sender })))
        )
        (asserts! (get active farm) ERR-NOT-AUTHORIZED)
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        
        ;; Update user position
        (map-set user-positions
            { farm-id: farm-id, user: tx-sender }
            {
                staked-amount: (+ (get staked-amount current-position) amount),
                reward-debt: u0, ;; Simplified - would calculate actual debt
                entry-block: (if (is-eq (get entry-block current-position) u0) 
                    block-height (get entry-block current-position))
            }
        )
        
        ;; Update farm
        (map-set yield-farms
            farm-id
            (merge farm {
                total-staked: (+ (get total-staked farm) amount),
                last-reward-block: block-height
            })
        )
        
        (ok true)
    )
)

;; Unstake tokens from farm
(define-public (unstake (farm-id uint) (amount uint))
    (let
        (
            (farm (unwrap! (map-get? yield-farms farm-id) ERR-FARM-NOT-FOUND))
            (position (unwrap! (map-get? user-positions { farm-id: farm-id, user: tx-sender }) ERR-INSUFFICIENT-STAKE))
        )
        (asserts! (>= (get staked-amount position) amount) ERR-INSUFFICIENT-STAKE)
        
        ;; Update user position
        (map-set user-positions
            { farm-id: farm-id, user: tx-sender }
            (merge position {
                staked-amount: (- (get staked-amount position) amount)
            })
        )
        
        ;; Update farm
        (map-set yield-farms
            farm-id
            (merge farm {
                total-staked: (- (get total-staked farm) amount),
                last-reward-block: block-height
            })
        )
        
        (ok true)
    )
)

;; Claim rewards
(define-public (claim-rewards (farm-id uint))
    (let
        (
            (rewards (unwrap! (calculate-rewards farm-id tx-sender) ERR-FARM-NOT-FOUND))
        )
        (asserts! (> rewards u0) ERR-INVALID-AMOUNT)
        
        ;; Reset reward debt (simplified)
        (let
            (
                (position (unwrap! (map-get? user-positions { farm-id: farm-id, user: tx-sender }) ERR-INSUFFICIENT-STAKE))
            )
            (map-set user-positions
                { farm-id: farm-id, user: tx-sender }
                (merge position { reward-debt: u0 })
            )
        )
        
        ;; Transfer rewards to user (implement token transfer)
        (ok rewards)
    )
)

;; Toggle farm active status (owner only)
(define-public (toggle-farm (farm-id uint))
    (let
        (
            (farm (unwrap! (map-get? yield-farms farm-id) ERR-FARM-NOT-FOUND))
        )
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        
        (map-set yield-farms
            farm-id
            (merge farm { active: (not (get active farm)) })
        )
        
        (ok true)
    )
)