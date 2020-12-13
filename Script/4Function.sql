USE [EnglishCenterDB]
GO

--biến toàn cục
SELECT '000000' AS Pass INTO PasswordOld
GO

----------------------------------------------------------------------------------------------------------------------
--FUNCTION
----------------------------------------------------------------------------------------------------------------------
--hàm lấy ra ngày lớn nhất của lịch học
--input: 0: admin, nhân viên(tất cả thời khóa biểu), các số còn lại là thời khóa biểu ứng với account
CREATE FUNCTION [GetDayMaxOfSchedule] (@id INT)--NgayLonNhatCuaLichHoc
RETURNS DATE
AS
BEGIN
	DECLARE @date DATE
	IF (@id = 0)
	BEGIN
		SELECT @date = MAX([Day]) 
		FROM [dbo].[Schedule]
	END
    ELSE
	BEGIN
		SELECT @date = MAX(Day)
		FROM [dbo].[Schedule] INNER JOIN [dbo].[Register]
		ON [Register].[IdClass] = [Schedule].[IdClass]
		WHERE [IdTeacher] = @id
		OR [IdStudent] = @id
	END
	IF (@date IS NULL)
		SET @date = GETDATE()
	SET @date = DATEADD(DAY, 7 - DATEPART(dw, @date), @date) 
	RETURN @date
END
GO

----------------------------------------------------------------------------------------------------------------------
--hàm mã hóa MD5 (đâu vào là password nhập vào, đầu ra là password đã mã hóa)
CREATE FUNCTION [EncodeMD5] (@pass VARCHAR(32))--MaHoaMD5
RETURNS VARCHAR(32)
AS
BEGIN
	RETURN CONVERT(VARCHAR(32), HashBytes('MD5', @pass), 2)
END
GO

-----------------------------------------------------------------------------------------------------------------------
--kiểm tra tính đúng sai của ngày quan hệ với thứ
-- @Thu = 0 --> 2-4-6, @Thu = 1 --> 3-5-7
CREATE FUNCTION [CheckDayWithWeekday] (@day DATE = NULL, @weekday CHAR(5) = NULL) --KiemTraNgayVoiThu
RETURNS INT
AS
BEGIN
	DECLARE @WeekdayOfDay INT
	SET @WeekdayOfDay = DATEPART(WEEKDAY, @day)
	IF (@weekday = '2-4-6')
	BEGIN
		IF (@WeekdayOfDay = 2 OR @WeekdayOfDay = 4 OR @WeekdayOfDay = 6)
			RETURN 1 -- đúng
	END
    ELSE
    BEGIN
		IF (@WeekdayOfDay = 3 OR @WeekdayOfDay = 5 OR @WeekdayOfDay = 7)
			RETURN 1 -- đúng
	END
	RETURN 0 -- sai
END
GO

---------------------------------------------------------------------------------------
--hàm kiểm tra toàn bộ ngày học, phòng học, lớp học của bảng lịch học có bị trùng không
CREATE FUNCTION [CheckDayRoomClassOfSchedule] (@day DATE, @room INT, @class INT)--TruyVanNgayPhongLop_LichHoc
RETURNS INT
AS
BEGIN
	DECLARE @ret INT, @dow CHAR(5)
	SELECT @dow = [DOW]
	FROM [dbo].[Class]
	WHERE [IdClass] = @class
	SET @ret = (SELECT COUNT(*)
				FROM [dbo].[Schedule] INNER JOIN [dbo].[Class]
				ON Class.IdClass = Schedule.IdClass
				WHERE [Day] = @day AND [IdRoom] = @room AND [DOW] = @dow)
	RETURN @ret
END
GO

----------------------------------------------------------------------------------------------------------
--tính số ngày từ 1 ngày đến ngày hiện tại
CREATE FUNCTION [GetDistanceToCurrentDate] (@day DATE)--KhoanCachDenHienTai
RETURNS INT
AS 
BEGIN
	DECLARE @ret INT
	SET @ret = (SELECT DATEDIFF(DAY, @day, GETDATE()))
	RETURN @ret
