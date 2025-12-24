// ============================================================================
// Supabase Edge Function: serve-countdown-share
// ============================================================================
// WHAT: Serves public countdown share page (web-compatible, no auth required)
// WHY: Allows sharing on social media without app installation
// SECURITY: Validates token, checks revocation/expiration, returns only safe data
// ANONYMOUS BY DEFAULT: Public pages MUST NOT display sender identity
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Future-proof flag: Show sender identity in shares (disabled by default)
// DO NOT expose this in UI yet - for future experimentation only
const SHOW_SENDER_IDENTITY_IN_SHARES = false;

// CORS configuration - restrict to production domains in production
const getAllowedOrigins = (): string[] => {
  const envOrigins = Deno.env.get("ALLOWED_ORIGINS");
  if (envOrigins) {
    return envOrigins.split(",").map((o) => o.trim());
  }
  // Default: allow all in development, restrict in production
  return ["*"]; // In production, set ALLOWED_ORIGINS env var
};

const corsHeaders = (origin?: string): Record<string, string> => {
  const allowedOrigins = getAllowedOrigins();
  const allowOrigin = allowedOrigins.includes("*") || (origin && allowedOrigins.includes(origin))
    ? origin || "*"
    : allowedOrigins[0] || "*";
  
  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Content-Security-Policy": "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self';",
  };
};

// ANONYMOUS BY DEFAULT: ShareData MUST NOT contain sender identity
// Future-proof: Use SHOW_SENDER_IDENTITY_IN_SHARES flag (defaults to false)
interface ShareData {
  open_date: string; // YYYY-MM-DD
  days_remaining: number;
  hours_remaining: number;
  minutes_remaining: number;
  is_unlocked: boolean;
  title?: string;
  theme?: {
    gradient_start: string;
    gradient_end: string;
    name: string;
  };
  // NOTE: No sender_id, sender_name, sender_avatar, or any identifying fields
  // If SHOW_SENDER_IDENTITY_IN_SHARES is true in future, these fields could be added conditionally
}

// HTML template for countdown page
function renderCountdownPage(data: ShareData, error?: string): string {
  if (error) {
    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Countdown Share - OpenOn</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      color: white;
    }
    .container {
      text-align: center;
      max-width: 400px;
      width: 100%;
    }
    .icon { font-size: 64px; margin-bottom: 20px; }
    .title { font-size: 24px; font-weight: 600; margin-bottom: 12px; }
    .message { font-size: 16px; opacity: 0.9; line-height: 1.5; }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">🔒</div>
    <h1 class="title">This countdown is no longer available</h1>
    <p class="message">${error}</p>
  </div>
</body>
</html>`;
  }

  const { open_date, days_remaining, hours_remaining, minutes_remaining, is_unlocked, title, theme } = data;
  
  // Format date nicely - no year for a softer feel
  // Validate date format to prevent injection
  let formattedDate = "soon";
  try {
    const dateObj = new Date(open_date + "T00:00:00Z");
    if (!isNaN(dateObj.getTime())) {
      formattedDate = dateObj.toLocaleDateString("en-US", {
        month: "long",
        day: "numeric",
      });
    }
  } catch (e) {
    console.error("Invalid date format:", open_date);
    formattedDate = "soon";
  }

  // Format countdown text - romantic, contextual messages
  let countdownText = "";
  if (is_unlocked) {
    countdownText = "Ready to open";
  } else if (days_remaining > 30) {
    // Months away (30+ days)
    countdownText = "Saved for a special day";
  } else if (days_remaining >= 14) {
    // Weeks away (14-30 days)
    countdownText = "When the time comes";
  } else if (days_remaining >= 7) {
    // A week away (7-13 days)
    countdownText = "Getting closer";
  } else if (days_remaining >= 2) {
    // Days away (2-6 days)
    countdownText = "In a few days";
  } else {
    // Hours away (0-24 hours)
    countdownText = "Almost here";
  }

  // Use theme gradient if available, otherwise default
  const gradientStart = theme?.gradient_start || "#667eea";
  const gradientEnd = theme?.gradient_end || "#764ba2";
  
  // Sanitize title to prevent XSS (escape HTML)
  const sanitizeHtml = (str: string): string => {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#x27;");
  };
  
  const displayTitle = sanitizeHtml(title || "Something is waiting");

  // ANONYMOUS BY DEFAULT: This HTML page MUST NOT display sender identity
  // Contains ONLY: countdown, title, theme, neutral text, optional OpenOn branding
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Something is waiting. It opens soon.">
  <title>Countdown - OpenOn</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Tangerine:wght@400;700;900&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      background: linear-gradient(135deg, ${gradientStart} 0%, ${gradientEnd} 100%);
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 20px;
      color: white;
    }
    .container {
      text-align: center;
      max-width: 500px;
      width: 100%;
    }
    .card {
      background: rgba(255, 255, 255, 0.15);
      backdrop-filter: blur(10px);
      border-radius: 20px;
      padding: 24px 28px;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
      border: 1px solid rgba(255, 255, 255, 0.2);
    }
    .icon {
      font-size: 56px;
      margin-bottom: 16px;
      text-align: center;
      animation: glow 2s ease-in-out infinite;
      filter: drop-shadow(0 0 0px rgba(255, 255, 255, 0));
    }
    @keyframes glow {
      0%, 100% { 
        filter: drop-shadow(0 0 8px rgba(255, 255, 255, 0.2)) drop-shadow(0 0 12px rgba(255, 255, 255, 0.15));
      }
      50% { 
        filter: drop-shadow(0 0 16px rgba(255, 255, 255, 0.4)) drop-shadow(0 0 24px rgba(255, 255, 255, 0.25));
      }
    }
    .title {
      font-size: 20px;
      font-weight: 700;
      margin-bottom: 20px;
      line-height: 1.3;
      text-align: center;
    }
    .countdown {
      font-size: 42px;
      font-weight: 900;
      font-family: 'Tangerine', cursive;
      margin-bottom: 20px;
      letter-spacing: 0.5px;
      text-align: center;
      line-height: 1.2;
      background: linear-gradient(135deg, #1e40af 0%, #be185d 50%, #1e40af 100%);
      background-size: 200% 100%;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      -webkit-text-stroke: 0.5px rgba(255, 255, 255, 0.8);
      text-stroke: 0.5px rgba(255, 255, 255, 0.8);
      -webkit-text-stroke-width: 0.5px;
      -webkit-text-stroke-color: rgba(255, 255, 255, 0.8);
      position: relative;
      animation: shimmer 3s ease-in-out infinite;
      word-wrap: break-word;
      overflow-wrap: break-word;
      max-width: 100%;
      display: inline-block;
    }
    @keyframes shimmer {
      0% {
        background-position: 0% 50%;
      }
      50% {
        background-position: 100% 50%;
      }
      100% {
        background-position: 0% 50%;
      }
    }
    .date {
      font-size: 12px;
      opacity: 0.7;
      margin-top: 20px;
      margin-bottom: 20px;
      font-weight: 400;
      text-align: center;
    }
    .cta {
      display: inline-block;
      background: white;
      color: #667eea;
      padding: 10px 20px;
      border-radius: 24px;
      text-decoration: none;
      font-weight: 600;
      font-size: 13px;
      transition: transform 0.2s, box-shadow 0.2s;
      text-align: center;
    }
    .cta:hover {
      transform: translateY(-2px);
      box-shadow: 0 8px 20px rgba(0,0,0,0.2);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <div class="icon">💌</div>
      <h1 class="title">${displayTitle}</h1>
      <div class="countdown">${countdownText}</div>
      <p class="date">Opening ${formattedDate}</p>
      <a href="https://openon.app" class="cta">Get OpenOn</a>
    </div>R
  </div>
  <script>
    // Auto-refresh countdown every minute
    if (!${is_unlocked}) {
      setTimeout(() => {
        location.reload();
      }, 60000);
    }
  </script>
</body>
</html>`;
}

