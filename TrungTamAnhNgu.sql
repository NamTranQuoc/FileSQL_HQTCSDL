﻿CREATE DATABASE TrungTamAnhNgu
GO

USE TrungTamAnhNgu
GO

CREATE TABLE Account
(
	IDTaiKhoan INT PRIMARY KEY,
	TaiKhoan VARCHAR(32) UNIQUE, -- tên tài khoản
	MatKhau VARCHAR(32),
	LoaiTaiKhoan INT CHECK (LoaiTaiKhoan > 0 AND LoaiTaiKhoan < 5), -- 1:Admin , 2:nhân viên, 3:Giáo viên, 4:học viên
)
GO

CREATE TABLE KhoaHoc
(
	MaKhoaHoc INT PRIMARY KEY,
	TenKhoaHoc NVARCHAR(30),
	SoBuoi INT CHECK(SoBuoi > 0),
	HocPhi INT,
	TrangThai INT DEFAULT 1 -- 1 là có sẳn; 0 là đã bị ẩn
)
GO

CREATE TABLE GiaoVien
(
	MaGiaoVien INT PRIMARY KEY REFERENCES dbo.Account(IDTaiKhoan),
	HoTen NVARCHAR(50),
	SDT CHAR(10),
	DiaChi NVARCHAR(50),
	LuongCoBan INT,
)
GO

CREATE TABLE LopHoc 
(
	MaLop INT PRIMARY KEY,
	SoHocVienDuKien INT,
	CaHoc INT CHECK(CaHoc > 0 AND CaHoc < 7), -- 1 ngày có 7 ca học từ ca 1 đến ca 6
	NgayHocTrongTuan CHAR(5) CHECK(NgayHocTrongTuan = '2-4-6' OR NgayHocTrongTuan = '3-5-7'), -- '2-4-6' or '3-5-7'
	ThuocKhoaHoc INT REFERENCES dbo.KhoaHoc(MaKhoaHoc)
	ON DELETE CASCADE
)
GO

CREATE TABLE PhongHoc
(
	IDPhong INT PRIMARY KEY,
	TenPhong CHAR(10)
)
GO

CREATE TABLE LichHoc
(
	MaGiaoVien INT REFERENCES dbo.GiaoVien(MaGiaoVien),
	MaLop INT REFERENCES dbo.LopHoc(MaLop),
	Buoi INT CHECK(Buoi > 0),
	Phong INT REFERENCES dbo.PhongHoc(IDPhong),
	NgayHoc DATE,
	PRIMARY KEY (MaGiaoVien, MaLop, Buoi)
)
GO

CREATE TABLE HocVien
(
	MaHocVien INT PRIMARY KEY REFERENCES dbo.Account(IDTaiKhoan),
	HoTen NVARCHAR(50),
	SDT CHAR(10),
	DiaChi NVARCHAR(50),
	Email VARCHAR(50),
	NgaySinh DATE,
)
GO

CREATE TABLE DangKy
(
	MaHocVien INT REFERENCES dbo.HocVien(MaHocVien),
	MaLop INT REFERENCES dbo.LopHoc(MaLop),
	TrangThaiThanhToan BIT, -- 1 = đã nộp tiền, 0 = chưa nộp tiền
)
GO

CREATE TABLE Vang
(
	MaHocVien INT REFERENCES dbo.HocVien(MaHocVien),
	MaLop INT REFERENCES dbo.LopHoc(MaLop),
	Buoi INT NOT NULL,
	HocBu INT REFERENCES dbo.LopHoc(MaLop),
	PRIMARY KEY (MaHocVien, MaLop, Buoi)
)
GO
----------------------------------------------------------------------------------------------------------------------
--FUNCTION
----------------------------------------------------------------------------------------------------------------------
--hàm lấy ra ngày lớn nhất của lịch học
--input: 0: admin, nhân viên(tất cả thời khóa biểu), các số còn lại là thời khóa biểu ứng với account
CREATE FUNCTION NgayLonNhatCuaLichHoc (@Ma INT)
RETURNS DATE
AS
BEGIN
	DECLARE @date DATE
	IF (@Ma = 0)
	BEGIN
		SELECT @date = MAX(NgayHoc) 
		FROM dbo.LichHoc
	END
    ELSE
	BEGIN
		SELECT @date = MAX(NgayHoc)
		FROM dbo.LichHoc INNER JOIN dbo.DangKy
		ON DangKy.MaLop = LichHoc.MaLop
		WHERE MaGiaoVien = @Ma
		OR MaHocVien = @Ma
	END
	SET @date = DATEADD(DAY, 7 - DATEPART(dw, @date), @date) 
	RETURN @date
END
GO

----------------------------------------------------------------------------------------------------------------------
--hàm mã hóa MD5 (đâu vào là password nhập vào, đầu ra là password đã mã hóa)
CREATE FUNCTION MaHoaMD5 (@pass VARCHAR(32))
RETURNS VARCHAR(32)
AS
BEGIN
	RETURN CONVERT(VARCHAR(32), HashBytes('MD5', @pass), 2)
END
GO

-----------------------------------------------------------------------------------------------------------------------
--kiểm tra tính đúng sai của ngày quan hệ với thứ
CREATE FUNCTION KiemTraNgayVoiThu (@Ngay DATE = NULL, @Thu CHAR(5) = NULL) -- @Thu = 0 --> 2-4-6, @Thu = 1 --> 3-5-7
RETURNS INT
AS
BEGIN
	DECLARE @ThuCuaNgay INT
	SET @ThuCuaNgay = DATEPART(WEEKDAY, @Ngay)
	IF (@Thu = '2-4-6')
	BEGIN
		IF (@ThuCuaNgay = 2 OR @ThuCuaNgay = 4 OR @ThuCuaNgay = 6)
			RETURN 1 -- đúng
	END
    ELSE
    BEGIN
		IF (@ThuCuaNgay = 3 OR @ThuCuaNgay = 5 OR @ThuCuaNgay = 7)
			RETURN 1 -- đúng
	END
	RETURN 0 -- sai
END
GO

---------------------------------------------------------------------------------------
--hàm kiểm tra toàn bộ ngày học, phòng học, lớp học của bảng lịch học có bị trùng không
CREATE FUNCTION TruyVanNgayPhongLop_LichHoc (@Ngay DATE, @Phong INT, @Lop INT)
RETURNS INT
AS
BEGIN
	DECLARE @ret INT, @Tuan CHAR(5)
	SELECT @Tuan = NgayHocTrongTuan
	FROM dbo.LopHoc
	WHERE MaLop = @Lop
	SET @ret = (SELECT COUNT(*)
				FROM dbo.LichHoc INNER JOIN dbo.LopHoc
				ON LopHoc.MaLop = LichHoc.MaLop
				WHERE NgayHoc = @Ngay AND Phong = @Phong AND NgayHocTrongTuan = @Tuan)
	RETURN @ret
