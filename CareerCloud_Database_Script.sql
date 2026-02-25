-- ============================================
-- CareerCloud Database Schema
-- Generated from CareerCloud.Pocos entities
-- ============================================

-- Drop existing tables (if any) - Remove this if you want to preserve data
-- DROP TABLE IF EXISTS Applicant_Job_Applications;
-- DROP TABLE IF EXISTS Applicant_Skills;
-- DROP TABLE IF EXISTS Applicant_Work_History;
-- DROP TABLE IF EXISTS Applicant_Educations;
-- DROP TABLE IF EXISTS Applicant_Resumes;
-- DROP TABLE IF EXISTS Applicant_Profiles;
-- DROP TABLE IF EXISTS Company_Job_Skills;
-- DROP TABLE IF EXISTS Company_Job_Educations;
-- DROP TABLE IF EXISTS Company_Jobs_Descriptions;
-- DROP TABLE IF EXISTS Company_Jobs;
-- DROP TABLE IF EXISTS Company_Locations;
-- DROP TABLE IF EXISTS Company_Descriptions;
-- DROP TABLE IF EXISTS Company_Profiles;
-- DROP TABLE IF EXISTS Security_Logins_Roles;
-- DROP TABLE IF EXISTS Security_Logins_Log;
-- DROP TABLE IF EXISTS Security_Logins;
-- DROP TABLE IF EXISTS Security_Roles;
-- DROP TABLE IF EXISTS System_Country_Codes;
-- DROP TABLE IF EXISTS System_Language_Codes;

-- ============================================
-- SYSTEM REFERENCE TABLES
-- ============================================

-- System Country Codes Reference Table
CREATE TABLE [System_Country_Codes] (
    [Code] NVARCHAR(5) NOT NULL,
    [Name] NVARCHAR(50) NULL,
    CONSTRAINT [PK_System_Country_Codes] PRIMARY KEY ([Code])
);

-- System Language Codes Reference Table
CREATE TABLE [System_Language_Codes] (
    [LanguageID] NVARCHAR(10) NOT NULL,
    [Name] NVARCHAR(50) NULL,
    [Native_Name] NVARCHAR(50) NULL,
    CONSTRAINT [PK_System_Language_Codes] PRIMARY KEY ([LanguageID])
);

-- ============================================
-- SECURITY TABLES
-- ============================================

-- Security Roles Table
CREATE TABLE [Security_Roles] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Role] NVARCHAR(50) NULL,
    [Is_Inactive] BIT NOT NULL DEFAULT(0),
    CONSTRAINT [PK_Security_Roles] PRIMARY KEY ([Id])
);
CREATE NONCLUSTERED INDEX [IX_Security_Roles_Role] ON [Security_Roles]([Role]);

-- Security Logins Table
CREATE TABLE [Security_Logins] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Login] NVARCHAR(255) NULL,
    [Password] NVARCHAR(MAX) NULL,
    [Created_Date] DATETIME NOT NULL,
    [Password_Update_Date] DATETIME NULL,
    [Agreement_Accepted_Date] DATETIME NULL,
    [Is_Locked] BIT NOT NULL DEFAULT(0),
    [Is_Inactive] BIT NOT NULL DEFAULT(0),
    [Email_Address] NVARCHAR(255) NULL,
    [Phone_Number] NVARCHAR(20) NULL,
    [Full_Name] NVARCHAR(255) NULL,
    [Force_Change_Password] BIT NOT NULL DEFAULT(0),
    [Prefferred_Language] NVARCHAR(10) NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Security_Logins] PRIMARY KEY ([Id])
);
CREATE NONCLUSTERED INDEX [IX_Security_Logins_Login] ON [Security_Logins]([Login]);
CREATE NONCLUSTERED INDEX [IX_Security_Logins_Email] ON [Security_Logins]([Email_Address]);

-- Security Logins Roles Junction Table
CREATE TABLE [Security_Logins_Roles] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Login] UNIQUEIDENTIFIER NOT NULL,
    [Role] UNIQUEIDENTIFIER NOT NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Security_Logins_Roles] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Security_Logins_Roles_Login] FOREIGN KEY ([Login]) REFERENCES [Security_Logins]([Id]),
    CONSTRAINT [FK_Security_Logins_Roles_Role] FOREIGN KEY ([Role]) REFERENCES [Security_Roles]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Security_Logins_Roles_Login] ON [Security_Logins_Roles]([Login]);
