# Fix-Hub Database Schema
## Complete Firestore Collections & Relationships for ERD

---

## 📊 Overview

Fix-Hub uses **Firebase Cloud Firestore** as its database. Below is the complete schema for all collections with their fields, data types, and relationships.

---

## 🗃️ Collections (Tables)

### 1. `users` - User Accounts

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique user identifier (Firebase UID) |
| `email` | String | ✅ | User email address |
| `name` | String | ✅ | Full name |
| `phone` | String | ✅ | Phone number |
| `role` | Enum String | ✅ | `customer`, `technician`, `admin`, `cashier` |
| `profileImageUrl` | String | ❌ | Profile picture URL (Firebase Storage) |
| `isActive` | Boolean | ✅ | Account active status (default: true) |
| `preferences` | Map | ❌ | User preferences (JSON object) |
| `inviteCodeId` | String (FK) | ❌ | Reference to invite_codes document |
| `inviteCode` | String | ❌ | The actual invite code used |
| `createdAt` | Timestamp | ✅ | Account creation date |
| `updatedAt` | Timestamp | ✅ | Last update date |

**Relationships:**
- Has many → `cars` (via `userId`)
- Has many → `bookings` (via `userId`)
- Has many → `user_notifications` (via `userId`)
- Can have one → `invite_codes` (via `inviteCodeId`)

---

### 2. `cars` - Registered Vehicles

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique car identifier |
| `userId` | String (FK) | ✅ | Owner's user ID |
| `make` | String | ✅ | Car manufacturer (Toyota, Honda, etc.) |
| `model` | String | ✅ | Car model name |
| `year` | Integer | ✅ | Manufacturing year |
| `color` | String | ✅ | Car color |
| `licensePlate` | String | ✅ | License plate number |
| `type` | Enum String | ✅ | `sedan`, `suv`, `hatchback`, `coupe`, `convertible`, `truck`, `van` |
| `vin` | String | ❌ | Vehicle Identification Number |
| `engineType` | String | ❌ | Engine type description |
| `mileage` | Integer | ❌ | Current mileage |
| `images` | Array<String> | ❌ | List of image URLs |
| `createdAt` | Timestamp | ✅ | Record creation date |
| `updatedAt` | Timestamp | ✅ | Last update date |

**Relationships:**
- Belongs to → `users` (via `userId`)
- Has many → `bookings` (via `carId`)

---

### 3. `bookings` - Service Appointments

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique booking identifier |
| `userId` | String (FK) | ✅ | Customer's user ID |
| `carId` | String (FK) | ✅ | Vehicle ID |
| `serviceId` | String (FK) | ❌ | Service catalog item ID |
| `maintenanceType` | Enum String | ✅ | `regular`, `repair`, `inspection`, `emergency` |
| `scheduledDate` | Timestamp | ✅ | Appointment date |
| `timeSlot` | String | ✅ | Time slot (e.g., "09:00 AM - 10:00 AM") |
| `status` | Enum String | ✅ | `pending`, `confirmed`, `inProgress`, `completedPendingPayment`, `completed`, `cancelled` |
| `description` | String | ❌ | Customer's description of issue |
| `assignedTechnicians` | Array<String> | ❌ | List of technician user IDs |
| `notes` | String | ❌ | Internal notes |
| `createdAt` | Timestamp | ✅ | Booking creation date |
| `updatedAt` | Timestamp | ✅ | Last update date |
| `startedAt` | Timestamp | ❌ | When technician started work |
| `completedAt` | Timestamp | ❌ | When service was completed |
| **Service Details** |
| `serviceItems` | Array<Map> | ❌ | List of service items (embedded) |
| `laborCost` | Double | ❌ | Labor charges |
| `tax` | Double | ❌ | Tax amount |
| `totalCost` | Double | ❌ | Total cost (saved on payment) |
| `technicianNotes` | String | ❌ | Technician's notes |
| **Discount/Offer** |
| `offerCode` | String | ❌ | Applied offer code |
| `offerTitle` | String | ❌ | Offer title for display |
| `discountPercentage` | Integer | ❌ | Discount percentage (0-100) |
| **Rating** |
| `rating` | Double | ❌ | Customer rating (1.0 - 5.0) |
| `ratingComment` | String | ❌ | Rating comment |
| `ratedAt` | Timestamp | ❌ | When rating was submitted |
| **Payment** |
| `isPaid` | Boolean | ✅ | Payment status (default: false) |
| `paidAt` | Timestamp | ❌ | Payment timestamp |
| `cashierId` | String (FK) | ❌ | Cashier who processed payment |
| `paymentMethod` | Enum String | ❌ | `cash`, `card`, `digital` |