END
GO

----------------------------------------------------------------------------------------------------------
--tính số ngày từ 1 ngày đến ngày hiện tại
CREATE FUNCTION KhoanCachDenHienTai (@Ngay DATE)
RETURNS INT
AS 
BEGIN
	DECLARE @ret INT
	SET @ret = (SELECT DATEDIFF(DAY, @Ngay, GETDATE()))
	RETURN @ret
END
GO

-----------------------------------------------------------------------------------------------------------
--truy vấn mã khóa học của lớp
CREATE FUNCTION LayMaKhoahoc (@MaLop INT)
RETURNS INT
AS
BEGIN
	DECLARE @ret INT
	SELECT @ret = ThuocKhoaHoc
	FROM dbo.LopHoc
	WHERE MaLop = @MaLop
	RETURN @ret
END
GO

----------------------------------------------------------------------------------------------------------
--kiểm tra trùng ca và trùng ngày học trong tuần
CREATE FUNCTION KiemTraCaVaNgayTrongTuan (@MaHS INT)
RETURNS INT
AS
BEGIN
	DECLARE @a INT, @b INT, @ret INT
	SELECT @a = COUNT(*) 
	FROM (SELECT CaHoc, NgayHocTrongTuan, NgayHoc
		  FROM dbo.DangKy, dbo.LopHoc, dbo.LichHoc
		  WHERE MaHocVien = @MaHS
		  AND LopHoc.MaLop = DangKy.MaLop
		  AND LichHoc.MaLop = LopHoc.MaLop) AS AA

	SELECT @b = COUNT(*) 
	FROM (SELECT DISTINCT CaHoc, NgayHocTrongTuan, NgayHoc
		  FROM dbo.DangKy, dbo.LopHoc, dbo.LichHoc
		  WHERE MaHocVien = @MaHS
		  AND LopHoc.MaLop = DangKy.MaLop
		  AND LichHoc.MaLop = LopHoc.MaLop) AS BB

	IF (@a != @b)
		SET @ret = 0 -- không thể đăng ký
	ELSE
		SET @ret = 1 -- có thể đăng ký
	RETURN @ret
END
GO
---------------------------------------------------------------------------------------------------------
-- tạo mã tự động
CREATE FUNCTION TaoMaTuDong (@NameTable CHAR(15))
RETURNS INT 
AS
BEGIN
	DECLARE @max INT
	SET @max = CASE @NameTable
		WHEN 'User' THEN (SELECT MAX(IDTaiKhoan) FROM dbo.Account)--giáo viên, học viên, nhân viên
		WHEN 'KhoaHoc' THEN (SELECT MAX(MaKhoaHoc) FROM dbo.KhoaHoc)
		WHEN 'LopHoc' THEN (SELECT MAX(MaLop) FROM dbo.LopHoc)
		WHEN 'PhongHoc' THEN (SELECT MAX(IDPhong) FROM dbo.PhongHoc)
		WHEN 'HocVien' THEN (SELECT MAX(MaHocVien) FROM dbo.HocVien)
		WHEN 'GiaoVien' THEN (SELECT MAX(MaGiaoVien) FROM dbo.GiaoVien)
	END
    
	SET @max = @max + 1
	RETURN @max
END
GO

------------------------------------------------------------------------------------------------------------------
--hàm tạo danh sách theo lớp
--CREATE VIEW DanhSachLop_1 AS (SELECT * FROM dbo.TaoViewLop(1))
CREATE FUNCTION TaoViewLop (@MaLop INT)
RETURNS TABLE
AS 
	RETURN SELECT HocVien.MaHocVien, HoTen, SDT, DiaChi, Email, NgaySinh
		   FROM dbo.HocVien INNER JOIN dbo.DangKy
		   ON DangKy.MaHocVien = HocVien.MaHocVien
		   WHERE MaLop = @MaLop
GO

------------------------------------------------------------------------------------------------------------------
--hàm tạo lịch giảng dạy cho giảng viên
--CREATE VIEW LichDayGiangVien_1 AS (SELECT * FROM dbo.TaoLichDayTheoGiangVien(1))
CREATE FUNCTION LichDayTheoGiangVien (@MaGiangVien INT)
RETURNS TABLE
AS
	RETURN SELECT LichHoc.MaLop, Buoi, TenPhong, NgayHoc, CaHoc
		   FROM dbo.LopHoc, dbo.LichHoc, dbo.PhongHoc
		   WHERE LichHoc.MaLop = LopHoc.MaLop
		   AND MaGiaoVien = @MaGiangVien
		   AND IDPhong = Phong
GO

----------------------------------------------------------------------------------------------------------------
--hàm tạo lịch học theo từng học viên
--CREATE VIEW Lich_1 AS (SELECT * FROM LichHocTheoHocVien(1))
CREATE FUNCTION LichHocTheoHocVien(@MaHocVien INT)
RETURNS TABLE
AS
	RETURN SELECT LichHoc.MaLop, LichHoc.Buoi, TenPhong, LichHoc.NgayHoc, CaHoc
		   FROM HocVien, DangKy, LichHoc, LopHoc, dbo.PhongHoc
		   WHERE DangKy.MaHocVien = @MaHocVien
		   AND DangKy.MaLop = LichHoc.MaLop
		   AND DangKy.MaHocVien = HocVien.MaHocVien
		   AND LopHoc.MaLop = LichHoc.MaLop
		   AND IDPhong = Phong
GO
---------------------------------------------------------------------------------------------------------
--hàm kiểm tra đăng nhập
--input: TaiKhoan, MatKhau
--output: 5 sai tài khoản hoặc mật khẩu, 1:Admin , 2:nhân viên, 3:Giáo viên, 4:học viên
CREATE FUNCTION KienTraDangNhap(@TaiKhoan VARCHAR(32), @MatKhau VARCHAR(32))
RETURNS INT
AS
BEGIN
	DECLARE @LoaiTaiKhoan INT
	SET @LoaiTaiKhoan = 5
	SET @MatKhau = dbo.MaHoaMD5(@MatKhau)
	SELECT @LoaiTaiKhoan = LoaiTaiKhoan
	FROM dbo.Account
	WHERE TaiKhoan = @TaiKhoan AND MatKhau = @MatKhau
	RETURN @LoaiTaiKhoan
END
GO
----------------------------------------------------------------------------------------------------------
-- lấy số lượng học sinh của lớp
CREATE FUNCTION SoLuongHocVienCuaLop (@MaLop INT)
RETURNS INT
AS
BEGIN
	DECLARE @SoLuong INT
	SELECT @SoLuong = COUNT(*) 
	FROM dbo.DangKy 
	WHERE MaLop = @MaLop
	RETURN @SoLuong
END
GO

