SELECT PostGIS_Full_Version();

-- 创建简单点位表
CREATE TABLE places (
  id SERIAL PRIMARY KEY,
  name TEXT,
  geom GEOGRAPHY(Point, 4326)
);

--2. 插入测试数据
INSERT INTO places (name, geom) VALUES
('Shanghai', ST_GeogFromText('POINT(121.4737 31.2304)')),
('Beijing', ST_GeogFromText('POINT(116.4074 39.9042)')),
('Guangzhou', ST_GeogFromText('POINT(113.2644 23.1291)'));

--📌 3. 查询两个点之间的实际地球距离（米）
SELECT 
  p1.name,
  p2.name,
  ST_Distance(p1.geom, p2.geom) AS meters
FROM places p1, places p2
WHERE p1.id < p2.id;

--📌 4. 查询在某个点 10km 范围内的地点
SELECT *
FROM places
WHERE ST_DWithin(
  geom,
  ST_GeogFromText('POINT(121.47 31.23)'), -- 用户位置
  10000  -- 半径10公里
);

--📌 5. 创建空间索引（极其重要）
--PostGIS 查询性能靠 GiST/SpGIST 索引：
CREATE INDEX idx_places_geom ON places USING GIST (geom);
--查询速度会从 秒级 → 毫秒级。

--📌 6. 查询最近的地点（KNN 查询）
SELECT name,
       ST_Distance(geom, ST_GeogFromText('POINT(121.47 31.23)')) AS meters
FROM places
ORDER BY geom <-> ST_GeogFromText('POINT(121.47 31.23)')
LIMIT 1;
--<-> 是 PostGIS 的 KNN 算子（需要 GiST 索引）。

--📌 7. Geography vs Geometry 区别（非常关键）
--类型	使用场景	距离计算	性能
--GEOGRAPHY	地球经纬度	椭球体真实距离（精准）	慢
--GEOMETRY	2D 平面地图、投影坐标	平面距离（快）	快
--
--如果你要做地图可视化、范围裁剪、轨迹分析：
--✔ 推荐 GEOMETRY(…. 3857)
--
--如果你要做 GPS 实际距离：
--✔ 用 GEOGRAPHY

--📌 8. 创建多边形表（行政区、地理围栏）
CREATE TABLE geofences (
  id SERIAL PRIMARY KEY,
  name TEXT,
  area GEOMETRY(Polygon, 4326)
);

--插入一个简单 polygon：
INSERT INTO geofences (name, area)
VALUES (
  'Test Fence',
  ST_GeomFromText('POLYGON((121.45 31.22, 121.48 31.22, 121.48 31.24, 121.45 31.24, 121.45 31.22))', 4326)
);

--📌 9. 判断点是否在多边形范围内（Geofencing）
SELECT p.name, g.name AS fence
FROM places p
JOIN geofences g
ON ST_Contains(g.area, ST_SetSRID(p.geom::geometry, 4326));

--📌 10. Buffer（缓冲区）：计算一个点周围的区域
--例如：输入一个点，生成 5km 范围多边形：
SELECT ST_Buffer(geom::geography, 5000)::geometry AS area
FROM places
WHERE name = 'Shanghai';

--📌 11. 导出为 GeoJSON（用于前端地图）
SELECT jsonb_build_object(
  'type', 'Feature',
  'geometry', ST_AsGeoJSON(geom)::jsonb,
  'properties', jsonb_build_object('id', id, 'name', name)
)
FROM places;

--📌 12. 导入 GeoJSON
INSERT INTO geofences (name, area)
SELECT 
  'GeoJSON Area',
  ST_GeomFromGeoJSON('{
    "type":"Polygon",
    "coordinates":[[
      [121.45,31.22],
      [121.48,31.22],
      [121.48,31.24],
      [121.45,31.24],
      [121.45,31.22]
    ]]
  }');

--📌 13. 轨迹表（Linestring）示例
CREATE TABLE tracks (
  id SERIAL PRIMARY KEY,
  device_id TEXT,
  path GEOMETRY(LineString, 4326)
);

--插入轨迹：
INSERT INTO tracks (device_id, path)
VALUES ('dev1', ST_GeomFromText('LINESTRING(121.47 31.23, 121.48 31.24, 121.50 31.25)', 4326));

--计算轨迹长度（米）：
SELECT ST_Length(path::geography) FROM tracks;

--📌 14. 土地面积、行政区域面积
SELECT name,
       ST_Area(area::geography) / 1000000 AS sq_km
FROM geofences;

