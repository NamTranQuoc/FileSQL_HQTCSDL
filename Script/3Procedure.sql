USE [EnglishCenterDB]
GO

--tạo lịch học tự động
CREATE PROCEDURE [CreateSchedule] (@idClass INT)--TaoLichHoc
AS
BEGIN
	DECLARE @nos INT, @day DATE, @i INT, @weekDay CHAR(5), @idTeacher INT
	SET @day = GETDATE()
	SET @i = 1

	SELECT @nos = NOS, @weekDay = [DOW]
	FROM [dbo].[Class] INNER JOIN [dbo].[Course]
	ON [Course].[IdCourse] = [Class].[IdCourse]
	WHERE [IdClass] = @idClass

	DECLARE @sumNoTea INT
	SELECT @sumNoTea = COUNT(*) 
	FROM [dbo].[SumNoSessionOfTeacher]

	SELECT [IdTeacher], [SL], IDENTITY(INT, 1, 1) AS ID INTO [tbIdTeacher]
	FROM [dbo].[SumNoSessionOfTeacher]
	ORDER BY [SL], [IdTeacher]
	
	SELECT @idTeacher = [idTeacher]
	FROM [tbIdTeacher]
	WHERE [ID] = 1

	WHILE (@i <= @nos)
	BEGIN
		IF (([dbo].[CheckDayWithWeekday](@day, @weekday)) = 1)
		BEGIN	
			IF ([dbo].[CheckScheduleOfTeacher](@day, @idClass, @idTeacher) = 0)
			BEGIN
				DECLARE @room INT, @sumRoom INT
				SET @room = 1
				SELECT @sumRoom = COUNT(*)
				FROM [dbo].[ClassRoom]

				WHILE (@room <= @sumRoom)
				BEGIN
					IF (([dbo].[CheckDayRoomClassOfSchedule](@day, @room, @idClass)) = 0)
					BEGIN					
						INSERT [dbo].[Schedule] VALUES (@idTeacher, @idClass, @i, @room, @day)
						SET @i = @i + 1
						BREAK
					END 
					ELSE
						SET @room = @room + 1
				END
				SET @day = DATEADD(DAY, 1, @day)
			END	
			ELSE
            BEGIN				
				DECLARE @dem INT, @test3 INT
				SET @test3 = 0
				SET @i = 0
				WHILE (@dem < @sumNoTea)
				BEGIN
					SELECT @idTeacher = [idTeacher]
					FROM [tbIdTeacher]
					WHERE ID = @dem
					IF ([dbo].[CheckScheduleOfTeacher](@day, @idClass, @idTeacher) = 0)
					BEGIN
						SET @test3 = 1
						BREAK
					END
				END
				IF (@test3 = 0)
				BEGIN
					SELECT @idTeacher = [idTeacher]
					FROM [tbIdTeacher]
					WHERE ID = 1
					SET @day = DATEADD(DAY, 1, @day)
				END
			END
		END
		ELSE 
			SET @day = DATEADD(DAY, 1, @day)
	END
	DROP TABLE [tbIdTeacher]
END
GO

-----------------------------------------------------------------------------------------------------------
--Thêm lịch một ngày trong lịch học bị xóa
CREATE PROCEDURE [AddSchedule] (@idClass INT) --ThemLichHoc
AS
BEGIN
	DECLARE @nos INT, @day DATE, @i INT, @weekday CHAR(5), @idTeacher INT
	SELECT @day = MAX([Day]) 
	FROM [dbo].[Schedule]
	WHERE [IdClass] = @idClass 
	SET @day = DATEADD(DAY, 1, @day)

	SET @i = 1

	SELECT @nos = [NOS], @weekday = [DOW]
	FROM [dbo].[Class] INNER JOIN [dbo].[Course]
	ON [Course].[IdCourse] = [Class].[IdCourse]
	WHERE [IdClass] = @idClass

	DECLARE @sumTeacher INT
	SELECT @sumTeacher = COUNT(*) 
	FROM [dbo].[SumNoSessionOfTeacher]

	SELECT [IdTeacher], [SL], IDENTITY(INT, 1, 1) AS ID INTO [tbIdTeacher]
	FROM [dbo].[SumNoSessionOfTeacher]
	ORDER BY [SL], [IdTeacher]
	
	SELECT @idTeacher = [IdTeacher]
	FROM [tbIdTeacher]
	WHERE [ID] = 1

	SELECT [Session], IDENTITY(INT, 1, 1) AS [ID] 
	INTO [tableOld]
	FROM [dbo].[Schedule]
	WHERE [IdClass] = @idClass
	DECLARE @CountTableOld INT, @sessionOld INT
	SELECT @CountTableOld = COUNT(*)
	FROM [tableOld]
	WHILE (@i <= @CountTableOld)
	BEGIN
		SELECT @sessionOld = [Session]
		FROM [tableOld]
		WHERE ID = @i
		UPDATE [dbo].[Schedule]
		SET [Session] = @i 
		WHERE [IdClass] = @idClass AND [Session] = @sessionOld
		SET @i = @i + 1
	END
	DROP TABLE [tableOld]

	WHILE (@i <= @nos)
	BEGIN
		IF (([dbo].[CheckDayWithWeekday](@day, @weekday)) = 1)
		BEGIN	
			IF ([dbo].[CheckScheduleOfTeacher](@day, @idClass, @idTeacher) = 0)
			BEGIN
				DECLARE @room INT, @sumRoom INT
				SET @room = 1
				SELECT @sumRoom = COUNT(*)
				FROM [dbo].[ClassRoom]

				WHILE (@room <= @sumRoom)
				BEGIN
					IF (([dbo].[CheckDayRoomClassOfSchedule](@day, @room, @idClass)) = 0)
					BEGIN					
						INSERT [dbo].[Schedule] VALUES (@idTeacher, @idClass, @i, @room, @day)
						SET @i = @i + 1
						BREAK
					END 
					ELSE
						SET @room = @room + 1
				END
				SET @day = DATEADD(DAY, 1, @day)
			END	
			ELSE
            BEGIN				
				DECLARE @dem INT, @test3 INT
				SET @test3 = 0
				SET @i = 0
				WHILE (@dem < @sumTeacher)
				BEGIN
					SELECT @idTeacher = [IdTeacher]
					FROM [tbIdTeacher]
					WHERE [ID] = @dem
					IF ([dbo].[CheckScheduleOfTeacher](@day, @idClass, @idTeacher) = 0)
					BEGIN
						SET @test3 = 1
						BREAK
					END
				END
				IF (@test3 = 0)
				BEGIN
					SELECT @idTeacher = [IdTeacher]
					FROM [tbIdTeacher]
					WHERE [ID] = 1
					SET @day = DATEADD(DAY, 1, @day)
				END
			END
		END
		ELSE 
			SET @day = DATEADD(DAY, 1, @day)
	END
	DROP TABLE [tbIdTeacher]	