----------------------------------------------------------------------------------------------------------
--kiểm tra ngày (@ngay) và ca (@ca) của giáo viên đó đã có lịch dạy chưa (@gv)
--nếu tồn tại trả về 1, không tồn tại trả về 0
CREATE FUNCTION KiemTraLichGiaoVien (@ngay DATE, @maLop INT, @gv INT)
RETURNS INT
AS
BEGIN
	DECLARE @t INT
	SELECT @t = COUNT(*)
	FROM dbo.LichHoc
	WHERE MaGiaoVien = @gv
	AND NgayHoc = @ngay
	AND MaLop = @maLop
	IF (@t = 0)
		RETURN 0
	RETURN 1
END
GO
---------------------------------------------------------------------------------------------------------
--danh sách lớp theo buổi (danh sách lớp cứng công với danh sách nhưng học viên học bù)
CREATE FUNCTION DanhSachLopTheobuoi (@MaLop INT, @Buoi INT)
RETURNS @table TABLE (MaHocVien INT, HoTen NVARCHAR(50), SDT CHAR(10), DiaChi NVARCHAR(50), Email VARCHAR(50), NgaySinh DATE)
AS
BEGIN	
	INSERT @table SELECT * FROM dbo.TaoViewLop (@MaLop)
	INSERT @table SELECT HocVien.MaHocVien, HoTen, SDT, DiaChi, Email, NgaySinh
				  FROM dbo.HocVien, (SELECT MaHocVien
									 FROM dbo.Vang
									 WHERE HocBu = @MaLop AND Buoi = @Buoi) AS Q 
				  WHERE HocVien.MaHocVien = Q.MaHocVien
	RETURN
END
GO

----------------------------------------------------------------------------------------------------------
-- PROCEDURE
----------------------------------------------------------------------------------------------------------
--tạo lịch học tự động
CREATE PROCEDURE TaoLichHoc (@MaLop INT)
AS
BEGIN
	DECLARE @SoBuoi INT, @Ngay DATE, @i INT, @Thu CHAR(5), @maGV INT
	SET @Ngay = GETDATE()
	SET @i = 1

	SELECT @SoBuoi = SoBuoi, @Thu = NgayHocTrongTuan
	FROM dbo.LopHoc INNER JOIN dbo.KhoaHoc
	ON KhoaHoc.MaKhoaHoc = LopHoc.ThuocKhoaHoc
	WHERE MaLop = @MaLop

	DECLARE @tongGV INT
	SELECT @tongGV = COUNT(*) FROM dbo.TongSoBuoiDayTheoGiaoVien

	SELECT MaGiaoVien, SL, IDENTITY(INT, 1, 1) AS ID INTO tbMaGV
	FROM dbo.TongSoBuoiDayTheoGiaoVien
	ORDER BY SL, MaGiaoVien
	
	SELECT @maGV = MaGiaoVien
	FROM tbMaGV
	WHERE ID = 1

	WHILE (@i <= @SoBuoi)
	BEGIN
		IF ((dbo.KiemTraNgayVoiThu(@Ngay, @Thu)) = 1)
		BEGIN	
			IF (dbo.KiemTraLichGiaoVien(@Ngay, @MaLop, @maGV) = 0)
			BEGIN
				DECLARE @Phong INT, @TongPhong INT
				SET @Phong = 1
				SELECT @TongPhong = COUNT(*)
				FROM dbo.PhongHoc

				WHILE (@Phong <= @TongPhong)
				BEGIN
					IF ((dbo.TruyVanNgayPhongLop_LichHoc(@Ngay, @Phong, @MaLop)) = 0)
					BEGIN					
						INSERT dbo.LichHoc VALUES (@maGV, @MaLop, @i, @Phong, @Ngay)
						SET @i = @i + 1
						BREAK
					END 
					ELSE
						SET @Phong = @Phong + 1
				END
				SET @Ngay = DATEADD(DAY, 1, @Ngay)
			END	
			ELSE
            BEGIN				
				DECLARE @dem INT, @test3 INT
				SET @test3 = 0
				SET @i = 0
				WHILE (@dem < @tongGV)
				BEGIN
					SELECT @maGV = MaGiaoVien
					FROM tbMaGV
					WHERE ID = @dem
					IF (dbo.KiemTraLichGiaoVien(@Ngay, @MaLop, @maGV) = 0)
					BEGIN
						SET @test3 = 1
						BREAK
					END
				END
				IF (@test3 = 0)
				BEGIN
					SELECT @maGV = MaGiaoVien
					FROM tbMaGV
					WHERE ID = 1
					SET @Ngay = DATEADD(DAY, 1, @Ngay)
				END
			END
		END
		ELSE 
			SET @Ngay = DATEADD(DAY, 1, @Ngay)
	END
	DROP TABLE tbMaGV
END
GO
-----------------------------------------------------------------------------------------------------------
--Thêm lịch một ngày trong lịch học bị xóa
CREATE PROCEDURE ThemLichHoc (@MaLop INT)
AS
BEGIN
	DECLARE @SoBuoi INT, @Ngay DATE, @i INT, @Thu CHAR(5), @maGV INT
	SELECT @Ngay = MAX(NgayHoc) 
	FROM dbo.LichHoc
	WHERE MaLop = @MaLop 
	SET @Ngay = DATEADD(DAY, 1, @Ngay)

	SET @i = 1

	SELECT @SoBuoi = SoBuoi, @Thu = NgayHocTrongTuan
	FROM dbo.LopHoc INNER JOIN dbo.KhoaHoc
	ON KhoaHoc.MaKhoaHoc = LopHoc.ThuocKhoaHoc
	WHERE MaLop = @MaLop

	DECLARE @tongGV INT
	SELECT @tongGV = COUNT(*) FROM dbo.TongSoBuoiDayTheoGiaoVien

	SELECT MaGiaoVien, SL, IDENTITY(INT, 1, 1) AS ID INTO tbMaGV
	FROM dbo.TongSoBuoiDayTheoGiaoVien
	ORDER BY SL, MaGiaoVien
	
	SELECT @maGV = MaGiaoVien
	FROM tbMaGV
	WHERE ID = 1

	SELECT Buoi, IDENTITY(INT, 1, 1) AS ID 
	INTO BangCu
	FROM dbo.LichHoc
	WHERE MaLop = @MaLop
	DECLARE @CountBangCu INT, @BuoiCu INT
	SELECT @CountBangCu = COUNT(*)
	FROM BangCu
	WHILE (@i <= @CountBangCu)
	BEGIN
		SELECT @BuoiCu = Buoi
		FROM BangCu
		WHERE ID = @i
		UPDATE dbo.LichHoc 
		SET Buoi = @i 
		WHERE MaLop = @MaLop AND Buoi = @BuoiCu
		SET @i = @i + 1
	END
	DROP TABLE BangCu

	WHILE (@i <= @SoBuoi)
	BEGIN
		IF ((dbo.KiemTraNgayVoiThu(@Ngay, @Thu)) = 1)
		BEGIN	
			IF (dbo.KiemTraLichGiaoVien(@Ngay, @MaLop, @maGV) = 0)
			BEGIN
				DECLARE @Phong INT, @TongPhong INT
				SET @Phong = 1
				SELECT @TongPhong = COUNT(*)
				FROM dbo.PhongHoc

				WHILE (@Phong <= @TongPhong)
				BEGIN
					IF ((dbo.TruyVanNgayPhongLop_LichHoc(@Ngay, @Phong, @MaLop)) = 0)
					BEGIN					
						INSERT dbo.LichHoc VALUES (@maGV, @MaLop, @i, @Phong, @Ngay)
						SET @i = @i + 1
						BREAK
					END 
					ELSE
						SET @Phong = @Phong + 1
				END
				SET @Ngay = DATEADD(DAY, 1, @Ngay)
			END	
			ELSE
            BEGIN				
				DECLARE @dem INT, @test3 INT
				SET @test3 = 0
				SET @i = 0
				WHILE (@dem < @tongGV)
				BEGIN
					SELECT @maGV = MaGiaoVien
					FROM tbMaGV
					WHERE ID = @dem
					IF (dbo.KiemTraLichGiaoVien(@Ngay, @MaLop, @maGV) = 0)
					BEGIN
						SET @test3 = 1
						BREAK
					END
				END
				IF (@test3 = 0)
				BEGIN
					SELECT @maGV = MaGiaoVien
					FROM tbMaGV
					WHERE ID = 1
					SET @Ngay = DATEADD(DAY, 1, @Ngay)
				END
			END
		END
		ELSE 
			SET @Ngay = DATEADD(DAY, 1, @Ngay)
	END
	DROP TABLE tbMaGV	
