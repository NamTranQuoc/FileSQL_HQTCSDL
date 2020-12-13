USE [EnglishCenterDB]
GO


-- tạo view lịch học của học viên được thêm vào
CREATE TRIGGER [CreateScheduleStudentTrigger] --TaoLichTheoHocVien
ON [dbo].[Student]
AFTER INSERT
AS
BEGIN 
	DECLARE @id INT, @sql VARCHAR(MAX), @userName VARCHAR(32)
	SELECT @id = [Inserted].[IdStudent]
	FROM [Inserted]
	SELECT @userName = [UserName]
	FROM [dbo].[Account]
	WHERE [IdAccount] = @id
	SET @sql = 'CREATE VIEW Schedule_' + CONVERT(VARCHAR(10), @id) + ' AS (SELECT * FROM [CreateScheduleOfStudent] (' + CONVERT(VARCHAR(10), @id) + '))'
	EXECUTE (@sql)
	SET @sql = 'GRANT SELECT ON [dbo].[Schedule_' +CONVERT(VARCHAR(10), @id) + '] TO ' + @userName
	EXEC (@sql)
END
GO

------------------------------------------------------------------------------------------------------------
-- tạo view lịch giảng dạy của giáo viên khi giáo viên được thêm vào
CREATE TRIGGER [CreateScheduleTeacherTrigger]--TaoLichTheoGiaoVien
ON [dbo].[Teacher]
AFTER INSERT
AS
BEGIN
	DECLARE @id INT, @sql VARCHAR(MAX), @userName VARCHAR(32)
	SELECT @id = [Inserted].[IdTeacher]
	FROM [Inserted]
	SELECT @userName = [UserName]
	FROM [dbo].[Account]
	WHERE [IdAccount] = @id
	SET @sql = 'CREATE VIEW [Schedule_' + CONVERT(VARCHAR(10), @id) + '] AS (SELECT * FROM [CreateScheduleOfTeacher] (' + CONVERT(VARCHAR(10), @id) + '))'
	EXECUTE (@sql)
	SET @sql = 'GRANT SELECT ON [dbo].[Schedule_' +CONVERT(VARCHAR(10), @id) + '] TO ' + @userName
	EXEC (@sql)
END
GO

------------------------------------------------------------------------------------------------------------
-- trigger update, insert Lịch học
-- cùng ca học, ngày học thì phòng học phải khác nhau (một phong chỉ được một lớp học).
-- ngày học trong lịch học phải trùng vào những ngày học trong tuần của lớp học đó 
-- (vd: lớp học đó có ngày học trong tuần là thứ 2-4-6 thì ngày nhập trong lịch học phải rơi vào thứ 2, thứ 4 hoặc thứ 6).
CREATE TRIGGER [CheckScheduleTrigger]--KiemTraLichHoc
ON [dbo].[Schedule]
AFTER UPDATE, INSERT
AS
	DECLARE @test INT
	SET @test = (SELECT [dbo].[CheckDayWithWeekday]([ne].[Day], [DOW]) 
				 FROM [inserted] [ne] INNER JOIN [dbo].[Class]
				 ON  [Class].[IdClass] = [ne].[IdClass])
	IF (@test = 0)
	BEGIN
		RAISERROR ('Not with the class schedule' ,15, 1)
		ROLLBACK TRAN
	END
	ELSE 
	BEGIN
		DECLARE @NewDay DATE, @NewRoom INT, @NewClass INT
		SELECT @NewDay = [Inserted].[Day], @NewRoom = [Inserted].[IdRoom], @NewClass = [Inserted].[IdClass] 
		FROM [Inserted]
		IF ((SELECT [dbo].[CheckDayRoomClassOfSchedule](@NewDay, @NewRoom, @NewClass)) > 1)
		BEGIN
			RAISERROR ('Incorrect classroom' ,15, 1)
			ROLLBACK TRAN
        END
	END
GO

--------------------------------------------------------------------------------------------------------------
--trigger update (Khi học viên đăng kí học bù) bẳng Vắng (kiểm tra khoản cách giữa buổi học bù và buổi vắng < 30 -- lớp học bù và lớp vắng phải cùng khóa học)
CREATE TRIGGER [CheckSessionAbsentTrigger] --KiemTraBuoiHocBu
ON [dbo].[Absent]
AFTER UPDATE
AS
BEGIN
	DECLARE @KC INT, @day DATE, @absent INT, @makeupclass INT
	SELECT @day = [Day]
	FROM Inserted INNER JOIN [dbo].[Schedule]
	ON [Schedule].[Session] = [Inserted].[Session]
	AND [Schedule].[IdClass] = [Inserted].[IdClass]
	SET @KC = (SELECT [dbo].[GetDistanceToCurrentDate](@day))
	SELECT @absent = [Inserted].[IdClass], @makeupclass = [Inserted].[MakeUpClass]
	FROM Inserted
	IF ((SELECT [dbo].[GetIdCourse](@absent)) != (SELECT [dbo].[GetIdCourse](@makeupclass)))
	BEGIN
		RAISERROR ('Incorrect course' ,15, 1)
		ROLLBACK TRAN
	END	
	IF (@KC > 30)
	BEGIN
		RAISERROR ('Time limit' ,15, 1)
		ROLLBACK TRAN
	END	
END									  
GO

