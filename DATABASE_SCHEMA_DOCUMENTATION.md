# CareerCloud Database Schema Documentation

## Overview
This document describes the database schema generated from the CareerCloud.Pocos entities. The schema is designed for a job/career management platform with support for applicants, companies, jobs, and security.

## Database Entities

### System Reference Tables

#### System_Country_Codes
Reference table for country codes used throughout the system.
- **Code** (PK): NVARCHAR(5) - ISO country code
- **Name**: NVARCHAR(50) - Country name

#### System_Language_Codes
Reference table for language codes used in descriptions.
- **LanguageID** (PK): NVARCHAR(10) - Language identifier
- **Name**: NVARCHAR(50) - Language name in English
- **Native_Name**: NVARCHAR(50) - Language name in native language

---

### Security Module

#### Security_Roles
Defines roles available in the system (Admin, Recruiter, Applicant, Company, etc.).
- **Id** (PK): UNIQUEIDENTIFIER - Role unique identifier
- **Role**: NVARCHAR(50) - Role name
- **Is_Inactive**: BIT - Status indicator

**Relationships:**
- 1:N with Security_Logins_Roles

#### Security_Logins
User accounts for platform login and authentication.
- **Id** (PK): UNIQUEIDENTIFIER - Login unique identifier
- **Login**: NVARCHAR(255) - Username/Login identifier
- **Password**: NVARCHAR(MAX) - Password hash
- **Created_Date**: DATETIME - Account creation date
- **Password_Update_Date**: DATETIME - Last password change date
- **Agreement_Accepted_Date**: DATETIME - Terms acceptance date
- **Is_Locked**: BIT - Account lock status
- **Is_Inactive**: BIT - Inactive status
- **Email_Address**: NVARCHAR(255) - Email address
- **Phone_Number**: NVARCHAR(20) - Phone number
- **Full_Name**: NVARCHAR(255) - Full name
- **Force_Change_Password**: BIT - Password change required flag
- **Prefferred_Language**: NVARCHAR(10) - User language preference
- **Time_Stamp**: ROWVERSION - Automatic timestamp for optimistic concurrency

**Relationships:**
- 1:N with Security_Logins_Roles
- 1:N with Applicant_Profiles
- 1:N with Security_Logins_Log

**Indexes:**
- IX_Security_Logins_Login (Login)
- IX_Security_Logins_Email (Email_Address)

#### Security_Logins_Roles
Junction table linking logins to roles (many-to-many relationship).
- **Id** (PK): UNIQUEIDENTIFIER - Record identifier
- **Login** (FK): UNIQUEIDENTIFIER - Reference to Security_Logins
- **Role** (FK): UNIQUEIDENTIFIER - Reference to Security_Roles
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Security_Logins
- FK to Security_Roles

**Indexes:**
- IX_Security_Logins_Roles_Login (Login)
- IX_Security_Logins_Roles_Role (Role)

#### Security_Logins_Log
Audit log for login attempts and authentication events.
- **Id** (PK): UNIQUEIDENTIFIER - Log entry identifier
- **Login** (FK): UNIQUEIDENTIFIER - Reference to Security_Logins
- **Source_IP**: NVARCHAR(50) - Source IP address
- **Logon_Date**: DATETIME - Login attempt timestamp
- **Is_Succesful**: BIT - Login success indicator

**Relationships:**
- FK to Security_Logins

**Indexes:**
- IX_Security_Logins_Log_Login (Login)
- IX_Security_Logins_Log_Logon_Date (Logon_Date)

---

### Company Module

#### Company_Profiles
Main company profile information.
- **Id** (PK): UNIQUEIDENTIFIER - Company unique identifier
- **Registration_Date**: DATETIME - Company registration date
- **Company_Website**: NVARCHAR(255) - Company website URL
- **Contact_Phone**: NVARCHAR(20) - Company contact phone
- **Contact_Name**: NVARCHAR(255) - Company contact person name
- **Company_Logo**: VARBINARY(MAX) - Company logo image (binary)
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- 1:N with Company_Descriptions
- 1:N with Company_Locations
- 1:N with Company_Jobs

**Indexes:**
- IX_Company_Profiles_Registration_Date (Registration_Date)

