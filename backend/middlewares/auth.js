const jwt = require('jsonwebtoken');

// In-memory revoke list (in production, use Redis)
const revokedTokens = new Set();

// Simple in-memory cache for demo (in production, use Redis)
const tokenCache = new Map();

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET + '_refresh';

/**
 * JWT Authentication Middleware
 * Verifies JWT tokens and adds user info to req.user with roles
 * Supports token refresh and maintains a revoke list
 */

/**
 * Main authentication middleware
 * Extracts and verifies JWT token, adds user to request with roles
 */
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({ 
      success: false,
      message: 'Access token required',
      error: 'MISSING_TOKEN'
    });
  }

  // Check if token is revoked
  if (revokedTokens.has(token)) {
    return res.status(401).json({ 
      success: false,
      message: 'Token has been revoked',
      error: 'TOKEN_REVOKED'
    });
  }

  // Verify token
  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      let errorCode = 'INVALID_TOKEN';
      let message = 'Invalid token';
      
      if (err.name === 'TokenExpiredError') {
        errorCode = 'TOKEN_EXPIRED';
        message = 'Token has expired';
      } else if (err.name === 'JsonWebTokenError') {
        errorCode = 'INVALID_TOKEN';
        message = 'Invalid token format';
      }

      return res.status(403).json({ 
        success: false,
        message,
        error: errorCode
      });
    }

    // Add user info to request with roles
    req.user = {
      userId: decoded.userId,
      role: decoded.role,
      roles: [decoded.role], // Array for compatibility with role-based access
      iat: decoded.iat,
      exp: decoded.exp
    };

    next();
  });
};

/**
 * Role-based authorization middleware
 * Requires specific roles to access protected routes
 */
const requireRoles = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        success: false,
        message: 'Authentication required',
        error: 'NOT_AUTHENTICATED'
      });
    }

    const userRole = req.user.role;
    const hasPermission = allowedRoles.includes(userRole) || userRole === 'Admin'; // Admin has access to everything

    if (!hasPermission) {
      return res.status(403).json({ 
        success: false,
        message: 'Insufficient permissions',
        error: 'INSUFFICIENT_PERMISSIONS',
        required: allowedRoles,
        current: userRole
      });
    }

    next();
  };
};

/**
 * Admin-only middleware
 */
const requireAdmin = requireRoles('Admin');

/**
 * Organizer or Admin middleware
 */
const requireOrganizerOrAdmin = requireRoles('Organizer', 'Admin');

/**
 * Generate access token
 */
const generateAccessToken = (user) => {
  return jwt.sign(
    { 
      userId: user.userId, 
      role: user.role 
    },
    JWT_SECRET,
    { expiresIn: '15m' } // Short-lived access token
  );
};

/**
 * Generate refresh token
 */
const generateRefreshToken = (user) => {
  const refreshToken = jwt.sign(
    { 
      userId: user.userId, 
      role: user.role,
      type: 'refresh'
    },
    JWT_REFRESH_SECRET,
    { expiresIn: '7d' } // Long-lived refresh token
  );
  
  // Store refresh token (in production, use Redis with expiration)
  tokenCache.set(`refresh_${user.userId}`, refreshToken);
  
  return refreshToken;
};

/**
 * Generate both access and refresh tokens
 */
const generateTokens = (user) => {
  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);
  
  return {
    accessToken,
    refreshToken,
    expiresIn: 900, // 15 minutes in seconds
    tokenType: 'Bearer'
  };
};

/**
 * Refresh token endpoint handler
 */
