# Telling Logger Backend Specification

This document specifies the backend requirements for supporting Telling Logger SDK features.

## Overview

The Telling Logger backend must support:
1. Basic log ingestion and storage
2. User properties tracking
3. Performance metrics analytics
4. User segmentation and filtering

## Database Schema

### Existing Tables

#### `logs` table
Primary table for all log events.

```sql
CREATE TABLE logs (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id),
    user_id VARCHAR(255),
    user_name VARCHAR(255),
    user_email VARCHAR(255),
    session_id VARCHAR(255),
    level VARCHAR(50) NOT NULL, -- trace, debug, info, warning, error, fatal
    type VARCHAR(50) NOT NULL, -- general, analytics, event, performance, network, security, exception, crash, custom
    message TEXT NOT NULL,
    stack_trace TEXT,
    metadata JSONB,
    device_platform VARCHAR(100),
    device_os_version VARCHAR(100),
    device_model VARCHAR(255),
    app_version VARCHAR(50),
    app_build_number VARCHAR(50),
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_project_timestamp (project_id, timestamp DESC),
    INDEX idx_user_id (project_id, user_id),
    INDEX idx_session_id (project_id, session_id),
    INDEX idx_level (project_id, level),
    INDEX idx_type (project_id, type),
    INDEX idx_metadata (project_id) USING GIN (metadata)
);
```

### New Tables for User Properties

#### `user_properties` table
Stores user property key-value pairs.

```sql
CREATE TABLE user_properties (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id),
    user_id VARCHAR(255) NOT NULL,
    property_key VARCHAR(255) NOT NULL,
    property_value JSONB NOT NULL,
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(project_id, user_id, property_key),
    INDEX idx_project_user (project_id, user_id),
    INDEX idx_property_key (project_id, property_key)
);
```

**Note**: User properties are also stored in log `metadata` as `_user_properties` for historical tracking.

### New Tables for Performance Metrics

#### `performance_metrics` table
Dedicated table for performance data (optional - can use logs table).

```sql
CREATE TABLE performance_metrics (
    id SERIAL PRIMARY KEY,
    project_id INTEGER NOT NULL REFERENCES projects(id),
    user_id VARCHAR(255),
    session_id VARCHAR(255),
    metric_type VARCHAR(100) NOT NULL, -- startup_time, fps, memory, screen_load
    value NUMERIC NOT NULL,
    metadata JSONB,
    timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    
    INDEX idx_project_metric (project_id, metric_type, timestamp DESC),
    INDEX idx_user_metrics (project_id, user_id, metric_type)
);
```

**Alternative**: Use existing `logs` table with `type = 'performance'` and parse metrics from metadata.

---

## API Endpoints

### 1. Log Ingestion (Existing)

**Endpoint:** `POST /api/v1/logs`

**Headers:**
```
Content-Type: application/json
x-api-key: {PROJECT_API_KEY}
```

**Request Body:**
```json
[
  {
    "id": "1700000000000",
    "type": "analytics",
    "level": "info",
    "message": "User logged in",
    "timestamp": "2025-01-15T12:00:00.000Z",
    "userId": "user_123",
    "userName": "John Doe",
    "userEmail": "john@example.com",
    "sessionId": "user_123_1700000000000",
    "metadata": {
      "login_method": "google",
      "_user_properties": {
        "subscription_tier": "premium",
        "mrr": 99.99,
        "signup_date": "2025-01-01"
      }
    },
    "device": {
      "platform": "iOS",
      "osVersion": "17.0",
      "deviceModel": "iPhone 15 Pro",
      "appVersion": "1.2.0",
      "appBuildNumber": "42"
    }
  }
]
```

**Response:** `200 OK`
```json
{
  "success": true,
  "received": 1
}
```

**Processing:**
1. Validate API key
2. Insert logs into `logs` table
3. If `_user_properties` exists in metadata, upsert to `user_properties` table
4. If `type = 'performance'`, optionally insert to `performance_metrics` table

---

### 2. User Properties (New)

#### Get User Properties

**Endpoint:** `GET /api/v1/users/{userId}/properties`

**Headers:**
```
x-api-key: {PROJECT_API_KEY}
```

**Response:** `200 OK`
```json
{
  "userId": "user_123",
  "properties": {
    "subscription_tier": "premium",
    "mrr": 99.99,
    "signup_date": "2025-01-01",
    "plan_renewal_date": "2025-12-31"
  },
  "updatedAt": "2025-01-15T12:00:00.000Z"
}
```

#### Set/Update User Properties

**Endpoint:** `POST /api/v1/users/{userId}/properties`

**Headers:**
```
Content-Type: application/json
x-api-key: {PROJECT_API_KEY}
```

**Request Body:**
```json
{
  "properties": {
    "subscription_tier": "enterprise",
    "mrr": 299.99
  }
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "updated": 2
}
```

**Processing:**
```sql
INSERT INTO user_properties (project_id, user_id, property_key, property_value, updated_at)
VALUES ($1, $2, $3, $4, NOW())
ON CONFLICT (project_id, user_id, property_key)
DO UPDATE SET property_value = $4, updated_at = NOW();
```

---

### 3. Performance Analytics (New)

#### Get Performance Overview

**Endpoint:** `GET /api/v1/analytics/performance/overview`

**Query Parameters:**
- `startDate` - ISO 8601 date
- `endDate` - ISO 8601 date
- `metric` - (optional) Filter by metric type