END
GO
------------------------------------------------------------------------------------------------------------
--thêm lịch học khi số buổi của khóa học tăng
CREATE PROCEDURE ThemLichHocTheoKhoa (@maLop INT)
AS
BEGIN
	DECLARE @SoBuoi INT, @Ngay DATE, @i INT, @Thu CHAR(5), @maGV INT
	SELECT @Ngay = MAX(NgayHoc) 
	FROM dbo.LichHoc
	WHERE MaLop = @MaLop 
	SET @Ngay = DATEADD(DAY, 1, @Ngay)
	SELECT @i = MAX(buoi) FROM dbo.LichHoc WHERE MaLop = @maLop
	SET @i = @i + 1
	
	SELECT @SoBuoi = SoBuoi, @Thu = NgayHocTrongTuan
	FROM dbo.LopHoc INNER JOIN dbo.KhoaHoc
	ON KhoaHoc.MaKhoaHoc = LopHoc.ThuocKhoaHoc
	WHERE MaLop = @MaLop

	DECLARE @tongGV INT
	SELECT @tongGV = COUNT(*) FROM dbo.TongSoBuoiDayTheoGiaoVien

	SELECT MaGiaoVien, SL, IDENTITY(INT, 1, 1) AS ID INTO tbMaGV
	FROM dbo.TongSoBuoiDayTheoGiaoVien
	ORDER BY SL, MaGiaoVien
	
	SELECT @maGV = MaGiaoVien
	FROM tbMaGV
	WHERE ID = 1

	WHILE (@i <= @SoBuoi)
	BEGIN
		IF ((dbo.KiemTraNgayVoiThu(@Ngay, @Thu)) = 1)
		BEGIN	
			IF (dbo.KiemTraLichGiaoVien(@Ngay, @MaLop, @maGV) = 0)
			BEGIN
				DECLARE @Phong INT, @TongPhong INT
				SET @Phong = 1
				SELECT @TongPhong = COUNT(*)
				FROM dbo.PhongHoc

				WHILE (@Phong <= @TongPhong)
				BEGIN
					IF ((dbo.TruyVanNgayPhongLop_LichHoc(@Ngay, @Phong, @MaLop)) = 0)
					BEGIN					
						INSERT dbo.LichHoc VALUES (@maGV, @MaLop, @i, @Phong, @Ngay)
						SET @i = @i + 1
						BREAK
					END 
					ELSE
						SET @Phong = @Phong + 1
				END
				SET @Ngay = DATEADD(DAY, 1, @Ngay)
			END	
			ELSE
            BEGIN				
				DECLARE @dem INT, @test3 INT
				SET @test3 = 0
				SET @i = 0
				WHILE (@dem < @tongGV)
				BEGIN
					SELECT @maGV = MaGiaoVien
					FROM tbMaGV
					WHERE ID = @dem
					IF (dbo.KiemTraLichGiaoVien(@Ngay, @MaLop, @maGV) = 0)
					BEGIN
						SET @test3 = 1
						BREAK
					END
				END
				IF (@test3 = 0)
				BEGIN
					SELECT @maGV = MaGiaoVien
					FROM tbMaGV
					WHERE ID = 1
					SET @Ngay = DATEADD(DAY, 1, @Ngay)
				END
			END
		END
		ELSE 
			SET @Ngay = DATEADD(DAY, 1, @Ngay)
	END
	DROP TABLE tbMaGV	
END
GO

------------------------------------------------------------------------------------------------------------
--xóa lịch học khi so buoi học của khoa học giảm
CREATE PROCEDURE XoaLichHoc (@maLop INT, @SoBuoiMoi INT, @SoBuoiCu INT)
AS
BEGIN
	WHILE (@SoBuoiMoi < @SoBuoiCu)
	BEGIN
		DELETE dbo.LichHoc
		WHERE MaLop = @maLop
		AND Buoi = @SoBuoiCu
		SET @SoBuoiCu = @SoBuoiCu - 1
	END
END
GO
------------------------------------------------------------------------------------------------------------
--thêm buổi vắng vào bẳng vắng
CREATE PROCEDURE ThemBuoiVang (@maHocVien INT, @maLop INT, @Buoi INT)
AS 
BEGIN
	INSERT dbo.Vang (MaHocVien, MaLop, Buoi) VALUES ( @maHocVien,@maLop,@Buoi)
END
GO

------------------------------------------------------------------------------------------------------------
--TRIGGER
------------------------------------------------------------------------------------------------------------
-- tạo view lịch học của học viên được thêm vào
CREATE TRIGGER TaoLichTheoHocVien
ON dbo.HocVien
AFTER INSERT
AS
BEGIN 
	DECLARE @Ma INT, @sql VARCHAR(MAX)
	SELECT @Ma = Inserted.MaHocVien
	FROM Inserted
	SET @sql = 'CREATE VIEW Lich_' + CONVERT(VARCHAR(10), @Ma) + ' AS (SELECT * FROM LichHocTheoHocVien(' + CONVERT(VARCHAR(10), @Ma) + '))'
	EXECUTE (@sql)
