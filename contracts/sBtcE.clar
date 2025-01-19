;; sBTC Enhancement Smart Contract - Initial Implementation
;; Version: 1.0.0

;; Error Codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-AMOUNT (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var minimum-wrap-amount uint u100000) ;; in sats
(define-data-var wrapped-bitcoin-total uint u0)

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

;; Read-Only Functions
(define-read-only (get-user-balance (user principal))
    (default-to u0 (map-get? user-balances user))
)

(define-read-only (get-pending-wrap (tx-hash (buff 32)))
    (map-get? pending-wraps {tx-hash: tx-hash})
)

(define-read-only (get-minimum-wrap-amount)
    (var-get minimum-wrap-amount)
)

;; Public Functions
(define-public (initialize-wrap (btc-tx-hash (buff 32)) (amount uint))
    (let
        (
            (caller tx-sender)
            (current-height block-height)
        )
        (asserts! (>= amount (var-get minimum-wrap-amount)) ERR-INVALID-AMOUNT)
        (map-set pending-wraps
            {tx-hash: btc-tx-hash}
            {
                user: caller,
                amount: amount,
                initiated-at: current-height
            }
        )
        (ok true)
    )
)

(define-public (complete-wrap (btc-tx-hash (buff 32)))
    (let
        (
            (wrap-info (unwrap! (get-pending-wrap btc-tx-hash) ERR-INVALID-AMOUNT))
            (user (get user wrap-info))
            (amount (get amount wrap-info))
        )
        ;; Update user balance
        (map-set user-balances
            user
            (+ (get-user-balance user) amount)
        )
        ;; Update total wrapped amount
        (var-set wrapped-bitcoin-total 
            (+ (var-get wrapped-bitcoin-total) amount)
        )
        (ok true)
    )
)

(define-public (initiate-unwrap (amount uint))
    (let
        (
            (user-balance (get-user-balance tx-sender))
        )
        (asserts! (>= user-balance amount) ERR-INSUFFICIENT-BALANCE)
        ;; Deduct from user balance
        (map-set user-balances
            tx-sender
            (- user-balance amount)
        )
        ;; Update total wrapped amount
        (var-set wrapped-bitcoin-total 
            (- (var-get wrapped-bitcoin-total) amount)
        )
        (ok true)
    )
)

;; Administrative Functions
(define-public (set-minimum-wrap-amount (new-amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set minimum-wrap-amount new-amount)
        (ok true)
    )
)