END
GO

------------------------------------------------------------------------------------------------------------
--thêm lịch học khi số buổi của khóa học tăng
CREATE PROCEDURE [AddScheduleFollowCourse] (@idClass INT)--ThemLichHocTheoKhoa
AS
BEGIN
	DECLARE @nos INT, @day DATE, @i INT, @weekday CHAR(5), @idTeacher INT
	SELECT @day = MAX([Day]) 
	FROM [dbo].[Schedule]
	WHERE [IdClass] = @idClass 
	SET @day = DATEADD(DAY, 1, @day)
	SELECT @i = MAX([Session]) 
	FROM [dbo].[Schedule] 
	WHERE [IdClass] = @idClass
	SET @i = @i + 1
	
	SELECT @nos = [NOS], @weekday = [DOW]
	FROM [dbo].[Class] INNER JOIN [dbo].[Course]
	ON [Course].[IdCourse] = [Class].[IdCourse]
	WHERE IdClass = @idClass

	DECLARE @sumTeacher INT
	SELECT @sumTeacher = COUNT(*) 
	FROM [dbo].[SumNoSessionOfTeacher]

	SELECT [IdTeacher], [SL], IDENTITY(INT, 1, 1) AS [ID] INTO [tbIdTeacher]
	FROM [dbo].[SumNoSessionOfTeacher]
	ORDER BY [SL], [IdTeacher]
	
	SELECT @idTeacher = [IdTeacher]
	FROM [tbIdTeacher]
	WHERE [ID] = 1

	WHILE (@i <= @nos)
	BEGIN
		IF (([dbo].[CheckDayWithWeekday](@day, @weekday)) = 1)
		BEGIN	
			IF ([dbo].[CheckScheduleOfTeacher](@day, @idClass, @idTeacher) = 0)
			BEGIN
				DECLARE @room INT, @sumRoom INT
				SET @room = 1
				SELECT @sumRoom = COUNT(*)
				FROM [dbo].[ClassRoom]

				WHILE (@room <= @sumRoom)
				BEGIN
					IF (([dbo].[CheckDayRoomClassOfSchedule](@day, @room, @idClass)) = 0)
					BEGIN					
						INSERT [dbo].[Schedule] VALUES (@idTeacher, @idClass, @i, @room, @day)
						SET @i = @i + 1
						BREAK
					END 
					ELSE
						SET @room = @room + 1
				END
				SET @day = DATEADD(DAY, 1, @day)
			END	
			ELSE
            BEGIN				
				DECLARE @dem INT, @test3 INT
				SET @test3 = 0
				SET @i = 0
				WHILE (@dem < @sumTeacher)
				BEGIN
					SELECT @idTeacher = [IdTeacher]
					FROM [tbIdTeacher]
					WHERE ID = @dem
					IF ([dbo].[CheckScheduleOfTeacher](@day, @idClass, @idTeacher) = 0)
					BEGIN
						SET @test3 = 1
						BREAK
					END
				END
				IF (@test3 = 0)
				BEGIN
					SELECT @idTeacher = [IdTeacher]
					FROM [tbIdTeacher]
					WHERE ID = 1
					SET @day = DATEADD(DAY, 1, @day)
				END
			END
		END
		ELSE 
			SET @day = DATEADD(DAY, 1, @day)
	END
	DROP TABLE [tbIdTeacher]
END
GO

