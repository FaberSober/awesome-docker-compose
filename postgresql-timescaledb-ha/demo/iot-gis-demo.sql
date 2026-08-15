-------------------------------------
--                                 --
--        存储车辆的GPS定位信息          --
--                                 --
-------------------------------------
--第一部分：详细操作步骤
--Step 1: 准备环境与插件
--确保你的数据库已经开启了必要的扩展。
-- TimescaleDB 开启
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- 常用扩展（可选）
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

--Step 2: 创建数据表
--我们创建一个名为 vehicle_positions 的表。
CREATE TABLE vehicle_positions (
    time        TIMESTAMPTZ NOT NULL,       -- 时间戳（必须）
    device_id   INTEGER NOT NULL,           -- 车辆/设备ID
    latitude    DOUBLE PRECISION,           -- 原始纬度
    longitude   DOUBLE PRECISION,           -- 原始经度
    location    GEOMETRY(POINT, 4326),      -- PostGIS 空间点 (WGS84坐标系)
    speed       DOUBLE PRECISION,           -- 速度 (km/h)
    heading     DOUBLE PRECISION,           -- 航向/角度 (0-360)
    status      JSONB                       -- 用于存储不定长的扩展字段（如油量、报警位等）
);

--Step 3: 转换为 Hypertable (时序分片)
--这是 TimescaleDB 的核心。我们按 time 进行切分。
-- 将普通表转换为 Hypertable
-- chunk_time_interval 建议根据数据量设定，数据量巨大时建议设为 1天 或 1周
SELECT create_hypertable('vehicle_positions', 'time', chunk_time_interval => INTERVAL '1 day');

--Step 4: 创建索引
--为了满足“查轨迹”和“查附近”的需求，我们需要复合索引和空间索引。
-- 1. 基础查询索引：查找特定车辆在特定时间的记录 (Hypertable 自动会对 time 建立索引，但加上 device_id 效率更高)
CREATE INDEX ix_device_time ON vehicle_positions (device_id, time DESC);

-- 2. 空间索引：用于 ST_DWithin 等地理查询
CREATE INDEX ix_location_gist ON vehicle_positions USING GIST (location);

--Step 5: 启用原生压缩 (关键步骤)
--对于大数据量，必须启用压缩。压缩后的数据不仅省空间，而且对于分析型查询（如“这辆车过去一个月的平均速度”）更快，因为加载的数据块更小。
-- 设置压缩策略
-- segmentby:按设备ID分段（同一设备的数据压在一起）
-- orderby: 按时间排序
ALTER TABLE vehicle_positions SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id',
    timescaledb.compress_orderby = 'time DESC'
);

-- 添加自动压缩策略：自动压缩 7 天前的数据
-- 注意：压缩后的数据默认是只读的（虽然最新版支持部分更新，但建议将其视为归档）
SELECT add_compression_policy('vehicle_positions', INTERVAL '7 days');

--Step 6: (可选) 设置数据保留策略
--如果你不需要永久保存数据（例如只保留 1 年），可以设置自动清理。
-- 自动删除 1 年前的数据
SELECT add_retention_policy('vehicle_positions', INTERVAL '1 year');

--第二部分：常用场景操作说明
--这里列出开发中最常遇到的 4 个场景的 SQL 写法。

--场景 1: 写入数据 (Insert)
--写入时，需要利用 PostGIS 函数将经纬度转换为 Geometry 对象。
INSERT INTO vehicle_positions (time, device_id, latitude, longitude, location, speed, heading, status)
VALUES (
    NOW(),
    1001,
    39.9042, 
    116.4074,
    ST_SetSRID(ST_MakePoint(116.4074, 39.9042), 4326), -- 注意：MakePoint是(经度, 纬度)
    60.5,
    180.0,
    '{"engine_temp": 90, "fuel": 80}'
);

--场景 2: 查询某辆车的历史轨迹 (Trajectory)
--通常用于在地图上画线。
SELECT time, latitude, longitude, speed
FROM vehicle_positions
WHERE device_id = 1001
  AND time > NOW() - INTERVAL '6 hours'
ORDER BY time ASC;

