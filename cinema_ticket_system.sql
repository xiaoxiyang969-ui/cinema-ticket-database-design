-- 1. 如果数据库不存在则创建
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'cinema_ticket_system')
BEGIN
    CREATE DATABASE cinema_ticket_system
    PRINT '数据库创建成功'
END
ELSE
BEGIN
    PRINT '数据库已存在'
END
GO

USE cinema_ticket_system
GO

-- ============================================
-- 2. 清理已存在的对象（如果多次运行）
-- ============================================

-- 2.1 删除视图
IF OBJECT_ID('v_user_order_details', 'V') IS NOT NULL DROP VIEW v_user_order_details
IF OBJECT_ID('v_screening_details', 'V') IS NOT NULL DROP VIEW v_screening_details
IF OBJECT_ID('v_movie_sales', 'V') IS NOT NULL DROP VIEW v_movie_sales
IF OBJECT_ID('v_cinema_revenue', 'V') IS NOT NULL DROP VIEW v_cinema_revenue
GO

-- 2.2 删除存储过程
IF OBJECT_ID('generate_seats_for_hall', 'P') IS NOT NULL DROP PROCEDURE generate_seats_for_hall
GO

-- 2.3 删除函数
IF OBJECT_ID('generate_order_id', 'FN') IS NOT NULL DROP FUNCTION generate_order_id
IF OBJECT_ID('get_available_seats', 'FN') IS NOT NULL DROP FUNCTION get_available_seats
GO

-- 2.4 删除表（按依赖顺序）
IF OBJECT_ID('payments', 'U') IS NOT NULL DROP TABLE payments
IF OBJECT_ID('system_logs', 'U') IS NOT NULL DROP TABLE system_logs
IF OBJECT_ID('reviews', 'U') IS NOT NULL DROP TABLE reviews
IF OBJECT_ID('user_coupons', 'U') IS NOT NULL DROP TABLE user_coupons
IF OBJECT_ID('order_seats', 'U') IS NOT NULL DROP TABLE order_seats
IF OBJECT_ID('orders', 'U') IS NOT NULL DROP TABLE orders
IF OBJECT_ID('admins', 'U') IS NOT NULL DROP TABLE admins
IF OBJECT_ID('seats', 'U') IS NOT NULL DROP TABLE seats
IF OBJECT_ID('coupons', 'U') IS NOT NULL DROP TABLE coupons
IF OBJECT_ID('screenings', 'U') IS NOT NULL DROP TABLE screenings
IF OBJECT_ID('users', 'U') IS NOT NULL DROP TABLE users
IF OBJECT_ID('movies', 'U') IS NOT NULL DROP TABLE movies
IF OBJECT_ID('halls', 'U') IS NOT NULL DROP TABLE halls
IF OBJECT_ID('cinemas', 'U') IS NOT NULL DROP TABLE cinemas
GO

-- ============================================
-- 3. 创建表结构
-- ============================================

