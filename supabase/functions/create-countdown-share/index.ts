// ============================================================================
// Supabase Edge Function: create-countdown-share
// ============================================================================
// WHAT: Creates a countdown share with secure token and generates visual assets
// WHY: Provides atomic operation + asset generation in one call
// SECURITY: Validates ownership, lock status, rate limits
// ANONYMOUS BY DEFAULT: Shares MUST NOT expose sender identity
// ============================================================================

// Future-proof flag: Show sender identity in shares (disabled by default)
// DO NOT expose this in UI yet - for future experimentation only
const SHOW_SENDER_IDENTITY_IN_SHARES = false;

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// ANONYMOUS BY DEFAULT: Share requests/responses MUST NOT include sender identity
// Future-proof: If show_sender_identity flag is added, it should default to false
interface CreateShareRequest {
  letter_id: string;
  share_type: "story" | "video" | "static" | "link";
  expires_at?: string; // ISO 8601 timestamp
  // NOTE: No show_sender_identity flag yet - defaults to anonymous (false)
}

interface CreateShareResponse {
  success: boolean;
  share_id?: string;
  share_token?: string;
  share_url?: string;
  asset_url?: string; // Signed URL for generated asset (MUST NOT contain sender identity)
  expires_at?: string;
  error_code?: string;
  error_message?: string;
  // NOTE: Response does NOT include sender_id, sender_name, sender_avatar
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Get authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "NOT_AUTHENTICATED",
          error_message: "Missing authorization header",
        } as CreateShareResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase clients
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey || !supabaseAnonKey) {
      console.error("Missing Supabase environment variables");
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "CONFIGURATION_ERROR",
          error_message: "Server configuration error",
        } as CreateShareResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Create authenticated client for user context
    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
    });

    // Verify user is authenticated
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "NOT_AUTHENTICATED",
          error_message: "Invalid or expired token",
        } as CreateShareResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    let body: CreateShareRequest;
    try {
      body = await req.json();
    } catch (parseError) {
      console.error("Failed to parse request body:", parseError);
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "INVALID_REQUEST",
          error_message: "Invalid JSON in request body",
        } as CreateShareResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    
    const { letter_id, share_type, expires_at } = body;

    if (!letter_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "INVALID_REQUEST",
          error_message: "letter_id is required",
        } as CreateShareResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!share_type || !["story", "video", "static", "link"].includes(share_type)) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "INVALID_REQUEST",
          error_message: "share_type must be one of: story, video, static, link",
        } as CreateShareResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Call RPC function to create share
    const { data: rpcResult, error: rpcError } = await supabaseClient.rpc(
      "rpc_create_countdown_share",
      {
        p_letter_id: letter_id,
        p_share_type: share_type,
        p_expires_at: expires_at || null,
      }
    );

    if (rpcError) {
      console.error("RPC error:", rpcError);
      console.error("RPC error details:", JSON.stringify(rpcError, null, 2));

      // Parse error code from error message
      const errorMessage = rpcError.message || rpcError.toString() || "Unknown RPC error";
      let errorCode = "UNEXPECTED_ERROR";
      let httpStatus = 500; // Default to 500 for unexpected errors

      if (errorMessage.includes("LETTER_NOT_FOUND")) {
        errorCode = "LETTER_NOT_FOUND";
        httpStatus = 404;
      } else if (errorMessage.includes("LETTER_NOT_LOCKED")) {
        errorCode = "LETTER_NOT_LOCKED";
        httpStatus = 400;
      } else if (errorMessage.includes("LETTER_ALREADY_OPENED")) {
        errorCode = "LETTER_ALREADY_OPENED";
        httpStatus = 400;
      } else       if (errorMessage.includes("LETTER_ALREADY_REVEALED")) {
        errorCode = "LETTER_ALREADY_REVEALED";
        httpStatus = 400;
      } else if (errorMessage.includes("countdown_shares_open_future") || errorMessage.includes("open_future")) {
        errorCode = "INVALID_STATE";
        httpStatus = 400;
      } else if (errorMessage.includes("LETTER_DELETED")) {
        errorCode = "LETTER_DELETED";
        httpStatus = 400;
      } else if (errorMessage.includes("NOT_AUTHORIZED")) {
        errorCode = "NOT_AUTHORIZED";
        httpStatus = 403;
      } else if (errorMessage.includes("Not authenticated") || errorMessage.includes("auth.uid()")) {
        errorCode = "NOT_AUTHENTICATED";
        httpStatus = 401;
      } else if (errorMessage.includes("DAILY_LIMIT_REACHED")) {
        errorCode = "DAILY_LIMIT_REACHED";
        httpStatus = 429;
      } else if (errorMessage.includes("INVALID_SHARE_TYPE")) {
        errorCode = "INVALID_SHARE_TYPE";
        httpStatus = 400;
      }

      return new Response(
        JSON.stringify({
          success: false,
          error_code: errorCode,
          error_message: errorMessage.replace(/^COUNTDOWN_SHARE_ERROR:/, ""),
        } as CreateShareResponse),
        {
          status: httpStatus,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!rpcResult) {
      console.error("RPC call returned null or undefined result");
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "UNEXPECTED_ERROR",
          error_message: "RPC call returned no result",
        } as CreateShareResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    
    if (!rpcResult.share_id || !rpcResult.share_token || !rpcResult.share_url) {
      console.error("RPC result missing required fields:", JSON.stringify(rpcResult, null, 2));
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "UNEXPECTED_ERROR",
          error_message: "RPC call succeeded but incomplete data returned",
        } as CreateShareResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const shareId = rpcResult.share_id as string;
    const shareToken = rpcResult.share_token as string;
    const shareUrl = rpcResult.share_url as string;

    // Generate visual asset (for story/video/static types)
    // ANONYMOUS BY DEFAULT: Generated assets MUST NOT include sender identity
    // Assets should contain ONLY: countdown text, neutral title, optional OpenOn branding
    let assetUrl: string | undefined;
    if (share_type !== "link") {
      try {
        // NOTE: Asset generation is not yet implemented
        // For now, we skip asset URL generation since the storage bucket/file doesn't exist yet
        // In production, you would:
        // 1. Generate image/video using a library like Canvas API or FFmpeg
        // 2. Upload to Supabase Storage bucket "countdown-shares"
        // 3. Return signed URL
        // IMPORTANT: Do NOT include sender avatar, name, or any identifying information
        
        // Skip asset URL generation for now - assets will be generated on-the-fly by client if needed
        // This is expected behavior and not an error
        console.debug("Asset generation not yet implemented - skipping asset URL");
      } catch (assetError) {
        console.error("Error in asset generation logic:", assetError);
        // Continue without asset URL - not critical for MVP
      }
    }

    // Return success
    return new Response(
      JSON.stringify({
        success: true,
        share_id: shareId,
        share_token: shareToken,
        share_url: shareUrl,
        asset_url: assetUrl,
        expires_at: rpcResult.expires_at || undefined,
      } as CreateShareResponse),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    console.error("Error stack:", error instanceof Error ? error.stack : "No stack trace");
    console.error("Error details:", JSON.stringify(error, Object.getOwnPropertyNames(error)));
    
    const errorMessage = error instanceof Error 
      ? error.message 
      : typeof error === 'string' 
        ? error 
        : JSON.stringify(error);
    
    return new Response(
      JSON.stringify({
        success: false,
        error_code: "UNEXPECTED_ERROR",
        error_message: errorMessage || "Unknown error occurred",
      } as CreateShareResponse),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

