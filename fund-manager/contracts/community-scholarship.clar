;; Community Scholarship Fund Smart Contract
;; Handles scholarship applications, funding, and disbursement

;; Constants
(define-constant CONTRACT_ADMINISTRATOR tx-sender)
(define-constant ERROR_UNAUTHORIZED_ACCESS (err u1))
(define-constant ERROR_APPLICATION_EXISTS (err u2))
(define-constant ERROR_DONATION_BELOW_MINIMUM (err u3))
(define-constant ERROR_INSUFFICIENT_BALANCE (err u4))
(define-constant ERROR_RECIPIENT_NOT_ELIGIBLE (err u5))
(define-constant ERROR_APPLICATION_PERIOD_CLOSED (err u6))
(define-constant MINIMUM_DONATION_AMOUNT u1000000) ;; in microSTX (1 STX)

;; Data Variables
(define-data-var scholarship-pool-balance uint u0)
(define-data-var application-submission-deadline uint u0)
(define-data-var scholarship-disbursement-period uint u0)

;; Data Maps
(define-map DonorRegistry 
    principal 
    {
        cumulative-donation-amount: uint,
        most-recent-donation-block: uint
    }
)

(define-map ScholarshipRecipients
    principal
    {
        recipient-status: (string-ascii 20),
        scholarship-amount: uint,
        academic-performance: uint,
        field-of-study: (string-ascii 50),
        academic-year: uint
    }
)

(define-map ScholarshipApplications
    principal
    {
        applicant-full-name: (string-ascii 50),
        academic-performance: uint,
        field-of-study: (string-ascii 50),
        academic-year: uint,
        requested-scholarship-amount: uint,
        application-status: (string-ascii 20)
    }
)

;; Private Functions
(define-private (is-administrator)
    (is-eq tx-sender CONTRACT_ADMINISTRATOR)
)

(define-private (validate-donation-amount (donation-amount uint))
    (>= donation-amount MINIMUM_DONATION_AMOUNT)
)

(define-private (update-donor-records (donor-address principal) (donation-amount uint))
    (let (
        (current-donor-info (default-to 
            { cumulative-donation-amount: u0, most-recent-donation-block: u0 } 
            (map-get? DonorRegistry donor-address)
        ))
    )
    (map-set DonorRegistry
        donor-address
        {
            cumulative-donation-amount: (+ (get cumulative-donation-amount current-donor-info) donation-amount),
            most-recent-donation-block: block-height
        }
    )
    )
)

;; Public Functions
(define-public (contribute-to-scholarship-fund)
    (let (
        (donation-amount (stx-get-balance tx-sender))
    )
    (if (validate-donation-amount donation-amount)
        (begin
            (try! (stx-transfer? donation-amount tx-sender (as-contract tx-sender)))
            (var-set scholarship-pool-balance (+ (var-get scholarship-pool-balance) donation-amount))
            (update-donor-records tx-sender donation-amount)
            (ok donation-amount)
        )
        ERROR_DONATION_BELOW_MINIMUM
    ))
)

(define-public (submit-scholarship-application 
    (applicant-name (string-ascii 50))
    (grade-point-average uint)
    (selected-major (string-ascii 50))
    (current-year uint)
    (requested-amount uint)
)
    (let (
        (existing-application (map-get? ScholarshipApplications tx-sender))
    )
    (if (is-some existing-application)
        ERROR_APPLICATION_EXISTS
        (if (> block-height (var-get application-submission-deadline))
            ERROR_APPLICATION_PERIOD_CLOSED
            (begin
                (map-set ScholarshipApplications
                    tx-sender
                    {
                        applicant-full-name: applicant-name,
                        academic-performance: grade-point-average,
                        field-of-study: selected-major,
                        academic-year: current-year,
                        requested-scholarship-amount: requested-amount,
                        application-status: "PENDING"
                    }
                )
                (ok true)
            )
        ))
    )
)

(define-public (evaluate-scholarship-application (applicant-address principal) (is-approved bool))
    (begin
        (asserts! (is-administrator) ERROR_UNAUTHORIZED_ACCESS)
        (match (map-get? ScholarshipApplications applicant-address)
            current-application
            (begin
                (map-set ScholarshipApplications
                    applicant-address
                    (merge current-application
                        {application-status: (if is-approved "APPROVED" "REJECTED")}
                    )
                )
                (if is-approved
                    (map-set ScholarshipRecipients
                        applicant-address
                        {
                            recipient-status: "ACTIVE",
                            scholarship-amount: (get requested-scholarship-amount current-application),
                            academic-performance: (get academic-performance current-application),
                            field-of-study: (get field-of-study current-application),
                            academic-year: (get academic-year current-application)
                        }
                    )
                    true
                )
                (ok true)
            )
            (err u404)
        )
    )
)

(define-public (process-scholarship-payment (recipient-address principal))
    (let (
        (recipient-details (map-get? ScholarshipRecipients recipient-address))
    )
    (match recipient-details
        recipient-info
        (if (and
                (is-administrator)
                (is-eq (get recipient-status recipient-info) "ACTIVE")
                (>= (var-get scholarship-pool-balance) (get scholarship-amount recipient-info))
            )
            (begin
                (try! (as-contract (stx-transfer? 
                    (get scholarship-amount recipient-info)
                    (as-contract tx-sender)
                    recipient-address
                )))
                (var-set scholarship-pool-balance (- (var-get scholarship-pool-balance) (get scholarship-amount recipient-info)))
                (map-set ScholarshipRecipients
                    recipient-address
                    (merge recipient-info {recipient-status: "PAID"})
                )
                (ok true)
            )
            ERROR_INSUFFICIENT_BALANCE
        )
        ERROR_RECIPIENT_NOT_ELIGIBLE
    ))
)

;; Read-Only Functions
(define-read-only (get-scholarship-fund-balance)
    (ok (var-get scholarship-pool-balance))
)

(define-read-only (get-donor-details (donor-address principal))
    (ok (map-get? DonorRegistry donor-address))
)

(define-read-only (get-application-details (applicant-address principal))
    (ok (map-get? ScholarshipApplications applicant-address))
)

(define-read-only (get-recipient-details (recipient-address principal))
    (ok (map-get? ScholarshipRecipients recipient-address))
)

;; Administrative Functions
(define-public (update-application-deadline (new-deadline-block uint))
    (begin
        (asserts! (is-administrator) ERROR_UNAUTHORIZED_ACCESS)
        (var-set application-submission-deadline new-deadline-block)
        (ok true)
    )
)

(define-public (update-disbursement-period (new-disbursement-block uint))
    (begin
        (asserts! (is-administrator) ERROR_UNAUTHORIZED_ACCESS)
        (var-set scholarship-disbursement-period new-disbursement-block)
        (ok true)
    )
)