**Relationships:**
- Belongs to → `users` (via `userId` - customer)
- Belongs to → `cars` (via `carId`)
- Has many → `users` (via `assignedTechnicians` - technicians)
- Processed by → `users` (via `cashierId` - cashier)
- Can have → `refunds` (via `bookingId`)

**Embedded: `serviceItems[]`**
```
{
  id: String,
  name: String,
  type: "part" | "labor" | "service",
  price: Double,
  quantity: Integer,
  description: String?,
  category: String?
}
```

---

### 4. `services` - Service Catalog

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique service item identifier |
| `name` | String | ✅ | Service/part name |
| `type` | Enum String | ✅ | `part`, `labor`, `service` |
| `price` | Double | ✅ | Base price |
| `description` | String | ❌ | Service description |
| `category` | String | ❌ | Category (e.g., "Oil Change", "Brake Service") |
| `isActive` | Boolean | ✅ | Whether service is available (default: true) |

**Relationships:**
- Used by → `bookings` (via `serviceItems` embedded array)

---

### 5. `inventory` - Stock Items

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique inventory item ID |
| `serviceItemId` | String (FK) | ❌ | Linked service catalog item |
| `name` | String | ✅ | Item name |
| `sku` | String | ✅ | Stock Keeping Unit code |
| `category` | Enum String | ✅ | `parts`, `supplies`, `tools` |
| `currentStock` | Integer | ✅ | Current quantity in stock |
| `lowStockThreshold` | Integer | ✅ | Alert when stock falls below (default: 10) |
| `reorderPoint` | Integer | ✅ | Reorder trigger point (default: 15) |
| `unitCost` | Double | ✅ | Cost per unit (purchase price) |
| `unitPrice` | Double | ✅ | Selling price per unit |
| `location` | String | ❌ | Storage location |
| `supplier` | String | ❌ | Supplier name |
| `supplierContact` | String | ❌ | Supplier contact info |
| `lastRestocked` | Timestamp | ❌ | Last restock date |
| `isActive` | Boolean | ✅ | Item active status (default: true) |
| `createdAt` | Timestamp | ✅ | Record creation date |
| `updatedAt` | Timestamp | ✅ | Last update date |

**Relationships:**
- Has many → `inventory_transactions` (via `inventoryItemId`)
- Has many → `low_stock_alerts` (via `inventoryItemId`)
- Can link to → `services` (via `serviceItemId`)

---

### 6. `inventory_transactions` - Stock Movements

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique transaction ID |
| `inventoryItemId` | String (FK) | ✅ | Inventory item reference |
| `type` | Enum String | ✅ | `in` (restock), `out` (usage), `adjustment` |
| `quantity` | Integer | ✅ | Quantity changed |
| `quantityBefore` | Integer | ✅ | Stock level before transaction |
| `quantityAfter` | Integer | ✅ | Stock level after transaction |
| `bookingId` | String (FK) | ❌ | Related booking (for usage) |
| `technicianId` | String (FK) | ❌ | Technician who used item |
| `reason` | String | ❌ | Transaction reason |
| `notes` | String | ❌ | Additional notes |
| `createdAt` | Timestamp | ✅ | Transaction timestamp |
| `createdBy` | String (FK) | ✅ | User who made the transaction |

**Relationships:**
- Belongs to → `inventory` (via `inventoryItemId`)
- Can reference → `bookings` (via `bookingId`)
- Created by → `users` (via `createdBy`)

---

### 7. `low_stock_alerts` - Stock Alerts

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique alert ID |
| `inventoryItemId` | String (FK) | ✅ | Inventory item reference |
| `currentStock` | Integer | ✅ | Stock level when alert was created |
| `threshold` | Integer | ✅ | Low stock threshold |
| `isResolved` | Boolean | ✅ | Whether alert is resolved |
| `resolvedAt` | Timestamp | ❌ | When alert was resolved |
| `createdAt` | Timestamp | ✅ | Alert creation timestamp |

**Relationships:**
- Belongs to → `inventory` (via `inventoryItemId`)

---

### 8. `refunds` - Refund Requests

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique refund ID |
| `bookingId` | String (FK) | ✅ | Related booking |
| `originalAmount` | Double | ✅ | Original payment amount |
| `refundAmount` | Double | ✅ | Amount to be refunded |
| `reason` | String | ✅ | Refund reason |
| `customerNotes` | String | ❌ | Additional customer notes |
| `status` | Enum String | ✅ | `requested`, `approved`, `rejected`, `processed` |
| `requestedBy` | String (FK) | ✅ | Cashier who requested refund |
| `requestedAt` | Timestamp | ✅ | Request timestamp |
| `approvedBy` | String (FK) | ❌ | Admin who approved/rejected |
| `approvedAt` | Timestamp | ❌ | Approval timestamp |
| `processedAt` | Timestamp | ❌ | When refund was processed |
| `originalPaymentMethod` | String | ❌ | Original payment method |
| `refundMethod` | String | ❌ | How refund was given |