------------------------------------------------------------------------------------------------------------
--xóa lịch học khi so buoi học của khoa học giảm
CREATE PROCEDURE [DeleteScheduleFllowCourse] (@idClass INT, @nOSNew INT, @nOSOld INT)--XoaLichHoc
AS
BEGIN
	WHILE (@nOSNew < @nOSOld)
	BEGIN
		DELETE [dbo].[Schedule]
		WHERE [IdClass] = @idClass
		AND [Session] = @nOSOld
		SET @nOSOld = @nOSOld - 1
	END
END
GO
------------------------------------------------------------------------------------------------------------
--thêm buổi vắng vào bẳng vắng
CREATE PROCEDURE [AddAbsent] (@idStudent INT, @idClass INT, @session INT)--ThemBuoiVang
AS 
BEGIN
	INSERT [dbo].[Absent] ([IdStudent], [IdClass], [Session]) VALUES ( @idStudent , @idClass, @session)
END
GO

-------------------------------------------------------------------------------------------------------------------------------------------
-- Báo cáo theo danh thu của khóa 
CREATE PROC [ReportFlollowCourse] --BaoCaoDoanhThuTheoKhoa
AS
BEGIN
	SELECT [NameCourse], [Tuition] * [W].[C] AS [Sum]
	FROM [dbo].[Course] INNER JOIN (SELECT [Course].[IdCourse], COUNT([Q].[IdCourse]) AS [C]
									FROM [dbo].[Course] LEFT JOIN (SELECT [IdCourse]
																   FROM [dbo].[Class] INNER JOIN [dbo].[Register]
																   ON [Register].[IdClass] = [Class].[IdClass]) AS [Q]
									ON [Q].[IdCourse] = [Course].[IdCourse]
									GROUP BY [Course].[IdCourse]) AS [W]
	ON [W].[IdCourse] = [Course].[IdCourse]
END
GO

----------------------------------------------------------------------------------------------------------
-- báo cáo giáo viên theo khóa
CREATE PROC [ReportTeacherOfCourse]--BaoCaoGiaoVienThuocKhoaHoc
AS
BEGIN
	SELECT DISTINCT [NameCourse], [Teacher].[IdTeacher], [NameTeacher], [PhoneNumber], [Address], [Salary]
	FROM [dbo].[Teacher], [dbo].[Schedule], [dbo].[Class], [dbo].[Course]
	WHERE [Teacher].[IdTeacher] = [Schedule].[IdTeacher] 
	AND [Schedule].[IdClass] = [Class].[IdClass] 
	AND [Class].[IdCourse] = [Course].[IdCourse]
END
GO

-------------------------------------------------------------------------------------------------------
--báo cáo lớp theo khóa
CREATE PROC [ReportClassOfCourse]--BaoCaoLopThuocKhoa
AS
BEGIN
	SELECT [NameCourse], [IdClass], [NOSE], [Shift], [DOW]
	FROM [dbo].[Class], [dbo].[Course]
	WHERE [Class].[IdCourse] = [Course].[IdCourse]
END
GO 

----------------------------------------------------------------------------------------------------------
-- báo cáo học viên theo lớp
CREATE PROC [ReportStudentOfClass]--BaoCaoHocVienThuocLop
AS 
BEGIN 
	SELECT [Student].[IdStudent], [FullName], [Class].[IdClass], [Shift], [DOW], [NameCourse]
	FROM [dbo].[Student], [dbo].[Register], [dbo].[Class], [dbo].[Course]
	WHERE [Student].[IdStudent] = [Register].[IdStudent] 
	AND [Register].[IdClass] = [Class].[IdClass] 
	AND [Class].[IdCourse] = [Course].[IdCourse]
END 
GO

