;; ------------------------------------------------------------
;; AquaLedger.clar
;; AquaLedger - Water Usage Token Monitor (Aqua tokens reward system)
;; Version: 1.0
;; Author: (you)
;; ------------------------------------------------------------

;; Fungible token representing rewards for conserving water.
;; Initial supply 0; tokens are minted by this contract as rewards.
(define-fungible-token aqua-token u0)

;; Contract owner (set at deploy-time)
(define-data-var owner principal tx-sender)

;; Reward rate: how many AQUA tokens per saved liter (integer)
(define-data-var reward-rate uint u1)

;; Users map: user principal -> (registered bool, sector string, baseline uint)
(define-map users
  { user: principal }
  { registered: bool, sector: (string-ascii 20), baseline: uint }
)

;; Oracles map: oracle principal -> allowed bool
(define-map allowed-oracles { oracle: principal } { allowed: bool })

;; Usage records: keyed by (user, period)
;; - period is an arbitrary uint identifier representing a day/week/month (e.g., YYYYMMDD)
;; - value: liters consumed, reporter (oracle who recorded), block-height timestamp
(define-map usage-records
  { user: principal, period: uint }
  { liters: uint, reporter: principal, timestamp: uint }
)

;; Events
;; Events (Clarity does not support custom event definitions; use 'print' for event logging in functions)

;; ----------------------------
;;  MODIFIERS / HELPERS
;; ----------------------------
(define-private (is-owner (sender principal))
  (is-eq (var-get owner) sender)
)

(define-private (is-oracle (sender principal))
  (default-to false (get allowed (map-get? allowed-oracles { oracle: sender })))
)

;; safe-get-user baseline (returns (ok baseline) or (err "NOT_REGISTERED"))
(define-read-only (get-user-baseline (u principal))
  (match (map-get? users { user: u })
    user-data (ok (get baseline user-data))
    (err "NOT_REGISTERED")
  )
)

;; ----------------------------
;;  OWNER / ADMIN FUNCTIONS
;; ----------------------------

;; Add or remove oracle
(define-public (set-oracle (oracle principal) (allow bool))
  (begin
    (asserts! (is-owner tx-sender) (err "UNAUTHORIZED"))
  (map-set allowed-oracles { oracle: tx-sender } { allowed: allow })
  (print { oracle: oracle, allowed: allow })
    (ok allow)
  )
)

;; Update reward-rate (tokens per saved liter)
(define-public (set-reward-rate (new-rate uint))
  (begin
    (asserts! (is-owner tx-sender) (err "UNAUTHORIZED"))
  (asserts! (var-set reward-rate new-rate) (err "REWARD_RATE_SET_FAILED"))
    (ok new-rate)
  )
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-owner tx-sender) (err "UNAUTHORIZED"))
  (asserts! (var-set owner new-owner) (err "OWNER_SET_FAILED"))
    (ok new-owner)
  )
)

;; ----------------------------
;;  USER FUNCTIONS
;; ----------------------------

;; Register user (optional baseline; owner or user can call)
(define-public (register-user (sector (string-ascii 20)) (baseline uint))
  (let ((u tx-sender))
    (begin
  (asserts! (>= baseline u0) (err "INVALID_BASELINE"))
  (map-set users { user: tx-sender } { registered: true, sector: sector, baseline: baseline })
  (print { user: u, sector: sector, baseline: baseline })
      (ok u)
    )
  )
)

;; Query user info
(define-read-only (get-user (u principal))
  (map-get? users { user: u })
)

;; ----------------------------
;;  ORACLE / RECORDING FUNCTIONS
;; ----------------------------

;; Oracles record usage for a user and period.
;; If the usage is <= baseline, user earns reward tokens:
;; reward = (baseline - liters) * reward-rate
(define-public (record-usage (user principal) (period uint) (liters uint))
  (begin
    ;; only allowed oracles may call
    (asserts! (is-oracle tx-sender) (err "NOT_AN_ORACLE"))

    ;; user must be registered
    (match (map-get? users { user: user })
      user-data
      (let (
             (baseline (get baseline user-data))
             (current (map-get? usage-records { user: user, period: period }))
           )
        ;; prevent duplicate recording for same user & period
        (asserts! (is-none current) (err "USAGE_ALREADY_RECORDED"))

  ;; store the usage record
  (asserts! (>= period u0) (err "INVALID_PERIOD"))
  (asserts! (>= liters u0) (err "INVALID_LITERS"))
  (map-set usage-records { user: tx-sender, period: period }
     { liters: liters, reporter: tx-sender, timestamp: u0 })

        ;; compute reward if under baseline
        (let ((reward (if (<= liters baseline) (* (- baseline liters) (var-get reward-rate)) u0)))
          (begin
            (if (> reward u0)
              (begin
                (unwrap-panic (ft-mint? aqua-token reward tx-sender))
                (print { user: tx-sender, period: period, liters: liters, reporter: tx-sender, reward: reward })
              )
              (print { user: tx-sender, period: period, liters: liters, reporter: tx-sender, reward: reward })
            )
            (ok reward)
          )
        )
      )
      (err "USER_NOT_REGISTERED")
    )
  )
)

;; Get usage for a user and period
(define-read-only (get-usage (user principal) (period uint))
  (map-get? usage-records { user: user, period: period })
)

;; ----------------------------
;;  TOKEN / REDEMPTION
;; ----------------------------

;; Users redeem AQUA tokens (burn). Off-chain systems listen to tokens-redeemed event to grant benefits.
(define-public (redeem-tokens (amount uint))
  (begin
    ;; burn tokens from sender (requires sender to have tokens)
    (try! (ft-burn? aqua-token amount tx-sender))
  (print { user: tx-sender, amount: amount })
    (ok amount)
  )
)

;; Get AQUA token balance
(define-read-only (get-aqua-balance (who principal))
  (ft-get-balance aqua-token who)
)

;; ----------------------------
;;  READ-ONLY ADMIN VIEWS
;; ----------------------------

(define-read-only (is-oracle-approved (who principal))
  (default-to false (get allowed (map-get? allowed-oracles { oracle: who })))
)

(define-read-only (get-reward-rate)
  (ok (var-get reward-rate))
)

(define-read-only (get-owner)
  (ok (var-get owner))
)