**Relationships:**
- Belongs to → `bookings` (via `bookingId`)
- Requested by → `users` (via `requestedBy` - cashier)
- Approved by → `users` (via `approvedBy` - admin)

---

### 9. `offers` - Promotional Offers

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique offer ID |
| `title` | String | ✅ | Offer title |
| `description` | String | ✅ | Offer description |
| `type` | Enum String | ✅ | `announcement`, `discount`, `promotion`, `news` |
| `imageUrl` | String | ❌ | Offer banner image URL |
| `startDate` | Timestamp | ✅ | Offer start date |
| `endDate` | Timestamp | ❌ | Offer end date |
| `isActive` | Boolean | ✅ | Whether offer is active |
| `createdBy` | String (FK) | ✅ | Admin who created the offer |
| `createdAt` | Timestamp | ✅ | Creation timestamp |
| `updatedAt` | Timestamp | ✅ | Last update timestamp |
| `discountPercentage` | Integer | ❌ | Discount percentage (0-100) |
| `code` | String | ❌ | Unique offer code |
| `terms` | String | ❌ | Terms and conditions |

**Relationships:**
- Created by → `users` (via `createdBy` - admin)
- Used by → `bookings` (via `offerCode`)

---

### 10. `invite_codes` - Registration Invite Codes

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique invite code document ID |
| `code` | String | ✅ | 8-character unique code |
| `role` | Enum String | ✅ | `technician`, `cashier`, `admin` |
| `maxUses` | Integer | ✅ | Maximum allowed uses |
| `usedCount` | Integer | ✅ | Current usage count |
| `isActive` | Boolean | ✅ | Whether code is active |
| `createdAt` | Timestamp | ✅ | Code creation timestamp |
| `createdBy` | String (FK) | ✅ | Admin who created the code |
| `usedBy` | Array<String> | ✅ | List of user IDs who used this code |

**Relationships:**
- Created by → `users` (via `createdBy` - admin)
- Used by → `users` (via `usedBy` array and `inviteCodeId`)

---

### 11. `user_notifications` - In-App Notifications

| Field | Data Type | Required | Description |
|-------|-----------|----------|-------------|
| `id` | String (Document ID) | ✅ | Unique notification ID |
| `userId` | String (FK) | ✅ | Recipient user ID |
| `type` | Enum String | ✅ | `push`, `inApp` |
| `category` | Enum String | ✅ | `booking`, `payment`, `reminder`, `system` |
| `title` | String | ✅ | Notification title |
| `message` | String | ✅ | Notification message body |
| `read` | Boolean | ✅ | Read status (default: false) |
| `sentAt` | Timestamp | ✅ | When notification was sent |
| `bookingId` | String (FK) | ❌ | Related booking |
| `carId` | String (FK) | ❌ | Related car |
| `metadata` | Map | ❌ | Additional metadata (JSON) |

**Relationships:**
- Belongs to → `users` (via `userId`)
- Can reference → `bookings` (via `bookingId`)
- Can reference → `cars` (via `carId`)

---