**Response:** `200 OK`
```json
{
  "period": {
    "start": "2025-01-01T00:00:00.000Z",
    "end": "2025-01-31T23:59:59.000Z"
  },
  "metrics": {
    "startup_time": {
      "avg_ms": 1250,
      "p50_ms": 1100,
      "p90_ms": 1800,
      "p95_ms": 2200,
      "p99_ms": 3500,
      "samples": 15234
    },
    "fps": {
      "avg": 58.5,
      "samples": 8934
    }
  }
}
```

**Query:**
```sql
SELECT 
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (metadata->>'startup_time_ms')::numeric) as p50,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY (metadata->>'startup_time_ms')::numeric) as p90,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY (metadata->>'startup_time_ms')::numeric) as p95,
  AVG((metadata->>'startup_time_ms')::numeric) as avg,
  COUNT(*) as samples
FROM logs
WHERE project_id = $1
  AND type = 'performance'
  AND message = 'App Startup'
  AND timestamp BETWEEN $2 AND $3;
```

---

## Analytics Queries

### User Segmentation by Properties

Find all users with specific property values:

```sql
SELECT DISTINCT l.user_id, l.user_name, l.user_email
FROM logs l
WHERE l.project_id = $1
  AND l.metadata->'_user_properties'->>'subscription_tier' = 'premium'
  AND l.timestamp > NOW() - INTERVAL '30 days';
```

### Performance Trends Over Time

Get startup time trend by day:

```sql
SELECT 
  DATE(timestamp) as date,
  AVG((metadata->>'startup_time_ms')::numeric) as avg_startup_ms,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY (metadata->>'startup_time_ms')::numeric) as p90_startup_ms
FROM logs
WHERE project_id = $1
  AND type = 'performance'
  AND message = 'App Startup'
  AND timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

### Error Rate by User Tier

Compare error rates across subscription tiers:

```sql
SELECT 
  metadata->'_user_properties'->>'subscription_tier' as tier,
  COUNT(*) as total_logs,
  COUNT(*) FILTER (WHERE level IN ('error', 'fatal')) as error_count,
  (COUNT(*) FILTER (WHERE level IN ('error', 'fatal'))::float / COUNT(*)) * 100 as error_rate
FROM logs
WHERE project_id = $1
  AND timestamp > NOW() - INTERVAL '7 days'
  AND metadata->'_user_properties'->>'subscription_tier' IS NOT NULL
GROUP BY metadata->'_user_properties'->>'subscription_tier';
```

---

## Data Retention

Recommended retention policies:

| Data Type | Retention | Notes |
|-----------|-----------|-------|
| Debug/Trace Logs | 7 days | High volume, low value |
| Info Logs | 30 days | Standard retention |
| Warning/Error Logs | 90 days | Important for debugging |
| Performance Metrics | 90 days | Trend analysis |
| User Properties | Forever | Current user state |
| Analytics Events | 1 year | Business intelligence |

**Implementation:**
```sql
-- Auto-delete old logs
DELETE FROM logs 
WHERE created_at < NOW() - INTERVAL '90 days' 
  AND level NOT IN ('error', 'fatal');
```

---

## Performance Optimization

### Indexes

Critical indexes for query performance:

```sql
-- Time-series queries
CREATE INDEX idx_logs_project_type_timestamp 
ON logs (project_id, type, timestamp DESC);

-- User activity queries  
CREATE INDEX idx_logs_user_timestamp 
ON logs (project_id, user_id, timestamp DESC);

-- Metadata searches (GIN index for JSONB)
CREATE INDEX idx_logs_metadata 
ON logs USING GIN (metadata);
```

### Partitioning

For high-volume projects, partition logs table by month:

```sql
CREATE TABLE logs_2025_01 PARTITION OF logs
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE logs_2025_02 PARTITION OF logs
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
```

---

## Security Considerations

1. **API Key Validation**: Always validate `x-api-key` header
2. **Rate Limiting**: Limit requests to 1000/minute per project
3. **Input Validation**: Sanitize all user inputs, especially metadata
4. **Data Isolation**: Ensure users can only access their project's data
5. **PII Handling**: Hash/encrypt sensitive user properties

---

## Migration Guide

### Adding User Properties to Existing Backend

1. Create `user_properties` table
2. Add GIN index to `logs.metadata` if not exists
3. Update log ingestion to extract `_user_properties` from metadata
4. Create user properties endpoints
5. Update analytics queries to use user properties

### Adding Performance Metrics

1. Option A: Use existing `logs` table with `type = 'performance'`
2. Option B: Create dedicated `performance_metrics` table
3. Add performance analytics endpoints
4. Create performance dashboards

---

## Example Implementation (Node.js/Express)

```javascript
// User properties endpoint
app.post('/api/v1/users/:userId/properties', async (req, res) => {
  const { userId } = req.params;
  const { properties } = req.body;
  const projectId = req.project.id; // From API key validation
  
  const queries = Object.entries(properties).map(([key, value]) => 
    db.query(`
      INSERT INTO user_properties (project_id, user_id, property_key, property_value)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (project_id, user_id, property_key)
      DO UPDATE SET property_value = $4, updated_at = NOW()
    `, [projectId, userId, key, JSON.stringify(value)])
  );
  
  await Promise.all(queries);
  res.json({ success: true, updated: queries.length });
});
```

---

**This specification provides everything needed to implement backend support for Telling Logger's advanced features.**
