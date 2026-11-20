import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { order_id } = await req.json();

    if (!order_id) {
      return new Response(
        JSON.stringify({ error: "Missing required field: order_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Read Razorpay credentials from environment secrets
    const razorpayKeyId = Deno.env.get("RAZORPAY_KEY_ID");
    const razorpayKeySecret = Deno.env.get("RAZORPAY_KEY_SECRET");

    if (!razorpayKeyId || !razorpayKeySecret) {
      console.error("Razorpay credentials not configured");
      return new Response(
        JSON.stringify({ error: "Payment gateway not configured" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Fetch payments for this order from Razorpay API
    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);

    const razorpayResponse = await fetch(
      `https://api.razorpay.com/v1/orders/${order_id}/payments`,
      {
        method: "GET",
        headers: {
          Authorization: `Basic ${basicAuth}`,
        },
      }
    );

    if (!razorpayResponse.ok) {
      const errorBody = await razorpayResponse.text();
      console.error(`Razorpay API error: ${razorpayResponse.status} - ${errorBody}`);
      return new Response(
        JSON.stringify({ error: "Failed to fetch payments", details: errorBody }),
        {
          status: razorpayResponse.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const data = await razorpayResponse.json();
    const payments = data.items || [];

    // Return the most recent payment ID (last in the list)
    const latestPayment = payments.length > 0 ? payments[payments.length - 1] : null;

    return new Response(
      JSON.stringify({
        payment_id: latestPayment?.id || null,
        status: latestPayment?.status || null,
        method: latestPayment?.method || null,
        count: payments.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error(`Edge function error: ${err.message}`);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: err.message }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
