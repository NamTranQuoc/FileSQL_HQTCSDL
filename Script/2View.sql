USE [EnglishCenterDB]
GO

--lịch của tất cả khóa học
CREATE VIEW [Schedule_] --Lich_
AS
	SELECT [Schedule].[IdClass], [Session], [NameClassRoom], [Day], [NameTeacher], [Shift]
	FROM [dbo].[Class], [dbo].[Schedule], [dbo].[ClassRoom], [dbo].[Teacher]
	WHERE [Class].[IdClass] = [Schedule].[IdClass]
	AND [IdRoom] = [IdClassRoom]
	AND [Teacher].[IdTeacher] = [Schedule].[IdTeacher]
GO
---------------------------------------------------------------------------------------------------------------------------------------------
--tổng số lượng buổi dạy trong lịch của giáo viên bắt đầu từ ngày hiện tại
CREATE VIEW [SumNoSessionOfTeacher] --TongSoBuoiDayTheoGiaoVien
AS
	SELECT [Teacher].[IdTeacher], COUNT(*) AS SL
	FROM [dbo].[Schedule] RIGHT JOIN [dbo].[Teacher]
	ON [Teacher].[IdTeacher] = [Schedule].[IdTeacher]
	GROUP BY [Teacher].[IdTeacher]
GO
---------------------------------------------------------------------------------------------------------------------------------------------
--tổng hợp số học viên đã đăng ký của một lớp
CREATE VIEW [SumNoStudentOfClass] --TongHocVienDaDangKyTheoLop
AS
	SELECT [Class].[IdClass], COUNT(IdStudent) AS [NOS]
	FROM [dbo].[Register] RIGHT JOIN [dbo].[Class]
	ON [Class].[IdClass] = [Register].[IdClass]
	GROUP BY [Class].[IdClass]
GO
---------------------------------------------------------------------------------------------------------------------------------------------
--Tổng hợp các lớp để học sinh đăng ký
CREATE VIEW [ListClass] --DanhSachLopDangKy
AS 
	SELECT [Class].[IdClass], [NOSE], [T].[NOS], [Shift], [DOW], [Class].[IdCourse], [NameCourse]
	FROM [dbo].[Class], [dbo].[Course], [dbo].[SumNoStudentOfClass] AS T
	WHERE [Course].[IdCourse] = [Class].[IdCourse]
	AND [Class].[IdClass] = [T].[IdClass]
GO