CREATE NONCLUSTERED INDEX [IX_Security_Logins_Roles_Role] ON [Security_Logins_Roles]([Role]);

-- Security Logins Log Table
CREATE TABLE [Security_Logins_Log] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Login] UNIQUEIDENTIFIER NOT NULL,
    [Source_IP] NVARCHAR(50) NULL,
    [Logon_Date] DATETIME NOT NULL,
    [Is_Succesful] BIT NOT NULL,
    CONSTRAINT [PK_Security_Logins_Log] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Security_Logins_Log_Login] FOREIGN KEY ([Login]) REFERENCES [Security_Logins]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Security_Logins_Log_Login] ON [Security_Logins_Log]([Login]);
CREATE NONCLUSTERED INDEX [IX_Security_Logins_Log_Logon_Date] ON [Security_Logins_Log]([Logon_Date]);

-- ============================================
-- COMPANY TABLES
-- ============================================

-- Company Profiles Table
CREATE TABLE [Company_Profiles] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Registration_Date] DATETIME NOT NULL,
    [Company_Website] NVARCHAR(255) NULL,
    [Contact_Phone] NVARCHAR(20) NULL,
    [Contact_Name] NVARCHAR(255) NULL,
    [Company_Logo] VARBINARY(MAX) NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Company_Profiles] PRIMARY KEY ([Id])
);
CREATE NONCLUSTERED INDEX [IX_Company_Profiles_Registration_Date] ON [Company_Profiles]([Registration_Date]);

-- Company Descriptions Table
CREATE TABLE [Company_Descriptions] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Company] UNIQUEIDENTIFIER NOT NULL,
    [LanguageId] NVARCHAR(10) NULL,
    [Company_Name] NVARCHAR(255) NULL,
    [Company_Description] NVARCHAR(MAX) NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Company_Descriptions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Company_Descriptions_Company] FOREIGN KEY ([Company]) REFERENCES [Company_Profiles]([Id]),
    CONSTRAINT [FK_Company_Descriptions_Language] FOREIGN KEY ([LanguageId]) REFERENCES [System_Language_Codes]([LanguageID])
);
CREATE NONCLUSTERED INDEX [IX_Company_Descriptions_Company] ON [Company_Descriptions]([Company]);
CREATE NONCLUSTERED INDEX [IX_Company_Descriptions_Language] ON [Company_Descriptions]([LanguageId]);

-- Company Locations Table
CREATE TABLE [Company_Locations] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Company] UNIQUEIDENTIFIER NOT NULL,
    [Country_Code] NVARCHAR(5) NULL,
    [State_Province_Code] NVARCHAR(10) NULL,
    [Street_Address] NVARCHAR(255) NULL,
    [City_Town] NVARCHAR(100) NULL,
    [Zip_Postal_Code] NVARCHAR(20) NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Company_Locations] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Company_Locations_Company] FOREIGN KEY ([Company]) REFERENCES [Company_Profiles]([Id]),
    CONSTRAINT [FK_Company_Locations_Country] FOREIGN KEY ([Country_Code]) REFERENCES [System_Country_Codes]([Code])
);
CREATE NONCLUSTERED INDEX [IX_Company_Locations_Company] ON [Company_Locations]([Company]);
CREATE NONCLUSTERED INDEX [IX_Company_Locations_Country] ON [Company_Locations]([Country_Code]);

-- Company Jobs Table
CREATE TABLE [Company_Jobs] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Company] UNIQUEIDENTIFIER NOT NULL,
    [Profile_Created] DATETIME NOT NULL,
    [Is_Inactive] BIT NOT NULL DEFAULT(0),
    [Is_Company_Hidden] BIT NOT NULL DEFAULT(0),
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Company_Jobs] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Company_Jobs_Company] FOREIGN KEY ([Company]) REFERENCES [Company_Profiles]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Company_Jobs_Company] ON [Company_Jobs]([Company]);
CREATE NONCLUSTERED INDEX [IX_Company_Jobs_Profile_Created] ON [Company_Jobs]([Profile_Created]);
CREATE NONCLUSTERED INDEX [IX_Company_Jobs_Is_Active] ON [Company_Jobs]([Is_Inactive]);

