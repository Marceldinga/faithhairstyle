import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const json = (body: any, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: corsHeaders });

const supabase = () =>
  createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

const norm = (v: string) => (v || "").toLowerCase();

/* ---------------- INTENT DETECTION ---------------- */

const asksPrice = (m: string) =>
  /price|how much|cost/i.test(m);

const asksServices = (m: string) =>
  /service|what do you offer/i.test(m);

const asksColors = (m: string) =>
  /color|hair color/i.test(m);

const asksAvailability = (m: string) =>
  /available|free|open|time/i.test(m);

const isGreeting = (m: string) =>
  ["hi", "hello", "hey"].includes(norm(m));

/* ---------------- MAIN ---------------- */

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const body = await req.json().catch(() => ({}));
    const message = body?.message || "";

    const db = supabase();

    /* ---------------- LOAD ONLY WHAT WE NEED ---------------- */

    const [{ data: services }, { data: colors }] = await Promise.all([
      db.from("services").select("*").eq("is_active", true),
      db.from("hair_colors").select("*").eq("is_active", true),
    ]);

    const safeServices = services || [];
    const safeColors = colors || [];

    /* ---------------- GREETING ---------------- */

    if (isGreeting(message)) {
      return json({
        reply:
          "Hello 👋 Welcome to Faithhairstyle. Ask about services, prices, or hair colors.",
      });
    }

    /* ---------------- SERVICES ---------------- */

    if (asksServices(message)) {
      return json({
        reply: safeServices
          .map((s) => `${s.name} - $${s.price} (${s.duration_minutes} min)`)
          .join("\n"),
      });
    }

    /* ---------------- PRICE LOOKUP ---------------- */

    if (asksPrice(message)) {
      const found = safeServices.find((s) =>
        norm(message).includes(norm(s.name))
      );

      if (!found) {
        return json({
          reply: "Which service are you asking about? " +
            safeServices.map((s) => s.name).join(", "),
        });
      }

      return json({
        reply: `${found.name} costs $${found.price} and takes ${found.duration_minutes} minutes.`,
      });
    }

    /* ---------------- HAIR COLORS ---------------- */

    if (asksColors(message)) {
      return json({
        reply: safeColors
          .map((c) => `${c.code} - ${c.name}`)
          .join("\n"),
      });
    }

    /* ---------------- DEFAULT SMART MATCH ---------------- */

    const service = safeServices.find((s) =>
      norm(message).includes(norm(s.name))
    );

    if (service) {
      return json({
        reply: `${service.name} costs $${service.price} and takes ${service.duration_minutes} minutes. Would you like to book it?`,
      });
    }

    /* ---------------- FALLBACK ---------------- */

    return json({
      reply:
        "I can help you with services, prices, hair colors, and bookings. What would you like to know?",
    });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});