import { createClient } from "npm:@supabase/supabase-js@2";

// ============================================================
// FAITHI SALON AGENT — SUPABASE EDGE FUNCTION
//
// Flutter
//    ↓
// Supabase Edge Function: chat-assistant
//    ↓
// Live Supabase salon data
//    ↓
// Hugging Face
//    ↓
// Qwen3-8B
//    ↓
// Faithi response
// ============================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods":
    "POST, OPTIONS",
};

// Hugging Face automatically chooses the fastest available provider.
const MODEL = "Qwen/Qwen3-8B:fastest";

const HF_ENDPOINT =
  "https://router.huggingface.co/v1/chat/completions";

// ============================================================
// FAITHI SYSTEM PROMPT
// ============================================================

const FAITHI_SYSTEM_PROMPT = `
You are Faithi, the virtual salon agent for Faith Hair Style.

You are NOT a generic chatbot.

You are an active salon customer-service agent whose responsibility
is to help customers complete salon tasks.

Your job is to understand what the customer wants, ask only the
necessary questions, use live salon information, recommend suitable
services, and guide the customer toward completing their salon task.

============================================================
PRIMARY RULE
============================================================

Do not wait for customers to know exactly what to ask.

A customer may not know:

- the hairstyle name
- braid size
- hair length
- hair color
- price
- what style fits their budget
- what appointment to choose
- how to prepare
- how booking works

Guide them.

For every request determine:

1. What is the customer trying to accomplish?
2. What information do we already know?
3. What information is still necessary?
4. What useful action can be performed now?
5. What is the ONE best next question if more information is required?

Do not reveal this reasoning.

Only give the helpful customer-facing response.

============================================================
CONVERSATION STYLE
============================================================

Speak like a friendly, knowledgeable salon receptionist
and stylist assistant.

Be:

- warm
- professional
- conversational
- helpful
- concise
- action-oriented

Most responses should be 1 to 4 sentences.

Do not write long explanations unless the customer asks for details.

Do not repeatedly introduce yourself.

Do not repeatedly say:
"How can I help you?"

Do not sound robotic.

Do not say:

"As an AI"
"As a language model"
"The database says"
"Supabase says"
"The API says"
"The backend says"
"The model says"

Speak naturally.

Say:

"I found..."
"We currently have..."
"That style starts at..."
"The next available opening is..."

============================================================
GREETING
============================================================

If this is the beginning of the conversation and the customer says:

hello
hi
hey
good morning
good afternoon
good evening

Respond naturally.

Example:

"Hi! I'm Faithi. What would you like me to help you get done today?"

You may briefly explain that you can help with:

- choosing a hairstyle
- prices
- budget
- colors
- appointments
- booking

Do not give a long introduction.

============================================================
ONE QUESTION AT A TIME
============================================================

Never interrogate the customer with many questions at once.

BAD:

"What style, size, length, color, budget and date do you want?"

GOOD:

"What kind of style are you looking for?"

Then use their answer to decide the next question.

Ask only ONE main question at a time.

============================================================
MEMORY
============================================================

Use the conversation history and customer preferences.

Remember information such as:

- budget
- selected hairstyle
- braid size
- hair length
- color
- occasion
- preferred date
- preferred time
- adult or kids service
- maintenance preference

Do not ask again for information already provided.

If the customer changes their preference, use the NEWEST preference.

============================================================
STYLE DISCOVERY
============================================================

If the customer says:

"I need my hair done."
"I want braids."
"I don't know what to get."
"Choose for me."
"What do you recommend?"

Do not immediately give a giant list.

Help narrow the choice.

You may ask about:

- desired look
- braids versus twists
- budget
- braid size
- length
- color
- occasion
- maintenance
- appointment timing

Ask only the most useful question first.

============================================================
STYLE RECOMMENDATIONS
============================================================

Only recommend actual Faith Hair Style services found in LIVE SALON DATA.

Consider:

- customer's budget
- desired hairstyle
- size
- length
- color
- occasion
- maintenance preference
- available services
- price

Prefer ONE strong recommendation.

If several options genuinely fit, recommend at most THREE.

Never invent a hairstyle that is not offered by the salon.

Example:

"I recommend Medium Senegalese Twists for the look you described.
They fit your budget and give you a neat protective style.
Would you like to see the price or one picture?"

============================================================
BUDGET
============================================================

If the customer gives a budget:

- remember the budget
- use live salon pricing
- find services within the budget
- narrow the options
- do not recommend something above the budget without saying so

Example:

Customer:
"My budget is $200."

Faithi:
"Got it. Do you prefer braids, twists, or would you like me to
choose the best option under $200?"

============================================================
PRICE QUESTIONS
============================================================

If the customer asks:

"How much?"
"What's the price?"
"How much are Senegalese twists?"
"What does this cost?"

Answer the price FIRST.

Use live salon prices only.

Example:

"Medium Senegalese Twists start at $170.
Would you like one picture or would you like me to check availability?"

Never invent a price.

============================================================
HAIRSTYLE SIZE
============================================================

When size matters, help the customer choose among actual available
service options.

Possible examples may include:

- jumbo
- large
- medium
- small-medium
- small

Only offer sizes supported by salon services.

============================================================
HAIR LENGTH
============================================================

When length matters, help the customer choose.

Examples may include:

- shoulder
- mid-back
- waist
- top butt
- mid butt
- under butt

Only mention options supported by live salon information.

============================================================
HAIR COLORS
============================================================

If the customer already knows the color they want, check whether it
is available.

If they do not know what color to choose, help them narrow it.

Example:

"Do you want something natural, warm, blonde, or something bold?"

Only recommend colors found in LIVE SALON DATA.

Never invent available colors.

============================================================
PICTURES
============================================================

Do NOT automatically send hairstyle pictures.

Only prepare an image result when the customer explicitly asks for:

- picture
- photo
- image
- show me
- let me see it
- what does it look like

Show only ONE matching hairstyle image at a time.

Do not include image URLs in your written response.

If the customer says:

"another"
"another one"
"show another"
"next photo"
"next picture"

continue with the hairstyle currently being discussed.

============================================================
APPOINTMENT AVAILABILITY
============================================================

Use LIVE SALON DATA.

If the customer asks:

"When can I come?"
"Do you have anything Saturday?"
"What's your next opening?"
"Are you available tomorrow?"

Use available appointment slots.

Do not invent times.

Do not dump the entire schedule.

Prefer 1 to 3 useful openings.

Example:

"I found openings Saturday at 10:00 AM and 1:30 PM.
Which one works better for you?"

============================================================
BOOKING
============================================================

Recognize booking readiness.

Examples:

"Book it."
"I want that one."
"I'll take it."
"That's good."
"That works."
"Let's do Saturday."
"I want 10 AM."
"I'm ready."

When the customer is ready:

STOP recommending alternatives.

Confirm the important selections briefly and guide them toward booking.

Example:

"Perfect. You're choosing Medium Senegalese Twists in color 1B.
I'll help you continue to booking."

Do not ask for information already known.

============================================================
HAIR INCLUDED
============================================================

If the customer asks:

"Is hair included?"
"Do I bring my own hair?"
"Does the price include hair?"

Use confirmed salon information only.

If that information is unavailable, say so briefly.

Do not guess.

============================================================
SERVICE DURATION
============================================================

If duration is present in live salon data, use it.

If duration is not available, do not invent an exact time.

Say that the exact duration needs confirmation if necessary.

============================================================
HAIR PREPARATION
============================================================

Help customers prepare for appointments.

Salon-specific instructions must come from confirmed salon policies.

Do not invent:

- deposit rules
- washing requirements
- blow-dry requirements
- cancellation rules
- late fees
- hair requirements

============================================================
KIDS SERVICES
============================================================

If the customer asks about a child:

- use kids services when available
- use kids prices when available
- prioritize comfortable and age-appropriate salon options
- ask age only when necessary

Do not automatically use adult pricing.

============================================================
OCCASIONS
============================================================

Use occasions when recommending styles.

Examples:

- birthday
- wedding
- vacation
- work
- school
- graduation
- party
- photoshoot

Example:

Customer:
"I need something for my birthday."

Faithi:
"Absolutely. Do you want something elegant, bold, or glamorous?"

============================================================
COMPARING HAIRSTYLES
============================================================

When customers compare styles, explain practical differences.

Consider:

- appearance
- price
- maintenance
- size
- length
- duration if available
- customer's goal

Then help them narrow the choice.

============================================================
SHORT CUSTOMER ANSWERS
============================================================

Customers may answer with only:

"yes"
"no"
"medium"
"small"
"Saturday"
"1B"
"waist"
"another"
"book it"

Interpret these using the current conversation context.

Do not restart the conversation.

============================================================
YES
============================================================

If the customer says "yes", determine what they agreed to from the
previous conversation and continue that action.

Do not respond with:

"How can I help you?"

============================================================
NO
============================================================

If the customer says "no", understand what they rejected and offer
the next useful action.

============================================================
HUMAN STYLIST
============================================================

If information requires human confirmation or the customer explicitly
asks for a person, guide them toward live chat or the stylist.

============================================================
ERRORS
============================================================

Never expose technical errors to customers.

Do not mention:

- HTTP errors
- API failures
- database failures
- environment variables
- Hugging Face errors
- Supabase errors
- stack traces

Give a customer-friendly response instead.

============================================================
LIVE DATA AUTHORITY
============================================================

LIVE SALON DATA is the authority for:

- services
- prices
- categories
- descriptions
- durations
- hair colors
- availability
- business information
- salon policies
- business hours

Never invent:

- service names
- prices
- discounts
- promotions
- colors
- available appointments
- business hours
- stylist names
- policies
- addresses
- hair-included status
- service duration

If live salon information does not contain the answer, say that the
information needs confirmation.

============================================================
FINAL AGENT RULE
============================================================

Your goal is NOT simply to answer messages.

Your goal is to help the customer COMPLETE their salon task.

If you can:

- find a service
- compare services
- narrow choices
- check a price
- remember a preference
- find a color
- find availability
- identify a hairstyle
- help with booking
- or guide the customer to the next step

do it.

Do not make the customer perform unnecessary work.
`;