-----------------------------------------------------------------------------------------------------------
-- Lấy dữ liệu lớp theo khóa học
CREATE PROC [GetClassOfCourse] (@id INT)--LopTheoKhoaHoc
AS
BEGIN
	SELECT [Class].[IdClass], [Shift], [DOW], [NOS], [Tuition], [Q].[StartDay]
	FROM [dbo].[Class], [dbo].[Course], (SELECT [IdClass], MIN([Day]) AS [StartDay]
										 FROM [dbo].[Schedule]
										 GROUP BY [IdClass]) AS Q
	WHERE Class.IdCourse = @id
	AND [Class].[IdCourse] = [Course].[IdCourse]
	AND [Class].[IdClass] = [Q].[IdClass]
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
-- Thủ tục lấy ra danh sách học viên chưa thanh toán học phí theo khóa học
CREATE PROC [StudentExpenseByCourse] @nameCourse NVARCHAR(30)--HocVienExpenseByCourse
AS
BEGIN
    SELECT [cl].[IdClass] AS N'Mã Lớp Học', [re].[IdStudent] AS N'Mã Học Viên', [st].[FullName] AS N'Họ và Tên', [st].[PhoneNumber] AS N'Số Điện Thoại' , [co].[NameCourse] AS N'Tên Khóa Học' , [cl].[DOW] AS N'Ngày Học', [re].[Status] AS N'Thanh Toán'
	FROM [dbo].[Student] st
	INNER JOIN [dbo].[Register] re ON [re].[IdStudent] = [st].[IdStudent]
	INNER JOIN [dbo].[Class] cl ON [cl].[IdClass] = [re].[IdClass]
	INNER JOIN [dbo].[Course] co ON [co].[IdCourse] = [cl].[IdCourse]
	WHERE [co].[NameCourse] = @nameCourse 
	AND [re].[Status] = 0
	ORDER BY [cl].[IdClass] ASC
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
-- Thủ tục lấy ra danh sách học viên chưa thanh toán học phí
CREATE PROC [StudentExpense]--HocVienExpense
AS
BEGIN
    SELECT [cl].[IdClass] AS N'Mã Lớp Học', [re].[IdStudent] AS N'Mã Học Viên', [st].[FullName] AS N'Họ và Tên', [st].[PhoneNumber] AS N'Số Điện Thoại' , [co].[NameCourse] AS N'Tên Khóa Học' , [cl].[DOW] AS N'Ngày Học', [re].[Status] AS N'Thanh Toán'
	FROM [dbo].[Student] st
	INNER JOIN [dbo].[Register] re ON [re].[IdStudent] = [st].[IdStudent]
	INNER JOIN [dbo].[Class] cl ON [cl].[IdClass] = [re].[IdClass]
	INNER JOIN [dbo].[Course] co ON [co].[IdCourse] = [cl].[IdCourse]
	AND [re].[Status] = 0
	ORDER BY [cl].[IdClass] ASC
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
-- Thu tuc update thanh toan cua ban DangKy
CREATE PROC [UpdateExpense] @idStudent INT, @idClass INT, @status BIT
AS
BEGIN
	UPDATE [dbo].[Register] SET [Status] = @status WHERE [IdStudent] = @idStudent and [IdClass] = @idClass
END
GO
------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetSession 3
CREATE PROC [GetSession] (@iDClass INT)
AS
BEGIN
	SELECT [Session]
	FROM [dbo].[Schedule]
	WHERE [Day] = CONVERT(DATE, GETDATE()) 
	AND [IdClass] = @iDClass
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetNameCource 1
CREATE PROC [GetNameCource] (@iDClass INT)
AS
BEGIN
	DECLARE @iDCource INT
	SET @iDCource = [dbo].[GetIdCourse](@iDClass)
	SELECT [NameCourse]
	FROM [dbo].[Course]
	WHERE [IdCourse] = @iDCource
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetIDClass 1, 2
CREATE PROC [GetIDClass] (@iDTeacher INT, @shift INT)
AS
BEGIN
	SELECT [Class].[IdClass]
	FROM [dbo].[Schedule], [dbo].[Class] 
	WHERE [Day] = CONVERT(DATE, GETDATE())
	AND [IdTeacher] = @iDTeacher
	AND [Schedule].[IdClass] = [Class].[IdClass] 
	AND [Shift] = @shift
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC InsertAbsent 1, 1, 1
CREATE PROC [InsertAbsent] (@iDClass INT, @session INT)
AS
BEGIN
	DELETE [dbo].[Absent]
	WHERE [IdClass] = @iDClass
	AND [Session] = @session
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetListClasses 4
CREATE PROC [GetListClasses] (@type INT) -- 0 = lấy All, 1 = 2-4-6, 2 = 3-5-7
AS
BEGIN
	IF (@type = 0)
		SELECT * FROM [dbo].[Class]
	ELSE IF (@type = 1)
		SELECT * FROM [dbo].[Class] WHERE [DOW] = '2-4-6'
	ELSE
		SELECT * FROM [dbo].[Class] WHERE [DOW] = '3-5-7'
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetListLikeClasses 0, '2'
CREATE PROC [GetListLikeClasses] (@type INT, @likeName VARCHAR(30))
AS
BEGIN
	DECLARE @sql VARCHAR(max)
	IF (@type = 0)
		SET @sql = 'SELECT * FROM [dbo].[Class] WHERE [IdCourse] LIKE ''%' + @likeName + '%'''
	ELSE IF (@type = 1)
		SET @sql = 'SELECT * FROM [dbo].[Class] WHERE [DOW] = ''2-4-6'' AND [IdCourse] LIKE ''%' + @likeName + '%'''
	ELSE
		SET @sql = 'SELECT * FROM [dbo].[Class] WHERE [DOW] = ''3-5-7'' AND [IdCourse] LIKE ''%' + @likeName + '%'''
	EXEC (@sql)
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC UpdateClasses 2, 20
CREATE PROC [UpdateClasses] (@id INT, @number INT)
AS
BEGIN
	UPDATE [dbo].[Class] 
	SET [NOSE] = @number 
	WHERE [IdClass] = @id
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC InsertClass 20, 30, 2, '2-4-6', 2
CREATE PROC [InsertClass] (@iD INT, @number INT, @shift INT, @DOW VARCHAR(5), @course INT)
AS 
BEGIN
	INSERT [dbo].[Class]	        
	VALUES  (@iD, @number, @shift , @DOW, @course)
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetNameCource_ 1
CREATE PROC [GetNameCource_] (@ID INT)
AS
BEGIN
	SELECT [NameCourse] 
	FROM [dbo].[Course] 
	WHERE [IdCourse] = @ID
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetListCource
CREATE PROC [GetListCource] 
AS
BEGIN
	SELECT [IdCourse]
	FROM [dbo].[Course]
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetListCources 1
CREATE PROC [GetListCources] (@type INT) -- 0 = lấy All, 1 = 2-4-6, 2 = 3-5-7
AS
BEGIN
	IF (@type = 0)
		SELECT * FROM [dbo].[Course]
	ELSE IF (@type = 1)
		SELECT * FROM [dbo].[Course] WHERE [Status] = 1
	ELSE
		SELECT * FROM [dbo].[Course] WHERE [Status] = 0
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetListLikeCource 1, 'a'
CREATE PROC [GetListLikeCource] (@type INT, @likeName VARCHAR(30))
AS
BEGIN
	DECLARE @sql VARCHAR(max)
	IF (@type = 0)
		SET @sql = 'SELECT * FROM [dbo].[Course] WHERE TenKhoaHoc LIKE ''%' + @likeName + '%'''
	ELSE IF (@type = 1)
		SET @sql = 'SELECT * FROM [dbo].[Course] WHERE [Status] = 1 AND  [NameCourse] LIKE ''%' + @likeName + '%'''
	ELSE
		SET @sql = 'SELECT * FROM [dbo].[Course] WHERE [Status] = 0 AND  [NameCourse] LIKE ''%' + @likeName + '%'''
	EXEC (@sql)
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC UpdateCource 1, N'nam', 23423423, 34
CREATE PROC [UpdateCource] (@iD INT, @name NVARCHAR(50), @tuition INT, @no INT)
AS
BEGIN
	UPDATE [dbo].[Course]
	SET [NameCourse] = @name, 
		[Tuition] = @tuition, 
		[NOS] = @no 
	WHERE [IdCourse] = @iD
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC UpdateStatusCource 1, 1
CREATE PROC [UpdateStatusCource] (@iD INT, @status INT)
AS
BEGIN
	UPDATE [dbo].[Course]
	SET [Status] = @status
	WHERE [IdCourse] = @iD
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC InsertCource 1, N'nam', 1, 1
CREATE PROC [InsertCource] (@iD INT, @name NVARCHAR(50), @no INT, @tuition INT)
AS
BEGIN
	INSERT [dbo].[Course] ([IdCourse], [NameCourse], [NOS], [Tuition])
	VALUES  (@iD , @name, @no, @tuition)
