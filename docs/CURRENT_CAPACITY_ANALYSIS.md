# Current Capacity Analysis

**Date**: Current  
**Configuration**: Single backend instance, default SQLAlchemy connection pool

---

## 🔍 Current Configuration

### Database Connection Pool
```python
# backend/app/db/base.py
engine = create_async_engine(
    settings.database_url,
    pool_pre_ping=True,
    # No explicit pool_size or max_overflow = uses SQLAlchemy defaults
)
```

**SQLAlchemy Defaults** (when not specified):
- `pool_size = 5` (base connections)
- `max_overflow = 10` (additional connections under load)
- **Total Maximum Connections: 15**

### Rate Limiting
- **60 requests per minute per IP address**
- In-memory storage (not distributed)

### Pagination
- Default: 20 items per page
- Maximum: 100 items per page

---

## 📊 Capacity Calculations

### 1. Connection Pool Bottleneck

**Theoretical Maximum:**
- 15 total database connections
- Average query time: ~50-200ms (with optimized indexes)
- With async/await, connections are released quickly

**Realistic Throughput:**
- If average request = 100ms: 1 connection handles ~10 req/sec
- 15 connections × 10 req/sec = **~150 requests/second** (theoretical)
- Accounting for overhead: **~100-120 requests/second** (realistic)

### 2. Rate Limiting Impact

**Per-User Limits:**
- Each user: 60 requests/minute = 1 request/second max
- But users don't constantly hit the limit
- Average active user: **2-5 requests/minute** during normal usage
- Peak usage: **5-10 requests/minute** (browsing, creating capsules)

### 3. Concurrent User Capacity

**Calculation Method 1: Request Rate**
- System capacity: ~100-120 req/sec = **6,000-7,200 req/min**
- Average user: 3 req/min
- **Concurrent users = 6,000 / 3 = ~2,000 users** (average usage)
- **Peak users = 6,000 / 10 = ~600 users** (all at peak)

**Calculation Method 2: Connection Pool**
- 15 connections available
- Average request holds connection for ~100ms
- Each connection can serve ~10 users/second (if users make 1 req/sec)
- **15 × 10 = ~150 concurrent users** (if all making requests simultaneously)

**Calculation Method 3: Rate Limiting**
- 60 req/min per user
- System: 6,000 req/min capacity
- **6,000 / 60 = 100 users** (if all hitting rate limit)

---

## 🎯 Realistic Capacity Estimate

### Conservative Estimate (Worst Case)
- **500-1,000 concurrent active users**
- Assumes: All users making requests simultaneously
- Bottleneck: Connection pool (15 connections)

### Realistic Estimate (Normal Usage)
- **1,000-2,000 concurrent active users**
- Assumes: Average 2-5 requests/minute per user
- Most users are idle/browsing, not constantly making requests

### Optimistic Estimate (Light Usage)
- **2,000-3,000 concurrent active users**
- Assumes: Most users idle, only 1-2 requests/minute average
- Connection pool not fully saturated

---

## ⚠️ Important Caveats

### 1. "Concurrent Users" Definition
- **Active users making requests**: 500-2,000
- **Total logged-in users**: Could be 10,000+ (most are idle)
- **Peak simultaneous requests**: Limited by 15 connections

### 2. Request Patterns Matter
- **Read-heavy workload** (viewing capsules, connections): Better capacity
- **Write-heavy workload** (creating capsules, connections): Lower capacity
- **Mixed workload** (typical): 1,000-2,000 concurrent active users

### 3. Database Performance
- **Well-optimized queries**: Indexes help, queries are fast
- **Database server capacity**: Not a bottleneck (Supabase handles this)
- **Network latency**: Minimal impact with async/await

### 4. Single Point of Failure
- **One backend instance**: If it crashes, all users affected
- **No redundancy**: No failover mechanism
- **No load balancing**: Can't distribute load

---

## 📈 Capacity by Scenario

### Scenario 1: Light Usage (Browsing)
- Users: Viewing capsules, connections, profiles
- Request rate: 1-2 req/min per user
- **Capacity: ~3,000-6,000 concurrent users**

### Scenario 2: Normal Usage (Mixed)
- Users: Browsing + occasional creates/updates
- Request rate: 2-5 req/min per user
- **Capacity: ~1,200-3,000 concurrent users**

### Scenario 3: Heavy Usage (Active Creation)
- Users: Actively creating capsules, connections
- Request rate: 5-10 req/min per user
- **Capacity: ~600-1,200 concurrent users**

### Scenario 4: Peak Load (All Users Active)
- Users: All making requests simultaneously
- Request rate: Limited by rate limit (60 req/min)
- **Capacity: ~100-500 concurrent users** (connection pool saturated)

---

## 🚨 Bottlenecks (In Order)

1. **Database Connection Pool** (15 connections) - **PRIMARY BOTTLENECK**
   - Limits concurrent database operations
   - First thing to hit capacity

2. **Rate Limiting** (60 req/min per IP)
   - Prevents abuse but also limits legitimate heavy users
   - Not a bottleneck for normal usage

3. **Single Instance**
   - Can't scale horizontally
   - No redundancy

4. **No Caching**
   - Every request hits database
   - Could improve capacity 2-3x with caching

---

## 💡 Quick Wins to Increase Capacity

### 1. Increase Connection Pool (Easiest, Biggest Impact)
```python
engine = create_async_engine(
    settings.database_url,
    pool_size=20,        # Increase from 5
    max_overflow=30,     # Increase from 10
    pool_pre_ping=True,
)
```
**Impact**: **3-4x capacity increase** (from ~1,500 to ~5,000-6,000 concurrent users)

### 2. Add Basic Caching (Medium Effort, High Impact)
- Cache user profiles: 5-minute TTL
- Cache connections list: 2-minute TTL
- **Impact**: **2-3x capacity increase** (reduces database load)

### 3. Add Read Replicas (Infrastructure, High Impact)
- Route read queries to replicas
- **Impact**: **2-5x capacity increase** (depends on read/write ratio)

---

## 📊 Summary Table

| Metric | Current Capacity | With Pool Fix | With Pool + Cache |
|--------|-----------------|---------------|-------------------|
| **Concurrent Active Users** | 1,000-2,000 | 5,000-6,000 | 10,000-15,000 |
| **Requests/Second** | 100-120 | 400-500 | 800-1,200 |
| **Peak Simultaneous Users** | 500-1,000 | 2,000-3,000 | 4,000-6,000 |
| **Bottleneck** | Connection Pool | Database CPU | Network/Infrastructure |

---

## 🎯 Final Answer

### With Current Setup:
**~1,000-2,000 concurrent active users** (making requests)

**Breakdown:**
- **Conservative (worst case)**: 500-1,000 users
- **Realistic (normal usage)**: 1,000-2,000 users  
- **Optimistic (light usage)**: 2,000-3,000 users

**Limiting Factor**: Database connection pool (15 connections)

**Note**: This is for **active users making requests**. Total logged-in users could be much higher (10,000+) if most are idle.

---

## 🔧 To Handle More Users

1. **Fix connection pool** → 5,000-6,000 users
2. **Add caching** → 10,000-15,000 users
3. **Add load balancer + multiple instances** → 50,000-100,000 users
4. **Add read replicas** → 100,000-500,000 users
5. **Full infrastructure** → 1M+ users