-- Company Jobs Descriptions Table
CREATE TABLE [Company_Jobs_Descriptions] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Job] UNIQUEIDENTIFIER NOT NULL,
    [Job_Name] NVARCHAR(255) NULL,
    [Job_Descriptions] NVARCHAR(MAX) NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Company_Jobs_Descriptions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Company_Jobs_Descriptions_Job] FOREIGN KEY ([Job]) REFERENCES [Company_Jobs]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Company_Jobs_Descriptions_Job] ON [Company_Jobs_Descriptions]([Job]);

-- Company Job Skills Table
CREATE TABLE [Company_Job_Skills] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Job] UNIQUEIDENTIFIER NOT NULL,
    [Skill] NVARCHAR(100) NULL,
    [Skill_Level] NVARCHAR(50) NULL,
    [Importance] INT NOT NULL DEFAULT(0),
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Company_Job_Skills] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Company_Job_Skills_Job] FOREIGN KEY ([Job]) REFERENCES [Company_Jobs]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Company_Job_Skills_Job] ON [Company_Job_Skills]([Job]);
CREATE NONCLUSTERED INDEX [IX_Company_Job_Skills_Skill] ON [Company_Job_Skills]([Skill]);

-- Company Job Educations Table
CREATE TABLE [Company_Job_Educations] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Job] UNIQUEIDENTIFIER NOT NULL,
    [Major] NVARCHAR(100) NULL,
    [Importance] SMALLINT NOT NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Company_Job_Educations] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Company_Job_Educations_Job] FOREIGN KEY ([Job]) REFERENCES [Company_Jobs]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Company_Job_Educations_Job] ON [Company_Job_Educations]([Job]);

-- ============================================
-- APPLICANT TABLES
-- ============================================

-- Applicant Profiles Table
CREATE TABLE [Applicant_Profiles] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Login] UNIQUEIDENTIFIER NOT NULL,
    [Current_Salary] DECIMAL(18, 2) NULL,
    [Current_Rate] DECIMAL(18, 2) NULL,
    [Currency] NVARCHAR(10) NULL,
    [Country_Code] NVARCHAR(5) NULL,
    [State_Province_Code] NVARCHAR(10) NULL,
    [Street_Address] NVARCHAR(255) NULL,
    [City_Town] NVARCHAR(100) NULL,
    [Zip_Postal_Code] NVARCHAR(20) NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Applicant_Profiles] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Applicant_Profiles_Login] FOREIGN KEY ([Login]) REFERENCES [Security_Logins]([Id]),
    CONSTRAINT [FK_Applicant_Profiles_Country] FOREIGN KEY ([Country_Code]) REFERENCES [System_Country_Codes]([Code])
);
CREATE NONCLUSTERED INDEX [IX_Applicant_Profiles_Login] ON [Applicant_Profiles]([Login]);
CREATE NONCLUSTERED INDEX [IX_Applicant_Profiles_Country] ON [Applicant_Profiles]([Country_Code]);

-- Applicant Work History Table
CREATE TABLE [Applicant_Work_History] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Applicant] UNIQUEIDENTIFIER NOT NULL,
    [Company_Name] NVARCHAR(255) NULL,
    [Country_Code] NVARCHAR(5) NULL,
    [Location] NVARCHAR(255) NULL,
    [Job_Title] NVARCHAR(100) NULL,
    [Job_Description] NVARCHAR(MAX) NULL,
    [Start_Month] SMALLINT NOT NULL,
    [Start_Year] INT NOT NULL,
    [End_Month] SMALLINT NOT NULL,
    [End_Year] INT NOT NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Applicant_Work_History] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Applicant_Work_History_Applicant] FOREIGN KEY ([Applicant]) REFERENCES [Applicant_Profiles]([Id]),
    CONSTRAINT [FK_Applicant_Work_History_Country] FOREIGN KEY ([Country_Code]) REFERENCES [System_Country_Codes]([Code])
);
CREATE NONCLUSTERED INDEX [IX_Applicant_Work_History_Applicant] ON [Applicant_Work_History]([Applicant]);
CREATE NONCLUSTERED INDEX [IX_Applicant_Work_History_Country] ON [Applicant_Work_History]([Country_Code]);

