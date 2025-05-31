;; Compact sBTC Atomic Swap Contract
;; Version: 2.1.0 - Simplified Implementation

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-SWAP-NOT-FOUND (err u104))
(define-constant ERR-SWAP-EXPIRED (err u105))
(define-constant ERR-INVALID-STATUS (err u106))

;; Constants
(define-constant SWAP-EXPIRATION-BLOCKS u144) ;; ~24 hours

;; Data Variables
(define-data-var swap-nonce uint u0)

;; Data Maps
(define-map user-balances principal uint)
(define-map atomic-swaps 
    uint  ;; swap-id
    {
        initiator: principal,
        stx-amount: uint,
        sbtc-amount: uint,
        timeout-height: uint,
        status: (string-ascii 10)
    }
)

;; Read-Only Functions
(define-read-only (get-balance (user principal))
    (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-swap (swap-id uint))
    (map-get? atomic-swaps swap-id)
)

;; Core Swap Functions
(define-public (create-swap (stx-amount uint) (sbtc-amount uint))
    (let ((swap-id (var-get swap-nonce)))
        (asserts! (> stx-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> sbtc-amount u0) ERR-INVALID-AMOUNT)
        
        (try! (stx-transfer? stx-amount tx-sender (as-contract tx-sender)))
        
        (map-set atomic-swaps swap-id
            {
                initiator: tx-sender,
                stx-amount: stx-amount,
                sbtc-amount: sbtc-amount,
                timeout-height: (+ block-height SWAP-EXPIRATION-BLOCKS),
                status: "pending"
            }
        )
        
        (var-set swap-nonce (+ swap-id u1))
        (ok swap-id)
    )
)

(define-public (accept-swap (swap-id uint))
    (let ((swap (unwrap! (map-get? atomic-swaps swap-id) ERR-SWAP-NOT-FOUND)))
        (asserts! (is-eq (get status swap) "pending") ERR-INVALID-STATUS)
        (asserts! (< block-height (get timeout-height swap)) ERR-SWAP-EXPIRED)
        (asserts! (>= (get-balance tx-sender) (get sbtc-amount swap)) ERR-INSUFFICIENT-BALANCE)
        
        ;; Transfer sBTC to initiator
        (try! (transfer-internal tx-sender (get initiator swap) (get sbtc-amount swap)))
        
        ;; Transfer STX to acceptor
        (try! (as-contract (stx-transfer? (get stx-amount swap) (as-contract tx-sender) tx-sender)))
        
        ;; Mark completed
        (map-set atomic-swaps swap-id (merge swap {status: "completed"}))
        (ok true)
    )
)

(define-public (cancel-swap (swap-id uint))
    (let ((swap (unwrap! (map-get? atomic-swaps swap-id) ERR-SWAP-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get initiator swap)) ERR-NOT-AUTHORIZED)
        (asserts! (is-eq (get status swap) "pending") ERR-INVALID-STATUS)
        
        (try! (as-contract (stx-transfer? (get stx-amount swap) (as-contract tx-sender) (get initiator swap))))
        (map-set atomic-swaps swap-id (merge swap {status: "cancelled"}))
        (ok true)
    )
)

;; Mint sBTC (simplified)
(define-public (mint (amount uint))
    (begin
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (map-set user-balances tx-sender (+ (get-balance tx-sender) amount))
        (ok true)
    )
)

;; Internal transfer helper
(define-private (transfer-internal (sender principal) (recipient principal) (amount uint))
    (let ((sender-balance (get-balance sender)))
        (asserts! (>= sender-balance amount) ERR-INSUFFICIENT-BALANCE)
        (map-set user-balances sender (- sender-balance amount))
        (map-set user-balances recipient (+ (get-balance recipient) amount))
        (ok true)
    )
)