--📌 15. 与 TimescaleDB 的时空组合（时序轨迹）
--如果你记录 GPS + 时间：
CREATE TABLE gps_points (
  time TIMESTAMPTZ NOT NULL,
  device_id TEXT,
  geom GEOMETRY(Point, 4326)
);

SELECT create_hypertable('gps_points', 'time');

--查询某设备的移动距离：
--SELECT device_id,
--       SUM(ST_Distance(
--           LAG(geom) OVER (PARTITION BY device_id ORDER BY time),
--           geom
--       )) AS total_distance
--FROM gps_points
--GROUP BY device_id;
WITH distances AS (
    SELECT
        device_id,
        time,
        geom,
        LAG(geom) OVER (PARTITION BY device_id ORDER BY time) AS prev_geom
    FROM gps_points
)
SELECT 
    device_id,
    SUM(ST_Distance(prev_geom, geom)) AS total_distance
FROM distances
WHERE prev_geom IS NOT NULL
GROUP BY device_id;

--✅ 示例 INSERT 数据（可直接执行）
-- Device 1：模拟一条从 (116.397) 向北移动的轨迹
INSERT INTO gps_points (time, device_id, geom) VALUES
('2025-01-01 08:00:00+08' , 'device_1', ST_SetSRID(ST_MakePoint(116.397, 39.908), 4326)),
('2025-01-01 08:01:00+08' , 'device_1', ST_SetSRID(ST_MakePoint(116.3975, 39.909), 4326)),
('2025-01-01 08:02:00+08' , 'device_1', ST_SetSRID(ST_MakePoint(116.398, 39.910), 4326)),
('2025-01-01 08:03:00+08' , 'device_1', ST_SetSRID(ST_MakePoint(116.3983, 39.911), 4326)),
('2025-01-01 08:04:00+08' , 'device_1', ST_SetSRID(ST_MakePoint(116.3987, 39.912), 4326)),
('2025-01-01 08:05:00+08' , 'device_1', ST_SetSRID(ST_MakePoint(116.3990, 39.913), 4326));

-- Device 2：模拟一条从 (121.473) 向东移动的轨迹
INSERT INTO gps_points (time, device_id, geom) VALUES
('2025-01-01 09:00:00+08' , 'device_2', ST_SetSRID(ST_MakePoint(121.473, 31.230), 4326)),
('2025-01-01 09:01:00+08' , 'device_2', ST_SetSRID(ST_MakePoint(121.4738, 31.2302), 4326)),
('2025-01-01 09:02:00+08' , 'device_2', ST_SetSRID(ST_MakePoint(121.4745, 31.2304), 4326)),
('2025-01-01 09:03:00+08' , 'device_2', ST_SetSRID(ST_MakePoint(121.4751, 31.2306), 4326)),
('2025-01-01 09:04:00+08' , 'device_2', ST_SetSRID(ST_MakePoint(121.4756, 31.2308), 4326)),
('2025-01-01 09:05:00+08' , 'device_2', ST_SetSRID(ST_MakePoint(121.4760, 31.2310), 4326));

--📌 数据预览（说明）
--device_1
--北京天安门附近附近模拟轨迹
--每分钟移动约 0.001°（约 80–100 米）
--适合距离计算和速度分析
--
--device_2
--上海外滩附近模拟轨迹
--每分钟向东移动约 0.0008°（约 70 米）
--
--⭐ 可立即测试的轨迹分析 SQL
--1）计算两条轨迹的总移动距离
WITH distances AS (
    SELECT
        device_id,
        time,
        ST_Distance(
            LAG(geom) OVER (PARTITION BY device_id ORDER BY time),
            geom
        ) AS dist
    FROM gps_points
)
SELECT device_id, SUM(dist) AS total_distance
FROM distances
WHERE dist IS NOT NULL
GROUP BY device_id;

--2）计算速度 km/h
WITH p AS (
    SELECT
        device_id,
        time,
        LAG(time) OVER (PARTITION BY device_id ORDER BY time) AS prev_time,
        LAG(geom) OVER (PARTITION BY device_id ORDER BY time) AS prev_geom,
        geom
    FROM gps_points
),
d AS (
    SELECT
        device_id,
        EXTRACT(EPOCH FROM time - prev_time) / 3600 AS hours,
        ST_Distance(prev_geom, geom) / 1000 AS km
    FROM p
    WHERE prev_geom IS NOT NULL
)
SELECT 
    device_id,
    SUM(km) AS total_km,
    SUM(hours) AS total_hours,
    SUM(km) / SUM(hours) AS avg_speed_kmh
FROM d
GROUP BY device_id;