-- Applicant Educations Table
CREATE TABLE [Applicant_Educations] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Applicant] UNIQUEIDENTIFIER NOT NULL,
    [Major] NVARCHAR(100) NULL,
    [Certificate_Diploma] NVARCHAR(100) NULL,
    [Start_Date] DATETIME NULL,
    [Completion_Date] DATETIME NULL,
    [Completion_Percent] TINYINT NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Applicant_Educations] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Applicant_Educations_Applicant] FOREIGN KEY ([Applicant]) REFERENCES [Applicant_Profiles]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Applicant_Educations_Applicant] ON [Applicant_Educations]([Applicant]);

-- Applicant Skills Table
CREATE TABLE [Applicant_Skills] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Applicant] UNIQUEIDENTIFIER NOT NULL,
    [Skill] NVARCHAR(100) NULL,
    [Skill_Level] NVARCHAR(50) NULL,
    [Start_Month] TINYINT NOT NULL,
    [Start_Year] INT NOT NULL,
    [End_Month] TINYINT NOT NULL,
    [End_Year] INT NOT NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Applicant_Skills] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Applicant_Skills_Applicant] FOREIGN KEY ([Applicant]) REFERENCES [Applicant_Profiles]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Applicant_Skills_Applicant] ON [Applicant_Skills]([Applicant]);
CREATE NONCLUSTERED INDEX [IX_Applicant_Skills_Skill] ON [Applicant_Skills]([Skill]);

-- Applicant Resumes Table
CREATE TABLE [Applicant_Resumes] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Applicant] UNIQUEIDENTIFIER NOT NULL,
    [Resume] NVARCHAR(MAX) NULL,
    [Last_Updated] DATETIME NULL,
    CONSTRAINT [PK_Applicant_Resumes] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Applicant_Resumes_Applicant] FOREIGN KEY ([Applicant]) REFERENCES [Applicant_Profiles]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Applicant_Resumes_Applicant] ON [Applicant_Resumes]([Applicant]);

-- Applicant Job Applications Table
CREATE TABLE [Applicant_Job_Applications] (
    [Id] UNIQUEIDENTIFIER NOT NULL,
    [Applicant] UNIQUEIDENTIFIER NOT NULL,
    [Job] UNIQUEIDENTIFIER NOT NULL,
    [Application_Date] DATETIME NOT NULL,
    [Time_Stamp] ROWVERSION NULL,
    CONSTRAINT [PK_Applicant_Job_Applications] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Applicant_Job_Applications_Applicant] FOREIGN KEY ([Applicant]) REFERENCES [Applicant_Profiles]([Id]),
    CONSTRAINT [FK_Applicant_Job_Applications_Job] FOREIGN KEY ([Job]) REFERENCES [Company_Jobs]([Id])
);
CREATE NONCLUSTERED INDEX [IX_Applicant_Job_Applications_Applicant] ON [Applicant_Job_Applications]([Applicant]);
CREATE NONCLUSTERED INDEX [IX_Applicant_Job_Applications_Job] ON [Applicant_Job_Applications]([Job]);
CREATE NONCLUSTERED INDEX [IX_Applicant_Job_Applications_Date] ON [Applicant_Job_Applications]([Application_Date]);

-- ============================================
-- SAMPLE DATA - Uncomment to populate reference tables
-- ============================================

/*
-- Insert sample country codes
INSERT INTO [System_Country_Codes] ([Code], [Name]) VALUES
('US', 'United States'),
('CA', 'Canada'),
('MX', 'Mexico'),
('GB', 'United Kingdom'),
('AU', 'Australia');

-- Insert sample language codes
INSERT INTO [System_Language_Codes] ([LanguageID], [Name], [Native_Name]) VALUES
('en', 'English', 'English'),
('es', 'Spanish', 'Español'),
('fr', 'French', 'Français'),
('de', 'German', 'Deutsch'),
('ja', 'Japanese', '日本語');

-- Insert sample security roles
INSERT INTO [Security_Roles] ([Id], [Role], [Is_Inactive]) VALUES
(NEWID(), 'Admin', 0),
(NEWID(), 'Recruiter', 0),
(NEWID(), 'Applicant', 0),
(NEWID(), 'Company', 0);
*/

-- ============================================
-- END OF SCRIPT
-- ============================================