END
GO

-----------------------------------------------------------------------------------------------------------
--truy vấn mã khóa học của lớp
CREATE FUNCTION [GetIdCourse] (@idClass INT)--LayMaKhoahoc
RETURNS INT
AS
BEGIN
	DECLARE @ret INT
	SELECT @ret = [IdCourse]
	FROM [dbo].[Class]
	WHERE [IdClass] = @idClass
	RETURN @ret
END
GO

----------------------------------------------------------------------------------------------------------
--kiểm tra trùng ca và trùng ngày học trong tuần
CREATE FUNCTION [CheckShiftDayOfWeek] (@idStudent INT)--KiemTraCaVaNgayTrongTuan
RETURNS INT
AS
BEGIN
	DECLARE @a INT, @b INT, @ret INT
	SELECT @a = COUNT(*) 
	FROM (SELECT [Shift], [DOW], [Day]
		  FROM [dbo].[Register], [dbo].[Class], [dbo].[Schedule]
		  WHERE [IdStudent] = @idStudent
		  AND [Class].[IdClass] = [Register].[IdClass]
		  AND [Schedule].[IdClass] = [Class].[IdClass]) AS AA

	SELECT @b = COUNT(*) 
	FROM (SELECT DISTINCT [Shift], [DOW], [Day]
		  FROM [dbo].[Register], [dbo].[Class], [dbo].[Schedule]
		  WHERE [IdStudent] = @idStudent
		  AND [Class].[IdClass] = [Register].[IdClass]
		  AND [Schedule].[IdClass] = [Class].[IdClass]) AS BB

	IF (@a != @b)
		SET @ret = 0 -- không thể đăng ký
	ELSE
		SET @ret = 1 -- có thể đăng ký
	RETURN @ret
END
GO
---------------------------------------------------------------------------------------------------------
-- tạo mã tự động
CREATE FUNCTION [AutomaticCodeGeneration] (@NameTable CHAR(15))--TaoMaTuDong
RETURNS INT 
AS
BEGIN
	DECLARE @max INT
	SET @max = CASE @NameTable
		WHEN 'User' THEN (SELECT MAX([IdAccount]) FROM [dbo].[Account])--giáo viên, học viên
		WHEN 'Course' THEN (SELECT MAX([IdCourse]) FROM [dbo].[Course])
		WHEN 'Class' THEN (SELECT MAX([IdClass]) FROM [dbo].[Class])
		WHEN 'Classroom' THEN (SELECT MAX([IdClassRoom]) FROM [dbo].[ClassRoom])
	END
    
	SET @max = @max + 1
	RETURN @max
END
GO

------------------------------------------------------------------------------------------------------------------
--hàm tạo danh sách theo lớp
--CREATE VIEW DanhSachLop_1 AS (SELECT * FROM dbo.TaoViewLop(1))
CREATE FUNCTION [CreateViewClass] (@idClass INT)--TaoViewLop
RETURNS TABLE
AS 
	RETURN SELECT [Register].[IdStudent], [FullName], [PhoneNumber], [Address], [Email], [DOB]
		   FROM [dbo].[Student] INNER JOIN [dbo].[Register]
		   ON [Register].[IdStudent] = [Student].[IdStudent]
		   WHERE [IdClass] = @idClass
GO

------------------------------------------------------------------------------------------------------------------
--hàm tạo lịch giảng dạy cho giảng viên
--CREATE VIEW LichDayGiangVien_1 AS (SELECT * FROM dbo.TaoLichDayTheoGiangVien(1))
CREATE FUNCTION [CreateScheduleOfTeacher] (@idTeacher INT)--LichDayTheoGiangVien
RETURNS TABLE
AS
	RETURN SELECT [Schedule].[IdClass], [Session], [NameClassRoom], [Day], [Shift]
		   FROM [dbo].[Class], [dbo].[Schedule], [dbo].[ClassRoom]
		   WHERE [Schedule].[IdClass] = [Class].[IdClass]
		   AND [IdTeacher] = @idTeacher
		   AND [IdClassRoom] = [IdRoom]