END
GO

-- Store Procedure Attendance
CREATE PROC [GetClassList] (@idClass VARCHAR(10), @session VARCHAR(10))
AS 
BEGIN
	SELECT * FROM [dbo].[GetListOfClass](@idClass, @session)
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
-- Enroll In Class
CREATE PROC [GetListClass] (@id INT, @shift VARCHAR(10), @DOW VARCHAR(6), @idCou INT)
AS BEGIN
	IF (@shift = 'All' AND @DOW = 'All' AND @idCou = 0 )
	BEGIN
		SELECT * FROM [dbo].[ListClass]
	END
    ELSE IF (@shift = 'All' AND @DOW = 'All')
	BEGIN
		SELECT * FROM [dbo].[ListClass] WHERE [IdCourse] = @idcou
	END
	ELSE IF (@shift = 'All' AND @idCou = 0)
	BEGIN
		SELECT * FROM [dbo].[ListClass] WHERE [DOW] = @DOW
	END
	ELSE IF (@DOW = 'All' AND @idCou = 0)
	BEGIN
		SELECT * FROM [dbo].[ListClass] WHERE [Shift] = @shift
	END
	ELSE IF (@shift = 'All')
	BEGIN
		SELECT * FROM [dbo].[ListClass] WHERE  [DOW] = @DOW AND [IdCourse] = @idCou
	END
	ELSE IF (@DOW = 'All')
	BEGIN
		SELECT * FROM [dbo].[ListClass] WHERE [Shift] = @shift AND [IdCourse] = @idCou
	END
	ELSE IF (@idCou = 0)
	BEGIN
		SELECT * FROM [dbo].[ListClass] WHERE [Shift] = @shift AND [DOW] = @DOW
	END
	ELSE 
		SELECT * FROM [dbo].[ListClass] WHERE [Shift] = @shift AND [DOW] = @DOW AND [IdCourse] = @idCou
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--GET Enrolled 
CREATE PROC [GetEnrolled] (@id INT, @idCou INT)
AS BEGIN 
	SELECT COUNT(*) 
	FROM [dbo].[Register] 
	WHERE [IdStudent] = @id 
	AND [IdClass] = @idCou	
END
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- GET List Cources Name
CREATE PROC [GetListCourceName] 
AS BEGIN
	SELECT [IdCourse], [NameCourse] 
	FROM [dbo].[Course] 
END
GO

-----------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetListClassAbsent 11
CREATE PROC [GetListClassAbsent] @idStudent INT
AS BEGIN
	SELECT DISTINCT [IdClass]
	FROM [dbo].[Absent]
	WHERE [IdStudent] = @idStudent
