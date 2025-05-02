;; Title: BitVault - Bitcoin-Backed Lending Protocol
;; Summary: A secure lending protocol built on Stacks Layer 2 that enables sBTC collateralized loans
;; Description: BitVault allows users to deposit sBTC as collateral, borrow against it, and
;; participate in liquidations while maintaining protocol safety through configurable parameters.
;; The protocol implements industry-standard safeguards including minimum collateralization ratios,
;; liquidation thresholds, and administrator controls for risk management.

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-ALREADY-INITIALIZED (err u104))
(define-constant ERR-NOT-INITIALIZED (err u105))
(define-constant ERR-LIQUIDATION-FAILED (err u106))

;; PROTOCOL PARAMETERS

(define-constant MIN-COLLATERAL-RATIO u150)         ;; 150% minimum collateralization ratio
(define-constant MAX-INTEREST-RATE u10000)          ;; 100% in basis points
(define-constant MIN-INTEREST-RATE u100)            ;; 1% in basis points
(define-constant MAX-LIQUIDATION-THRESHOLD u9500)   ;; 95% in basis points
(define-constant MIN-LIQUIDATION-THRESHOLD u7000)   ;; 70% in basis points
(define-constant MAX-REWARD-MULTIPLIER u120)        ;; 120% maximum reward multiplier

;; PROTOCOL STATE

(define-data-var contract-owner principal tx-sender)
(define-data-var protocol-paused bool false)
(define-data-var total-deposits uint u0)
(define-data-var total-borrows uint u0)
(define-data-var interest-rate uint u500)           ;; 5% APR in basis points
(define-data-var liquidation-threshold uint u8000)  ;; 80% threshold in basis points
(define-data-var allowed-token principal 'SP000000000000000000002Q6VF78.token)

;; STORAGE MAPS

(define-map user-deposits 
    { user: principal } 
    { amount: uint }
)

(define-map user-borrows 
    { user: principal } 
    { 
        amount: uint, 
        collateral: uint 
    }
)

(define-map liquidator-rewards 
    { liquidator: principal } 
    { amount: uint }
)

;; TRAITS

(define-trait sip-010-trait
    (
        (transfer (uint principal principal (optional (buff 34))) (response bool uint))
        (get-balance (principal) (response uint uint))
    )
)

;; AUTHORIZATION FUNCTIONS

(define-private (is-contract-owner)
    (is-eq tx-sender (var-get contract-owner))
)

;; Validate token contract
(define-private (is-valid-token (token-contract <sip-010-trait>))
    (is-eq (contract-of token-contract) (var-get allowed-token))
)

;; SAFE ARITHMETIC OPERATIONS

(define-private (safe-subtract (a uint) (b uint))
    (ok (if (>= a b) (- a b) u0))
)

(define-private (safe-add (a uint) (b uint))
    (let ((sum (+ a b)))
        (asserts! (>= sum a) (err u401))  ;; Check for overflow
        (ok sum)
    )
)

(define-private (safe-multiply (a uint) (b uint))
    (let ((product (* a b)))
        (asserts! (or (is-eq a u0) (is-eq (/ product a) b)) (err u402))  ;; Check for overflow
        (ok product)
    )
)

;; CORE PROTOCOL FUNCTIONS

;; Initialize the protocol with the specified token contract
(define-public (initialize (token-contract <sip-010-trait>))
    (begin
        (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
        (ok true)
    )
)

;; Deposit sBTC as collateral
(define-public (deposit-collateral (token-contract <sip-010-trait>) (amount uint))
    (let
        (
            (sender tx-sender)
            (current-deposit (default-to { amount: u0 } (map-get? user-deposits { user: sender })))
        )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (not (var-get protocol-paused)) ERR-NOT-INITIALIZED)
        (asserts! (is-valid-token token-contract) ERR-NOT-AUTHORIZED)
        
        (match (contract-call? token-contract transfer amount sender (as-contract tx-sender) none)
            success
                (begin
                    (map-set user-deposits
                        { user: sender }
                        { amount: (+ amount (get amount current-deposit)) }
                    )
                    (var-set total-deposits (+ (var-get total-deposits) amount))
                    (ok true)
                )
            error (err u101)
        )
    )
)

;; Borrow against deposited collateral
(define-public (borrow (token-contract <sip-010-trait>) (amount uint))
    (let
        (
            (sender tx-sender)
            (user-deposit (default-to { amount: u0 } (map-get? user-deposits { user: sender })))
            (user-borrow (default-to { amount: u0, collateral: u0 } (map-get? user-borrows { user: sender })))
            (collateral-value (get amount user-deposit))
            (borrow-value (+ amount (get amount user-borrow)))
        )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (not (var-get protocol-paused)) ERR-NOT-INITIALIZED)
        (asserts! (is-collateral-sufficient collateral-value borrow-value) ERR-INSUFFICIENT-COLLATERAL)
        
        (map-set user-borrows
            { user: sender }
            { amount: borrow-value, collateral: collateral-value }
        )
        (var-set total-borrows (+ (var-get total-borrows) amount))
        (ok true)
    )
)

;; Repay borrowed amount
(define-public (repay (token-contract <sip-010-trait>) (amount uint))
    (let
        (
            (sender tx-sender)
            (user-borrow (default-to { amount: u0, collateral: u0 } (map-get? user-borrows { user: sender })))
            (borrow-amount (get amount user-borrow))
        )
        (asserts! (>= borrow-amount amount) ERR-INVALID-AMOUNT)
        (asserts! (is-valid-token token-contract) ERR-NOT-AUTHORIZED)
        
        (match (contract-call? token-contract transfer amount sender (as-contract tx-sender) none)
            success
                (begin
                    (map-set user-borrows
                        { user: sender }
                        { amount: (- borrow-amount amount), collateral: (get collateral user-borrow) }
                    )
                    (var-set total-borrows (- (var-get total-borrows) amount))
                    (ok true)
                )
            error (err u101)
        )
    )
)