// ============================================================
// BASIC HELPERS
// ============================================================

function cleanString(value: unknown): string {
  return value == null ? "" : String(value).trim();
}

function containsAny(
  text: string,
  values: string[],
): boolean {
  const lower = text.toLowerCase();

  return values.some(
    (value) => lower.includes(value),
  );
}

function detectIntent(text: string): string {
  const lower = text.toLowerCase();

  if (
    containsAny(lower, [
      "book",
      "appointment",
      "schedule",
      "reserve",
    ])
  ) {
    return "booking";
  }

  if (
    containsAny(lower, [
      "available",
      "availability",
      "open time",
      "opening",
      "slot",
      "when can",
    ])
  ) {
    return "availability";
  }

  if (
    containsAny(lower, [
      "price",
      "cost",
      "how much",
    ])
  ) {
    return "price";
  }

  if (
    containsAny(lower, [
      "picture",
      "photo",
      "image",
      "show me",
      "let me see",
    ])
  ) {
    return "image";
  }

  if (
    containsAny(lower, [
      "color",
      "colour",
      "1b",
      "99j",
      "613",
    ])
  ) {
    return "color";
  }

  if (
    containsAny(lower, [
      "recommend",
      "choose for me",
      "what should i get",
      "what style",
    ])
  ) {
    return "recommendation";
  }

  return "conversation";
}

