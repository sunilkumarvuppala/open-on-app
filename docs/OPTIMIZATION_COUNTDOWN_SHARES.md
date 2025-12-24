# Countdown Shares Feature - Production Optimization Guide

> **Note**: This document is a technical optimization guide. For complete feature documentation, see [features/COUNTDOWN_SHARES.md](./features/COUNTDOWN_SHARES.md).

## Overview
This document outlines optimizations for the countdown shares feature to support 500,000+ users with optimal performance, security, and UX.

## Critical Issues Fixed

### 1. Hardcoded Values → Configuration
- ✅ Share base URL moved to environment variables
- ✅ Cache durations moved to constants
- ✅ Font URLs optimized with preconnect
- ✅ Color values remain (design constants)

### 2. Security Enhancements
- ✅ CSP headers added to Edge Function
- ✅ Input sanitization for HTML template
- ✅ Rate limiting on public share views
- ✅ CORS restricted to production domains
- ✅ XSS protection headers

### 3. Performance Optimizations
- ✅ Connection pooling in Edge Function
- ✅ Response caching with proper headers
- ✅ Debouncing on share button clicks
- ✅ Widget optimization (RepaintBoundary, const constructors)
- ✅ Lazy loading of preview dialog
- ✅ Font loading optimization (preconnect + display=swap)

### 4. Error Handling
- ✅ Retry logic for transient failures
- ✅ Circuit breaker pattern for Edge Functions
- ✅ Graceful degradation
- ✅ User-friendly error messages

### 5. Database Optimizations
- ✅ Indexes on all query paths
- ✅ Partial indexes for revoked/expired shares
- ✅ Connection pooling
- ✅ Query optimization (avoid N+1)

## Configuration

### Environment Variables

**Flutter (.env):**
```env
SHARE_BASE_URL=https://openon.app/share
SHARE_CACHE_TTL=60
```

**Edge Function (Supabase Dashboard):**
```env
SHARE_BASE_URL=https://openon.app/share
SHARE_CACHE_TTL=60
ALLOWED_ORIGINS=https://openon.app,https://www.openon.app
```

**Database (Supabase Config):**
```sql
-- Set via Supabase Dashboard > Settings > Database > Custom Config
app.share_base_url = 'https://openon.app/share'
```

## Performance Targets

- **Share Creation**: < 200ms (p95)
- **Share Page Load**: < 100ms (p95)
- **Preview Dialog**: < 50ms render time
- **Database Queries**: < 10ms (p95)
- **Edge Function**: < 150ms (p95)

## Monitoring

### Key Metrics
- Share creation rate
- Share page views
- Error rates by type
- Response times (p50, p95, p99)
- Cache hit rates
- Database query performance

### Alerts
- Error rate > 1%
- Response time p95 > 500ms
- Database connection pool exhaustion
- Cache hit rate < 80%

## Scaling Considerations

### Horizontal Scaling
- Edge Functions auto-scale
- Database read replicas for public queries
- CDN for static assets

### Vertical Scaling
- Database connection pool size
- Edge Function memory allocation
- Cache size limits

## Security Checklist

- [x] Input sanitization
- [x] CSP headers
- [x] Rate limiting
- [x] CORS restrictions
- [x] Token security (32+ chars, cryptographically random)
- [x] RLS policies enforced
- [x] No sensitive data in public endpoints
- [x] XSS protection
- [x] SQL injection prevention (parameterized queries)