## 🔗 Entity Relationship Diagram (ERD) - Text Representation

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                      FIX-HUB DATABASE SCHEMA                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

    ┌───────────────┐         ┌───────────────┐         ┌───────────────┐
    │  invite_codes │◄────────│     users     │────────►│     cars      │
    │───────────────│  uses   │───────────────│  owns   │───────────────│
    │ code          │         │ id (PK)       │         │ id (PK)       │
    │ role          │         │ email         │         │ userId (FK)   │
    │ maxUses       │         │ name          │         │ make          │
    │ usedCount     │         │ phone         │         │ model         │
    │ usedBy[]      │         │ role          │         │ year          │
    │ isActive      │         │ isActive      │         │ type          │
    │ createdBy     │         │ inviteCodeId  │         │ licensePlate  │
    └───────────────┘         └───────┬───────┘         └───────┬───────┘
                                      │                         │
              ┌───────────────────────┼─────────────────────────┤
              │                       │                         │
              │                       │ creates                 │ has
              │                       ▼                         ▼
    ┌───────────────┐         ┌───────────────┐         ┌───────────────┐
    │    offers     │         │   bookings    │────────►│   refunds     │
    │───────────────│  uses   │───────────────│  has    │───────────────│
    │ id (PK)       │◄────────│ id (PK)       │         │ id (PK)       │
    │ title         │         │ userId (FK)   │         │ bookingId(FK) │
    │ code          │         │ carId (FK)    │         │ refundAmount  │
    │ discountPct   │         │ status        │         │ status        │
    │ createdBy(FK) │         │ serviceItems[]│         │ requestedBy   │
    │ isActive      │         │ isPaid        │         │ approvedBy    │
    │ startDate     │         │ cashierId(FK) │         │ processedAt   │
    └───────────────┘         │ assignedTech[]│         └───────────────┘
                              └───────┬───────┘
                                      │
              ┌───────────────────────┴─────────────────────────┐
              │                                                 │
              │ references                                      │ sends
              ▼                                                 ▼
    ┌───────────────┐         ┌───────────────┐         ┌─────────────────────┐
    │   services    │         │   inventory   │         │  user_notifications │
    │───────────────│         │───────────────│         │─────────────────────│
    │ id (PK)       │         │ id (PK)       │         │ id (PK)             │
    │ name          │         │ name          │         │ userId (FK)         │
    │ type          │         │ sku           │         │ bookingId (FK)      │
    │ price         │         │ category      │         │ title               │
    │ category      │         │ currentStock  │         │ message             │
    │ isActive      │         │ unitCost      │         │ read                │
    └───────────────┘         │ unitPrice     │         │ sentAt              │
                              └───────┬───────┘         └─────────────────────┘
                                      │
              ┌───────────────────────┴─────────────────────────┐
              │                                                 │
              │ has                                             │ triggers
              ▼                                                 ▼
    ┌───────────────────────┐                 ┌───────────────────────┐
    │ inventory_transactions│                 │   low_stock_alerts    │
    │───────────────────────│                 │───────────────────────│
    │ id (PK)               │                 │ id (PK)               │
    │ inventoryItemId (FK)  │                 │ inventoryItemId (FK)  │
    │ type (in/out/adjust)  │                 │ currentStock          │
    │ quantity              │                 │ threshold             │
    │ quantityBefore        │                 │ isResolved            │
    │ quantityAfter         │                 │ createdAt             │
    │ bookingId (FK)        │                 └───────────────────────┘
    │ createdBy (FK)        │
    └───────────────────────┘
```

---

## 🔑 Primary Keys (PK) & Foreign Keys (FK) Summary

| Collection | Primary Key | Foreign Keys |
|------------|-------------|--------------|
| `users` | `id` | `inviteCodeId` |
| `cars` | `id` | `userId` |
| `bookings` | `id` | `userId`, `carId`, `serviceId`, `cashierId`, `assignedTechnicians[]` |
| `services` | `id` | - |
| `inventory` | `id` | `serviceItemId` |
| `inventory_transactions` | `id` | `inventoryItemId`, `bookingId`, `technicianId`, `createdBy` |
| `low_stock_alerts` | `id` | `inventoryItemId` |
| `refunds` | `id` | `bookingId`, `requestedBy`, `approvedBy` |
| `offers` | `id` | `createdBy` |
| `invite_codes` | `id` | `createdBy`, `usedBy[]` |
| `user_notifications` | `id` | `userId`, `bookingId`, `carId` |

---

## 📋 Enums Reference

### UserRole
- `customer`
- `technician`
- `admin`
- `cashier`

### CarType
- `sedan`
- `suv`
- `hatchback`
- `coupe`
- `convertible`
- `truck`
- `van`

### MaintenanceType
- `regular`
- `repair`
- `inspection`
- `emergency`

### BookingStatus
- `pending`
- `confirmed`
- `inProgress`
- `completedPendingPayment`
- `completed`
- `cancelled`

### PaymentMethod
- `cash`
- `card`
- `digital`

### ServiceItemType
- `part`
- `labor`
- `service`

### InventoryCategory
- `parts`
- `supplies`
- `tools`

### RefundStatus
- `requested`
- `approved`
- `rejected`
- `processed`

### OfferType
- `announcement`
- `discount`
- `promotion`
- `news`

### NotificationType
- `push`
- `inApp`

### NotificationCategory
- `booking`
- `payment`
- `reminder`
- `system`

### InventoryTransactionType
- `in` (restock)
- `out` (usage)
- `adjustment`

---

## 📊 Cardinality Summary

| Relationship | Type |
|--------------|------|
| User → Cars | 1:N (One user can have many cars) |
| User → Bookings | 1:N (One user can have many bookings) |
| Car → Bookings | 1:N (One car can have many bookings) |
| Booking → Refunds | 1:1 (One booking can have one refund) |
| Booking → Technicians | N:M (Many bookings, many technicians via array) |
| User → Notifications | 1:N (One user receives many notifications) |
| Inventory → Transactions | 1:N (One item has many transactions) |
| Inventory → Alerts | 1:N (One item can have many alerts) |
| Offer → Bookings | 1:N (One offer used by many bookings) |
| InviteCode → Users | 1:N (One code used by many users) |

---

**Document Version:** 1.0  
**Last Updated:** December 2024