function isImageRequest(text: string): boolean {
  return containsAny(text, [
    "picture",
    "photo",
    "image",
    "show me",
    "let me see",
    "what does it look like",
  ]);
}

function removeThinking(text: string): string {
  return text
    .replace(
      /<think>[\s\S]*?<\/think>/gi,
      "",
    )
    .replace(
      /<think>[\s\S]*/gi,
      "",
    )
    .trim();
}

// ============================================================
// SERVICE MATCHING
// ============================================================

function findMatchingServices(
  text: string,
  services: Record<string, unknown>[],
) {
  const lower = text.toLowerCase();

  const matches = services.filter((service) => {
    const name = cleanString(
      service.name,
    ).toLowerCase();

    if (!name) return false;

    if (lower.includes(name)) {
      return true;
    }

    const words = name
      .split(/\s+/)
      .filter((word) => word.length >= 4);

    return words.some(
      (word) => lower.includes(word),
    );
  });

  return matches;
}

// ============================================================
// MAIN FUNCTION
// ============================================================

Deno.serve(async (req) => {
  // ----------------------------------------------------------
  // CORS
  // ----------------------------------------------------------

  if (req.method === "OPTIONS") {
    return new Response(
      "ok",
      {
        headers: corsHeaders,
      },
    );
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({
        error: "Method not allowed",
      }),
      {
        status: 405,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }

  try {
    // ========================================================
    // SECRETS
    // ========================================================

    const HF_TOKEN =
      Deno.env.get("HF_TOKEN");

    const SUPABASE_URL =
      Deno.env.get("SUPABASE_URL");

    const SUPABASE_SERVICE_ROLE_KEY =
      Deno.env.get(
        "SUPABASE_SERVICE_ROLE_KEY",
      );

    if (!HF_TOKEN) {
      throw new Error(
        "HF_TOKEN is missing.",
      );
    }

    if (
      !SUPABASE_URL ||
      !SUPABASE_SERVICE_ROLE_KEY
    ) {
      throw new Error(
        "Supabase server environment is missing.",
      );
    }

    // ========================================================
    // SUPABASE SERVER CLIENT
    // ========================================================

    const supabase = createClient(
      SUPABASE_URL,
      SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    // ========================================================
    // REQUEST
    // ========================================================

    const body = await req.json();

    const customerMessage =
      cleanString(body.message);

    if (!customerMessage) {
      return new Response(
        JSON.stringify({
          error: "Message is required.",
        }),
        {
          status: 400,
          headers: {
            ...corsHeaders,
            "Content-Type":
              "application/json",
          },
        },
      );
    }

    // ========================================================
    // HISTORY
    // ========================================================

    const rawHistory =
      Array.isArray(body.history)
        ? body.history
        : [];

    const history = rawHistory
      .slice(-10)
      .map((item: any) => ({
        role:
          item?.role === "assistant"
            ? "assistant"
            : "user",

        content:
          cleanString(item?.content),
      }))
      .filter(
        (item: any) =>
          item.content.length > 0,
      );

    // ========================================================
    // CUSTOMER PREFERENCES
    // ========================================================

    const customerPreferences =
      body.customer_preferences &&
      typeof body.customer_preferences ===
        "object"
        ? body.customer_preferences
        : {};

    // ========================================================
    // LOAD LIVE SALON SERVICES
    // ========================================================

    const {
      data: servicesData,
      error: servicesError,
    } = await supabase
      .from("services")
      .select(
        `
          id,
          name,
          category,
          description,
          price,
          duration_minutes,
          image_url,
          is_active
        `,
      )
      .eq("is_active", true)
      .order(
        "price",
        {
          ascending: true,
        },
      )
      .limit(100);

    if (servicesError) {
      console.error(
        "Services error:",
        servicesError,
      );
    }

    const services =
      Array.isArray(servicesData)
        ? servicesData
        : [];

    // ========================================================
    // LOAD COLORS
    // ========================================================

    let hairColors: any[] = [];

    try {
      const {
        data,
        error,
      } = await supabase
        .from("hair_colors")
        .select(
          `
            code,
            name,
            is_active
          `,
        )
        .eq(
          "is_active",
          true,
        )
        .order(
          "code",
          {
            ascending: true,
          },
        )
        .limit(100);

      if (!error && Array.isArray(data)) {
        hairColors = data;
      }
    } catch (error) {
      console.error(
        "Hair colors error:",
        error,
      );
    }

    // ========================================================
    // LOAD AVAILABILITY
    // ========================================================

    let availability: any[] = [];

    try {
      const today =
        new Date()
          .toISOString()
          .substring(
            0,
            10,
          );

      const {
        data,
        error,
      } = await supabase
        .from(
          "availability_slots",
        )
        .select("*")
        .eq(
          "is_available",
          true,
        )
        .gte(
          "slot_date",
          today,
        )
        .order(
          "slot_date",
          {
            ascending: true,
          },
        )
        .order(
          "start_time",
          {
            ascending: true,
          },
        )
        .limit(20);

      if (!error && Array.isArray(data)) {
        availability = data;
      }
    } catch (error) {
      console.error(
        "Availability error:",
        error,
      );
    }

    // ========================================================
    // LOAD BUSINESS INFO
    // ========================================================

    let businessInfo: any[] = [];

    try {
      const {
        data,
        error,
      } = await supabase
        .from(
          "business_info",
        )
        .select("*")
        .limit(20);

      if (!error && Array.isArray(data)) {
        businessInfo = data;
      }
    } catch (error) {
      console.error(
        "Business info error:",
        error,
      );
    }

    // ========================================================
    // LOAD POLICIES
    // ========================================================

    let policies: any[] = [];

    try {
      const {
        data,
        error,
      } = await supabase
        .from("policies")
        .select("*")
        .limit(30);

      if (!error && Array.isArray(data)) {
        policies = data;
      }
    } catch (error) {
      console.error(
        "Policies error:",
        error,
      );
    }

    // ========================================================
    // LOAD HOURS
    // ========================================================

    let salonHours: any[] = [];

    try {
      const {
        data,
        error,
      } = await supabase
        .from("salon_hours")
        .select("*")
        .limit(20);

      if (!error && Array.isArray(data)) {
        salonHours = data;
      }
    } catch (error) {
      console.error(
        "Salon hours error:",
        error,
      );
    }

    // ========================================================
    // LIVE CONTEXT FOR QWEN
    // ========================================================

    const liveSalonContext = `
CURRENT CUSTOMER PREFERENCES:

${JSON.stringify(
  customerPreferences,
)}

LIVE FAITH HAIR STYLE SERVICES:

${JSON.stringify(
  services,
)}

LIVE HAIR COLORS:

${JSON.stringify(
  hairColors,
)}

LIVE APPOINTMENT AVAILABILITY:

${JSON.stringify(
  availability,
)}

BUSINESS INFORMATION:

${JSON.stringify(
  businessInfo,
)}

SALON POLICIES:

${JSON.stringify(
  policies,
)}

SALON HOURS:

${JSON.stringify(
  salonHours,
)}

IMPORTANT:

Use this live information as the source of truth.

Do not invent missing salon facts.

If information is unavailable, tell the customer it needs confirmation.
`;

    // ========================================================
    // MESSAGES
    // ========================================================

    const messages = [
      {
        role: "system",
        content:
          FAITHI_SYSTEM_PROMPT,
      },

      {
        role: "system",
        content:
          liveSalonContext,
      },

      ...history,

      {
        role: "user",
        content:
          customerMessage,
      },
    ];

    // ========================================================
    // HUGGING FACE / QWEN
    // ========================================================

    const hfResponse =
      await fetch(
        HF_ENDPOINT,
        {
          method: "POST",

          headers: {
            Authorization:
              `Bearer ${HF_TOKEN}`,

            "Content-Type":
              "application/json",
          },

          body: JSON.stringify({
            model: MODEL,

            messages,

            temperature: 0.3,

            max_tokens: 400,

            stream: false,
          }),
        },
      );

    // ========================================================
    // HF ERROR
    // ========================================================

    if (!hfResponse.ok) {
      const errorText =
        await hfResponse.text();

      console.error(
        "Hugging Face error:",
        hfResponse.status,
        errorText,
      );

      return new Response(
        JSON.stringify({
          reply:
            "I'm having trouble connecting right now. Please try again in a moment.",

          dataframe: {
            rows: [],
          },

          meta: {
            error: true,
            intent:
              detectIntent(
                customerMessage,
              ),
          },
        }),
        {
          status: 502,

          headers: {
            ...corsHeaders,
            "Content-Type":
              "application/json",
          },
        },
      );
    }

    // ========================================================
    // PARSE QWEN RESPONSE
    // ========================================================

    const hfData =
      await hfResponse.json();

    let reply =
      cleanString(
        hfData?.choices?.[0]
          ?.message?.content,
      );

    reply =
      removeThinking(reply);

    if (!reply) {
      throw new Error(
        "Qwen returned an empty response.",
      );
    }

    // ========================================================
    // FIND RELEVANT SERVICE
    // ========================================================

    const serviceMatches =
      findMatchingServices(
        `${customerMessage} ${reply}`,
        services,
      );

    // ========================================================
    // STRUCTURED FRONTEND ROWS
    // ========================================================

    let structuredRows: any[] = [];

    if (
      serviceMatches.length > 0
    ) {
      if (
        isImageRequest(
          customerMessage,
        )
      ) {
        // ONE image/service at a time.
        structuredRows = [
          {
            source_table:
              "services",

            ...serviceMatches[0],
          },
        ];
      } else {
        // Keep response compact.
        structuredRows =
          serviceMatches
            .slice(
              0,
              3,
            )
            .map(
              (service) => ({
                source_table:
                  "services",

                ...service,
              }),
            );
      }
    }

    // ========================================================
    // SUCCESS
    // ========================================================

    return new Response(
      JSON.stringify({
        reply,

        dataframe: {
          rows:
            structuredRows,
        },

        meta: {
          assistant:
            "faithi",

          provider:
            "huggingface",

          model:
            MODEL,

          intent:
            detectIntent(
              customerMessage,
            ),

          salon_data: {
            services_loaded:
              services.length,

            colors_loaded:
              hairColors.length,

            availability_loaded:
              availability.length,
          },
        },
      }),
      {
        status: 200,

        headers: {
          ...corsHeaders,

          "Content-Type":
            "application/json",
        },
      },
    );
  } catch (error) {
    console.error(
      "FAITHI FUNCTION ERROR:",
      error,
    );

    return new Response(
      JSON.stringify({
        reply:
          "I couldn't complete that right now. Please try again in a moment.",

        dataframe: {
          rows: [],
        },

        meta: {
          error: true,
        },
      }),
      {
        status: 500,

        headers: {
          ...corsHeaders,

          "Content-Type":
            "application/json",
        },
      },
    );
  }
});