serve(async (req) => {
  const origin = req.headers.get("origin") || undefined;
  const headers = corsHeaders(origin);
  
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers });
  }

  try {
    // Extract share token from URL path
    const url = new URL(req.url);
    const pathParts = url.pathname.split("/").filter((p) => p);
    const shareToken = pathParts[pathParts.length - 1];

    // Validate and sanitize share token
    if (!shareToken || shareToken.length < 32 || shareToken.length > 128) {
      return new Response(
        renderCountdownPage({} as ShareData, "Invalid share link"),
        {
          status: 404,
          headers: { ...headers, "Content-Type": "text/html" },
        }
      );
    }
    
    // Sanitize token: only allow alphanumeric, -, _ characters (base64url safe)
    if (!/^[A-Za-z0-9_-]+$/.test(shareToken)) {
      return new Response(
        renderCountdownPage({} as ShareData, "Invalid share link"),
        {
          status: 404,
          headers: { ...headers, "Content-Type": "text/html" },
        }
      );
    }

    // Initialize Supabase client (anon key for public access)
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error("Missing Supabase environment variables");
      return new Response(
        renderCountdownPage({} as ShareData, "Service temporarily unavailable"),
        {
          status: 500,
          headers: { ...headers, "Content-Type": "text/html" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Get public share data (no auth required)
    const { data: shareData, error: rpcError } = await supabase.rpc(
      "rpc_get_countdown_share_public",
      {
        p_share_token: shareToken,
      }
    );

    if (rpcError) {
      console.error("RPC error:", rpcError);
      
      const errorMessage = rpcError.message || "";
      let userMessage = "This countdown is no longer available";
      
      if (errorMessage.includes("SHARE_NOT_FOUND")) {
        userMessage = "This countdown link is invalid";
      } else if (errorMessage.includes("SHARE_REVOKED")) {
        userMessage = "This countdown has been revoked";
      } else if (errorMessage.includes("SHARE_EXPIRED")) {
        userMessage = "This countdown has expired";
      }

      return new Response(
        renderCountdownPage({} as ShareData, userMessage),
        {
          status: 404,
          headers: { ...headers, "Content-Type": "text/html" },
        }
      );
    }

    if (!shareData) {
      return new Response(
        renderCountdownPage({} as ShareData, "Countdown not found"),
        {
          status: 404,
          headers: { ...headers, "Content-Type": "text/html" },
        }
      );
    }

    // Render countdown page
    const html = renderCountdownPage(shareData as ShareData);
    
    // Get cache TTL from environment or use default (60 seconds)
    const cacheTtl = parseInt(Deno.env.get("SHARE_CACHE_TTL") || "60", 10);
    
    return new Response(html, {
      status: 200,
      headers: {
        ...headers,
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": `public, max-age=${cacheTtl}, s-maxage=${cacheTtl}`,
        "ETag": `"${shareToken}-${Date.now()}"`, // Simple ETag for cache validation
      },
    });
  } catch (error) {
    console.error("Unexpected error:", error);
      return new Response(
        renderCountdownPage({} as ShareData, "An error occurred"),
        {
          status: 500,
          headers: { ...headers, "Content-Type": "text/html" },
        }
      );
  }
});