END
GO

------------------------------------------------------------------------------------------------------------
-- tạo view lịch giảng dạy của giáo viên khi giáo viên được thêm vào
CREATE TRIGGER TaoLichTheoGiaoVien
ON dbo.GiaoVien
AFTER INSERT
AS
BEGIN
	DECLARE @Ma INT, @sql VARCHAR(MAX)
	SELECT @Ma = Inserted.MaGiaoVien
	FROM Inserted
	SET @sql = 'CREATE VIEW Lich_' + CONVERT(VARCHAR(10), @Ma) + ' AS (SELECT * FROM LichDayTheoGiangVien(' + CONVERT(VARCHAR(10), @Ma) + '))'
	EXECUTE (@sql)
END
GO

------------------------------------------------------------------------------------------------------------
-- trigger update, insert Lịch học
-- cùng ca học, ngày học thì phòng học phải khác nhau (một phong chỉ được một lớp học).
-- ngày học trong lịch học phải trùng vào những ngày học trong tuần của lớp học đó 
-- (vd: lớp học đó có ngày học trong tuần là thứ 2-4-6 thì ngày nhập trong lịch học phải rơi vào thứ 2, thứ 4 hoặc thứ 6).
CREATE TRIGGER KiemTraLichHoc
ON dbo.LichHoc
AFTER UPDATE, INSERT
AS
	DECLARE @test INT
	SET @test = (SELECT dbo.KiemTraNgayVoiThu(ne.NgayHoc, dbo.LopHoc.NgayHocTrongTuan) 
				 FROM inserted ne INNER JOIN dbo.LopHoc
				 ON LopHoc.MaLop = ne.MaLop)
	IF (@test = 0)
	BEGIN
		PRINT (N'Lỗi ngày nhập không trung với lịch của lớp')
		ROLLBACK TRAN
	END
	ELSE 
	BEGIN
		DECLARE @NewNgay DATE, @NewPhong INT, @NewLop INT
		SELECT @NewNgay = NgayHoc, @NewPhong = Phong, @NewLop = MaLop 
		FROM Inserted
		IF ((SELECT dbo.TruyVanNgayPhongLop_LichHoc(@NewNgay, @NewPhong, @NewLop)) > 1)
		BEGIN
			PRINT (N'Trùng phòng học')
			ROLLBACK TRAN
        END
	END
GO

--------------------------------------------------------------------------------------------------------------
--trigger update (Khi học viên đăng kí học bù) bẳng Vắng (kiểm tra khoản cách giữa buổi học bù và buổi vắng < 30 -- lớp học bù và lớp vắng phải cùng khóa học)
CREATE TRIGGER KiemTraBuoiHocBu
ON dbo.Vang
AFTER UPDATE
AS
BEGIN
	DECLARE @KC INT, @Ngay DATE, @Vang INT, @Bu INT
	SELECT @Ngay = NgayHoc
	FROM Inserted INNER JOIN dbo.LichHoc
	ON LichHoc.Buoi = Inserted.Buoi AND LichHoc.MaLop = Inserted.MaLop
	SET @KC = (SELECT dbo.KhoanCachDenHienTai(@Ngay))
	SELECT @Vang = Inserted.MaLop, @Bu = Inserted.HocBu
	FROM Inserted
	IF ((SELECT dbo.LayMaKhoahoc(@Vang)) != (SELECT dbo.LayMaKhoahoc(@Bu)))
	BEGIN
		PRINT (N'Không đúng khóa học')
		ROLLBACK TRAN
	END	
	IF (@KC > 30)
	BEGIN
		PRINT (N'Quá thời gian học bù cho phép')
		ROLLBACK TRAN
	END	
END									  
GO

------------------------------------------------------------------------------------------
--không được đăng ký hai lớp cùng lịch học và lớp đã full
CREATE TRIGGER KiemTraDangKy
ON dbo.DangKy
AFTER INSERT, UPDATE
AS
BEGIN 
	DECLARE @MaHocVien INT, @NewLop INT, @test INT
	SELECT @MaHocVien = Inserted.MaHocVien, @NewLop = Inserted.MaLop
	FROM Inserted
	SET @test = (SELECT dbo.KiemTraCaVaNgayTrongTuan(@MaHocVien))
	IF (@test = 0)
	BEGIN
		PRINT (N'Trùng lịch học')
		ROLLBACK TRAN
	END
	ELSE
	BEGIN
		DECLARE @SoHocVienThucTe INT, @SoHocVienDuKien INT
		SET @SoHocVienThucTe = dbo.SoLuongHocVienCuaLop(@NewLop)
		SELECT @SoHocVienDuKien = SoHocVienDuKien
		FROM Inserted INNER JOIN dbo.LopHoc
		ON LopHoc.MaLop = Inserted.MaLop
		WHERE Inserted.MaLop = @NewLop
		IF (@SoHocVienThucTe > @SoHocVienDuKien)
		BEGIN
			PRINT (N'Lớp đã đủ học viên')
			ROLLBACK TRAN
		END
	END
END
GO

------------------------------------------------------------------------------------------------------------------------------------------
-- tạo lịch học khi thêm lớp + tạo danh sách học viên của lớp
CREATE TRIGGER TaoLichHoc_Trigger
ON dbo.LopHoc
AFTER INSERT
AS
BEGIN
	DECLARE @maGV INT, @maLop INT, @sql VARCHAR(MAX)
	SELECT @maLop = Inserted.MaLop
	FROM Inserted
	--tạo lịch học	
	EXECUTE dbo.TaoLichHoc @maLop		
	--tạo danh sách học viên của lớp
	SET @sql = 'CREATE VIEW DanhSachLop_' + CONVERT(VARCHAR(10), @maLop) + ' AS (SELECT * FROM dbo.TaoViewLop(' + CONVERT(VARCHAR(10), @maLop) + '))'
	EXECUTE (@sql)
END
GO
---------------------------------------------------------------------------------------------------------------------------------------------
--trigger mã hóa mật khẩu trước khi lưu
CREATE TRIGGER MaHoa
ON dbo.Account
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @pass VARCHAR(32), @id INT
	SELECT @pass = Inserted.MatKhau, @id = Inserted.IDTaiKhoan 
	FROM Inserted
	SET @pass = dbo.MaHoaMD5(@pass)
	UPDATE dbo.Account 
	SET MatKhau = @pass
	WHERE IDTaiKhoan = @id
