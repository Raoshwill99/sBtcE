;; sBTC Enhancement Smart Contract - Phase 2
;; Version: 2.0.0 - Atomic Swap Implementation

;; Define SIP-010 Trait
(define-trait ft-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-balance (principal) (response uint uint))
        (get-total-supply () (response uint uint))
        (get-name () (response (string-ascii 32) uint))
        (get-symbol () (response (string-ascii 32) uint))
        (get-decimals () (response uint uint))
        (get-token-uri () (response (optional (string-utf8 256)) uint))
    )
)

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-SWAP-ALREADY-EXISTS (err u103))
(define-constant ERR-SWAP-NOT-FOUND (err u104))
(define-constant ERR-SWAP-EXPIRED (err u105))
(define-constant ERR-INVALID-STATUS (err u106))
(define-constant ERR-TRANSFER-FAILED (err u107))

;; Constants
(define-constant SWAP-EXPIRATION-BLOCKS u144) ;; ~24 hours in blocks
(define-constant STX-DECIMALS u6)
(define-constant SBTC-DECIMALS u8)

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var minimum-wrap-amount uint u100000) ;; in sats
(define-data-var wrapped-bitcoin-total uint u0)
(define-data-var swap-nonce uint u0)

;; Data Maps
(define-map user-balances principal uint)
(define-map pending-wraps 
    { tx-hash: (buff 32) }
    { 
        user: principal,
        amount: uint,
        initiated-at: uint
    }
)

;; Atomic Swap Data Structure
(define-map atomic-swaps 
    uint  ;; swap-id
    {
        initiator: principal,
        stx-amount: uint,
        sbtc-amount: uint,
        timeout-height: uint,
        status: (string-ascii 20),
        counterparty: (optional principal)
    }
)

;; Read-Only Functions
(define-read-only (get-user-balance (user principal))
    (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-pending-wrap (tx-hash (buff 32)))
    (map-get? pending-wraps {tx-hash: tx-hash})
)

(define-read-only (get-swap-details (swap-id uint))
    (map-get? atomic-swaps swap-id)
)

(define-read-only (calculate-stx-to-sbtc-rate (stx-amount uint))
    ;; Simple fixed rate calculation
    (/ (* stx-amount u100000000) u1000000)
)

;; Atomic Swap Functions
(define-public (create-atomic-swap (stx-amount uint) (sbtc-amount uint))
    (let
        (
            (swap-id (var-get swap-nonce))
            (timeout-height (+ block-height SWAP-EXPIRATION-BLOCKS))
        )
        ;; Verify amounts
        (asserts! (> stx-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> sbtc-amount u0) ERR-INVALID-AMOUNT)
        
        ;; Lock STX
        (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender)))
        
        ;; Create swap
        (map-set atomic-swaps
            swap-id
            {
                initiator: tx-sender,
                stx-amount: stx-amount,
                sbtc-amount: sbtc-amount,
                timeout-height: timeout-height,
                status: "pending",
                counterparty: none
            }
        )
        
        ;; Increment nonce
        (var-set swap-nonce (+ swap-id u1))
        
        (ok swap-id)
    )
)

(define-public (accept-atomic-swap (swap-id uint))
    (let
        (
            (swap (unwrap! (map-get? atomic-swaps swap-id) ERR-SWAP-NOT-FOUND))
            (status (get status swap))
            (sbtc-amount (get sbtc-amount swap))
            (initiator-principal (get initiator swap))
            (swap-stx-amount (get stx-amount swap))
        )
        ;; Verify swap is still valid
        (asserts! (is-eq status "pending") ERR-INVALID-STATUS)
        (asserts! (< block-height (get timeout-height swap)) ERR-SWAP-EXPIRED)
        
        ;; Verify sBTC balance
        (asserts! (>= (get-user-balance tx-sender) sbtc-amount) ERR-INSUFFICIENT-BALANCE)
        
        ;; Transfer sBTC to initiator
        (try! (transfer-sbtc tx-sender initiator-principal sbtc-amount))
        
        ;; Transfer STX to acceptor
        (try! (as-contract (stx-transfer? swap-stx-amount (as-contract tx-sender) tx-sender)))
        
        ;; Update swap status
        (map-set atomic-swaps
            swap-id
            (merge swap 
                {
                    status: "completed",
                    counterparty: (some tx-sender)
                }
            )
        )
        
        (ok true)
    )
)

(define-public (cancel-atomic-swap (swap-id uint))
    (let
        (
            (swap (unwrap! (map-get? atomic-swaps swap-id) ERR-SWAP-NOT-FOUND))
            (status (get status swap))
            (initiator-principal (get initiator swap))
            (swap-stx-amount (get stx-amount swap))
        )
        ;; Verify caller is initiator
        (asserts! (is-eq tx-sender initiator-principal) ERR-NOT-AUTHORIZED)
        ;; Verify swap is still pending
        (asserts! (is-eq status "pending") ERR-INVALID-STATUS)
        
        ;; Return STX to initiator
        (try! (as-contract (stx-transfer? swap-stx-amount (as-contract tx-sender) initiator-principal)))
        
        ;; Update swap status
        (map-set atomic-swaps
            swap-id
            (merge swap {status: "cancelled"})
        )
        
        (ok true)
    )
)

;; Helper Functions
(define-private (transfer-sbtc (sender principal) (recipient principal) (amount uint))
    (begin
        ;; Verify balance
        (asserts! (>= (get-user-balance sender) amount) ERR-INSUFFICIENT-BALANCE)
        
        ;; Deduct from sender
        (map-set user-balances
            sender
            (- (get-user-balance sender) amount)
        )
        ;; Add to recipient
        (map-set user-balances
            recipient
            (+ (get-user-balance recipient) amount)
        )
        (ok true)
    )
)