#### Company_Descriptions
Multilingual company descriptions.
- **Id** (PK): UNIQUEIDENTIFIER - Description unique identifier
- **Company** (FK): UNIQUEIDENTIFIER - Reference to Company_Profiles
- **LanguageId** (FK): NVARCHAR(10) - Reference to System_Language_Codes
- **Company_Name**: NVARCHAR(255) - Company name in specific language
- **Company_Description**: NVARCHAR(MAX) - Company description text
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Company_Profiles
- FK to System_Language_Codes

**Indexes:**
- IX_Company_Descriptions_Company (Company)
- IX_Company_Descriptions_Language (LanguageId)

#### Company_Locations
Physical locations of company offices/branches.
- **Id** (PK): UNIQUEIDENTIFIER - Location unique identifier
- **Company** (FK): UNIQUEIDENTIFIER - Reference to Company_Profiles
- **Country_Code** (FK): NVARCHAR(5) - Reference to System_Country_Codes
- **State_Province_Code**: NVARCHAR(10) - State/Province code
- **Street_Address**: NVARCHAR(255) - Street address
- **City_Town**: NVARCHAR(100) - City/Town name
- **Zip_Postal_Code**: NVARCHAR(20) - ZIP/Postal code
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Company_Profiles
- FK to System_Country_Codes

**Indexes:**
- IX_Company_Locations_Company (Company)
- IX_Company_Locations_Country (Country_Code)

#### Company_Jobs
Job postings created by companies.
- **Id** (PK): UNIQUEIDENTIFIER - Job unique identifier
- **Company** (FK): UNIQUEIDENTIFIER - Reference to Company_Profiles
- **Profile_Created**: DATETIME - Job posting creation date
- **Is_Inactive**: BIT - Job status (active/inactive)
- **Is_Company_Hidden**: BIT - Company visibility flag
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Company_Profiles
- 1:N with Applicant_Job_Applications
- 1:N with Company_Job_Educations
- 1:N with Company_Job_Skills
- 1:N with Company_Jobs_Descriptions

**Indexes:**
- IX_Company_Jobs_Company (Company)
- IX_Company_Jobs_Profile_Created (Profile_Created)
- IX_Company_Jobs_Is_Active (Is_Inactive)

#### Company_Jobs_Descriptions
Detailed job descriptions.
- **Id** (PK): UNIQUEIDENTIFIER - Description unique identifier
- **Job** (FK): UNIQUEIDENTIFIER - Reference to Company_Jobs
- **Job_Name**: NVARCHAR(255) - Job title/name
- **Job_Descriptions**: NVARCHAR(MAX) - Detailed job description
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Company_Jobs

**Indexes:**
- IX_Company_Jobs_Descriptions_Job (Job)

#### Company_Job_Skills
Required skills for job positions.
- **Id** (PK): UNIQUEIDENTIFIER - Skill requirement identifier
- **Job** (FK): UNIQUEIDENTIFIER - Reference to Company_Jobs
- **Skill**: NVARCHAR(100) - Skill name
- **Skill_Level**: NVARCHAR(50) - Required skill level (Beginner, Intermediate, Advanced, Expert)
- **Importance**: INT - Importance rating (0-100)
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Company_Jobs

**Indexes:**
- IX_Company_Job_Skills_Job (Job)
- IX_Company_Job_Skills_Skill (Skill)

#### Company_Job_Educations
Required education for job positions.
- **Id** (PK): UNIQUEIDENTIFIER - Education requirement identifier
- **Job** (FK): UNIQUEIDENTIFIER - Reference to Company_Jobs
- **Major**: NVARCHAR(100) - Required major/field of study
- **Importance**: SMALLINT - Importance rating
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Company_Jobs

**Indexes:**
- IX_Company_Job_Educations_Job (Job)

---

### Applicant Module

#### Applicant_Profiles
Applicant profile and personal information.
- **Id** (PK): UNIQUEIDENTIFIER - Applicant unique identifier
- **Login** (FK): UNIQUEIDENTIFIER - Reference to Security_Logins
- **Current_Salary**: DECIMAL(18,2) - Current salary amount
- **Current_Rate**: DECIMAL(18,2) - Current hourly/contract rate
- **Currency**: NVARCHAR(10) - Currency code (USD, CAD, etc.)
- **Country_Code** (FK): NVARCHAR(5) - Reference to System_Country_Codes
- **State_Province_Code**: NVARCHAR(10) - State/Province
- **Street_Address**: NVARCHAR(255) - Street address
- **City_Town**: NVARCHAR(100) - City/Town
- **Zip_Postal_Code**: NVARCHAR(20) - ZIP/Postal code
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Security_Logins
- FK to System_Country_Codes
- 1:N with Applicant_Work_History
- 1:N with Applicant_Educations
- 1:N with Applicant_Job_Applications
- 1:N with Applicant_Resumes
- 1:N with Applicant_Skills

