CREATE DATABASE [EnglishCenterDB]
GO

USE [EnglishCenterDB]
GO

CREATE TABLE [Account]
(
	[IdAccount] INT PRIMARY KEY,
	[UserName] VARCHAR(32) UNIQUE, -- tên tài khoản
	[Password] VARCHAR(32),
	[TypeAccount] INT CHECK ([TypeAccount] > 0 AND [TypeAccount] < 5), -- 1:Admin , 3:Giáo viên, 4:học viên
)
GO

CREATE TABLE [Course]
(
	[IdCourse] INT PRIMARY KEY,
	[NameCourse] NVARCHAR(30),
	[NOS] INT CHECK([NOS] > 0), -- số buổi học của khóa học
	[Tuition] INT,
	[Status] INT DEFAULT 1 -- 1 là có sẳn; 0 là đã bị ẩn
)
GO

CREATE TABLE [Teacher]
(
	[IdTeacher] INT PRIMARY KEY REFERENCES dbo.Account([IDAccount]),
	[NameTeacher] NVARCHAR(50),
	[PhoneNumber] CHAR(10),
	[Address] NVARCHAR(50),
	[Salary] INT,
)
GO

CREATE TABLE [Class] 
(
	[IdClass] INT PRIMARY KEY,
	[NOSE] INT, -- số học viên dự kiến
	[Shift] INT CHECK([Shift] > 0 AND [Shift] < 7), -- 1 ngày có 7 ca học từ ca 1 đến ca 6
	[DOW] CHAR(5) CHECK([DOW] = '2-4-6' OR [DOW] = '3-5-7'), -- ngày học trong tuần '2-4-6' or '3-5-7'
	[IdCourse] INT REFERENCES dbo.Course(IdCourse)
	ON DELETE CASCADE
)
GO

CREATE TABLE [ClassRoom]
(
	[IdClassRoom] INT PRIMARY KEY,
	[NameClassRoom] CHAR(10)
)
GO

CREATE TABLE [Schedule]
(
	[IdTeacher] INT REFERENCES dbo.Teacher([IdTeacher]),
	[IdClass] INT REFERENCES dbo.Class([IdClass]),
	[Session] INT CHECK([Session] > 0),
	[IdRoom] INT REFERENCES dbo.ClassRoom([IdClassRoom]),
	[Day] DATE,
	PRIMARY KEY ([IdTeacher], [IdClass], [Session])
)
GO

CREATE TABLE [Student]
(
	[IdStudent] INT PRIMARY KEY REFERENCES dbo.Account([IdAccount]),
	[FullName] NVARCHAR(50),
	[PhoneNumber] CHAR(10),
	[Address] NVARCHAR(50),
	[Email] VARCHAR(50),
	[DOB] DATE,
)
GO

CREATE TABLE [Register]
(
	[IdStudent] INT REFERENCES dbo.Student([IdStudent]),
	[IdClass] INT REFERENCES dbo.Class([IdClass]),
	[Status] BIT, -- 1 = đã nộp tiền, 0 = chưa nộp tiền
)
GO

CREATE TABLE [Absent]
(
	[IdStudent] INT REFERENCES dbo.Student([IdStudent]),
	[IdClass] INT REFERENCES dbo.Class([IdClass]),
	[Session] INT NOT NULL,
	[MakeUpClass] INT REFERENCES dbo.Class([IdClass]),
	PRIMARY KEY ([IdStudent], [IdClass], [Session])
)
GO