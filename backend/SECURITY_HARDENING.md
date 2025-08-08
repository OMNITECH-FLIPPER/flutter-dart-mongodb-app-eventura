# Security & CORS Hardening Implementation

This document outlines the comprehensive security hardening measures implemented in the Eventura Backend API.

## ✅ Security Middleware Implemented

### 1. Helmet Configuration
- **Purpose**: Sets various HTTP headers to protect against common security vulnerabilities
- **Configuration**:
  ```javascript
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"],
      },
    },
    crossOriginEmbedderPolicy: false
  }));
  ```
- **Protection**: XSS, clickjacking, MIME-type sniffing, and other injection attacks

### 2. Express Rate Limiting
- **Purpose**: Prevents brute force attacks and API abuse
- **Configuration**:
  ```javascript
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes (configurable via RATE_LIMIT_WINDOW_MS)
    max: 100, // 100 requests per window (configurable via RATE_LIMIT_MAX_REQUESTS)
    message: { error: 'Too many requests from this IP, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
  });
  ```
- **Environment Variables**: `RATE_LIMIT_WINDOW_MS`, `RATE_LIMIT_MAX_REQUESTS`

### 3. Compression
- **Purpose**: Reduces bandwidth usage and improves performance
- **Implementation**: `app.use(compression())`
- **Benefits**: Faster response times, reduced server load

### 4. CORS Configuration
- **Purpose**: Controls cross-origin resource sharing
- **Configuration**:
  ```javascript
  const corsOrigin = process.env.CORS_ORIGIN || '*';
  const corsOptions = {
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    credentials: true,
    optionsSuccessStatus: 200
  };
  ```
- **Environment Variable**: `CORS_ORIGIN` (supports comma-separated multiple origins)
- **Example**: `CORS_ORIGIN=http://localhost:3000,https://yourdomain.com`

### 5. HTTPS Enforcement in Production
- **Purpose**: Forces HTTPS connections in production environments
- **Configuration**:
  ```javascript
  if (process.env.NODE_ENV === 'production') {
    app.enable('trust proxy');
  }
  
  app.use((req, res, next) => {
    if (process.env.NODE_ENV === 'production' && !req.secure && req.get('x-forwarded-proto') !== 'https') {
      return res.redirect(301, `https://${req.get('host')}${req.url}`);
    }
    next();
  });
  ```
- **Benefits**: Ensures encrypted communication in production

### 6. Input Sanitization

#### NoSQL Injection Protection
- **Library**: `express-mongo-sanitize`
- **Implementation**: `app.use(mongoSanitize())`
- **Protection**: Prevents MongoDB operator injection attacks

#### XSS Protection
- **Library**: `xss`
- **Implementation**: Custom middleware that sanitizes all request inputs
- **Coverage**: `req.body`, `req.query`, `req.params`
- **Function**:
  ```javascript
  function sanitizeObject(obj) {
    if (obj && typeof obj === 'object') {
      if (Array.isArray(obj)) {
        return obj.map(item => sanitizeObject(item));
      } else {
        const sanitized = {};
        for (const [key, value] of Object.entries(obj)) {
          if (typeof value === 'string') {
            sanitized[key] = xss(value);
          } else if (value && typeof value === 'object') {
            sanitized[key] = sanitizeObject(value);
          } else {
            sanitized[key] = value;
          }
        }
        return sanitized;
      }
    }
    return typeof obj === 'string' ? xss(obj) : obj;
  }
  ```

### 7. Static File Security
- **Purpose**: Secure serving of uploaded files with additional headers
- **Configuration**:
  ```javascript
  app.use('/uploads', express.static('uploads', {
    setHeaders: (res, path) => {
      res.setHeader('X-Content-Type-Options', 'nosniff');
      res.setHeader('X-Frame-Options', 'DENY');
      res.setHeader('Cache-Control', 'public, max-age=31536000');
    }
  }));
  ```

## 🔧 Environment Variables

### Required Security Variables
```env
# CORS Configuration
CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Production Environment
NODE_ENV=production
```

### Security Variable Descriptions
- **CORS_ORIGIN**: Controls allowed origins for CORS requests
  - `*` = Allow all origins (development only)
  - `http://localhost:3000` = Single origin
  - `http://localhost:3000,https://yourdomain.com` = Multiple origins
- **RATE_LIMIT_WINDOW_MS**: Time window in milliseconds (default: 15 minutes)
- **RATE_LIMIT_MAX_REQUESTS**: Maximum requests per window (default: 100)
- **NODE_ENV**: Environment mode (enables HTTPS redirect when set to 'production')

## 📊 Security Logging

The application now logs security configuration on startup:
```
🛡️  Security configuration:
   - CORS Origins: *
   - Rate Limit: 100 requests per 15 minutes
   - HTTPS Redirect: disabled
   - Security Headers: enabled (Helmet)
   - Input Sanitization: enabled (XSS + NoSQL injection protection)
```

## 🚀 Production Deployment Checklist

### Before deploying to production:
1. ✅ Set `NODE_ENV=production`
2. ✅ Configure specific `CORS_ORIGIN` (avoid using `*`)
3. ✅ Adjust rate limiting based on expected traffic
4. ✅ Ensure HTTPS certificate is configured on the server
5. ✅ Test all security headers are present
6. ✅ Validate input sanitization is working
7. ✅ Monitor rate limiting effectiveness

### Security Best Practices Applied:
- **Defense in Depth**: Multiple layers of security
- **Input Validation**: All user inputs are sanitized
- **Secure Headers**: Comprehensive HTTP security headers
- **Rate Limiting**: Protection against DoS attacks
- **HTTPS Enforcement**: Encrypted communication
- **Environment-based Configuration**: Different settings for dev/prod

## 🔒 Security Headers Added

When Helmet is applied, the following security headers are automatically set:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security` (in HTTPS mode)
- `Content-Security-Policy` (with custom directives)
- `Referrer-Policy: no-referrer`
- `Permissions-Policy` (restricts browser features)

## 📝 Notes

1. **XSS Library**: Replaced deprecated `xss-clean` with modern `xss` library
2. **Performance**: Compression middleware reduces bandwidth usage
3. **Flexibility**: All security settings are configurable via environment variables
4. **Development vs Production**: Different security postures for different environments
5. **Monitoring**: Security configuration is logged on startup for verification

This implementation provides comprehensive security hardening while maintaining flexibility and performance.