END
GO
----------------------------------------------------------------------------------------------------------------------------------------------
--nếu số buổi của một khóa học tăng thì lịch tự động thêm buổi học 
--nêu số buổi của một khóa học giảm thì lịch tự xóa buổi học
CREATE TRIGGER UpdateKhoahoc
ON dbo.KhoaHoc
AFTER UPDATE
AS
BEGIN
	DECLARE @old INT, @new INT, @maKhoa INT
	SELECT @old = Deleted.SoBuoi, @maKhoa = Deleted.MaKhoaHoc FROM Deleted
	SELECT @new = Inserted.SoBuoi FROM Inserted
	IF (@new > @old)
	BEGIN
		SELECT MaLop, IDENTITY(INT, 1, 1) AS ID
		INTO ListMaLop
		FROM dbo.LopHoc
		WHERE ThuocKhoaHoc = @maKhoa
		DECLARE @i INT, @tongMa INT, @maLop INT
		SET @i = 1
		SELECT @tongMa = COUNT(*) FROM ListMaLop
		WHILE (@i <= @tongMa)
		BEGIN
			SELECT @maLop = MaLop FROM ListMaLop WHERE ID = @i
			EXECUTE dbo.ThemLichHocTheoKhoa @maLop
			SET @i = @i + 1
		END
		DROP TABLE ListMaLop
	END
	ELSE IF (@new < @old)
	BEGIN
		SELECT MaLop, IDENTITY(INT, 1, 1) AS ID
		INTO ListMaLop
		FROM dbo.LopHoc
		WHERE ThuocKhoaHoc = @maKhoa
		DECLARE @i2 INT, @tongMa2 INT, @maLop2 INT
		SET @i2 = 1
		SELECT @tongMa2 = COUNT(*) FROM ListMaLop
		WHILE (@i2 <= @tongMa2)
		BEGIN
			SELECT @maLop2 = MaLop FROM ListMaLop WHERE ID = @i2
			EXECUTE dbo.XoaLichHoc @maLop2, @new, @old	
			SET @i2 = @i2 + 1	
		END
		DROP TABLE ListMaLop
    END
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------
--nếu một buổi trong lịch học đó xóa thì tự động sinh ra 1 buổi để bù lại buổi đã xóa
CREATE TRIGGER DeleteLichHoc
ON dbo.LichHoc
AFTER DELETE
AS
BEGIN
	DECLARE @SoBuoi INT, @SoBuoiTrongLich INT
	SELECT @SoBuoi = SoBuoi
	FROM dbo.KhoaHoc, Deleted, dbo.LopHoc
	WHERE MaKhoaHoc = ThuocKhoaHoc
	AND Deleted.MaLop = LopHoc.MaLop

	DECLARE @MaLop INT
	SELECT @MaLop = Deleted.MaLop
	FROM Deleted

	SELECT @SoBuoiTrongLich = COUNT(*)
	FROM dbo.LichHoc
	WHERE MaLop = @MaLop

	IF (@SoBuoiTrongLich < @SoBuoi)
		EXECUTE dbo.ThemLichHoc @MaLop = @MaLop
END
GO

----------------------------------------------------------------------------------------------------------------------------------------------
--View
----------------------------------------------------------------------------------------------------------------------------------------------
--lịch của tất cả khóa học
CREATE VIEW Lich_
AS
	SELECT LichHoc.MaLop, Buoi, TenPhong, NgayHoc, HoTen, CaHoc
	FROM dbo.LichHoc, dbo.LopHoc, dbo.PhongHoc, dbo.GiaoVien
	WHERE LopHoc.MaLop = LichHoc.MaLop
	AND Phong = IDPhong
	AND GiaoVien.MaGiaoVien = LichHoc.MaGiaoVien
GO
---------------------------------------------------------------------------------------------------------------------------------------------
--tổng số lượng buổi dạy trong lịch của giáo viên bắt đầu từ ngày hiện tại
CREATE VIEW TongSoBuoiDayTheoGiaoVien
AS
	SELECT GiaoVien.MaGiaoVien, COUNT(*) AS SL
	FROM dbo.LichHoc RIGHT JOIN dbo.GiaoVien
	ON GiaoVien.MaGiaoVien = LichHoc.MaGiaoVien
	GROUP BY GiaoVien.MaGiaoVien
GO

-----------------------------------------------------------------------------------------------------------------------------------------------
-- CÁC HÀM VÀ THỦ TỤC XỬ LÝ HỌC BÙ CỦA HỌC VIÊN
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Hàm lấy các lớp có thể học bù của 1 buổi 
Create function LayHocBu(@TheoKhoaHoc int, @MaLop int, @BuoiHoc int)
returns table
as
	return (Select LichHoc.MaGiaoVien,LichHoc.MaLop,LichHoc.Buoi,LichHoc.Phong,LichHoc.NgayHoc,Chon=0
			From LopHoc,LichHoc
			Where LopHoc.ThuocKhoaHoc=@TheoKhoaHoc and LichHoc.Buoi=@BuoiHoc 
			and LopHoc.MaLop=LichHoc.MaLop and DATEDIFF(day, GETDATE(), LichHoc.NgayHoc)>=0
			and LichHoc.MaLop!=@MaLop)
GO

-- Hàm lấy Khóa học của 1 lớp học 
Create function LayKhoaLH(@MaLop int)
returns int
as
begin
	declare @MaKhoaHoc int
	Select @MaKhoaHoc=ThuocKhoaHoc
	From LopHoc
	Where MaLop=@MaLop
	return @MaKhoaHoc
end
GO

-- Hàm Kiểm tra buổi học bù đã được đăng ký chưa
Create function KtraHocBuCoTonTai(@maHocVien int, @maLop int, @buoi int)
returns int
as
begin
	declare @hocBu int
	if(Exists(Select * From Vang Where MaHocVien=@maHocVien and MaLop=@maLop and Buoi=@buoi))
	begin
		Select @hocBu=HocBu From Vang Where MaHocVien=@maHocVien and MaLop=@maLop and Buoi=@buoi
		return @hocBu
	end
	return -1
end
GO

-- Thủ tục khi nhấn Lưu đăng ký học bù: nếu chưa Đk thì thêm, ngược lại cập nhật
Create proc ThemVaCapNhatHocBu @maHocVien int, @maLop int, @buoi int, @hocBu int 
as
begin
	if((Select dbo.KtraHocBuCoTonTai(@maHocVien,@maLop,@buoi))!=-1)
	begin
		Update Vang Set HocBu=@hocBu Where MaHocVien=@maHocVien and MaLop=@maLop and Buoi=@buoi
	end
	else
	begin
		Insert into Vang values(@maHocVien,@maLop,@buoi,@hocBu)
	end
end
GO

-- Thủ tục Hủy bỏ việc đăng ký học bù
Create proc HuyBoHocBu(@maHocVien int, @maLop int, @buoi int)
as
begin
	Delete From Vang Where MaHocVien=@maHocVien and MaLop=@maLop and Buoi=@buoi
end
GO