GO

----------------------------------------------------------------------------------------------------------------
--hàm tạo lịch học theo từng học viên
--CREATE VIEW Lich_1 AS (SELECT * FROM LichHocTheoHocVien(1))
CREATE FUNCTION [CreateScheduleOfStudent](@idStudent INT)--LichHocTheoHocVien
RETURNS TABLE
AS
	RETURN SELECT [Schedule].[IdClass], [Session], [NameClassRoom], [Day], [Shift]
		   FROM [dbo].[Student], [dbo].[Register], [dbo].[Schedule], [dbo].[Class], [dbo].[ClassRoom]
		   WHERE [Register].[IdStudent] = @idStudent
		   AND [Register].[IdClass] = [Schedule].[IdClass]
		   AND [Register].[IdStudent] = [Student].[IdStudent]
		   AND [Class].[IdClass] = [Schedule].[IdClass]
		   AND [IdClassRoom] = [IdRoom]
GO
---------------------------------------------------------------------------------------------------------
--hàm kiểm tra đăng nhập
--input: TaiKhoan, MatKhau
--output: 5 sai tài khoản hoặc mật khẩu, 1:Admin, 3:Giáo viên, 4:học viên
CREATE FUNCTION [CheckLogin] (@userName VARCHAR(32), @password VARCHAR(32))--KienTraDangNhap
RETURNS INT
AS
BEGIN
	DECLARE @typeAccount INT
	SET @typeAccount = 5
	SET @password = [dbo].[EncodeMD5](@password)
	SELECT @typeAccount = [TypeAccount]
	FROM dbo.Account
	WHERE [UserName] = @userName 
	AND [Password] = @password
	RETURN @typeAccount
END
GO
----------------------------------------------------------------------------------------------------------
-- lấy số lượng học sinh của lớp
CREATE FUNCTION [GetStudentOfClass] (@idClass INT)--SoLuongHocVienCuaLop
RETURNS INT
AS
BEGIN
	DECLARE @count INT
	SET @count = 0
	SELECT @count = COUNT(*) 
	FROM [dbo].[Register] 
	WHERE [IdClass] = @idClass
	RETURN @count
END
GO

----------------------------------------------------------------------------------------------------------
--kiểm tra ngày (@ngay) và ca (@ca) của giáo viên đó đã có lịch dạy chưa (@gv)
--nếu tồn tại trả về 1, không tồn tại trả về 0
CREATE FUNCTION [CheckScheduleOfTeacher] (@day DATE, @idClass INT, @idTeacher INT)--KiemTraLichGiaoVien
RETURNS INT
AS
BEGIN
	DECLARE @t INT
	SELECT @t = COUNT(*)
	FROM [dbo].[Schedule]
	WHERE [IdTeacher] = @idTeacher
	AND [Day] = @day
	AND [IdClass] = @idClass
	IF (@t = 0)
		RETURN 0
	RETURN 1
END
GO
---------------------------------------------------------------------------------------------------------
--danh sách lớp theo buổi (danh sách lớp cứng công với danh sách nhưng học viên học bù)
CREATE FUNCTION [GetListOfClass] (@idClass INT, @session INT)--DanhSachLopTheobuoi
RETURNS @table TABLE ([IdStudent] INT, [FullName] NVARCHAR(50), [PhoneNumber] CHAR(10), [Address] NVARCHAR(50), [Email] VARCHAR(50), [DOB] DATE)
AS
BEGIN	
	INSERT @table SELECT * FROM [dbo].[CreateViewClass] (@idClass)
	INSERT @table SELECT [Student].[IdStudent], [FullName], [PhoneNumber], [Address], [Email], [DOB]
				  FROM [dbo].[Student], (SELECT [IdStudent]
									 FROM [dbo].[Absent]
									 WHERE [MakeUpClass] = @idClass 
									 AND [Session] = @session) AS Q 
				  WHERE [Student].[IdStudent] = [Q].[IdStudent]
	RETURN
END
GO