------------------------------------------------------------------------------------------
--không được đăng ký hai lớp cùng lịch học và lớp đã full
CREATE TRIGGER [CheckRegisterTrigger] --KiemTraDangKy
ON [dbo].[Register]
AFTER INSERT, UPDATE
AS
BEGIN 
	DECLARE @idStudent INT, @newClass INT, @test INT
	SELECT @idStudent = [Inserted].[IdStudent], @newClass = [Inserted].[IdClass]
	FROM Inserted
	SET @test = (SELECT [dbo].[CheckShiftDayOfWeek](@idStudent))
	IF (@test = 0)
	BEGIN
		RAISERROR ('Incorrect schedule', 15, 1)
		ROLLBACK TRAN
	END
	ELSE
	BEGIN
		DECLARE @real INT, @expect INT
		SET @real = [dbo].[GetStudentOfClass](@newClass)
		SELECT @expect = [NOSE]
		FROM Inserted INNER JOIN [dbo].[Class]
		ON [Class].[IdClass] = [Inserted].[IdClass]
		WHERE [Inserted].[IdClass] = @newClass
		IF (@real > @expect)
		BEGIN
			RAISERROR ('Class is full', 15, 1)
			ROLLBACK TRAN
		END
	END
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
-- tạo lịch học khi thêm lớp + tạo danh sách học viên của lớp
CREATE TRIGGER [CreateScheduleClassTrigger] --TaoLichHoc_Trigger
ON [dbo].[Class]
AFTER INSERT
AS
BEGIN
	DECLARE @idTeacher INT, @idClass INT, @sql VARCHAR(MAX)
	SELECT @idClass = [Inserted].[IdClass]
	FROM Inserted
	--tạo lịch học	
	EXECUTE [dbo].[CreateSchedule] @idClass	
	--tạo danh sách học viên của lớp
	SET @sql = 'CREATE VIEW [ListClass_' + CONVERT(VARCHAR(10), @idClass) + '] AS (SELECT * FROM [dbo].[CreateViewClass](' + CONVERT(VARCHAR(10), @idClass) + '))'
	EXECUTE (@sql)
END
GO
---------------------------------------------------------------------------------------------------------------------------------------------
--trigger mã hóa mật khẩu trước khi lưu
CREATE TRIGGER [EncodeTrigger] --MaHoa
ON [dbo].[Account]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @pass VARCHAR(32), @id INT, @username VARCHAR(32), @type INT, @oldPass VARCHAR(32)
	SELECT @pass = [Inserted].[Password], @id = [Inserted].[IdAccount], @type = [Inserted].[TypeAccount], @username = [Inserted].[UserName]
	FROM [Inserted]
	SELECT @oldPass = [pass]
	FROM [PasswordOld]
	EXEC [dbo].[UserAuthorization] @username, @pass, @oldPass, @type
	SET @pass = [dbo].[EncodeMD5](@pass)
	UPDATE [dbo].[Account]
	SET [Password] = @pass
	WHERE [IdAccount] = @id	
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------
--nếu số buổi của một khóa học tăng thì lịch tự động thêm buổi học 
--nêu số buổi của một khóa học giảm thì lịch tự xóa buổi học
CREATE TRIGGER [UpdateCourseTrigger] --UpdateKhoahoc
ON [dbo].[Course]
AFTER UPDATE
AS
BEGIN
	DECLARE @old INT, @new INT, @idCourse INT
	SELECT @old = [Deleted].[NOS], @idCourse = [Deleted].[IdCourse] FROM [Deleted]
	SELECT @new = [Inserted].[NOS] FROM [Inserted]
	IF (@new > @old)
	BEGIN
		SELECT [IdClass], IDENTITY(INT, 1, 1) AS [ID]
		INTO [ListIdClass]
		FROM [dbo].[Class]
		WHERE [IdCourse] = @idCourse
		DECLARE @i INT, @countId INT, @idClass INT
		SET @i = 1
		SELECT @countId = COUNT(*) FROM [ListIdClass]
		WHILE (@i <= @countId)
		BEGIN
			SELECT @idClass = [idClass] FROM [ListIdClass] WHERE [ID] = @i
			EXECUTE [dbo].[AddScheduleFollowCourse] @idClass
			SET @i = @i + 1
		END
		DROP TABLE [ListIdClass]
	END
	ELSE IF (@new < @old)
	BEGIN
		SELECT [IdClass], IDENTITY(INT, 1, 1) AS [ID]
		INTO [ListIdClass]
		FROM [dbo].[Class]
		WHERE [IdCourse] = @idCourse
		DECLARE @i2 INT, @countId2 INT, @idClass2 INT
		SET @i2 = 1
		SELECT @countId2 = COUNT(*) FROM [ListIdClass]
		WHILE (@i2 <= @countId2)
		BEGIN
			SELECT @idClass2 = [IdClass] FROM [ListIdClass] WHERE [ID] = @i2
			EXECUTE [dbo].[DeleteScheduleFllowCourse] @idClass2, @new, @old	
			SET @i2 = @i2 + 1	
		END
		DROP TABLE [ListIdClass]
    END
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------
--nếu một buổi trong lịch học đó xóa thì tự động sinh ra 1 buổi để bù lại buổi đã xóa
CREATE TRIGGER [DeleteScheduleTrigger] --DeleteLichHoc
ON [dbo].[Schedule]
AFTER DELETE
AS
BEGIN
	DECLARE @expect INT, @real INT
	SELECT @expect = [NOS]
	FROM [dbo].[Course], [Deleted], [dbo].[Class]
	WHERE [Course].[IdCourse] = [Class].[IdCourse]
	AND [Class].[IdClass] = [Deleted].[IdClass]

	DECLARE @idClass INT
	SELECT @idClass = [Deleted].[IdClass]
	FROM [Deleted]

	SELECT @real = COUNT(*)
	FROM [dbo].[Schedule]
	WHERE [IdClass] = @idClass

	IF (@real < @expect)
		EXECUTE [dbo].[AddSchedule] @idClass
END
GO