**Indexes:**
- IX_Applicant_Profiles_Login (Login)
- IX_Applicant_Profiles_Country (Country_Code)

#### Applicant_Work_History
Job positions held by applicants.
- **Id** (PK): UNIQUEIDENTIFIER - Work history entry identifier
- **Applicant** (FK): UNIQUEIDENTIFIER - Reference to Applicant_Profiles
- **Company_Name**: NVARCHAR(255) - Company name
- **Country_Code** (FK): NVARCHAR(5) - Reference to System_Country_Codes
- **Location**: NVARCHAR(255) - Work location
- **Job_Title**: NVARCHAR(100) - Job title
- **Job_Description**: NVARCHAR(MAX) - Job responsibilities
- **Start_Month**: SMALLINT - Employment start month (1-12)
- **Start_Year**: INT - Employment start year
- **End_Month**: SMALLINT - Employment end month (1-12)
- **End_Year**: INT - Employment end year
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Applicant_Profiles
- FK to System_Country_Codes

**Indexes:**
- IX_Applicant_Work_History_Applicant (Applicant)
- IX_Applicant_Work_History_Country (Country_Code)

#### Applicant_Educations
Educational background of applicants.
- **Id** (PK): UNIQUEIDENTIFIER - Education entry identifier
- **Applicant** (FK): UNIQUEIDENTIFIER - Reference to Applicant_Profiles
- **Major**: NVARCHAR(100) - Field of study/Major
- **Certificate_Diploma**: NVARCHAR(100) - Certificate/Diploma name
- **Start_Date**: DATETIME - Education start date
- **Completion_Date**: DATETIME - Education completion date
- **Completion_Percent**: TINYINT - Completion percentage (0-100)
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Applicant_Profiles

**Indexes:**
- IX_Applicant_Educations_Applicant (Applicant)

#### Applicant_Skills
Skills listed by applicants.
- **Id** (PK): UNIQUEIDENTIFIER - Skill entry identifier
- **Applicant** (FK): UNIQUEIDENTIFIER - Reference to Applicant_Profiles
- **Skill**: NVARCHAR(100) - Skill name
- **Skill_Level**: NVARCHAR(50) - Proficiency level (Beginner, Intermediate, Advanced, Expert)
- **Start_Month**: TINYINT - Skill start month (1-12)
- **Start_Year**: INT - Skill start year
- **End_Month**: TINYINT - Skill end month (1-12)
- **End_Year**: INT - Skill end year
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Applicant_Profiles

**Indexes:**
- IX_Applicant_Skills_Applicant (Applicant)
- IX_Applicant_Skills_Skill (Skill)

#### Applicant_Resumes
Resume documents uploaded by applicants.
- **Id** (PK): UNIQUEIDENTIFIER - Resume entry identifier
- **Applicant** (FK): UNIQUEIDENTIFIER - Reference to Applicant_Profiles
- **Resume**: NVARCHAR(MAX) - Resume content (text/formatted)
- **Last_Updated**: DATETIME - Last modification date

**Relationships:**
- FK to Applicant_Profiles

**Indexes:**
- IX_Applicant_Resumes_Applicant (Applicant)

#### Applicant_Job_Applications
Job applications submitted by applicants.
- **Id** (PK): UNIQUEIDENTIFIER - Application entry identifier
- **Applicant** (FK): UNIQUEIDENTIFIER - Reference to Applicant_Profiles
- **Job** (FK): UNIQUEIDENTIFIER - Reference to Company_Jobs
- **Application_Date**: DATETIME - Application submission date
- **Time_Stamp**: ROWVERSION - Automatic timestamp

**Relationships:**
- FK to Applicant_Profiles
- FK to Company_Jobs

**Indexes:**
- IX_Applicant_Job_Applications_Applicant (Applicant)
- IX_Applicant_Job_Applications_Job (Job)
- IX_Applicant_Job_Applications_Date (Application_Date)

---

## Data Types Mapping