--场景 3: 空间搜索 - 查找附近的车辆 (Nearby Search)
--这是 PostGIS 的强项。查找距离某个坐标点（例如某仓库） 5 公里内的所有车辆记录。
-- 假设中心点为 (116.40, 39.90)
SELECT time, device_id, latitude, longitude
FROM vehicle_positions
WHERE time > NOW() - INTERVAL '5 minutes' -- 仅查最近5分钟活跃的
  AND ST_DWithin(
      location, 
      ST_SetSRID(ST_MakePoint(116.40, 39.90), 4326)::geography, -- 转为 geography 计算米
      5000 -- 距离 5000 米
  );

--场景 4: 数据降采样 (Downsampling)
--这是 TimescaleDB 的杀手级功能。 当你要查询某辆车过去一个月的轨迹时，直接 SELECT 会返回数百万个点，前端会卡死。你需要使用 time_bucket 来降低数据密度（例如：每 5 分钟取一个点）。
SELECT 
    time_bucket('5 minutes', time) AS bucket, -- 每5分钟一个桶
    last(latitude, time) as lat,              -- 取该时间段最后一个点的纬度
    last(longitude, time) as lon,             -- 取该时间段最后一个点的经度
    max(speed) as max_speed                   -- 计算该时间段最高速
FROM vehicle_positions
WHERE device_id = 1001
  AND time > NOW() - INTERVAL '7 days'
GROUP BY bucket
ORDER BY bucket;

--第三部分：给你的建议 (Pro Tips)
--经纬度顺序：PostGIS 的 ST_MakePoint 参数顺序是 (经度 Longitude, 纬度 Latitude)，也就是 (X, Y)。千万别弄反了，否则定位会跑去南极或非洲。
--
--Geography vs Geometry：
--
--在表定义中，我使用了 GEOMETRY(POINT, 4326)，这在存储和简单平面计算上更快。
--
--但在计算距离（ST_DWithin 或 ST_Distance）时，建议强转为 ::geography（如场景3所示），这样计算单位是米，而不是度，结果更精确。
--
--更新与删除：TimescaleDB 对压缩数据的 Update/Delete 操作有性能惩罚。尽量将 GPS 数据视为“不可变日志流”（Append-only）。如果必须修正数据，建议在数据尚未被压缩（例如最近 7 天）的时间窗口内进行。

--我们要生成的数据总量约为： 30天 * 24小时 * 3600秒 * 3辆车 ≈ 7,776,000 条数据。
--
--对于 PostgreSQL + TimescaleDB 来说，写入 700 多万条数据通常只需要几秒到几十秒（取决于你的硬件），因为我们使用的是批量生成 (INSERT INTO ... SELECT)。
--
--SQL 脚本说明
--为了让数据看起来真实（不是所有点都重叠在一起），我在 SQL 中使用了一点三角函数（sin, cos）来模拟车辆在地图上绕圈行驶的轨迹。
--
--完整的生成脚本
--请直接在数据库中执行以下 SQL：

-- 1. 清理旧数据（可选，如果你想重测）
-- TRUNCATE TABLE vehicle_positions;
--select * from vehicle_positions;

-- 2. 批量生成并插入数据
INSERT INTO vehicle_positions (time, device_id, latitude, longitude, location, speed, heading, status)
SELECT
    t.time_point,
    d.device_id,
    -- 模拟纬度: 基础纬度 + 设备偏移 + 基于时间的移动(sin)
    39.90 + (d.device_id * 0.01) + (0.05 * sin(extract(epoch from t.time_point) / 1000.0)) AS latitude,
    -- 模拟经度: 基础经度 + 设备偏移 + 基于时间的移动(cos)
    116.40 + (d.device_id * 0.01) + (0.05 * cos(extract(epoch from t.time_point) / 1000.0)) AS longitude,
    -- PostGIS Geometry 对象 (注意: MakePoint是 经度, 纬度)
    ST_SetSRID(ST_MakePoint(
        116.40 + (d.device_id * 0.01) + (0.05 * cos(extract(epoch from t.time_point) / 1000.0)), 
        39.90 + (d.device_id * 0.01) + (0.05 * sin(extract(epoch from t.time_point) / 1000.0))
    ), 4326) AS location,
    -- 模拟速度: 20到100之间的随机数
    20 + (random() * 80) AS speed,
    -- 模拟方向: 0到360
    random() * 360 AS heading,
    -- 模拟状态: 随机JSON
    jsonb_build_object('engine_temp', (80 + random()*20)::int, 'fuel', (100 - (extract(hour from t.time_point)))::int)
FROM 
    -- 生成过去30天的时间序列，步长为1秒
    generate_series(NOW() - INTERVAL '30 days', NOW(), INTERVAL '1 second') AS t(time_point)
