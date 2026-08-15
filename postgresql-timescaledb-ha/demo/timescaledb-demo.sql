SELECT extname, extversion FROM pg_extension;

DROP TABLE metrics;
CREATE TABLE metrics (
  time TIMESTAMPTZ NOT NULL,
  device_id TEXT,
  value DOUBLE PRECISION
);

-- SELECT create_hypertable('metrics', 'time');

SELECT create_hypertable(
    'metrics',
    'time',
    chunk_time_interval => interval '1 day',  -- 每天一个 chunk
    partitioning_column => 'device_id',
    number_partitions => 10
);

-- 时间 + 设备联合索引
CREATE INDEX ON metrics (device_id, time DESC);

-- 或者单列索引
CREATE INDEX ON metrics (time DESC);

-- 数据插入示例
INSERT INTO metrics (time, device_id, value)
VALUES
('2025-11-17 21:00:00+00', 'device01', 12.5),
('2025-11-17 21:01:00+00', 'device01', 13.0),
('2025-11-17 21:00:00+00', 'device02', 7.8);

SELECT
    time_bucket('1 minute', time) AS minute,
    device_id,
    AVG(value) AS avg_value,
    MAX(value) AS max_value,
    MIN(value) AS min_value
FROM metrics
GROUP BY minute, device_id
ORDER BY minute DESC;

SELECT *
FROM metrics
WHERE time > NOW() - INTERVAL '1 hour'
ORDER BY time DESC;

-- 启用压缩
ALTER TABLE metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id'
);

-- 压缩超过 7 天的历史数据
SELECT add_compression_policy('metrics', INTERVAL '7 days');

-- 如果你需要 实时统计指标，TimescaleDB 可以创建 物化视图，自动聚合：
CREATE MATERIALIZED VIEW metrics_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS hour,
    device_id,
    AVG(value) AS avg_value,
    MAX(value) AS max_value
FROM metrics
GROUP BY hour, device_id;

--自动维护最新数据
--查询历史聚合时极快
--可以设置刷新策略
SELECT add_continuous_aggregate_policy('metrics_hourly',
  start_offset => INTERVAL '1 day',
  end_offset => INTERVAL '1 hour',
  schedule_interval => INTERVAL '15 minutes');