-- Thủ tục lấy số buổi học của 1 lớp
Create proc SoBuoiHoc @maLop int
as
begin
	Select KhoaHoc.SoBuoi From LopHoc,KhoaHoc 
    Where LopHoc.ThuocKhoaHoc=KhoaHoc.MaKhoaHoc and
		  LopHoc.MaLop= @maLop
end
GO
---------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------------------------
--NHẬP DỮ LIỆU
--------------------------------------------------------------------------------------------------------------------------------------------
--Account
INSERT dbo.Account VALUES ( 0, 'admin', 'admin', 1)
INSERT dbo.Account VALUES ( 1, 'GV001', '000000', 3)
INSERT dbo.Account VALUES ( 2, 'GV002', '000000', 3)
INSERT dbo.Account VALUES ( 3, 'GV003', '000000', 3)
INSERT dbo.Account VALUES ( 4, 'GV004', '000000', 3)
INSERT dbo.Account VALUES ( 5, 'GV005', '000000', 3)
INSERT dbo.Account VALUES ( 6, 'GV006', '000000', 3)
INSERT dbo.Account VALUES ( 7, 'GV007', '000000', 3)
INSERT dbo.Account VALUES ( 8, 'GV008', '000000', 3)
INSERT dbo.Account VALUES ( 9, 'GV009', '000000', 3)
INSERT dbo.Account VALUES ( 10, 'GV010', '000000', 3)
INSERT dbo.Account VALUES ( 11, 'HV00001', '000000', 4)
INSERT dbo.Account VALUES ( 12, 'HV00002', '000000', 4)
INSERT dbo.Account VALUES ( 13, 'HV00003', '000000', 4)
INSERT dbo.Account VALUES ( 14, 'HV00004', '000000', 4)
INSERT dbo.Account VALUES ( 15, 'HV00005', '000000', 4)
INSERT dbo.Account VALUES ( 16, 'HV00006', '000000', 4)
INSERT dbo.Account VALUES ( 17, 'HV00007', '000000', 4)
INSERT dbo.Account VALUES ( 18, 'HV00008', '000000', 4)
INSERT dbo.Account VALUES ( 19, 'HV00009', '000000', 4)
INSERT dbo.Account VALUES ( 20, 'HV00010', '000000', 4)
INSERT dbo.Account VALUES ( 21, 'HV00011', '000000', 4)
INSERT dbo.Account VALUES ( 22, 'HV00012', '000000', 4)
INSERT dbo.Account VALUES ( 23, 'HV00013', '000000', 4)
INSERT dbo.Account VALUES ( 24, 'HV00014', '000000', 4)
INSERT dbo.Account VALUES ( 25, 'HV00015', '000000', 4)
INSERT dbo.Account VALUES ( 26, 'HV00016', '000000', 4)
INSERT dbo.Account VALUES ( 27, 'HV00017', '000000', 4)
INSERT dbo.Account VALUES ( 28, 'HV00018', '000000', 4)
INSERT dbo.Account VALUES ( 29, 'HV00019', '000000', 4)
INSERT dbo.Account VALUES ( 30, 'HV00020', '000000', 4)
INSERT dbo.Account VALUES ( 31, 'NV001', '000000', 2)
INSERT dbo.Account VALUES ( 32, 'NV002', '000000', 2)
INSERT dbo.Account VALUES ( 33, 'NV003', '000000', 2)
INSERT dbo.Account VALUES ( 34, 'NV004', '000000', 2)
INSERT dbo.Account VALUES ( 35, 'NV005', '000000', 2)
GO

--Khóa học
INSERT dbo.KhoaHoc (MaKhoaHoc, TenKhoaHoc, SoBuoi, HocPhi) VALUES  (1, N'TOIEC', 45, 5000000)
INSERT dbo.KhoaHoc (MaKhoaHoc, TenKhoaHoc, SoBuoi, HocPhi) VALUES  (2, N'IELTS', 50, 7000000)
INSERT dbo.KhoaHoc (MaKhoaHoc, TenKhoaHoc, SoBuoi, HocPhi) VALUES  (3, N'GIAO TIẾP', 30, 6000000)
INSERT dbo.KhoaHoc (MaKhoaHoc, TenKhoaHoc, SoBuoi, HocPhi) VALUES  (4, N'CƠ BẢN', 25, 2000000)
GO

--Phòng học
INSERT dbo.PhongHoc VALUES  ( 1, 'A101')
INSERT dbo.PhongHoc VALUES  ( 2, 'A102')
INSERT dbo.PhongHoc VALUES  ( 3, 'A103')
INSERT dbo.PhongHoc VALUES  ( 4, 'A201')
INSERT dbo.PhongHoc VALUES  ( 5, 'A202')
INSERT dbo.PhongHoc VALUES  ( 6, 'A203')
INSERT dbo.PhongHoc VALUES  ( 7, 'A204')
INSERT dbo.PhongHoc VALUES  ( 8, 'A205')
INSERT dbo.PhongHoc VALUES  ( 9, 'A301')
INSERT dbo.PhongHoc VALUES  ( 10, 'A302')
GO

--Giáo viên
INSERT dbo.GiaoVien VALUES ( 1, N'Trần Văn Một', '0412784124', N'Linh Đông - Thủ Đức', 100000)
INSERT dbo.GiaoVien VALUES ( 2, N'Chung Thị Hai', '0947368638', N'Hiệp Bình Chánh - Thủ Đức', 90000)
INSERT dbo.GiaoVien VALUES ( 3, N'Huỳnh Ba', '0735267489', N'Linh Trung - Thủ Đức', 105000)
INSERT dbo.GiaoVien VALUES ( 4, N'Nguyễn Thị Bốn', '0897537643', N'Bình Thọ - Thủ Đức', 110000)
INSERT dbo.GiaoVien VALUES ( 5, N'Hoàng Ngọc Năm', '0172648339', N'Linh Chiểu - Thủ Đức', 95000)
INSERT dbo.GiaoVien VALUES ( 6, N'Nguyễn Thanh Sáu', '0966463433', N'Tam Phủ - Thủ Đức', 97000)
INSERT dbo.GiaoVien VALUES ( 7, N'Trần Công Bảy', '0937448832', N'Thảo Điền - Quận 2', 120000)
INSERT dbo.GiaoVien VALUES ( 8, N'Đoàn Thiên Bát', '0987263778', N'Thanh Đa - Bình Thạnh', 115000)
INSERT dbo.GiaoVien VALUES ( 9, N'Trần Giác Cửu', '0963748996', N'Phường 5 - Gò Vấp', 117000)
INSERT dbo.GiaoVien VALUES ( 10, N'Nguyễn Phạm Nhân', '0274836338', N'Hiệp Bình Phước - Thủ Đức', 100000)
GO

