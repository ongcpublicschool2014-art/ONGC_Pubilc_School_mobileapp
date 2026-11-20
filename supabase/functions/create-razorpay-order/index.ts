import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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
    // 1. Parse request body
    const { amount, currency, pay_id, receipt } = await req.json();

    // 2. Validate required fields
    if (!amount || !pay_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: amount, pay_id" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!Number.isInteger(amount) || amount <= 0) {
      return new Response(
        JSON.stringify({ error: "Amount must be a positive integer (in paise)" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // 3. Read Razorpay credentials from environment secrets
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

    // 4. Create Razorpay order via Orders API
    const basicAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`);

    const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${basicAuth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: amount,
        currency: currency || "INR",
        receipt: receipt || `PAY-${pay_id}`,
        payment_capture: 1,
      }),
    });

    if (!razorpayResponse.ok) {
      const errorBody = await razorpayResponse.text();
      console.error(`Razorpay API error: ${razorpayResponse.status} - ${errorBody}`);
      return new Response(
        JSON.stringify({ error: "Failed to create payment order", details: errorBody }),
        {
          status: razorpayResponse.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const razorpayOrder = await razorpayResponse.json();
    const orderId = razorpayOrder.id;

    console.log(`Razorpay order created: ${orderId} for pay_id: ${pay_id}, amount: ${amount}`);

    // 5. Update payment record with order_id
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { error: updateError } = await supabase
      .from("payment")
      .update({ payorderid: orderId })
      .eq("pay_id", pay_id);

    if (updateError) {
      console.error(`Failed to update payment record: ${updateError.message}`);
      // Still return order_id - payment can proceed
    }

    // 6. Return order_id to client
    return new Response(
      JSON.stringify({
        order_id: orderId,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency,
        status: razorpayOrder.status,
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