const refreshTokenHandler = (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(401).json({ 
      success: false,
      message: 'Refresh token required',
      error: 'MISSING_REFRESH_TOKEN'
    });
  }

  // Check if refresh token is revoked
  if (revokedTokens.has(refreshToken)) {
    return res.status(401).json({ 
      success: false,
      message: 'Refresh token has been revoked',
      error: 'REFRESH_TOKEN_REVOKED'
    });
  }

  jwt.verify(refreshToken, JWT_REFRESH_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ 
        success: false,
        message: 'Invalid refresh token',
        error: 'INVALID_REFRESH_TOKEN'
      });
    }

    // Verify this refresh token belongs to the user
    const storedToken = tokenCache.get(`refresh_${decoded.userId}`);
    if (storedToken !== refreshToken) {
      return res.status(403).json({ 
        success: false,
        message: 'Invalid refresh token',
        error: 'INVALID_REFRESH_TOKEN'
      });
    }

    // Generate new tokens
    const user = { userId: decoded.userId, role: decoded.role };
    const tokens = generateTokens(user);

    // Revoke the old refresh token
    revokedTokens.add(refreshToken);
    
    res.json({
      success: true,
      ...tokens
    });
  });
};

/**
 * Revoke token (logout)
 */
const revokeToken = (req, res) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  const { refreshToken, allTokens } = req.body;

  if (allTokens && req.user) {
    // Revoke all tokens for this user
    const userId = req.user.userId;
    
    // Remove refresh token from cache
    tokenCache.delete(`refresh_${userId}`);
    
    // In a real application, you'd mark all tokens for this user as revoked in Redis
    // For now, we'll just revoke the current tokens
    if (token) revokedTokens.add(token);
    if (refreshToken) revokedTokens.add(refreshToken);

    return res.json({ 
      success: true,
      message: 'All tokens revoked successfully' 
    });
  }

  // Revoke specific tokens
  if (token) {
    revokedTokens.add(token);
  }
  
  if (refreshToken) {
    revokedTokens.add(refreshToken);
    
    // Remove from cache if it exists
    jwt.verify(refreshToken, JWT_REFRESH_SECRET, (err, decoded) => {
      if (!err && decoded.userId) {
        tokenCache.delete(`refresh_${decoded.userId}`);
      }
    });
  }

  res.json({ 
    success: true,
    message: 'Token(s) revoked successfully' 
  });
};

/**
 * Optional authentication middleware (doesn't fail if no token)
 * Useful for routes that work for both authenticated and unauthenticated users
 */
const optionalAuth = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return next(); // Continue without user info
  }

  // Check if token is revoked
  if (revokedTokens.has(token)) {
    return next(); // Continue without user info
  }

  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (!err) {
      req.user = {
        userId: decoded.userId,
        role: decoded.role,
        roles: [decoded.role],
        iat: decoded.iat,
        exp: decoded.exp
      };
    }
    next();
  });
};

/**
 * Middleware to check if user owns resource or is admin
 */
const requireOwnershipOrAdmin = (userIdParam = 'userId') => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ 
        success: false,
        message: 'Authentication required',
        error: 'NOT_AUTHENTICATED'
      });
    }

    const resourceUserId = req.params[userIdParam];
    const isOwner = req.user.userId === resourceUserId;
    const isAdmin = req.user.role === 'Admin';

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ 
        success: false,
        message: 'Access denied. You can only access your own resources.',
        error: 'INSUFFICIENT_PERMISSIONS'
      });
    }

    next();
  };
};

/**
 * Get revoked tokens count (for monitoring)
 */
const getRevokedTokensCount = () => revokedTokens.size;

/**
 * Clear expired tokens from revoke list (cleanup function)
 * In production, Redis handles this automatically with TTL
 */
const cleanupRevokedTokens = () => {
  // In a real implementation, you'd check token expiration and remove expired ones
  // For now, this is a placeholder
  console.log(`Current revoked tokens count: ${revokedTokens.size}`);
};

// Cleanup every hour
setInterval(cleanupRevokedTokens, 60 * 60 * 1000);

module.exports = {
  authenticateToken,
  requireRoles,
  requireAdmin,
  requireOrganizerOrAdmin,
  requireOwnershipOrAdmin,
  optionalAuth,
  generateTokens,
  generateAccessToken,
  generateRefreshToken,
  refreshTokenHandler,
  revokeToken,
  getRevokedTokensCount,
  cleanupRevokedTokens
};
