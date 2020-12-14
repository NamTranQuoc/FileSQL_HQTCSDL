USE [EnglishCenterDB]
GO

-- Tạo role cho Giáo Viên
CREATE ROLE [role_teacher]

GO
---------------------------------------------------------------------------------------------------------------------------------------------
-- Tạo role cho Học Sinh
CREATE ROLE [role_student]

GO
---------------------------------------------------------------------------------------------------------------------------------------------
-- Tạo quyền cho Khách
IF ((SELECT COUNT(*) FROM master.sys.syslogins where name = 'login_guest') > 0)
	DROP LOGIN login_guest
GO
IF EXISTS (SELECT name FROM [EnglishCenterDB].sys.database_principals WHERE type = N'S' AND name = 'login_guest')  
	DROP USER login_guest
GO
CREATE LOGIN login_guest WITH PASSWORD = '1@34a'
GO
CREATE USER login_guest FOR LOGIN login_guest
GO

---------------------------------------------------------------------------------------------------------------------------------------------
--Cấp quyền
---------------------------------------------------------------------------------------------------------------------------------------------
-- Quyền cho Giáo Viên 
--GRANT SELECT ON dbo.PhongHoc TO role_giaovien 
GRANT EXEC ON [GetDayMaxOfSchedule] TO [role_teacher]
GRANT EXEC ON [GetTeacher] TO [role_teacher]
GRANT EXEC ON [GetScheduleOfWeek] TO [role_teacher]
GRANT EXEC ON [GetSession] TO [role_teacher]
GRANT SELECT ON [GetListOfClass] TO [role_teacher]
GRANT EXEC ON [GetNameCource] TO [role_teacher]
GRANT EXEC ON [GetIDClass] TO [role_teacher]
GRANT EXEC ON [CheckAbsent] TO [role_teacher]
GRANT EXEC ON [InsertAbsent] TO [role_teacher]
GRANT EXEC ON [AddAbsent] TO [role_teacher]

---------------------------------------------------------------------------------------------------------------------------------------------
-- Quyền cho Học Sinh
--GRANT SELECT ON dbo.PhongHoc TO role_hocsinh
GRANT EXEC ON [GetDayMaxOfSchedule] TO [role_student]
GRANT EXEC ON [GetScheduleOfWeek] TO [role_student]
GRANT EXEC ON [GetStudent] TO [role_student]
GRANT EXEC ON [GetListClasses] TO [role_student]
GRANT EXEC ON [GetListCourceName] TO [role_student]
GRANT EXEC ON [GetListClassAbsent] TO [role_student]
GRANT EXEC ON [GetListSessionAbsent] TO [role_student]
GRANT EXEC ON [GetClassAbsent] TO [role_student]
GRANT EXEC ON [CheckAbsent] TO [role_student]
GRANT EXEC ON [EnrollAbsent] TO [role_student]
GRANT EXEC ON [UnenrollAbsent] TO [role_student]
GRANT EXEC ON [CheckEnroll] TO [role_student]
GRANT EXEC ON [GetEnrolled] TO [role_student]
GRANT EXEC ON [GetListCourceName] TO [role_student]
GRANT EXEC ON [CheckClassEnable] TO [role_student]
GRANT EXEC ON [DeleteEnroll] TO [role_student]
GRANT EXEC ON [InsertEnroll] TO [role_student]
GRANT EXEC ON [GetListClass] TO [role_student]

---------------------------------------------------------------------------------------------------------------------------------------------
-- Quyền của Khách
--GRANT SELECT ON dbo.PhongHoc TO Khach 
GRANT EXEC ON [GetListNameCourse] TO login_guest
GRANT EXEC ON [GetClassOfCourse] TO login_guest
GRANT EXEC ON [CheckLogin] TO login_guest
GRANT EXEC ON [GetIdUser] TO login_guest
GRANT EXEC ON [AutomaticCodeGeneration] TO login_guest
GRANT EXEC ON [InsertStudent] TO login_guest
--GRANT EXEC ON dbo.phanQuyen TO login_guest