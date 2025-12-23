// ============================================================================
// Supabase Edge Function: send-thought
// ============================================================================
// WHAT: Handles thought sending with rate limiting and push notifications
// WHY: Provides atomic operation + notification dispatch in one call
// SECURITY: Uses service role for RPC call, validates user auth
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SendThoughtRequest {
  receiver_id: string;
  client_source?: string;
}

interface SendThoughtResponse {
  success: boolean;
  thought_id?: string;
  error_code?: string;
  error_message?: string;
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
        } as SendThoughtResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Initialize Supabase client with service role for RPC call
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error("Missing Supabase environment variables");
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "CONFIGURATION_ERROR",
          error_message: "Server configuration error",
        } as SendThoughtResponse),
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
    const supabaseClient = createClient(
      supabaseUrl,
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    );

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
        } as SendThoughtResponse),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const body: SendThoughtRequest = await req.json();
    const { receiver_id, client_source } = body;

    if (!receiver_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "INVALID_RECEIVER",
          error_message: "receiver_id is required",
        } as SendThoughtResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Call RPC function with user's auth context
    // We use the admin client but set the user context via RPC
    // Actually, we need to call as the user - let's use the user's token
    const { data: rpcResult, error: rpcError } = await supabaseClient.rpc(
      "rpc_send_thought",
      {
        p_receiver_id: receiver_id,
        p_client_source: client_source || null,
      }
    );

    if (rpcError) {
      console.error("RPC error:", rpcError);

      // Parse error code from error message
      const errorMessage = rpcError.message || "";
      let errorCode = "UNEXPECTED_ERROR";

      if (errorMessage.includes("THOUGHT_ALREADY_SENT_TODAY")) {
        errorCode = "THOUGHT_ALREADY_SENT_TODAY";
      } else if (errorMessage.includes("DAILY_LIMIT_REACHED")) {
        errorCode = "DAILY_LIMIT_REACHED";
      } else if (errorMessage.includes("NOT_CONNECTED")) {
        errorCode = "NOT_CONNECTED";
      } else if (errorMessage.includes("BLOCKED")) {
        errorCode = "BLOCKED";
      } else if (errorMessage.includes("INVALID_RECEIVER")) {
        errorCode = "INVALID_RECEIVER";
      }

      return new Response(
        JSON.stringify({
          success: false,
          error_code: errorCode,
          error_message: errorMessage.replace(/^THOUGHT_ERROR:/, ""),
        } as SendThoughtResponse),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!rpcResult || !rpcResult.thought_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error_code: "UNEXPECTED_ERROR",
          error_message: "RPC call succeeded but no thought_id returned",
        } as SendThoughtResponse),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const thoughtId = rpcResult.thought_id as string;

    // Send push notification to receiver (if notification preferences allow)
    try {
      // Get receiver's notification preferences and device token
      const { data: receiverProfile } = await supabaseAdmin
        .from("user_profiles")
        .select("user_id, device_token")
        .eq("user_id", receiver_id)
        .single();

      // TODO: Check user notification preferences table if it exists
      // For now, we'll send if device_token exists
      if (receiverProfile?.device_token) {
        // Get sender's name for notification
        const { data: senderProfile } = await supabaseAdmin
          .from("user_profiles")
          .select("first_name, last_name, username")
          .eq("user_id", user.id)
          .single();

        const senderName =
          senderProfile?.first_name ||
          senderProfile?.username ||
          "Someone";

        // Insert notification record
        await supabaseAdmin.from("notifications").insert({
          user_id: receiver_id,
          type: "thought_received", // You may need to add this to your NotificationType enum
          title: "Thought",
          body: `${senderName} thought of you today.`,
          metadata: {
            thought_id: thoughtId,
            sender_id: user.id,
          },
        });

        // TODO: Send actual push notification via your provider (FCM, APNS, etc.)
        // This is a stub - implement based on your notification infrastructure
        console.log(
          `Would send push notification to ${receiver_id} with token ${receiverProfile.device_token}`
        );
      }
    } catch (notifError) {
      // Log but don't fail the request if notification fails
      console.error("Failed to send notification:", notifError);
    }

    // Return success
    return new Response(
      JSON.stringify({
        success: true,
        thought_id: thoughtId,
      } as SendThoughtResponse),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        success: false,
        error_code: "UNEXPECTED_ERROR",
        error_message: error instanceof Error ? error.message : "Unknown error",
      } as SendThoughtResponse),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

