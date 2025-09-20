# plp-week8-ecommerce-db
Final Project – PLP Week 8: Database Management System (E-commerce Store Schema in MySQL)
# E-commerce Database Management System (MySQL)

## 📌 Objective
This project designs and implements a relational database schema for an **E-commerce Store** using **MySQL**.  
It demonstrates proper database normalization, constraints, and relationships.

## 🗂 Schema Features
- **Customers & Profiles** (One-to-One)
- **Orders & Order Items** (One-to-Many)
- **Products, Categories, Suppliers** (Many-to-Many relationships)
- **Inventory Management** (stock tracking, purchase orders, stock movements)
- **Payments & Coupons**
- **Product Reviews**

## 🔑 Constraints
- `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, `CHECK` constraints applied.
- Relationships:
  - One-to-One → Customers ↔ Profiles
  - One-to-Many → Customers → Orders, Orders → Order Items
  - Many-to-Many → Products ↔ Categories, Products ↔ Suppliers

## 🚀 How to Run
1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/ecommerce-database.git
   cd ecommerce-database