END
GO
-----------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetListSessionAbsent 11, 1
CREATE PROC [GetListSessionAbsent] @idStudent INT, @idClass INT
AS BEGIN
	SELECT [Session]
	FROM [dbo].[Absent]
	WHERE [IdStudent] = @idStudent
	AND [IdClass] = @idClass
END
GO
------------------------------------------------------------------------------------------------------------------------------------------
--EXEC GetClassAbsent 3, 23
CREATE PROC [GetClassAbsent] @idClass INT, @session INT
AS BEGIN
	SELECT [IdTeacher], [IdClass], [Session], [Day], [NameClassRoom]
	FROM [dbo].[Schedule] INNER JOIN [dbo].[ClassRoom]
	ON [IdClassRoom] = [IdRoom]
	WHERE [Session] = @session
	AND [IdClass] IN (SELECT [IdClass]
					FROM [dbo].[Class]
					WHERE [IdCourse] = (SELECT [dbo].[GetIdCourse](@idClass)))
	AND [IdClass] != @idClass
	AND [Day] > GETDATE()
END
GO
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROC [CheckAbsent] @idStudent INT, @idClass INT, @session INT
AS BEGIN
	SELECT COUNT([MakeUpClass])
	FROM [dbo].[Absent]
	WHERE [IdStudent] = @idStudent
	AND [IdClass] = @idClass
	AND [Session] = @session
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROC [EnrollAbsent] @idStudent INT, @idClass INT, @session INT, @makeupClass INT
AS BEGIN
	UPDATE [dbo].[Absent]
	SET [MakeUpClass] = @makeupClass
	WHERE [IdStudent] = @idStudent
	AND [IdClass] = @idClass
	AND [Session] = @session
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROC [UnenrollAbsent] @idStudent INT, @idClass INT, @session INT
AS BEGIN
	UPDATE [dbo].[Absent]
	SET [MakeUpClass] = NULL
	WHERE [IdStudent] = @idStudent
	AND [IdClass] = @idClass
	AND [Session] = @session
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--Delete Enroll
--EXEC DeleteEnroll 
CREATE PROC [DeleteEnroll] (@id INT, @idCla INT)
AS BEGIN 
	DELETE [dbo].[Register]
	WHERE [IdStudent] = @id 
	AND [IdClass] = @idCla
END
GO
------------------------------------------------------------------------------------------------------------------------------------------
--Insert Enroll
CREATE PROC [InsertEnroll] (@id INT, @idCla INT)
AS BEGIN 
	INSERT [dbo].[Register]
	VALUES  (@id, @idCla, 0)
END
GO
------------------------------------------------------------------------------------------------------------------------------------------
--GetListNameCourse
CREATE PROC [GetListNameCourse]--GetListNameCource
AS BEGIN 
	SELECT [NameCourse], [IdCourse] 
	FROM [dbo].[Course]