| C# Type | SQL Type | Notes |
|---------|----------|-------|
| Guid | UNIQUEIDENTIFIER | Used for all primary and foreign keys |
| string? | NVARCHAR(N) | Length varies based on context |
| string? (large text) | NVARCHAR(MAX) | Used for descriptions, job details, resume content |
| decimal? | DECIMAL(18,2) | Used for salary and rate fields |
| DateTime | DATETIME | Standard timestamp columns |
| DateTime? | DATETIME | Optional timestamp columns |
| bool | BIT | Boolean flags (0=false, 1=true) |
| byte? | TINYINT | Completion percentage, month fields |
| short | SMALLINT | Month and year fields |
| int | INT | Year and importance fields |
| byte[]? | VARBINARY(MAX) | Company logo image |
| byte[]? (RowVersion) | ROWVERSION | Automatic timestamp for concurrency control |

---

## Key Features

### 1. **Primary Keys**
- All entities use UNIQUEIDENTIFIER (Guid) as primary key
- Ensures distributed/scalable architecture capability

### 2. **Foreign Keys**
- implement referential integrity constraints
- Prevent orphan records
- Support cascading operations (defined by application logic)

### 3. **Indexes**
- Clustered indexes on primary keys (automatic)
- Non-clustered indexes on foreign keys for join performance
- Additional indexes on commonly searched fields (login, email, application date)

### 4. **Timestamps (ROWVERSION)**
- Automatic timestamp columns using SQL Server's ROWVERSION type
- Supports optimistic concurrency control in Entity Framework
- Updated automatically by SQL Server on each row modification

### 5. **Nullable Fields**
- Most string and date fields are nullable (NULL allowed)
- Required fields are NOT NULL
- Check C# POCO definitions for exact nullability

---

## Usage Instructions

### 1. **Create Database Schema**
```sql
-- Run the entire script:
-- \path\to\CareerCloud_Database_Script.sql
```

### 2. **Drop Existing Schema (if needed)**
Uncomment the DROP TABLE statements at the top of the SQL script if you want to remove existing tables.

### 3. **Populate Reference Data**
Uncomment the sample INSERT statements at the bottom of the script to populate:
- System_Country_Codes
- System_Language_Codes
- Security_Roles

### 4. **Connection String Example**
```csharp
Server=YOUR_SERVER;Database=CareerCloud;User Id=sa;Password=YourPassword;Trusted_Connection=false;
```

---

## Entity Relationship Diagram (Text Format)

```
Security_Logins (1) -------- (N) Security_Logins_Roles
    |
    +---------- (1) -------- (N) Applicant_Profiles
    |
    +---------- (1) -------- (N) Security_Logins_Log

Applicant_Profiles (1) -------- (N) Applicant_Work_History
    |
    +---------- (1) -------- (N) Applicant_Educations
    |
    +---------- (1) -------- (N) Applicant_Skills
    |
    +---------- (1) -------- (N) Applicant_Resumes
    |
    +---------- (1) -------- (N) Applicant_Job_Applications

Company_Profiles (1) -------- (N) Company_Descriptions
    |
    +---------- (1) -------- (N) Company_Locations
    |
    +---------- (1) -------- (N) Company_Jobs

Company_Jobs (1) -------- (N) Company_Jobs_Descriptions
    |
    +---------- (1) -------- (N) Company_Job_Skills
    |
    +---------- (1) -------- (N) Company_Job_Educations
    |
    +---------- (1) -------- (N) Applicant_Job_Applications

Security_Roles (1) -------- (N) Security_Logins_Roles
```

---

## Performance Considerations

1. **Indexes**: All foreign key columns are indexed for fast lookups
2. **Partitioning**: Consider partitioning large tables (Security_Logins_Log, Applicant_Job_Applications) by date
3. **Archive**: Archive old audit logs (Security_Logins_Log) to maintain performance
4. **Statistics**: Regularly update table statistics for query optimization

---

## Security Notes

1. **Password Storage**: Passwords should use strong hashing algorithms (bcrypt, Argon2, etc.) - not plain text
2. **Audit Logging**: Security_Logins_Log provides basic audit trail of login attempts
3. **Role-Based Access**: Implement RBAC using Security_Roles and Security_Logins_Roles tables
4. **Data Privacy**: Ensure compliance with GDPR/privacy regulations when storing personal data

---

## Modifications & Extensions

To extend the schema:
1. Add new columns to existing tables
2. Create junction tables for new many-to-many relationships
3. Add new reference tables in the System module
4. Update corresponding POCO classes in CareerCloud.Pocos project

---

**Last Updated**: February 25, 2026
**Database Version**: 1.0
**Compatible With**: .NET 6+ | Entity Framework Core 6+
