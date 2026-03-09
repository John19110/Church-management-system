# Sunday School Management System 

Backend system built with **ASP.NET Core Web API** for managing Sunday schools in churches.

This project is part of my backend engineering portfolio and demonstrates building a real-world system using layered architecture, authentication, authorization, and database management.

---

## 🚀 About The Project

Churches need an organized way to manage:

- Students
- Servants (teachers)
- Classes & stages
- Attendance
- User permissions

This API provides secure and scalable endpoints to handle those operations.

---

## 🧠 What This Project Demonstrates

✔ Building RESTful APIs  
✔ Layered Architecture (API → BLL → DAL)  
✔ Entity Framework Core  
✔ ASP.NET Identity  
✔ JWT Authentication  
✔ Role-based Authorization  
✔ DTOs & Separation of Concerns  
✔ Dependency Injection  
✔ LINQ & Async operations  
✔ Clean code practices  

---

## 🏗️ Architecture

API (Controllers)  
↓  
BLL (Managers / Services / Business Rules)  
↓  
DAL (DbContext / Entities)  
↓  
Database


Each layer has a single responsibility which makes the system:

- easier to test  
- easier to maintain  
- scalable for future features  

---

## 🧰 Tech Stack

- ASP.NET Core Web API  
- Entity Framework Core  
- SQL Server  
- ASP.NET Core Identity  
- JWT Bearer Tokens  
- Swagger / OpenAPI  

---

## ✨ Main Features

### Authentication
- Register user
- Login
- JWT token generation

### Authorization
- Role-based permissions (Admin / Servant)

### Management Modules
- Manage Students
- Manage Classes
- Assign students to classes
- Track Attendance

> More features are continuously being added as the project grows.

---

## 🔐 Security

The system uses:

- Password hashing via Identity  
- Signed JWT tokens  
- Protected endpoints via `[Authorize]`  
- Role checks  

---