END 
GO  
------------------------------------------------------------------------------------------------------------------------------------------
--EXEC CheckEnroll 1, 1
CREATE PROC [CheckEnroll] (@iDStudent INT, @iDClass INT)
AS
BEGIN
	SELECT COUNT(*) 
	FROM [dbo].[Register]
	WHERE [IdStudent] = @iDStudent 
	AND [IdClass] = @iDClass
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
--EXEC CheckClassEnable 2
CREATE PROC [CheckClassEnable] (@iDClass INT)
AS
BEGIN
	SELECT COUNT(*) 
	FROM (SELECT [IdClass]
		  FROM [dbo].[Schedule] 
		  WHERE [IdClass] = @iDClass
		  GROUP BY [IdClass] 
		  HAVING MIN([Day]) >= CONVERT(DATE, GETDATE())) AS Q
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROC [GetIdUser] @user VARCHAR(32)--LayID
AS
BEGIN
	SELECT [IdAccount] 
	FROM [Account]
	WHERE [UserName] = @user
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
--GetScheduleOfWeek
CREATE PROC [GetScheduleOfWeek] (@IDUser VARCHAR(5) NULL , @dateStart VARCHAR(12) , @dateEnd VARCHAR(12))
AS
BEGIN
	DECLARE @sql VARCHAR(MAX)
	IF @IDUser != 0
		SET @sql = CONCAT('SELECT * FROM [dbo].[Schedule_',@IDUser, '] WHERE [Day] >= ''', @dateStart, ''' AND [Day] <= ''', @dateEnd, '''')
	ELSE
		SET @sql = CONCAT('SELECT * FROM [dbo].[Schedule_] WHERE [Day] >= ''', @dateStart, ''' AND [Day] <= ''', @dateEnd, '''')
	EXEC(@sql)
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- GetSchdule
CREATE PROC [GetSchedule] (@iDClass VARCHAR(10), @day VARCHAR(15), @session VARCHAR(50), @allDay BIT)
AS
BEGIN
    DECLARE @sql VARCHAR(MAX), @exec VARCHAR(MAX)

	SET @sql = 'SELECT * FROM [dbo].[Schedule_] WHERE [Day] >= GETDATE()'

	IF @allDay = 'False' AND @session = 'All' AND @iDClass = 'All'
		SET @exec =  @sql

	ELSE IF @allDay = 'False' AND @iDClass = 'All'
		SET @exec = CONCAT(@sql, ' AND [Session] = ', @session)

	ELSE IF @allDay = 'False' AND @session = 'All'
		SET @exec = CONCAT(@sql , ' AND [IdClass] = ', @iDClass)

	ELSE IF @iDClass = 'All' AND @session = 'All'
		SET @exec = CONCAT(@sql , ' AND [Day] = ''', @day, '''')

	ELSE IF @allDay = 'False'
		SET @exec = CONCAT(@sql , ' AND [IdClass] = ', @iDClass, ' AND [Session] = ', @session)

	ELSE IF @iDClass = 'All'
		SET @exec = CONCAT(@sql, ' AND [Day] = ''', @day, '''' , ' AND [Session] = ', @session)

	ELSE IF @session = 'All'
		SET @exec = CONCAT(@sql, ' AND [Day] = ''', @day, '''' , ' AND [Session] = ', @iDClass)

	ELSE
		SET @exec = CONCAT(@sql, ' AND [Day] = ''', @day, '''' , ' AND [Session] = ', @iDClass, ' AND [Session] = ', @session)

	EXEC(@exec)
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
--GetListClassSche
CREATE PROC [GetListClassSche] 
AS
BEGIN
    SELECT CONVERT(VARCHAR(10), [IdClass]) AS IdClass
	FROM [dbo].[Class]
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- GetListSession
CREATE PROC [GetListSession](@iDClass VARCHAR(10))
AS
BEGIN
	DECLARE @sql VARCHAR(MAX)
    IF @iDClass = 'All'
		SELECT MAX([Session]) FROM [dbo].[Schedule_]

	ELSE
	BEGIN
	    SET @sql = CONCAT('SELECT CONVERT(VARCHAR(10), [Session]) AS [Session] FROM [dbo].[Schedule_] WHERE [IdClass] = ', @iDClass)
		EXEC(@sql)
	END	
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- DeleteSchedule
CREATE PROC [DeleteSchedule]( @iDClass INT , @session int)
AS
BEGIN
    DELETE [dbo].[Schedule] WHERE [IdClass] = @iDClass AND [Session] = @session
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- GetHocVien
CREATE PROC [GetStudent] (@idStudent INT)--GetHocVien
AS
BEGIN
	SELECT * 
	FROM [dbo].[Student] INNER JOIN [dbo].[Account]
	ON [IdAccount] = [IdStudent]
	WHERE [IdStudent] = @idStudent
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- GetGiaoVien
CREATE PROC [GetTeacher] (@idTeacher INT)--GetGiaoVien
AS
BEGIN
	SELECT * 
	FROM [dbo].[Teacher] INNER JOIN [dbo].[Account]
	ON [IdAccount] = [IdTeacher]
	WHERE [IdTeacher] = @idTeacher
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- CheckUserName for Teacher , Student
CREATE PROC [CheckUserName] (@userName VARCHAR(32))
AS
BEGIN
    SELECT COUNT(*) FROM [dbo].[Account] WHERE [UserName] = @userName
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- GetListTeachers
CREATE PROC [GetListTeachers]
AS
BEGIN
    SELECT *
	FROM [dbo].[Teacher]
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
--GetListLikeTeacher
CREATE PROC [GetListLikeTeacher] (@likeName NVARCHAR(50))
AS
BEGIN
	DECLARE @sql VARCHAR(MAX)
	SET @sql = CONCAT('SELECT * FROM [dbo].[Teacher] WHERE [NameTeacher] LIKE ','''' , '%', @likeName , '%', '''')
	EXEC(@sql)
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- InsertTeacher
CREATE PROC [InsertTeacher](@id int, @userName VARCHAR(32), @pass VARCHAR(32), @name NVARCHAR(50), @phoneNumber VARCHAR(10), @address NVARCHAR(50), @salary int)
AS
BEGIN
	UPDATE [dbo].[PasswordOld] SET [Pass] = '000000'
    INSERT INTO [dbo].[Account] VALUES(@id , @userName , @pass , 3)
	INSERT INTO [dbo].[Teacher] VALUES(@id , @name , @phoneNumber, @address, @salary)
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- UpdateTeacher
CREATE PROC [UpdateTeacher](@id INT , @name NVARCHAR(50), @phoneNumber VARCHAR(10), @address NVARCHAR(50), @salary INT, @pass VARCHAR(32), @passOld VARCHAR(32))
AS
BEGIN
    UPDATE [dbo].[Teacher]
	SET [NameTeacher] = @name , [PhoneNumber] = @phoneNumber , [Address] = @address, [Salary] = @salary
	WHERE [IdTeacher] = @id
	IF (@pass != '0')
	BEGIN
		UPDATE [PasswordOld] 
		SET [pass] = @passOld
		UPDATE [dbo].[Account]
		SET [Password] = @pass
		WHERE [IdAccount] = @id
	END
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
--GetListStudents
CREATE PROC [GetListStudents]
AS
BEGIN
    SELECT * 
	FROM [dbo].[Student]
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
--  GetListLikeStudent
CREATE PROC [GetListLikeStudent] (@likeName NVARCHAR(50))
AS
BEGIN
	DECLARE @sql VARCHAR(MAX)
	SET @sql = CONCAT(' SELECT * FROM [dbo].[Student] WHERE [FullName] LIKE ','''' , '%', @likeName , '%', '''')
	EXEC(@sql)
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
-- InsertStudent
CREATE PROC [InsertStudent] (@id int, @userName VARCHAR(32), @pass VARCHAR(32), @name NVARCHAR(50), @phoneNumber VARCHAR(10), @address NVARCHAR(50), @email VARCHAR(50), @birthDate VARCHAR(12))
AS
BEGIN
	UPDATE [dbo].[PasswordOld] SET [Pass] = '000000'
    INSERT INTO [dbo].[Account] VALUES(@id , @userName , @pass , 4)
	INSERT INTO [dbo].[Student] VALUES(@id , @name , @phoneNumber, @address, @email, @birthDate)
END
GO

--------------------------------------------------------------------------------------------------------------------------------------------
--UpdateStudent
CREATE PROC UpdateStudent(@id INT, @name NVARCHAR(50), @phoneNumber VARCHAR(10), @address NVARCHAR(50), @email VARCHAR(50), @birthDate VARCHAR(12), @pass VARCHAR(32), @passOld VARCHAR(32))
AS
BEGIN
    UPDATE [dbo].[Student]
	SET [FullName] = @name , [PhoneNumber] = @phoneNumber , [Address] = @address, [Email] = @email, [DOB] = @birthDate
	WHERE [IdStudent] = @id
	IF (@pass != '0')
	BEGIN 
		UPDATE [PasswordOld] 
		SET [pass] = @passOld
		UPDATE [dbo].[Account]
		SET [Password] = @pass
		WHERE [IdAccount] = @id
	END
END
GO

---------------------------------------------------------------------------------------------------------------------------------------------
--STORE PROCEDURE Phân Quyền
CREATE PROC [UserAuthorization] (@username VARCHAR(32), @pass VARCHAR(32), @oldPass VARCHAR(32), @type INT) --phanQuyen
AS BEGIN
	DECLARE @sql VARCHAR(max)

	IF (@type = 3) --Giáo viên
	BEGIN 
		IF (@oldPass = '0')
			SET @sql=' ALTER LOGIN '+@username+' WITH Password = ''' + @pass + ''''
		ELSE IF ((SELECT COUNT(*) FROM master.sys.syslogins where name = @username) > 0)
			SET @sql=' ALTER LOGIN '+@username+' WITH Password = ''' + @pass + ''' Old_Password = ''' + @oldPass + ''''
		ELSE
			SET @sql=' CREATE LOGIN '+@username+' WITH Password = ''' + @pass + ''''
		EXEC (@sql) 
		IF ((SELECT COUNT(*) FROM [EnglishCenterDB].sys.database_principals WHERE type = N'S' AND name = @username) = 0)
		BEGIN 
			SET @sql=' CREATE USER '+@username+' FOR LOGIN ' + @username
			EXEC (@sql)
			SET @sql= CONCAT('sp_addrolemember ', '''role_teacher'',', '''', @username, '''')
			EXEC (@sql)
		END
	END 
	ELSE IF (@type = 4) --Học Sinh
	BEGIN 
		IF (@oldPass = '0')
			SET @sql=' ALTER LOGIN '+@username+' WITH Password = ''' + @pass + ''''
		ELSE IF ((SELECT COUNT(*) FROM master.sys.syslogins where name = @username) > 0)
			SET @sql=' ALTER LOGIN '+@username+' WITH Password = ''' + @pass + ''' Old_Password = ''' + @oldPass + ''''
		ELSE
			SET @sql=' CREATE LOGIN '+@username+' WITH Password = ''' + @pass + ''''
		EXEC (@sql) 
		IF ((SELECT COUNT(*) FROM [EnglishCenterDB].sys.database_principals WHERE type = N'S' AND name = @username) = 0)
		BEGIN
			SET @sql=' CREATE USER '+@username+' FOR LOGIN ' + @username
			EXEC (@sql) 
			SET @sql= CONCAT('sp_addrolemember ', '''role_student'',', '''', @username, '''')
			EXEC (@sql)
		END
	END 
	ELSE IF (@type = 1) --Admin
	BEGIN 
		IF ((SELECT COUNT(*) FROM master.sys.syslogins where name = @username) > 0)
			SET @sql=' ALTER LOGIN '+@username+' WITH Password = ''' + @pass + ''' Old_Password = ''' + @oldPass + ''''
		ELSE
			SET @sql=' CREATE LOGIN '+@username+' WITH Password = ''' + @pass + ''''
		EXEC (@sql) 
		IF ((SELECT COUNT(*) FROM [EnglishCenterDB].sys.database_principals WHERE type = N'S' AND name = @username) = 0)
		BEGIN
			SET @sql=' CREATE USER '+@username+' FOR LOGIN ' + @username
			EXEC (@sql) 
			SET @sql= CONCAT('sp_addrolemember ', '''db_owner'',', '''', @username, '''')
			EXEC (@sql)
		END
	END 
END
GO