-- 3.1 影院信息表
CREATE TABLE cinemas (
    cinema_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    address NVARCHAR(200) NOT NULL,
    city NVARCHAR(50) NOT NULL,
    phone NVARCHAR(20) NULL,
    email NVARCHAR(100) NULL,
    opening_hours NVARCHAR(100) NULL,
    facilities NVARCHAR(MAX) NULL,
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.2 影厅信息表
CREATE TABLE halls (
    hall_id INT PRIMARY KEY IDENTITY(1,1),
    cinema_id INT NOT NULL,
    hall_name NVARCHAR(50) NOT NULL,
    hall_type NVARCHAR(10) NOT NULL DEFAULT '2D',
    total_rows INT NOT NULL,
    total_columns INT NOT NULL,
    capacity INT NOT NULL,
    facilities NVARCHAR(MAX) NULL,
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.3 电影信息表
CREATE TABLE movies (
    movie_id INT PRIMARY KEY IDENTITY(1,1),
    title NVARCHAR(200) NOT NULL,
    original_title NVARCHAR(200) NULL,
    director NVARCHAR(100) NULL,
    actors NVARCHAR(MAX) NULL,
    duration INT NOT NULL,
    release_date DATE NULL,
    end_date DATE NULL,
    language NVARCHAR(50) NULL,
    country NVARCHAR(50) NULL,
    genres NVARCHAR(200) NULL,
    description NVARCHAR(MAX) NULL,
    poster_url NVARCHAR(500) NULL,
    trailer_url NVARCHAR(500) NULL,
    rating DECIMAL(2,1) DEFAULT 0,
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.4 放映场次表
CREATE TABLE screenings (
    screening_id INT PRIMARY KEY IDENTITY(1,1),
    movie_id INT NOT NULL,
    hall_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    language_type NVARCHAR(20) DEFAULT N'国语',
    subtitle_type NVARCHAR(20) DEFAULT N'无',
    available_seats INT NOT NULL,
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.5 用户信息表
CREATE TABLE users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username NVARCHAR(50) NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    email NVARCHAR(100) NOT NULL,
    phone NVARCHAR(20) NULL,
    full_name NVARCHAR(100) NULL,
    avatar_url NVARCHAR(500) NULL,
    gender NVARCHAR(1) DEFAULT 'U',
    birthday DATE NULL,
    balance DECIMAL(10,2) DEFAULT 0.00,
    points INT DEFAULT 0,
    membership_level NVARCHAR(10) DEFAULT N'普通',
    status TINYINT DEFAULT 1,
    last_login_at DATETIME NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.6 座位信息表
CREATE TABLE seats (
    seat_id BIGINT PRIMARY KEY IDENTITY(1,1),
    hall_id INT NOT NULL,
    row_num INT NOT NULL,
    column_num INT NOT NULL,
    seat_code NVARCHAR(10) NOT NULL,
    seat_type NVARCHAR(10) DEFAULT N'普通',
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.7 订单表
CREATE TABLE orders (
    order_id NVARCHAR(32) PRIMARY KEY,
    user_id INT NOT NULL,
    screening_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    actual_amount DECIMAL(10,2) NOT NULL,
    order_status NVARCHAR(10) DEFAULT N'待支付',
    payment_method NVARCHAR(10) NULL,
    payment_time DATETIME NULL,
    contact_name NVARCHAR(100) NOT NULL,
    contact_phone NVARCHAR(20) NOT NULL,
    is_used TINYINT DEFAULT 0,
    used_time DATETIME NULL,
    expire_time DATETIME NULL,
    note NVARCHAR(MAX) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.8 订单座位关联表
CREATE TABLE order_seats (
    order_seat_id BIGINT PRIMARY KEY IDENTITY(1,1),
    order_id NVARCHAR(32) NOT NULL,
    seat_id BIGINT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.9 优惠券表
CREATE TABLE coupons (
    coupon_id INT PRIMARY KEY IDENTITY(1,1),
    coupon_code NVARCHAR(20) NOT NULL,
    coupon_name NVARCHAR(100) NOT NULL,
    coupon_type NVARCHAR(10) NOT NULL,
    discount_value DECIMAL(10,2) NOT NULL,
    min_amount DECIMAL(10,2) DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_quantity INT NOT NULL,
    used_quantity INT DEFAULT 0,
    status TINYINT DEFAULT 1,
    applicable_movies NVARCHAR(MAX) NULL,
    applicable_cinemas NVARCHAR(MAX) NULL,
    description NVARCHAR(MAX) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.10 用户优惠券表
CREATE TABLE user_coupons (
    user_coupon_id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    coupon_id INT NOT NULL,
    status NVARCHAR(10) DEFAULT N'未使用',
    obtained_at DATETIME DEFAULT GETDATE(),
    used_at DATETIME NULL,
    order_id NVARCHAR(32) NULL,
    expire_at DATE NOT NULL
)
GO

-- 3.11 评论表
CREATE TABLE reviews (
    review_id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    movie_id INT NOT NULL,
    order_id NVARCHAR(32) NOT NULL,
    rating DECIMAL(2,1) NOT NULL,
    content NVARCHAR(MAX) NOT NULL,
    is_anonymous TINYINT DEFAULT 0,
    like_count INT DEFAULT 0,
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.12 管理员表
CREATE TABLE admins (
    admin_id INT PRIMARY KEY IDENTITY(1,1),
    username NVARCHAR(50) NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    email NVARCHAR(100) NOT NULL,
    phone NVARCHAR(20) NULL,
    role NVARCHAR(20) DEFAULT N'影院管理员',
    cinema_id INT NULL,
    last_login_at DATETIME NULL,
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.13 系统日志表
CREATE TABLE system_logs (
    log_id BIGINT PRIMARY KEY IDENTITY(1,1),
    user_id INT NULL,
    admin_id INT NULL,
    action_type NVARCHAR(50) NOT NULL,
    module NVARCHAR(50) NOT NULL,
    description NVARCHAR(MAX) NOT NULL,
    ip_address NVARCHAR(45) NULL,
    user_agent NVARCHAR(MAX) NULL,
    request_params NVARCHAR(MAX) NULL,
    status TINYINT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE()
)
GO

-- 3.14 支付记录表
CREATE TABLE payments (
    payment_id NVARCHAR(32) PRIMARY KEY,
    order_id NVARCHAR(32) NOT NULL,
    user_id INT NOT NULL,
    payment_method NVARCHAR(10) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    transaction_id NVARCHAR(64) NULL,
    payment_status NVARCHAR(10) DEFAULT N'待支付',
    pay_time DATETIME NULL,
    refund_time DATETIME NULL,
    note NVARCHAR(MAX) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
)
GO

PRINT '所有表创建完成'
GO

-- ============================================
-- 4. 添加约束（修复级联删除问题）
-- ============================================

-- 4.1 外键约束（使用 NO ACTION 避免循环级联）
ALTER TABLE halls ADD CONSTRAINT fk_halls_cinema FOREIGN KEY (cinema_id) REFERENCES cinemas(cinema_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE screenings ADD CONSTRAINT fk_screenings_movie FOREIGN KEY (movie_id) REFERENCES movies(movie_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE screenings ADD CONSTRAINT fk_screenings_hall FOREIGN KEY (hall_id) REFERENCES halls(hall_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE seats ADD CONSTRAINT fk_seats_hall FOREIGN KEY (hall_id) REFERENCES halls(hall_id) ON DELETE CASCADE ON UPDATE NO ACTION
ALTER TABLE orders ADD CONSTRAINT fk_orders_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE orders ADD CONSTRAINT fk_orders_screening FOREIGN KEY (screening_id) REFERENCES screenings(screening_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE order_seats ADD CONSTRAINT fk_order_seats_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE NO ACTION
ALTER TABLE order_seats ADD CONSTRAINT fk_order_seats_seat FOREIGN KEY (seat_id) REFERENCES seats(seat_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE user_coupons ADD CONSTRAINT fk_user_coupons_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE user_coupons ADD CONSTRAINT fk_user_coupons_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE user_coupons ADD CONSTRAINT fk_user_coupons_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE reviews ADD CONSTRAINT fk_reviews_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE reviews ADD CONSTRAINT fk_reviews_movie FOREIGN KEY (movie_id) REFERENCES movies(movie_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE reviews ADD CONSTRAINT fk_reviews_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE admins ADD CONSTRAINT fk_admins_cinema FOREIGN KEY (cinema_id) REFERENCES cinemas(cinema_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE payments ADD CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE NO ACTION ON UPDATE NO ACTION
ALTER TABLE payments ADD CONSTRAINT fk_payments_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE NO ACTION ON UPDATE NO ACTION
GO

-- 4.2 唯一约束
ALTER TABLE halls ADD CONSTRAINT uk_halls_unique UNIQUE (cinema_id, hall_name)
ALTER TABLE screenings ADD CONSTRAINT uk_screenings_hall_time UNIQUE (hall_id, start_time)
ALTER TABLE users ADD CONSTRAINT uk_users_username UNIQUE (username)
ALTER TABLE users ADD CONSTRAINT uk_users_email UNIQUE (email)
ALTER TABLE users ADD CONSTRAINT uk_users_phone UNIQUE (phone)
ALTER TABLE seats ADD CONSTRAINT uk_seats_hall_position UNIQUE (hall_id, row_num, column_num)
ALTER TABLE seats ADD CONSTRAINT uk_seats_hall_code UNIQUE (hall_id, seat_code)
ALTER TABLE coupons ADD CONSTRAINT uk_coupons_code UNIQUE (coupon_code)
ALTER TABLE user_coupons ADD CONSTRAINT uk_user_coupons_coupon_user UNIQUE (coupon_id, user_id)
ALTER TABLE reviews ADD CONSTRAINT uk_reviews_order UNIQUE (order_id)
ALTER TABLE admins ADD CONSTRAINT uk_admins_username UNIQUE (username)
ALTER TABLE admins ADD CONSTRAINT uk_admins_email UNIQUE (email)
ALTER TABLE payments ADD CONSTRAINT uk_payments_transaction UNIQUE (transaction_id)
ALTER TABLE order_seats ADD CONSTRAINT uk_order_seats UNIQUE (order_id, seat_id)
GO

-- 4.3 检查约束
ALTER TABLE halls ADD CONSTRAINT chk_halls_type CHECK (hall_type IN ('2D', '3D', 'IMAX', '4DX', 'VIP'))
ALTER TABLE users ADD CONSTRAINT chk_users_gender CHECK (gender IN ('M', 'F', 'U'))
ALTER TABLE users ADD CONSTRAINT chk_users_membership CHECK (membership_level IN ('普通', '白银', '黄金', '铂金', '钻石'))
ALTER TABLE seats ADD CONSTRAINT chk_seats_type CHECK (seat_type IN ('普通', '情侣座', 'VIP', '残疾人座'))
ALTER TABLE orders ADD CONSTRAINT chk_orders_status CHECK (order_status IN ('待支付', '已支付', '已取消', '已完成', '已退款'))
ALTER TABLE coupons ADD CONSTRAINT chk_coupons_type CHECK (coupon_type IN ('折扣券', '满减券', '代金券'))
ALTER TABLE user_coupons ADD CONSTRAINT chk_user_coupons_status CHECK (status IN ('未使用', '已使用', '已过期'))
ALTER TABLE reviews ADD CONSTRAINT chk_reviews_rating CHECK (rating >= 0 AND rating <= 5)
ALTER TABLE admins ADD CONSTRAINT chk_admins_role CHECK (role IN ('超级管理员', '影院管理员', '内容管理员', '财务管理员'))
ALTER TABLE payments ADD CONSTRAINT chk_payments_status CHECK (payment_status IN ('待支付', '支付成功', '支付失败', '已退款'))
GO

PRINT '所有约束添加完成'
GO

-- ============================================
-- 5. 创建索引
-- ============================================

-- 5.1 影院表索引
CREATE INDEX idx_cinemas_city ON cinemas(city)
CREATE INDEX idx_cinemas_status ON cinemas(status)
CREATE INDEX idx_cinemas_city_status ON cinemas(city, status)
GO

-- 5.2 影厅表索引
CREATE INDEX idx_halls_cinema ON halls(cinema_id)
CREATE INDEX idx_halls_type ON halls(hall_type)
CREATE INDEX idx_halls_status ON halls(status)
GO

-- 5.3 电影表索引
CREATE INDEX idx_movies_status ON movies(status)
CREATE INDEX idx_movies_release_date ON movies(release_date)
CREATE INDEX idx_movies_rating ON movies(rating DESC)
CREATE INDEX idx_movies_title ON movies(title)
GO

-- 5.4 场次表索引
CREATE INDEX idx_screenings_movie_time ON screenings(movie_id, start_time DESC)
CREATE INDEX idx_screenings_hall_time ON screenings(hall_id, start_time)
CREATE INDEX idx_screenings_start_time ON screenings(start_time)
CREATE INDEX idx_screenings_status ON screenings(status)
GO

-- 5.5 用户表索引
CREATE INDEX idx_users_email ON users(email)
CREATE INDEX idx_users_phone ON users(phone)
CREATE INDEX idx_users_status ON users(status)
CREATE INDEX idx_users_membership ON users(membership_level)
GO

-- 5.6 座位表索引
CREATE INDEX idx_seats_hall ON seats(hall_id)
CREATE INDEX idx_seats_status ON seats(status)
CREATE INDEX idx_seats_type ON seats(seat_type)
GO

-- 5.7 订单表索引
CREATE INDEX idx_orders_user_status ON orders(user_id, order_status, created_at DESC)
CREATE INDEX idx_orders_screening ON orders(screening_id)
CREATE INDEX idx_orders_status ON orders(order_status)
CREATE INDEX idx_orders_created ON orders(created_at DESC)
CREATE INDEX idx_orders_payment_time ON orders(payment_time)
GO

-- 5.8 其他表索引
CREATE INDEX idx_coupons_code ON coupons(coupon_code)
CREATE INDEX idx_coupons_status ON coupons(status)
CREATE INDEX idx_coupons_date ON coupons(start_date, end_date)
CREATE INDEX idx_user_coupons_user_status ON user_coupons(user_id, status)
CREATE INDEX idx_user_coupons_expire ON user_coupons(expire_at)
CREATE INDEX idx_reviews_movie_rating ON reviews(movie_id, rating DESC)
CREATE INDEX idx_reviews_user ON reviews(user_id)
CREATE INDEX idx_reviews_created ON reviews(created_at DESC)
CREATE INDEX idx_admins_role ON admins(role)
CREATE INDEX idx_admins_cinema ON admins(cinema_id)
CREATE INDEX idx_payments_order ON payments(order_id)
CREATE INDEX idx_payments_user ON payments(user_id)
CREATE INDEX idx_payments_status ON payments(payment_status)
CREATE INDEX idx_payments_pay_time ON payments(pay_time)
GO

PRINT '所有索引创建完成'
GO

-- ============================================
-- 6. 创建函数（修复版本）
-- ============================================

-- 6.1 生成订单号函数
CREATE FUNCTION dbo.generate_order_id()
RETURNS NVARCHAR(32)
AS
BEGIN
    DECLARE @order_id NVARCHAR(32)
    
    -- 使用当前时间的完整字符串，确保唯一性
    SET @order_id = CONVERT(NVARCHAR(8), GETDATE(), 112) +       -- YYYYMMDD
                   REPLACE(CONVERT(NVARCHAR(8), GETDATE(), 108), ':', '') +  -- HHMMSS
                   RIGHT('00' + CAST(DATEPART(MILLISECOND, GETDATE()) AS NVARCHAR(3)), 3)
    
    RETURN @order_id
END
GO

-- 6.2 获取可用座位数函数（简化版）
CREATE FUNCTION dbo.get_available_seats(@screening_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @total_seats INT
    DECLARE @booked_seats INT
    DECLARE @result INT
    
    -- 获取影厅总座位数
    SELECT @total_seats = h.capacity
    FROM screenings s
    INNER JOIN halls h ON s.hall_id = h.hall_id
    WHERE s.screening_id = @screening_id
    
    -- 获取已预订座位数
    SELECT @booked_seats = COUNT(*)
    FROM order_seats os
    INNER JOIN orders o ON os.order_id = o.order_id
    WHERE o.screening_id = @screening_id 
    AND o.order_status IN ('待支付', '已支付')
    
    -- 计算可用座位数
    SET @result = ISNULL(@total_seats, 0) - ISNULL(@booked_seats, 0)
    IF @result < 0 SET @result = 0
    
    RETURN @result
END
GO

PRINT '函数创建完成'
GO

-- ============================================
-- 7. 创建存储过程（修复版）
-- ============================================

-- 7.1 生成座位存储过程（修正版）
CREATE PROCEDURE dbo.generate_seats_for_hall
    @hall_id INT,
    @rows INT,
    @columns INT
AS
BEGIN
    SET NOCOUNT ON
    
    DECLARE @error_message NVARCHAR(4000)
    
    -- 检查影厅是否存在
    IF NOT EXISTS (SELECT 1 FROM halls WHERE hall_id = @hall_id)
    BEGIN
        SET @error_message = N'影厅不存在，ID: ' + CAST(@hall_id AS NVARCHAR(10))
        RAISERROR(@error_message, 16, 1)
        RETURN -1
    END
    
    -- 检查是否已有座位
    IF EXISTS (SELECT 1 FROM seats WHERE hall_id = @hall_id)
    BEGIN
        PRINT N'影厅已存在座位，跳过生成'
        RETURN 0
    END
    
    DECLARE @row INT = 1
    DECLARE @col INT
    DECLARE @seat_code NVARCHAR(10)
    DECLARE @seat_count INT = 0
    
    BEGIN TRY
        BEGIN TRANSACTION
        
        WHILE @row <= @rows
        BEGIN
            SET @col = 1
            WHILE @col <= @columns
            BEGIN
                -- 生成座位代码（A01, A02...）
                SET @seat_code = CHAR(64 + @row) + 
                                RIGHT('0' + CAST(@col AS NVARCHAR(2)), 2)
                
                INSERT INTO seats (hall_id, row_num, column_num, seat_code)
                VALUES (@hall_id, @row, @col, @seat_code)
                
                SET @col = @col + 1
                SET @seat_count = @seat_count + 1
            END
            SET @row = @row + 1
        END
        
        -- 更新影厅容量
        UPDATE halls 
        SET capacity = @rows * @columns,
            total_rows = @rows,
            total_columns = @columns,
            updated_at = GETDATE()
        WHERE hall_id = @hall_id
        
        COMMIT TRANSACTION
        
        PRINT N'成功生成 ' + CAST(@seat_count AS NVARCHAR) + N' 个座位'
        RETURN 0
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @error_message = ERROR_MESSAGE()
        RAISERROR(N'生成座位失败: %s', 16, 1, @error_message)
        RETURN -1
    END CATCH
END
GO

PRINT '存储过程创建完成'
GO

-- ============================================
-- 8. 插入示例数据
-- ============================================

PRINT '开始插入示例数据...'
GO

-- 8.1 插入影院数据
INSERT INTO cinemas (name, address, city, phone, opening_hours, facilities) 
VALUES 
(N'万达影城（朝阳店）', N'北京市朝阳区建国路93号万达广场3层', N'北京', '010-12345678', N'09:00-24:00', N'["IMAX", "4DX", "免费停车", "餐饮服务"]'),
(N'CGV影城（上海中心店）', N'上海市浦东新区陆家嘴环路128号', N'上海', '021-87654321', N'08:30-23:30', N'["IMAX", "情侣座", "儿童乐园", "会员休息室"]')

PRINT '影院数据插入完成'
GO

-- 8.2 插入影厅数据
INSERT INTO halls (cinema_id, hall_name, hall_type, total_rows, total_columns, capacity, facilities) 
VALUES 
(1, N'1号厅', 'IMAX', 10, 15, 150, N'["IMAX巨幕", "全景声"]'),
(1, N'2号厅', '3D', 8, 12, 96, N'["3D眼镜", "空调"]'),
(2, N'VIP厅', 'VIP', 6, 8, 48, N'["真皮沙发", "免费饮品", "独立卫生间"]')

PRINT '影厅数据插入完成'
GO

-- 8.3 插入电影数据
INSERT INTO movies (title, director, actors, duration, release_date, genres, description, rating) 
VALUES 
(N'流浪地球3', N'郭帆', N'["吴京", "刘德华", "李雪健"]', 148, '2024-02-10', N'科幻,灾难,冒险', N'太阳即将毁灭，人类在地球表面建造出巨大的推进器，寻找新的家园。', 9.2),
(N'热辣滚烫', N'贾玲', N'["贾玲", "雷佳音", "张小斐"]', 129, '2024-02-10', N'喜剧,剧情', N'乐莹宅家多年，无所事事。大学毕业工作一段时间后，乐莹选择脱离社会...', 8.7),
(N'飞驰人生2', N'韩寒', N'["沈腾", "范丞丞", "尹正"]', 121, '2024-02-10', N'喜剧,运动', N'昔日冠军车手张驰沦为落魄驾校教练，偶然的机会他重组车队，挑战最后一届巴音布鲁克拉力赛...', 8.5)

PRINT '电影数据插入完成'
GO

-- 8.4 插入场次数据（修正DATEADD用法）
DECLARE @today_date DATETIME
SET @today_date = CONVERT(DATE, GETDATE())

INSERT INTO screenings (movie_id, hall_id, start_time, end_time, price, available_seats) 
VALUES 
(1, 1, DATEADD(HOUR, 14, @today_date), DATEADD(MINUTE, 148, DATEADD(HOUR, 14, @today_date)), 89.00, 150),
(1, 1, DATEADD(HOUR, 19, @today_date), DATEADD(MINUTE, 148, DATEADD(HOUR, 19, @today_date)), 99.00, 150),
(2, 2, DATEADD(HOUR, 15, @today_date), DATEADD(MINUTE, 129, DATEADD(HOUR, 15, @today_date)), 69.00, 96),
(3, 3, DATEADD(HOUR, 20, @today_date), DATEADD(MINUTE, 121, DATEADD(HOUR, 20, @today_date)), 129.00, 48)

PRINT '场次数据插入完成'
GO

-- 8.5 插入用户数据
INSERT INTO users (username, password_hash, email, phone, full_name, balance, points) 
VALUES 
(N'zhangsan', 'hashed_password_123', 'zhangsan@email.com', '13800138001', N'张三', 500.00, 1000),
(N'lisi', 'hashed_password_456', 'lisi@email.com', '13800138002', N'李四', 200.00, 500),
(N'wangwu', 'hashed_password_789', 'wangwu@email.com', '13800138003', N'王五', 1000.00, 2000)

PRINT '用户数据插入完成'
GO

-- 8.6 生成座位（先确保存储过程存在）
PRINT '开始生成座位...'
EXEC generate_seats_for_hall @hall_id = 1, @rows = 10, @columns = 15
EXEC generate_seats_for_hall @hall_id = 2, @rows = 8, @columns = 12
EXEC generate_seats_for_hall @hall_id = 3, @rows = 6, @columns = 8
PRINT '座位生成完成'
GO

-- 8.7 插入优惠券数据
INSERT INTO coupons (coupon_code, coupon_name, coupon_type, discount_value, min_amount, start_date, end_date, total_quantity) 
VALUES 
('WELCOME2024', N'新用户优惠券', N'满减券', 20.00, 50.00, '2024-01-01', '2024-12-31', 10000),
('MOVIELOVER', N'影迷专属折扣', N'折扣券', 0.85, 0.00, '2024-01-01', '2024-12-31', 5000),
('WEEKEND30', N'周末特惠', N'折扣券', 0.70, 100.00, '2024-01-01', '2024-12-31', 3000)

PRINT '优惠券数据插入完成'
GO

-- 8.8 插入管理员数据
INSERT INTO admins (username, password_hash, full_name, email, role, cinema_id) 
VALUES 
('admin', 'hashed_admin_password', N'系统管理员', 'admin@cinema.com', N'超级管理员', NULL),
('cinema1_admin', 'hashed_cinema1_password', N'张经理', 'manager1@cinema.com', N'影院管理员', 1),
('cinema2_admin', 'hashed_cinema2_password', N'李经理', 'manager2@cinema.com', N'影院管理员', 2)

PRINT '管理员数据插入完成'
GO

-- ============================================
-- 9. 创建视图（简化版）
-- ============================================

-- 9.1 场次详情视图
CREATE VIEW v_screening_details AS
SELECT 
    s.screening_id,
    m.movie_id,
    m.title AS movie_title,
    m.poster_url,
    m.duration,
    m.rating AS movie_rating,
    c.cinema_id,
    c.name AS cinema_name,
    c.address AS cinema_address,
    c.city,
    h.hall_id,
    h.hall_name,
    h.hall_type,
    s.start_time,
    s.end_time,
    s.price,
    s.language_type,
    s.subtitle_type,
    s.available_seats,
    h.capacity AS total_seats,
    s.status AS screening_status
FROM screenings s
INNER JOIN movies m ON s.movie_id = m.movie_id
INNER JOIN halls h ON s.hall_id = h.hall_id
INNER JOIN cinemas c ON h.cinema_id = c.cinema_id
WHERE s.status = 1
AND m.status = 1
GO

-- 9.2 用户订单详情视图（简化版）
CREATE VIEW v_user_order_details AS
SELECT 
    o.order_id,
    o.user_id,
    u.username,
    u.full_name AS user_name,
    s.screening_id,
    m.movie_id,
    m.title AS movie_title,
    c.cinema_id,
    c.name AS cinema_name,
    h.hall_name,
    s.start_time,
    o.total_amount,
    o.discount_amount,
    o.actual_amount,
    o.order_status,
    o.payment_method,
    o.payment_time,
    o.contact_name,
    o.contact_phone,
    o.is_used,
    o.used_time,
    o.created_at AS order_time,
    COUNT(os.order_seat_id) AS seat_count
FROM orders o
INNER JOIN users u ON o.user_id = u.user_id
INNER JOIN screenings s ON o.screening_id = s.screening_id
INNER JOIN movies m ON s.movie_id = m.movie_id
INNER JOIN halls h ON s.hall_id = h.hall_id
INNER JOIN cinemas c ON h.cinema_id = c.cinema_id
LEFT JOIN order_seats os ON o.order_id = os.order_id
GROUP BY 
    o.order_id, o.user_id, u.username, u.full_name,
    s.screening_id, m.movie_id, m.title,
    c.cinema_id, c.name, h.hall_name,
    s.start_time, o.total_amount, o.discount_amount,
    o.actual_amount, o.order_status, o.payment_method,
    o.payment_time, o.contact_name, o.contact_phone,
    o.is_used, o.used_time, o.created_at
GO

PRINT '视图创建完成'
GO

-- ============================================
-- 10. 验证数据（修复PRINT语句）
-- ============================================

DECLARE @cinema_count INT, @hall_count INT, @movie_count INT, @screening_count INT
DECLARE @user_count INT, @seat_count INT, @coupon_count INT, @admin_count INT

SELECT @cinema_count = COUNT(*) FROM cinemas
SELECT @hall_count = COUNT(*) FROM halls
SELECT @movie_count = COUNT(*) FROM movies
SELECT @screening_count = COUNT(*) FROM screenings
SELECT @user_count = COUNT(*) FROM users
SELECT @seat_count = COUNT(*) FROM seats
SELECT @coupon_count = COUNT(*) FROM coupons
SELECT @admin_count = COUNT(*) FROM admins

PRINT '=== 数据验证 ==='
PRINT '影院数量: ' + CAST(@cinema_count AS NVARCHAR(10))
PRINT '影厅数量: ' + CAST(@hall_count AS NVARCHAR(10))
PRINT '电影数量: ' + CAST(@movie_count AS NVARCHAR(10))
PRINT '场次数量: ' + CAST(@screening_count AS NVARCHAR(10))
PRINT '用户数量: ' + CAST(@user_count AS NVARCHAR(10))
PRINT '座位数量: ' + CAST(@seat_count AS NVARCHAR(10))
PRINT '优惠券数量: ' + CAST(@coupon_count AS NVARCHAR(10))
PRINT '管理员数量: ' + CAST(@admin_count AS NVARCHAR(10))
PRINT ''
PRINT '=== 数据库创建完成 ==='
PRINT '数据库名称: cinema_ticket_system'
PRINT '创建时间: ' + CONVERT(NVARCHAR(20), GETDATE(), 120)
PRINT '表数量: 14'
PRINT '视图数量: 2'
PRINT '函数数量: 2'
PRINT '存储过程数量: 1'
PRINT ''
PRINT '系统已准备就绪，可以开始使用！'
GO

-- 查看所有影院
SELECT * FROM cinemas;

-- 查看北京地区的影院
SELECT * FROM cinemas WHERE city = '北京';

-- 查看影院及影厅数量
SELECT c.*, COUNT(h.hall_id) as hall_count
FROM cinemas c
LEFT JOIN halls h ON c.cinema_id = h.cinema_id
GROUP BY c.cinema_id, c.name, c.address, c.city, c.phone, c.email, 
         c.opening_hours, c.facilities, c.status, c.created_at, c.updated_at;

-- 查看所有电影
SELECT * FROM movies;

-- 查看正在上映的电影
SELECT * FROM movies WHERE status = 1;

-- 按评分排序
SELECT * FROM movies ORDER BY rating DESC;

-- 搜索电影
SELECT * FROM movies WHERE title LIKE'热辣%'

-- 使用视图查看场次详情
SELECT * FROM v_screening_details;

-- 查看特定电影的场次
SELECT * FROM v_screening_details 
WHERE movie_title = '流浪地球3'
ORDER BY start_time;

-- 查看某影院的场次
SELECT * FROM v_screening_details 
WHERE cinema_name = '万达影城（朝阳店）'
AND start_time > GETDATE();

-- 查看影厅座位
SELECT * FROM seats WHERE hall_id = 1;

-- 查看某场次的座位状态
SELECT 
    s.seat_id,
    s.seat_code,
    s.seat_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM order_seats os
            INNER JOIN orders o ON os.order_id = o.order_id
            WHERE os.seat_id = s.seat_id 
            AND o.screening_id = 1
            AND o.order_status IN ('待支付', '已支付')
        ) THEN '已售'
        ELSE '可选'
    END as seat_status
FROM seats s
WHERE s.hall_id = (SELECT hall_id FROM screenings WHERE screening_id = 1)
ORDER BY s.row_num, s.column_num;

-- 管理员添加新电影
INSERT INTO movies (title, director, actors, duration, release_date, genres, description)
VALUES ('新电影1', '导演1', '["主演1.1", "主演1.2"]', 120, '2024-04-01', '剧情,爱情', '电影简介');

-- 直接按电影标题删除
DELETE FROM movies WHERE title = '新电影1'; 

-- 最简方式：列出 cinema_ticket_system 所有用户表名
USE cinema_ticket_system;
GO
SELECT name AS 表名 FROM sys.tables;
USE cinema_ticket_system;
GO

-- 1. 影院表
SELECT TOP 10 * FROM cinemas;
PRINT '--------------------------';

-- 2. 影厅表
SELECT TOP 10 * FROM halls;
PRINT '--------------------------';

-- 3. 电影表
SELECT TOP 10 * FROM movies;
PRINT '--------------------------';

-- 4. 放映场次表
SELECT TOP 10 * FROM screenings;
PRINT '--------------------------';

-- 5. 用户表
SELECT TOP 10 * FROM users;
PRINT '--------------------------';

-- 6. 座位表
SELECT TOP 10 * FROM seats;
PRINT '--------------------------';

-- 7. 订单表
SELECT TOP 10 * FROM orders;
PRINT '--------------------------';

-- 8. 订单座位关联表
SELECT TOP 10 * FROM order_seats;
PRINT '--------------------------';

-- 9. 优惠券表
SELECT TOP 10 * FROM coupons;
PRINT '--------------------------';

-- 10. 用户优惠券表
SELECT TOP 10 * FROM user_coupons;
PRINT '--------------------------';

-- 11. 评论表
SELECT TOP 10 * FROM reviews;
PRINT '--------------------------';

-- 12. 管理员表
SELECT TOP 10 * FROM admins;
PRINT '--------------------------';