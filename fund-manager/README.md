# Community Scholarship Fund Smart Contract

A decentralized scholarship management system built on Stacks blockchain using Clarity smart contracts. This contract enables transparent management of educational funds, scholarship applications, and automated disbursement.

## Overview

The Community Scholarship Fund smart contract provides a trustless platform for:
- Managing scholarship funds
- Processing student applications
- Evaluating candidates
- Disbursing funds transparently
- Tracking donor contributions

## Features

### Fund Management
- Secure donation collection
- Transparent fund tracking
- Minimum donation thresholds
- Real-time balance monitoring

### Application Processing
- Student application submission
- Academic credentials verification
- Application status tracking
- Automated eligibility checks

### Scholarship Administration
- Application review system
- Multi-stage approval process
- Automated disbursement
- Recipient status tracking

### Donor Management
- Donor registry
- Contribution history
- Donation analytics
- Transparent fund allocation

## Prerequisites

- Stacks blockchain environment
- Clarity CLI tools
- Node.js (for testing)
- Clarinet (recommended for local development)

### Key Functions

1. Administrative Functions
```clarity
(define-public (update-application-deadline (new-deadline-block uint)))
(define-public (update-disbursement-period (new-disbursement-block uint)))
```

2. Application Functions
```clarity
(define-public (submit-scholarship-application 
    (applicant-name (string-ascii 50))
    (grade-point-average uint)
    (selected-major (string-ascii 50))
    (current-year uint)
    (requested-amount uint)))
```

3. Fund Management
```clarity
(define-public (contribute-to-scholarship-fund))
(define-public (process-scholarship-payment (recipient-address principal)))
```

## Usage Guide

### For Administrators

1. Initialize Contract:
```clarity
;; Set application deadline
(contract-call? .scholarship-fund update-application-deadline u12345)

;; Set disbursement period
(contract-call? .scholarship-fund update-disbursement-period u12445)
```

2. Review Applications:
```clarity
;; Evaluate scholarship application
(contract-call? .scholarship-fund evaluate-scholarship-application 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 true)
```

### For Students

1. Submit Application:
```clarity
(contract-call? .scholarship-fund submit-scholarship-application 
    "John Doe"
    u385  ;; GPA (3.85)
    "Computer Science"
    u2    ;; Second year
    u5000000)  ;; 5 STX requested
```

### For Donors

1. Make Donation:
```clarity
(contract-call? .scholarship-fund contribute-to-scholarship-fund)
```

## Security Considerations

1. Access Control
- Only contract administrator can:
  - Review applications
  - Process payments
  - Update system parameters

2. Fund Safety
- Minimum donation requirements
- Balance checks before disbursement
- Secure fund storage

3. Data Integrity
- Application verification
- Status tracking
- Immutable records

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open Pull Request