--Học Viên
INSERT dbo.HocVien VALUES  ( 11, N'Phạm Luật', '0976877857', N'Thủ Đức', 'phanluat01@gmail.com', '2000-06-01')
INSERT dbo.HocVien VALUES  ( 12, N'Lê Thị Sĩ', '0483747673', N'Thủ Đức', 'emai1@gmail.com', '2000-05-04')
INSERT dbo.HocVien VALUES  ( 13, N'Nguyễn Anh Hùng', '0948475847', N'Thủ Đức', 'eami2@gmail.com', '1999-12-09')
INSERT dbo.HocVien VALUES  ( 14, N'Hoàng Mĩ Nhân', '0989877868', N'Thủ Đức', 'eamil3@gmail.com', '1999-07-19')
INSERT dbo.HocVien VALUES  ( 15, N'Huỳnh Thi Quan', '0334945345', N'Thủ Đức', 'amil4@gmail.com', '1999-09-23')
INSERT dbo.HocVien VALUES  ( 16, N'Trần Văn Nhất', '0398874833', N'Thủ Đức', 'email5@gmail.com', '2000-08-12')
INSERT dbo.HocVien VALUES  ( 17, N'Trần Quốc Bắc', '0978775646', N'Thủ Đức', 'email6@gmail.com', '2001-01-30')
INSERT dbo.HocVien VALUES  ( 18, N'Nguyễn Văn Vỹ', '0439849394', N'Thủ Đức', 'email7@gmail.com', '2000-01-12')
INSERT dbo.HocVien VALUES  ( 19, N'Pham Thì Nữ', '0434874874', N'Thủ Đức', 'email8@gmail.com', '2000-03-27')
INSERT dbo.HocVien VALUES  ( 20, N'Thi Lý Vi', '0787476367', N'Thủ Đức', 'main8@gmail.com', '1999-08-23')
INSERT dbo.HocVien VALUES  ( 21, N'Nguyễn Thị Kim', '0483748373', N'Thủ Đức', 'mail10@gmail.com', '2000-12-17')
INSERT dbo.HocVien VALUES  ( 22, N'Phạm Xuân Hoài', '0141873264', N'Thủ Đức', 'main11@gmail.com', '2000-11-01')
INSERT dbo.HocVien VALUES  ( 23, N'Lê Hồng Hưng', '0547777462', N'Thủ Đức', 'main12@gmail.com', '1998-01-03')
INSERT dbo.HocVien VALUES  ( 24, N'Nguyễn Lý Quan Phúc', '0254872847', N'Thủ Đức', 'mainl13@gmail.com', '1999-01-08')
INSERT dbo.HocVien VALUES  ( 25, N'Đặng Hoàng Lan', '0473461873', N'Thủ Đức', 'naml17@gmail.com', '2000-07-12')
INSERT dbo.HocVien VALUES  ( 26, N'Võ Thanh Trúc', '0627628238', N'Thủ Đức', 'hanma13@gmail.com', '2000-08-10')
INSERT dbo.HocVien VALUES  ( 27, N'Phan Quang huy', '0936765636', N'Thủ Đức', 'hamn27@gmail.com', '2000-06-17')
INSERT dbo.HocVien VALUES  ( 28, N'Huỳnh Thị Mai', '0483476367', N'Thủ Đức', 'ginanm30@gmail.com', '2000-09-28')
INSERT dbo.HocVien VALUES  ( 29, N'Bùi Thanh Trúc', '0947773667', N'Thủ Đức', 'annss29@gmail.com', '1999-07-02')
INSERT dbo.HocVien VALUES  ( 30, N'Trần Thanh Hào', '0877367366', N'Thủ Đức', 'manin182@gmail.com', '1999-05-20')
GO

--Lớp học
INSERT dbo.LopHoc VALUES  (1, 30, 1, '2-4-6', 1)
INSERT dbo.LopHoc VALUES  (2, 35, 2, '3-5-7', 1)
INSERT dbo.LopHoc VALUES  (3, 25, 3, '2-4-6', 2)
INSERT dbo.LopHoc VALUES  (4, 40, 4, '2-4-6', 2)
INSERT dbo.LopHoc VALUES  (5, 30, 4, '2-4-6', 2)
INSERT dbo.LopHoc VALUES  (6, 35, 5, '3-5-7', 3)
INSERT dbo.LopHoc VALUES  (7, 35, 5, '2-4-6', 3)
INSERT dbo.LopHoc VALUES  (8, 40, 6, '3-5-7', 4)
INSERT dbo.LopHoc VALUES  (9, 20, 6, '3-5-7', 4)
INSERT dbo.LopHoc VALUES  (10, 25, 1, '2-4-6', 4)
GO

--Đăng Ký
INSERT dbo.DangKy VALUES  ( 11, 1, 0)
INSERT dbo.DangKy VALUES  ( 11, 2, 0)
INSERT dbo.DangKy VALUES  ( 12, 2, 0)
INSERT dbo.DangKy VALUES  ( 13, 1, 1)
INSERT dbo.DangKy VALUES  ( 14, 3, 0)
INSERT dbo.DangKy VALUES  ( 15, 4, 0)
INSERT dbo.DangKy VALUES  ( 15, 6, 0)
INSERT dbo.DangKy VALUES  ( 13, 8, 1)
INSERT dbo.DangKy VALUES  ( 16, 7, 1)
INSERT dbo.DangKy VALUES  ( 17, 8, 0)
INSERT dbo.DangKy VALUES  ( 18, 9, 0)
INSERT dbo.DangKy VALUES  ( 19, 10, 1)
INSERT dbo.DangKy VALUES  ( 20, 1, 1)
INSERT dbo.DangKy VALUES  ( 21, 2, 0)
INSERT dbo.DangKy VALUES  ( 22, 2, 0)
INSERT dbo.DangKy VALUES  ( 23, 3, 1)
INSERT dbo.DangKy VALUES  ( 23, 4, 1)
INSERT dbo.DangKy VALUES  ( 24, 5, 0)
INSERT dbo.DangKy VALUES  ( 25, 7, 0)
INSERT dbo.DangKy VALUES  ( 26, 8, 1)
INSERT dbo.DangKy VALUES  ( 27, 6, 0)
INSERT dbo.DangKy VALUES  ( 28, 8, 1)
INSERT dbo.DangKy VALUES  ( 29, 6, 1)
INSERT dbo.DangKy VALUES  ( 30, 1, 0)
INSERT dbo.DangKy VALUES  ( 30, 2, 0)
INSERT dbo.DangKy VALUES  ( 30, 9, 0)
GO

--Vắng
INSERT dbo.Vang VALUES  ( 11, 1, 3, NULL)
INSERT dbo.Vang VALUES  ( 11, 2, 8, 1)
INSERT dbo.Vang VALUES  ( 15, 6, 9, NULL)
INSERT dbo.Vang VALUES  ( 13, 3, 9, 5)
INSERT dbo.Vang VALUES  ( 20, 1, 10, 2)
GO