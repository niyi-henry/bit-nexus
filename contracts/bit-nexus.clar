;; Title: BitNexus Gaming Protocol
;;
;; Summary: A comprehensive Bitcoin Layer 2 gaming ecosystem built on Stacks 
;;          that enables true ownership of digital game assets through NFTs,
;;          player progression systems, and Bitcoin-backed reward mechanisms.
;;
;; Description: BitNexus revolutionizes blockchain gaming by creating an 
;;              interoperable metaverse where players can mint, trade, and 
;;              level up unique gaming assets across multiple game worlds. 
;;              The protocol features a sophisticated avatar system, 
;;              experience-based progression, competitive leaderboards, 
;;              and automated Bitcoin reward distribution. Built for the 
;;              Stacks ecosystem, BitNexus leverages Bitcoin's security 
;;              while providing fast, low-cost gaming transactions.
;;
;; Key Features:
;; - NFT-based gaming assets with rarity and power systems
;; - Cross-world avatar progression and achievements
;; - Competitive leaderboards with Bitcoin rewards
;; - Multi-world gaming ecosystem with entry requirements
;; - Decentralized asset trading and ownership
;; - Experience-based leveling system with validation

;; ERROR CONSTANTS

(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-GAME-ASSET (err u2))
(define-constant ERR-INSUFFICIENT-FUNDS (err u3))
(define-constant ERR-TRANSFER-FAILED (err u4))
(define-constant ERR-LEADERBOARD-FULL (err u5))
(define-constant ERR-ALREADY-REGISTERED (err u6))
(define-constant ERR-INVALID-REWARD (err u7))
(define-constant ERR-INVALID-INPUT (err u8))
(define-constant ERR-INVALID-SCORE (err u9))
(define-constant ERR-INVALID-FEE (err u10))
(define-constant ERR-INVALID-ENTRIES (err u11))
(define-constant ERR-PLAYER-NOT-FOUND (err u12))
(define-constant ERR-INVALID-AVATAR (err u13))
(define-constant ERR-WORLD-NOT-FOUND (err u14))
(define-constant ERR-INVALID-NAME (err u15))
(define-constant ERR-INVALID-DESCRIPTION (err u16))
(define-constant ERR-INVALID-RARITY (err u17))
(define-constant ERR-INVALID-POWER-LEVEL (err u18))
(define-constant ERR-INVALID-ATTRIBUTES (err u19))
(define-constant ERR-INVALID-WORLD-ACCESS (err u20))
(define-constant ERR-INVALID-OWNER (err u21))
(define-constant ERR-MAX-LEVEL-REACHED (err u22))
(define-constant ERR-MAX-EXPERIENCE-REACHED (err u23))
(define-constant ERR-INVALID-LEVEL-UP (err u24))

;; GAME MECHANICS CONSTANTS

(define-constant MAX-LEVEL u100)
(define-constant MAX-EXPERIENCE-PER-LEVEL u1000)
(define-constant BASE-EXPERIENCE-REQUIRED u100)

;; PROTOCOL CONFIGURATION

(define-data-var protocol-fee uint u10)
(define-data-var max-leaderboard-entries uint u50)
(define-data-var total-prize-pool uint u0)
(define-data-var total-assets uint u0)
(define-data-var total-avatars uint u0)
(define-data-var total-worlds uint u0)

;; ACCESS CONTROL

(define-map protocol-admin-whitelist
  principal
  bool
)

;; NFT DEFINITIONS

(define-non-fungible-token bitnexus-asset uint)
(define-non-fungible-token bitnexus-avatar uint)

;; DATA STRUCTURES

;; Gaming Asset Metadata
(define-map bitnexus-asset-metadata
  { token-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    rarity: (string-ascii 20),
    power-level: uint,
    world-id: uint,
    attributes: (list 10 (string-ascii 20)),
    experience: uint,
    level: uint,
  }
)

;; Avatar Metadata & Progression
(define-map avatar-metadata
  { avatar-id: uint }
  {
    name: (string-ascii 50),
    level: uint,
    experience: uint,
    achievements: (list 20 (string-ascii 50)),
    equipped-assets: (list 5 uint),
    world-access: (list 10 uint),
  }
)

;; Game World Configuration
(define-map game-worlds
  { world-id: uint }
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    entry-requirement: uint,
    active-players: uint,
    total-rewards: uint,
  }
)

;; Competitive Leaderboard
(define-map leaderboard
  { player: principal }
  {
    score: uint,
    games-played: uint,
    total-rewards: uint,
    avatar-id: uint,
    rank: uint,
    achievements: (list 20 (string-ascii 50)),
  }
)

;; VALIDATION FUNCTIONS

(define-private (is-valid-name (name (string-ascii 50)))
  (and
    (>= (len name) u1)
    (<= (len name) u50)
    (not (is-eq name ""))
  )
)

(define-private (is-valid-description (description (string-ascii 200)))
  (and
    (>= (len description) u1)
    (<= (len description) u200)
    (not (is-eq description ""))
  )
)

(define-private (is-valid-rarity (rarity (string-ascii 20)))
  (or
    (is-eq rarity "common")
    (is-eq rarity "uncommon")
    (is-eq rarity "rare")
    (is-eq rarity "epic")
    (is-eq rarity "legendary")
  )
)

(define-private (is-valid-power-level (power uint))
  (and (>= power u1) (<= power u1000))
)

(define-private (is-valid-attributes (attributes (list 10 (string-ascii 20))))
  (and
    (>= (len attributes) u1)
    (<= (len attributes) u10)
  )
)

(define-private (is-valid-world-access (worlds (list 10 uint)))
  (and
    (>= (len worlds) u1)
    (<= (len worlds) u10)
    (fold check-world-exists worlds true)
  )
)

(define-private (check-world-exists
    (world-id uint)
    (valid bool)
  )
  (and valid (is-some (get-world-details world-id)))
)

;; UTILITY FUNCTIONS

(define-read-only (is-protocol-admin (sender principal))
  (default-to false (map-get? protocol-admin-whitelist sender))
)

(define-read-only (is-valid-principal (input principal))
  (and
    (not (is-eq input tx-sender))
    (not (is-eq input (as-contract tx-sender)))
  )
)

(define-read-only (is-safe-principal (input principal))
  (and
    (is-valid-principal input)
    (or
      (is-protocol-admin input)
      (is-some (map-get? leaderboard { player: input }))
    )
  )
)