USE TrungTamAnhNgu
go

---------------------------------------------------------------------------------------------------------------------------------------------
--Phần Quyền
---------------------------------------------------------------------------------------------------------------------------------------------
-- Quyền cho Giáo Viên 
--GRANT SELECT ON dbo.PhongHoc TO role_giaovien 
GRANT EXEC ON NgayLonNhatCuaLichHoc TO role_giaovien
GRANT EXEC ON GetGiaoVien TO role_giaovien
GRANT EXEC ON GetScheduleOfWeek TO role_giaovien
GRANT EXEC ON GetSession TO role_giaovien
GRANT SELECT ON DanhSachLopTheoBuoi TO role_giaovien
GRANT EXEC ON GetNameCource TO role_giaovien
GRANT EXEC ON GetIDClass TO role_giaovien
GRANT EXEC ON CheckAbsent TO role_giaovien
GRANT EXEC ON InsertAbsent TO role_giaovien
GRANT EXEC ON ThemBuoiVang TO role_giaovien

---------------------------------------------------------------------------------------------------------------------------------------------
-- Quyền cho Học Sinh
--GRANT SELECT ON dbo.PhongHoc TO role_hocsinh
GRANT EXEC ON NgayLonNhatCuaLichHoc TO role_hocsinh
GRANT EXEC ON GetScheduleOfWeek TO role_hocsinh
GRANT EXEC ON GetHocVien TO role_hocsinh
GRANT EXEC ON GetListClass TO role_hocsinh
GRANT EXEC ON GetListCourceName TO role_hocsinh
GRANT EXEC ON GetListClassAbsent TO role_hocsinh
GRANT EXEC ON GetListSessionAbsent TO role_hocsinh
GRANT EXEC ON GetClassAbsent TO role_hocsinh
GRANT EXEC ON CheckAbsent TO role_hocsinh
GRANT EXEC ON EnrollAbsent TO role_hocsinh
GRANT EXEC ON UnenrollAbsent TO role_hocsinh
GRANT EXEC ON CheckEnroll TO role_hocsinh
GRANT EXEC ON GetEnrolled TO role_hocsinh
GRANT EXEC ON GetListCourceName TO role_hocsinh
GRANT EXEC ON CheckClassEnable TO role_hocsinh
GRANT EXEC ON DeleteEnroll TO role_hocsinh
GRANT EXEC ON InsertEnroll TO role_hocsinh

---------------------------------------------------------------------------------------------------------------------------------------------
-- Quyền của Khách
--GRANT SELECT ON dbo.PhongHoc TO Khach 
GRANT EXEC ON GetListNameCource TO Khach
GRANT EXEC ON LopTheoKhoaHoc TO Khach
GRANT EXEC ON KienTraDangNhap TO Khach
GRANT EXEC ON LayID TO Khach
GRANT EXEC ON TaoMaTuDong TO Khach
GRANT EXEC ON InsertStudent TO Khach
GRANT EXEC ON dbo.phanQuyen TO Khach