CROSS JOIN 
    -- 生成3个车辆ID (1001, 1002, 1003)
    (VALUES (1001), (1002), (1003)) AS d(device_id);

--验证数据是否录入成功
--数据录入后，你可以执行以下查询来验证结果：
--
--1. 检查总数据量
--应该接近 777 万条。
SELECT count(*) FROM vehicle_positions;

--2. 检查每辆车的数据分布
SELECT device_id, count(*), min(time), max(time)
FROM vehicle_positions
GROUP BY device_id
ORDER BY device_id;

--3. 查看压缩效果（非常重要）
--由于你刚刚写入的是“历史数据”（过去30天），TimescaleDB 的后台压缩作业可能还没运行。你可以手动触发一次压缩，看看效果。
-- 查看压缩前后的存储空间对比
SELECT * FROM hypertable_detailed_size('vehicle_positions');

-- 手动压缩 30 天前到 1 小时前的数据（确保覆盖刚才生成的历史数据）
SELECT compress_chunk(i)
FROM show_chunks('vehicle_positions') i;

-- 查看压缩前后的存储空间对比
SELECT * FROM hypertable_detailed_size('vehicle_positions');


--在 DBeaver 中查看带有 PostGIS 数据的轨迹非常方便。为了获得最佳的地图可视化体验，我为你准备了两种 SQL 查询方案：
--
--点模式（Points）：可以看到每一个定位点，适合查看具体的点位分布。
--
--线模式（LineString）：将点连接成一条连续的轨迹线，这才是真正的“轨迹”。
--
--方案一：查看连续轨迹线 (推荐)
--这个查询利用 PostGIS 的 ST_MakeLine 聚合函数，将该车辆当天的所有点按时间排序后，连成一条完整的线。
SELECT 
    -- 将所有点按时间排序连接成一条线
    ST_MakeLine(location ORDER BY time) AS trajectory_line,
    -- 也可以计算一下当天的总里程(单位:米)作为参考
    ST_Length(ST_MakeLine(location ORDER BY time)::geography) AS total_distance_meters
FROM vehicle_positions
WHERE device_id = 1001
  AND time >= '2025-11-18 00:00:00'
  AND time <  '2025-11-19 00:00:00';

--方案二：查看原始散点
--如果你想看具体的每一个点（点击地图上的点可以看到该点的时间和速度），请使用这个查询：
SELECT 
    time, 
    speed, 
    location -- DBeaver 会自动识别这个 Geometry 字段
FROM vehicle_positions
WHERE device_id = 1001
  AND time >= '2025-11-18 00:00:00'
  AND time <  '2025-11-19 00:00:00'
ORDER BY time ASC;

--如何在 DBeaver 中操作查看地图
--执行上述任意一个 SQL 后，请按照以下步骤在地图上显示：
--
--运行查询：点击运行按钮（Ctrl+Enter）。
--
--找到结果集：在下方的“Result”面板中。
--
--切换到空间视图：
--
--在结果面板的右侧垂直栏（通常在 Result Grid 的右边），你会看到一个 "Spatial"（或者图标是地球仪/地图形状）的标签。
--
--点击它。
--
--配置地图底图（如果是第一次打开）：
--
--如果是空白背景，点击地图控件角落的设置或 Leaflet / CRS 按钮。
--
--确保坐标系（SRID）被识别为 4326 (WGS 84)。
--
--DBeaver 通常默认使用 OpenStreetMap 作为底图，你应该能直接看到车辆轨迹叠加在地图上。
--
--💡 性能优化小技巧
--由于你是“每秒一个点”，一天可能有 86,400 个点。 如果直接在 DBeaver 里渲染 方案一 或 方案二 感觉卡顿，或者地图加载太慢，建议使用 TimescaleDB 的 time_bucket 或 ST_Simplify 进行降采样（抽稀），只显示大致轮廓：
-- 优化版：每分钟取一个点连成线（数据量减少60倍，渲染极快，形状基本不变）
SELECT 
    ST_MakeLine(location ORDER BY bucket) AS trajectory_line
FROM (
    SELECT 
        time_bucket('1 minute', time) AS bucket,
        first(location, time) as location -- 每分钟取第一个点
    FROM vehicle_positions
    WHERE device_id = 1001
      AND time >= '2025-11-18 00:00:00'
      AND time <  '2025-11-19 00:00:00'
    GROUP BY bucket
) sub;


