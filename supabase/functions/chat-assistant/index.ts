import { createClient } from "npm:@supabase/supabase-js@2";
import { ChatOpenAI } from "npm:@langchain/openai@1";
import { StateGraph, StateSchema, START, END } from "npm:@langchain/langgraph@1";
import * as z from "npm:zod@4";

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

const HF_BASE_URL =
  "https://router.huggingface.co/v1";

const HF_ENDPOINT =
  `${HF_BASE_URL}/chat/completions`;

// ============================================================
// FAITH HAIR STYLE WEBSITE FACTS
// ============================================================
// These are public facts already shown by the Flutter website.
// Supabase business_info remains the preferred source of truth.
// These values are only used as a fallback when a matching field is not
// present in business_info yet, so Faithi can still answer questions about
// the salon's own homepage/app without pretending it cannot access it.
const WEBSITE_FALLBACK_FACTS = {
  business_name: "Faith Hair Style",
  location: "Riverdale, Maryland",
  phone: "+1 301-541-9875",
  whatsapp: "+1 301-541-9875",
  instagram_url: "https://www.instagram.com/faith_styl_/",
  tiktok_url: "https://www.tiktok.com/@nfor.ako",
  website_sections: [
    "Home",
    "Gallery",
    "AI Help",
    "Book",
    "Live Chat",
    "Social",
  ],
};

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

For a new booking, collect and validate ALL of these required fields before creating the booking:

- exact salon service
- appointment date
- appointment time
- hair color
- customer's full name
- customer's 10-digit phone number
- customer's valid email address

Do not create a booking with a missing required field.
Do not invent any field.
Use information the customer already provided and do not ask for it again.
The agent may summarize the booking-so-far while collecting the next missing field.

Confirm the important selections briefly. When the customer has clearly chosen to proceed and all required booking information is available, perform the booking directly through the agent action system instead of sending the customer to another page.

Example:

"Perfect. You're choosing Medium Senegalese Twists in color 1B.
I'll take care of the booking with you here."

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
FOLLOW-UP EXPLANATIONS
============================================================

If the customer asks a short follow-up such as:

- "why"
- "why not"
- "how come"
- "what do you mean"
- "explain that"
- "why is that"

use the immediately previous assistant statement and conversation context.

Answer the REASON behind that statement.

Do NOT simply repeat the previous answer.

For availability explanations:
- distinguish between a salon-closed day, configured slots that are unavailable,
  booked appointments, and a date that has no availability slots configured
- only state a reason that is supported by LIVE SALON DATA
- if the data does not reveal the exact reason, say exactly what is known and
  what is not known instead of guessing

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
FAITH HAIR STYLE WEBSITE / HOMEPAGE
============================================================

When a customer refers to:

- the homepage
- the home page
- our website
- this website
- the Faith Hair Style website
- the platform
- the app
- the gallery
- the booking page
- the social page

treat those references as the Faith Hair Style business experience, not as
an unrelated external website.

Do NOT say you cannot access external pages when the customer is referring
to Faith Hair Style's own website/app.

Use LIVE SALON DATA and WEBSITE KNOWLEDGE to answer the question.

Examples:

Customer: "Check on the homepage."
If the previous question was about the phone number, use the salon phone
from BUSINESS INFORMATION / WEBSITE KNOWLEDGE and answer it directly.

Customer: "What is on the gallery page?"
Use live service/image information and explain what is available.

Customer: "Can I book from here?"
Yes. If the required booking details are available, complete the booking
directly through the agent action system. Do not send the customer away.

For website facts, prefer Supabase data. Use WEBSITE FALLBACK FACTS only
when the same public fact is not yet present in Supabase.

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
CURRENT DATE / TIME
============================================================

The live salon context includes CURRENT SALON DATE AND TIME.

When the customer asks for today's date, day, current time, tomorrow,
this weekend, or another relative date, use that live salon clock.

Never say you do not know today's date when CURRENT SALON DATE AND TIME
is present.

============================================================
APPOINTMENT LOOKUP
============================================================

The live salon context may include CURRENT/FUTURE APPOINTMENTS loaded
from the salon appointment or booking table.

Use those appointment records when the customer asks about appointments.

Never say you cannot access the appointment page when appointment data
has been provided in LIVE SALON DATA.

Do not reveal another customer's phone number, email address, or other
private contact information.

If an appointment cannot be uniquely matched to the customer, ask for
one identifying detail at a time instead of guessing.

============================================================
AGENT ACTION EXECUTION
============================================================

Faithi can perform real customer-service actions through LangGraph.

Supported customer actions include:

- create a booking
- find the customer's own booking
- check booking status
- cancel the customer's own booking
- reschedule the customer's own booking
- update the customer's own booking details such as service, color, name, email, or notes

For any action that changes a booking:

- use only information the customer actually provided or clearly confirmed
- never invent consent
- never invent identity, phone number, email, booking ID, service, date, time, or color
- ask only ONE missing question at a time
- do not claim an action was completed unless the AGENT ACTION RESULT says performed=true
- if an action is blocked because a slot is unavailable, offer a real live alternative
- protect customer privacy and never reveal another customer's personal information

When all required information is available and the customer clearly wants the action, perform it. Do not make the customer open another page or repeat information unnecessarily.

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

async function loadOptionalTableRows(
  supabase: any,
  tableNames: string[],
  limit = 50,
): Promise<{ rows: Record<string, unknown>[]; table: string | null }> {
  for (const tableName of tableNames) {
    try {
      const { data, error } = await supabase
        .from(tableName)
        .select("*")
        .limit(limit);

      if (!error && Array.isArray(data)) {
        return {
          rows: data as Record<string, unknown>[],
          table: tableName,
        };
      }
    } catch (_) {
      // Optional website-content tables are allowed to be absent.
    }
  }

  return { rows: [], table: null };
}

function findWebsiteField(
  rows: Record<string, unknown>[],
  aliases: string[],
): string {
  const wanted = aliases.map((value) => value.toLowerCase());

  for (const row of rows) {
    // Wide-row schema: { phone: "...", address: "..." }
    for (const alias of aliases) {
      const value = cleanString((row as any)?.[alias]);
      if (value) return value;
    }

    // Key/value schema: { key: "phone", value: "..." }
    const rowKey = cleanString(
      (row as any)?.key ??
        (row as any)?.name ??
        (row as any)?.label ??
        (row as any)?.title,
    ).toLowerCase();

    if (rowKey && wanted.some((alias) => rowKey === alias || rowKey.includes(alias))) {
      const value = cleanString(
        (row as any)?.value ??
          (row as any)?.content ??
          (row as any)?.detail ??
          (row as any)?.description ??
          (row as any)?.text,
      );
      if (value) return value;
    }
  }

  return "";
}

function buildWebsiteKnowledge(
  businessInfo: Record<string, unknown>[],
  faqs: Record<string, unknown>[],
  testimonials: Record<string, unknown>[],
  salonHours: Record<string, unknown>[],
) {
  const phone = findWebsiteField(businessInfo, [
    "phone",
    "phone_number",
    "business_phone",
    "contact_phone",
    "contact_number",
    "telephone",
  ]) || WEBSITE_FALLBACK_FACTS.phone;

  const whatsapp = findWebsiteField(businessInfo, [
    "whatsapp",
    "whatsapp_number",
    "whatsapp_phone",
  ]) || WEBSITE_FALLBACK_FACTS.whatsapp;

  const instagram = findWebsiteField(businessInfo, [
    "instagram",
    "instagram_url",
    "instagram_link",
  ]) || WEBSITE_FALLBACK_FACTS.instagram_url;

  const tiktok = findWebsiteField(businessInfo, [
    "tiktok",
    "tiktok_url",
    "tiktok_link",
  ]) || WEBSITE_FALLBACK_FACTS.tiktok_url;

  const address = findWebsiteField(businessInfo, [
    "address",
    "street_address",
    "business_address",
    "location",
  ]);

  const email = findWebsiteField(businessInfo, [
    "email",
    "email_address",
    "contact_email",
  ]);

  const businessName = findWebsiteField(businessInfo, [
    "business_name",
    "salon_name",
    "name",
  ]) || WEBSITE_FALLBACK_FACTS.business_name;

  return {
    business_name: businessName,
    location: address || WEBSITE_FALLBACK_FACTS.location,
    address: address || null,
    phone,
    whatsapp,
    email: email || null,
    instagram_url: instagram,
    tiktok_url: tiktok,
    website_sections: WEBSITE_FALLBACK_FACTS.website_sections,
    faqs,
    testimonials,
    salon_hours: salonHours,
  };
}

function recentConversationText(
  history: Record<string, unknown>[],
  customerMessage: string,
): string {
  const recent = history
    .slice(-4)
    .map((item) => cleanString((item as any)?.content))
    .filter(Boolean);

  return [...recent, customerMessage].join("\n").toLowerCase();
}

function buildOwnWebsiteReferenceReply({
  customerMessage,
  history,
  websiteKnowledge,
}: {
  customerMessage: string;
  history: Record<string, unknown>[];
  websiteKnowledge: ReturnType<typeof buildWebsiteKnowledge>;
}): string {
  const current = customerMessage.toLowerCase().trim();
  const mentionsOwnSite = [
    "homepage",
    "home page",
    "website",
    "web site",
    "this page",
    "our page",
    "platform",
    "the app",
    "your app",
  ].some((term) => current.includes(term));

  if (!mentionsOwnSite) return "";

  const context = recentConversationText(history, customerMessage);

  if (
    context.includes("phone") ||
    context.includes("number") ||
    context.includes("contact") ||
    context.includes("call")
  ) {
    const parts = [
      `Yes. Faith Hair Style lists ${websiteKnowledge.phone} as the contact number.`,
    ];
    if (websiteKnowledge.whatsapp) {
      parts.push(`You can also use ${websiteKnowledge.whatsapp} for WhatsApp.`);
    }
    parts.push("I can continue helping you here too.");
    return parts.join(" ");
  }

  if (context.includes("whatsapp")) {
    return `Yes. The Faith Hair Style WhatsApp number is ${websiteKnowledge.whatsapp}. I can also continue your booking here.`;
  }

  if (context.includes("instagram")) {
    return `Yes. Faith Hair Style's Instagram is ${websiteKnowledge.instagram_url}.`;
  }

  if (context.includes("tiktok")) {
    return `Yes. Faith Hair Style's TikTok is ${websiteKnowledge.tiktok_url}.`;
  }

  if (
    context.includes("address") ||
    context.includes("location") ||
    context.includes("where are you")
  ) {
    return websiteKnowledge.address
      ? `Faith Hair Style is located at ${websiteKnowledge.address}.`
      : `Faith Hair Style is in ${websiteKnowledge.location}. The exact street address is not listed in the salon data I have right now.`;
  }

  if (context.includes("email")) {
    return websiteKnowledge.email
      ? `Faith Hair Style's contact email is ${websiteKnowledge.email}.`
      : "I don't see a confirmed public email address in the salon information right now. You can use the listed phone/WhatsApp contact or continue with me here.";
  }

  // For broader website/page questions, the model receives WEBSITE KNOWLEDGE
  // and all live salon tables in the next step and can answer naturally.
  return "";
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
      "cancel",
      "reschedule",
      "booking status",
      "my booking",
      "change my booking",
      "move my appointment",
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
// SALON CLOCK + APPOINTMENT HELPERS
// ============================================================

const DEFAULT_SALON_TIME_ZONE = "America/New_York";

function getSalonClock(timeZone: string) {
  const now = new Date();

  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
    weekday: "long",
  }).formatToParts(now);

  const part = (type: string) =>
    parts.find((item) => item.type === type)?.value || "";

  const isoDate = `${part("year")}-${part("month")}-${part("day")}`;
  const displayDate = new Intl.DateTimeFormat("en-US", {
    timeZone,
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(now);

  const displayTime = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
  }).format(now);

  return {
    isoDate,
    displayDate,
    displayTime,
    timeZone,
  };
}

function pickFirst(
  row: Record<string, unknown>,
  keys: string[],
): unknown {
  for (const key of keys) {
    const value = row?.[key];
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }
  return null;
}

function normalizeDateOnly(value: unknown): string {
  const text = cleanString(value);
  if (!text) return "";

  const isoMatch = text.match(/^(\d{4}-\d{2}-\d{2})/);
  if (isoMatch) return isoMatch[1];

  const parsed = new Date(text);
  if (Number.isNaN(parsed.getTime())) return "";
  return parsed.toISOString().slice(0, 10);
}

function sanitizeAppointment(
  row: Record<string, unknown>,
  sourceTable: string,
) {
  const date = pickFirst(row, [
    "appointment_date",
    "preferred_date",
    "booking_date",
    "scheduled_date",
    "slot_date",
    "date",
    "start_date",
    "starts_at",
    "start_at",
    "scheduled_at",
  ]);

  const time = pickFirst(row, [
    "appointment_time",
    "preferred_time",
    "start_time",
    "booking_time",
    "time",
    "starts_at",
    "start_at",
    "scheduled_at",
  ]);

  const service = pickFirst(row, [
    "service_name",
    "service",
    "hairstyle",
    "style",
    "service_title",
  ]);

  const status = pickFirst(row, [
    "status",
    "booking_status",
    "appointment_status",
  ]);

  const customerName = pickFirst(row, [
    "customer_name",
    "client_name",
    "name",
  ]);

  return {
    source_table: sourceTable,
    id: pickFirst(row, ["id", "booking_id", "appointment_id"]),
    date: date ? normalizeDateOnly(date) || cleanString(date) : "",
    time: cleanString(time),
    service: cleanString(service),
    status: cleanString(status),
    customer_name: cleanString(customerName),
    braid_size: cleanString(pickFirst(row, ["braid_size", "size"])),
    braid_length: cleanString(pickFirst(row, ["braid_length", "length"])),
    color: cleanString(pickFirst(row, ["hair_color", "color"])),
  };
}

async function loadAppointmentRows(
  supabase: any,
  today: string,
) {
  const tableNames = ["appointments", "bookings"];
  const candidateDateColumns = [
    "appointment_date",
    "preferred_date",
    "booking_date",
    "scheduled_date",
    "slot_date",
    "date",
  ];

  const results: any[] = [];
  const loadedTables: string[] = [];

  for (const tableName of tableNames) {
    let tableLoaded = false;

    for (const column of candidateDateColumns) {
      const { data, error } = await supabase
        .from(tableName)
        .select("*")
        .gte(column, today)
        .limit(100);

      if (!error && Array.isArray(data)) {
        results.push(
          ...data.map((row: Record<string, unknown>) =>
            sanitizeAppointment(row, tableName)
          ),
        );
        loadedTables.push(tableName);
        tableLoaded = true;
        break;
      }

      const message = cleanString(error?.message).toLowerCase();
      const code = cleanString(error?.code);

      // If the table itself does not exist, trying more columns is pointless.
      if (
        code === "42P01" ||
        message.includes("relation") && message.includes("does not exist") ||
        message.includes("could not find the table")
      ) {
        tableLoaded = true;
        break;
      }
    }

    // If no known date column worked, load a small sample and filter in code.
    if (!tableLoaded) {
      const { data, error } = await supabase
        .from(tableName)
        .select("*")
        .limit(100);

      if (!error && Array.isArray(data)) {
        results.push(
          ...data.map((row: Record<string, unknown>) =>
            sanitizeAppointment(row, tableName)
          ),
        );
        loadedTables.push(tableName);
      }
    }
  }

  const unique = new Map<string, any>();

  for (const item of results) {
    const key = [
      item.source_table,
      item.id,
      item.date,
      item.time,
      item.service,
      item.customer_name,
    ].join("|");
    unique.set(key, item);
  }

  const appointments = [...unique.values()]
    .filter((item) => !item.date || item.date >= today)
    .sort((a, b) => {
      const left = `${a.date || "9999-12-31"} ${a.time || ""}`;
      const right = `${b.date || "9999-12-31"} ${b.time || ""}`;
      return left.localeCompare(right);
    })
    .slice(0, 100);

  return {
    appointments,
    loadedTables,
  };
}


// ============================================================
// FOLLOW-UP EXPLANATION HELPERS
// ============================================================

function getLastAssistantHistoryMessage(
  history: Record<string, unknown>[],
): string {
  for (let i = history.length - 1; i >= 0; i--) {
    const row = history[i];
    if (cleanString(row?.role).toLowerCase() === "assistant") {
      const content = cleanString(row?.content);
      if (content) return content;
    }
  }
  return "";
}

function isWhyFollowUp(text: string): boolean {
  const value = cleanString(text)
    .toLowerCase()
    .replace(/[?!.,]+$/g, "")
    .trim();

  return [
    "why",
    "why not",
    "how come",
    "what do you mean",
    "explain",
    "explain that",
    "why is that",
    "why is this",
    "why cant i",
    "why can't i",
    "why cant i come",
    "why can't i come",
  ].includes(value);
}

function looksLikeAvailabilityStatement(text: string): boolean {
  const lower = cleanString(text).toLowerCase();

  return containsAny(lower, [
    "opening",
    "openings",
    "available",
    "availability",
    "slot",
    "slots",
    "appointment",
    "appointments",
    "scheduled for",
    "next available",
    "no openings",
    "don't have any openings",
    "do not have any openings",
  ]);
}

function monthNumberFromName(value: string): number {
  const months: Record<string, number> = {
    january: 1,
    february: 2,
    march: 3,
    april: 4,
    may: 5,
    june: 6,
    july: 7,
    august: 8,
    september: 9,
    october: 10,
    november: 11,
    december: 12,
  };

  return months[value.toLowerCase()] ?? 0;
}

function extractReferencedIsoDate(
  text: string,
  salonClock: ReturnType<typeof getSalonClock>,
): string {
  const raw = cleanString(text);
  if (!raw) return "";

  const exact = raw.match(/\b(\d{4}-\d{2}-\d{2})\b/);
  if (exact) return exact[1];

  const monthMatch = raw.match(
    /\b(january|february|march|april|may|june|july|august|september|october|november|december)\s+(\d{1,2})(?:st|nd|rd|th)?(?:,\s*(\d{4}))?\b/i,
  );

  if (monthMatch) {
    const month = monthNumberFromName(monthMatch[1]);
    const day = Number(monthMatch[2]);
    const salonYear = Number(salonClock.isoDate.slice(0, 4));
    let year = Number(monthMatch[3] ?? salonYear);

    if (
      month >= 1 && month <= 12 &&
      day >= 1 && day <= 31 &&
      Number.isFinite(year)
    ) {
      let candidate =
        `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;

      // If the customer/assistant omitted the year and that calendar date is
      // already far in the past, interpret it as the next occurrence.
      if (!monthMatch[3] && candidate < salonClock.isoDate) {
        year += 1;
        candidate =
          `${String(year).padStart(4, "0")}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
      }

      return candidate;
    }
  }

  const weekdayMatch = raw.match(
    /\b(sunday|monday|tuesday|wednesday|thursday|friday|saturday)\b/i,
  );

  if (weekdayMatch) {
    return resolveDateExpression(
      weekdayMatch[1],
      salonClock,
    );
  }

  return "";
}

function displaySalonDate(
  isoDate: string,
  timeZone: string,
): string {
  const parsed = new Date(`${isoDate}T12:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return isoDate;

  return new Intl.DateTimeFormat("en-US", {
    timeZone,
    weekday: "long",
    year: "numeric",
    month: "long",
    day: "numeric",
  }).format(parsed);
}

function weekdayNameForIsoDate(isoDate: string): string {
  const parsed = new Date(`${isoDate}T12:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return "";

  return new Intl.DateTimeFormat("en-US", {
    timeZone: "UTC",
    weekday: "long",
  }).format(parsed);
}

function salonHoursRowForWeekday(
  salonHours: Record<string, unknown>[],
  weekday: string,
): Record<string, unknown> | null {
  const wanted = cleanString(weekday).toLowerCase();

  for (const row of salonHours) {
    const rawDay = cleanString(
      pickFirst(row, [
        "day_of_week",
        "weekday",
        "day",
        "day_name",
        "name",
      ]),
    ).toLowerCase();

    if (!rawDay) continue;

    if (
      rawDay === wanted ||
      rawDay.startsWith(wanted.slice(0, 3)) ||
      wanted.startsWith(rawDay.slice(0, 3))
    ) {
      return row;
    }
  }

  return null;
}

function salonHoursRowExplicitlyClosed(
  row: Record<string, unknown> | null,
): boolean {
  if (!row) return false;

  if (row.is_open === false) return true;
  if (row.open === false) return true;
  if (row.is_closed === true) return true;
  if (row.closed === true) return true;

  const status = cleanString(
    pickFirst(row, ["status", "availability_status"]),
  ).toLowerCase();

  return ["closed", "off", "unavailable"].includes(status);
}

function nextOpenAvailabilityLabel(
  availability: Record<string, unknown>[],
  afterDate: string,
  timeZone: string,
): string {
  const sorted = [...availability]
    .filter((row) => {
      const date = normalizeDateOnly(
        pickFirst(row, ["slot_date", "date", "booking_date"]),
      );

      return date && date > afterDate && row.is_available !== false;
    })
    .sort((a, b) => {
      const left =
        `${normalizeDateOnly(pickFirst(a, ["slot_date", "date", "booking_date"]))} ${normalizeDbTime(pickFirst(a, ["start_time", "time", "slot_time"]))}`;
      const right =
        `${normalizeDateOnly(pickFirst(b, ["slot_date", "date", "booking_date"]))} ${normalizeDbTime(pickFirst(b, ["start_time", "time", "slot_time"]))}`;
      return left.localeCompare(right);
    });

  const first = sorted[0];
  if (!first) return "";

  const date = normalizeDateOnly(
    pickFirst(first, ["slot_date", "date", "booking_date"]),
  );
  const time = normalizeDbTime(
    pickFirst(first, ["start_time", "time", "slot_time"]),
  );

  if (!date) return "";

  const dateLabel = displaySalonDate(date, timeZone);
  return time
    ? `${dateLabel} at ${displayDbTime(time)}`
    : dateLabel;
}

async function buildAvailabilityWhyReply({
  supabase,
  customerMessage,
  history,
  salonClock,
  salonHours,
  appointments,
  availability,
}: {
  supabase: any;
  customerMessage: string;
  history: Record<string, unknown>[];
  salonClock: ReturnType<typeof getSalonClock>;
  salonHours: Record<string, unknown>[];
  appointments: Record<string, unknown>[];
  availability: Record<string, unknown>[];
}): Promise<string | null> {
  if (!isWhyFollowUp(customerMessage)) return null;

  const previousAssistant =
    getLastAssistantHistoryMessage(history);

  if (
    !previousAssistant ||
    !looksLikeAvailabilityStatement(previousAssistant)
  ) {
    return null;
  }

  let targetDate =
    extractReferencedIsoDate(previousAssistant, salonClock);

  // If the assistant message did not include a parsable date, also inspect the
  // most recent user messages because the requested date is often there.
  if (!targetDate) {
    for (let i = history.length - 1; i >= 0; i--) {
      const row = history[i];
      if (cleanString(row?.role).toLowerCase() !== "user") continue;
      targetDate = extractReferencedIsoDate(
        cleanString(row?.content),
        salonClock,
      );
      if (targetDate) break;
    }
  }

  if (!targetDate) {
    return (
      "I was referring to the live appointment schedule. " +
      "I can explain the exact reason once I can identify the date we were discussing."
    );
  }

  const dateLabel =
    displaySalonDate(targetDate, salonClock.timeZone);
  const weekday =
    weekdayNameForIsoDate(targetDate);

  const hoursRow =
    salonHoursRowForWeekday(salonHours, weekday);

  if (salonHoursRowExplicitlyClosed(hoursRow)) {
    const next =
      nextOpenAvailabilityLabel(
        availability,
        targetDate,
        salonClock.timeZone,
      );

    return next
      ? `${dateLabel} is unavailable because the salon schedule marks ${weekday} as closed. The next listed opening I can see is ${next}.`
      : `${dateLabel} is unavailable because the salon schedule marks ${weekday} as closed.`;
  }

  let allSlots: Record<string, unknown>[] = [];
  let slotsTableReadable = true;

  try {
    const { data, error } = await supabase
      .from("availability_slots")
      .select("*")
      .eq("slot_date", targetDate)
      .order("start_time", { ascending: true })
      .limit(200);

    if (error) {
      slotsTableReadable = false;
    } else if (Array.isArray(data)) {
      allSlots = data;
    }
  } catch (_) {
    slotsTableReadable = false;
  }

  const openSlots = allSlots.filter(
    (row) => row.is_available === true,
  );

  if (openSlots.length > 0) {
    const times = openSlots
      .map((row) =>
        displayDbTime(
          pickFirst(row, ["start_time", "time", "slot_time"]),
        )
      )
      .filter(Boolean)
      .slice(0, 3);

    const listed = times.length > 0
      ? ` at ${times.join(", ")}`
      : "";

    return (
      `I checked again, and ${dateLabel} actually has ${openSlots.length} open ` +
      `slot${openSlots.length === 1 ? "" : "s"}${listed}. ` +
      "My previous message was incorrect."
    );
  }

  const dateAppointments = appointments.filter((item) => {
    const date = normalizeDateOnly(
      pickFirst(item, [
        "date",
        "booking_date",
        "appointment_date",
        "preferred_date",
      ]),
    );

    if (date !== targetDate) return false;

    const status = cleanString(
      pickFirst(item, ["status", "booking_status", "appointment_status"]),
    ).toLowerCase();

    return !["cancelled", "canceled", "declined"].includes(status);
  });

  if (allSlots.length > 0 && openSlots.length === 0) {
    const next =
      nextOpenAvailabilityLabel(
        availability,
        targetDate,
        salonClock.timeZone,
      );

    const bookedPart = dateAppointments.length > 0
      ? ` I can also see ${dateAppointments.length} active appointment${dateAppointments.length === 1 ? "" : "s"} scheduled that day.`
      : "";

    const nextPart = next
      ? ` The next listed opening is ${next}.`
      : "";

    return (
      `Because every configured appointment slot for ${dateLabel} is currently marked unavailable.` +
      bookedPart +
      nextPart
    );
  }

  if (dateAppointments.length > 0) {
    const next =
      nextOpenAvailabilityLabel(
        availability,
        targetDate,
        salonClock.timeZone,
      );

    const nextPart = next
      ? ` The next listed opening is ${next}.`
      : "";

    return (
      `I can see ${dateAppointments.length} active appointment${dateAppointments.length === 1 ? "" : "s"} on ${dateLabel}, ` +
      "but there are no open availability slots listed for that date. " +
      "The live data does not show whether the rest of the day is intentionally blocked or simply not opened for booking yet." +
      nextPart
    );
  }

  if (slotsTableReadable) {
    const next =
      nextOpenAvailabilityLabel(
        availability,
        targetDate,
        salonClock.timeZone,
      );

    const nextPart = next
      ? ` The next listed opening is ${next}.`
      : "";

    return (
      `There are no availability slots configured for ${dateLabel} in the live schedule. ` +
      "That is why I could not offer that date. The current data does not tell me whether the salon is closed that day or the schedule has not been opened yet." +
      nextPart
    );
  }

  return (
    `I could not verify the exact reason ${dateLabel} has no opening from the live schedule. ` +
    "I should not guess."
  );
}

// ============================================================
// LANGCHAIN + LANGGRAPH AGENT HELPERS
// ============================================================

const AGENT_ACTIONS = [
  "conversation",
  "find_booking",
  "create_booking",
  "cancel_booking",
  "reschedule_booking",
  "update_booking",
] as const;

type AgentAction = typeof AGENT_ACTIONS[number];

type AgentPlan = {
  action: AgentAction;
  customer_name?: string;
  phone?: string;
  email?: string;
  service_id?: string;
  service_name?: string;
  booking_id?: string;
  booking_date?: string;
  start_time?: string;
  new_date?: string;
  new_start_time?: string;
  hair_color_code?: string;
  notes?: string;
  reason?: string;
};

type AgentActionResult = {
  action: AgentAction;
  performed: boolean;
  status: "not_needed" | "needs_input" | "completed" | "blocked" | "error";
  message: string;
  missing_fields?: string[];
  rows?: Record<string, unknown>[];
  booking_id?: string;
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(
    JSON.stringify(body),
    {
      status,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json",
      },
    },
  );
}

function textFromLangChainContent(content: unknown): string {
  if (typeof content === "string") return content.trim();
  if (!Array.isArray(content)) return cleanString(content);

  return content
    .map((part: any) => {
      if (typeof part === "string") return part;
      if (part?.type === "text") return cleanString(part.text);
      return "";
    })
    .filter(Boolean)
    .join("\n")
    .trim();
}

function normalizePhone(value: unknown): string {
  let digits = cleanString(value).replace(/\D/g, "");
  if (digits.length === 11 && digits.startsWith("1")) {
    digits = digits.slice(1);
  }
  return digits;
}

function normalizeEmail(value: unknown): string {
  return cleanString(value).toLowerCase();
}

function normalizeDbTime(value: unknown): string {
  const raw = cleanString(value);
  if (!raw) return "";

  const twelveHour = raw.match(
    /^(\d{1,2})(?::(\d{2}))?\s*(am|pm)$/i,
  );

  if (twelveHour) {
    let hour = Number(twelveHour[1]);
    const minute = Number(twelveHour[2] ?? "0");
    const suffix = twelveHour[3].toLowerCase();

    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
      return "";
    }

    if (suffix === "pm" && hour !== 12) hour += 12;
    if (suffix === "am" && hour === 12) hour = 0;

    return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:00`;
  }

  const twentyFourHour = raw.match(
    /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/,
  );

  if (twentyFourHour) {
    const hour = Number(twentyFourHour[1]);
    const minute = Number(twentyFourHour[2]);
    const second = Number(twentyFourHour[3] ?? "0");

    if (
      hour >= 0 && hour <= 23 &&
      minute >= 0 && minute <= 59 &&
      second >= 0 && second <= 59
    ) {
      return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}:${String(second).padStart(2, "0")}`;
    }
  }

  return "";
}

function displayDbTime(value: unknown): string {
  const normalized = normalizeDbTime(value);
  if (!normalized) return cleanString(value);

  const [hourText, minute] = normalized.split(":");
  let hour = Number(hourText);
  const suffix = hour >= 12 ? "PM" : "AM";
  hour %= 12;
  if (hour === 0) hour = 12;
  return `${hour}:${minute} ${suffix}`;
}

function addMinutesToTime(value: unknown, minutes: number): string {
  const normalized = normalizeDbTime(value);
  if (!normalized) return "";

  const [hour, minute] = normalized.split(":").map(Number);
  const total = hour * 60 + minute + minutes;
  const wrapped = ((total % 1440) + 1440) % 1440;
  const endHour = Math.floor(wrapped / 60);
  const endMinute = wrapped % 60;

  return `${String(endHour).padStart(2, "0")}:${String(endMinute).padStart(2, "0")}:00`;
}

function addDaysToIsoDate(isoDate: string, days: number): string {
  const parsed = new Date(`${isoDate}T12:00:00Z`);
  if (Number.isNaN(parsed.getTime())) return "";
  parsed.setUTCDate(parsed.getUTCDate() + days);
  return parsed.toISOString().slice(0, 10);
}

function resolveDateExpression(
  value: unknown,
  salonClock: ReturnType<typeof getSalonClock>,
): string {
  const raw = cleanString(value);
  if (!raw) return "";

  const exact = raw.match(/^(\d{4}-\d{2}-\d{2})/);
  if (exact) return exact[1];

  const lower = raw.toLowerCase().trim();
  if (lower === "today") return salonClock.isoDate;
  if (lower === "tomorrow") return addDaysToIsoDate(salonClock.isoDate, 1);

  const weekdays: Record<string, number> = {
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6,
  };

  const weekday = Object.keys(weekdays).find((day) => lower.includes(day));
  if (weekday) {
    const base = new Date(`${salonClock.isoDate}T12:00:00Z`);
    if (!Number.isNaN(base.getTime())) {
      const todayDay = base.getUTCDay();
      let delta = (weekdays[weekday] - todayDay + 7) % 7;
      if (lower.includes("next ") && delta === 0) delta = 7;
      return addDaysToIsoDate(salonClock.isoDate, delta);
    }
  }

  const parsed = new Date(raw);
  if (Number.isNaN(parsed.getTime())) return "";
  return parsed.toISOString().slice(0, 10);
}

function extractFirstJsonObject(text: string): Record<string, unknown> | null {
  const cleaned = removeThinking(text)
    .replace(/^```(?:json)?/i, "")
    .replace(/```$/i, "")
    .trim();

  try {
    const direct = JSON.parse(cleaned);
    if (direct && typeof direct === "object" && !Array.isArray(direct)) {
      return direct as Record<string, unknown>;
    }
  } catch (_) {
    // Continue to brace extraction.
  }

  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  if (start < 0 || end <= start) return null;

  try {
    const parsed = JSON.parse(cleaned.slice(start, end + 1));
    if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
  } catch (_) {
    return null;
  }

  return null;
}

function normalizeAgentPlan(value: unknown): AgentPlan {
  const source = value && typeof value === "object"
    ? value as Record<string, unknown>
    : {};

  const rawAction = cleanString(source.action).toLowerCase();
  const action = AGENT_ACTIONS.includes(rawAction as AgentAction)
    ? rawAction as AgentAction
    : "conversation";

  const plan: AgentPlan = { action };

  const stringFields = [
    "customer_name",
    "phone",
    "email",
    "service_id",
    "service_name",
    "booking_id",
    "booking_date",
    "start_time",
    "new_date",
    "new_start_time",
    "hair_color_code",
    "notes",
    "reason",
  ] as const;

  for (const key of stringFields) {
    const valueText = cleanString(source[key]);
    if (valueText) plan[key] = valueText;
  }

  return plan;
}

// ============================================================
// DETERMINISTIC BOOKING COLLECTION
// ============================================================

const REQUIRED_BOOKING_FIELDS = [
  "service",
  "appointment date",
  "appointment time",
  "hair color",
  "full name",
  "phone number",
  "email address",
] as const;

function isValidEmail(value: unknown): boolean {
  const email = normalizeEmail(value);
  if (!email) return false;
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email);
}

function isExplicitCreateBookingIntent(text: string): boolean {
  const lower = cleanString(text).toLowerCase();
  if (!lower) return false;

  // These are other booking operations, not a new booking.
  if (
    containsAny(lower, [
      "cancel",
      "reschedule",
      "move my appointment",
      "change my appointment",
      "change my booking",
      "booking status",
      "status of my booking",
      "find my booking",
      "check my booking",
    ])
  ) {
    return false;
  }

  return (
    /\b(book|reserve)\b/i.test(lower) ||
    /\bschedule\s+(?:me|an appointment|a booking|my appointment)\b/i.test(lower) ||
    /\b(make|set up)\s+(?:an?\s+)?appointment\b/i.test(lower) ||
    containsAny(lower, [
      "book it",
      "book that",
      "book this",
      "i want to book",
      "i would like to book",
      "i'd like to book",
      "i am ready to book",
      "i'm ready to book",
      "confirm my booking",
      "submit my booking",
    ])
  );
}

function assistantLooksLikeBookingCollection(text: string): boolean {
  const lower = cleanString(text).toLowerCase();
  if (!lower) return false;

  return (
    lower.includes("booking so far") ||
    lower.includes("which hairstyle") ||
    lower.includes("which service") ||
    lower.includes("what date would you like") ||
    lower.includes("which date would you like") ||
    lower.includes("what time would you like") ||
    lower.includes("which time would you like") ||
    lower.includes("what is your full name") ||
    lower.includes("what's your full name") ||
    lower.includes("what phone number") ||
    lower.includes("which phone number") ||
    lower.includes("what email address") ||
    lower.includes("which email address") ||
    lower.includes("which hair color") ||
    lower.includes("what hair color")
  );
}

function lastAssistantMessage(history: Record<string, unknown>[]): string {
  for (let i = history.length - 1; i >= 0; i--) {
    if (cleanString(history[i]?.role).toLowerCase() === "assistant") {
      return cleanString(history[i]?.content);
    }
  }
  return "";
}

function isOngoingCreateBookingFlow(history: Record<string, unknown>[]): boolean {
  const lastAssistant = lastAssistantMessage(history);
  if (assistantLooksLikeBookingCollection(lastAssistant)) return true;

  // If a recent user explicitly started a booking and no later user message
  // clearly switched to cancel/reschedule/status, keep collecting the draft.
  const recentUserMessages = history
    .filter((item) => cleanString(item?.role).toLowerCase() === "user")
    .map((item) => cleanString(item?.content))
    .filter(Boolean)
    .slice(-6);

  let active = false;
  for (const text of recentUserMessages) {
    const lower = text.toLowerCase();
    if (
      containsAny(lower, [
        "cancel",
        "reschedule",
        "move my appointment",
        "change my booking",
        "booking status",
        "check my booking",
      ])
    ) {
      active = false;
      continue;
    }
    if (isExplicitCreateBookingIntent(text)) active = true;
  }
  return active && assistantLooksLikeBookingCollection(lastAssistant);
}

function extractEmailFromText(text: string): string {
  const match = cleanString(text).match(
    /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i,
  );
  return match ? normalizeEmail(match[0]) : "";
}

function extractPhoneFromText(text: string): string {
  const raw = cleanString(text);
  const candidates = raw.match(/(?:\+?1[\s.-]?)?(?:\(?\d{3}\)?[\s.-]?)\d{3}[\s.-]?\d{4}/g) ?? [];
  for (const candidate of candidates) {
    const normalized = normalizePhone(candidate);
    if (normalized.length === 10) return normalized;
  }
  return "";
}

function extractTimeFromText(text: string): string {
  const raw = cleanString(text);
  if (!raw) return "";

  const twelveHour = raw.match(/\b(\d{1,2})(?::(\d{2}))?\s*(AM|PM)\b/i);
  if (twelveHour) {
    return normalizeDbTime(twelveHour[0]);
  }

  const twentyFourHour = raw.match(/\b(\d{1,2}):([0-5]\d)(?::([0-5]\d))?\b/);
  if (twentyFourHour) {
    const hour = Number(twentyFourHour[1]);
    // Without AM/PM, only accept an unambiguous 24-hour time.
    // "8:30" or "10:00" will be clarified instead of guessed.
    if (hour === 0 || hour >= 13) {
      return normalizeDbTime(twentyFourHour[0]);
    }
  }

  return "";
}

function extractDateFromText(
  text: string,
  salonClock: ReturnType<typeof getSalonClock>,
): string {
  const raw = cleanString(text);
  if (!raw) return "";

  const iso = raw.match(/\b\d{4}-\d{2}-\d{2}\b/);
  if (iso) return resolveDateExpression(iso[0], salonClock);

  const relative = raw.match(
    /\b(?:today|tomorrow|(?:next\s+)?(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday))\b/i,
  );
  if (relative) return resolveDateExpression(relative[0], salonClock);

  const monthDate = raw.match(
    /\b(?:january|february|march|april|may|june|july|august|september|october|november|december)\s+\d{1,2}(?:st|nd|rd|th)?(?:,?\s+\d{4})?\b/i,
  );
  if (monthDate) {
    let candidate = monthDate[0].replace(/(st|nd|rd|th)\b/gi, "");
    if (!/\b\d{4}\b/.test(candidate)) {
      candidate = `${candidate}, ${salonClock.isoDate.slice(0, 4)}`;
      let resolved = resolveDateExpression(candidate, salonClock);
      if (resolved && resolved < salonClock.isoDate) {
        const nextYear = String(Number(salonClock.isoDate.slice(0, 4)) + 1);
        candidate = candidate.replace(/\d{4}\s*$/, nextYear);
        resolved = resolveDateExpression(candidate, salonClock);
      }
      return resolved;
    }
    return resolveDateExpression(candidate, salonClock);
  }

  const numeric = raw.match(/\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b/);
  if (numeric) return resolveDateExpression(numeric[0], salonClock);

  return "";
}

function extractNameFromText(text: string, promptedForName = false): string {
  const raw = cleanString(text);
  if (!raw) return "";

  const explicit = raw.match(
    /\b(?:my\s+name\s+is|name\s+is|this\s+is)\s+([A-Za-z][A-Za-z' -]{1,79})\s*$/i,
  );
  if (explicit) return cleanString(explicit[1]);

  if (!promptedForName) return "";
  if (extractEmailFromText(raw) || extractPhoneFromText(raw)) return "";
  if (/\d/.test(raw)) return "";
  if (!/^[A-Za-z][A-Za-z' -]{1,79}$/.test(raw)) return "";

  const lower = raw.toLowerCase();
  if (
    [
      "yes",
      "no",
      "okay",
      "ok",
      "sure",
      "book it",
      "ready",
      "medium",
      "small",
      "large",
      "jumbo",
    ].includes(lower)
  ) {
    return "";
  }

  return raw;
}

function findColorCodeFromText(
  text: string,
  hairColors: Record<string, unknown>[],
): string {
  const lower = cleanString(text).toLowerCase();
  if (!lower) return "";

  // Prefer exact code matches, then full color-name matches.
  const sorted = [...hairColors].sort(
    (a, b) => cleanString(b.code).length - cleanString(a.code).length,
  );

  for (const color of sorted) {
    const code = cleanString(color.code);
    if (!code) continue;
    const pattern = new RegExp(
      `(^|[^a-z0-9])${code.replace(/[.*+?^${}()|[\]\\]/g, "\\$&").toLowerCase()}([^a-z0-9]|$)`,
      "i",
    );
    if (pattern.test(lower)) return code;
  }

  for (const color of hairColors) {
    const name = cleanString(color.name);
    if (name && lower.includes(name.toLowerCase())) {
      return cleanString(color.code);
    }
  }

  return "";
}

function findUniqueServiceFromText(
  text: string,
  services: Record<string, unknown>[],
): Record<string, unknown> | null {
  const lower = cleanString(text).toLowerCase();
  if (!lower) return null;

  // Exact/full-name mentions are strongest. Longest wins.
  const fullMatches = services
    .filter((service) => {
      const name = cleanString(service.name).toLowerCase();
      return name && lower.includes(name);
    })
    .sort(
      (a, b) => cleanString(b.name).length - cleanString(a.name).length,
    );

  if (fullMatches.length > 0) return fullMatches[0];

  const matched = findMatchingServices(lower, services);
  if (matched.length === 1) return matched[0];
  return null;
}

function parseBookingSummaryFromAssistantHistory(
  history: Record<string, unknown>[],
): AgentPlan {
  for (let i = history.length - 1; i >= 0; i--) {
    if (cleanString(history[i]?.role).toLowerCase() !== "assistant") continue;
    const text = cleanString(history[i]?.content);
    if (!text.toLowerCase().includes("booking so far")) continue;

    const plan: AgentPlan = { action: "create_booking" };
    const service = text.match(/Service:\s*([^;\n]+?)(?=;|\.?(?:\n|$))/i)?.[1];
    const date = text.match(/Date:\s*([^;\n]+?)(?=;|\.?(?:\n|$))/i)?.[1];
    const time = text.match(/Time:\s*([^;\n]+?)(?=;|\.?(?:\n|$))/i)?.[1];
    const color = text.match(/Color:\s*([^;\n]+?)(?=;|\.?(?:\n|$))/i)?.[1];
    const name = text.match(/Name:\s*([^;\n]+?)(?=;|\.?(?:\n|$))/i)?.[1];

    if (service && cleanString(service).toLowerCase() !== "not selected") {
      plan.service_name = cleanString(service);
    }
    if (date && cleanString(date).toLowerCase() !== "not selected") {
      plan.booking_date = cleanString(date);
    }
    if (time && cleanString(time).toLowerCase() !== "not selected") {
      plan.start_time = cleanString(time);
    }
    if (color && cleanString(color).toLowerCase() !== "not selected") {
      plan.hair_color_code = cleanString(color);
    }
    if (name && cleanString(name).toLowerCase() !== "not provided") {
      plan.customer_name = cleanString(name);
    }

    return plan;
  }

  return { action: "create_booking" };
}

function previousAssistantForIndex(
  history: Record<string, unknown>[],
  index: number,
): string {
  for (let i = index - 1; i >= 0; i--) {
    if (cleanString(history[i]?.role).toLowerCase() === "assistant") {
      return cleanString(history[i]?.content);
    }
  }
  return "";
}

function buildDeterministicCreateBookingPlan({
  customerMessage,
  history,
  customerPreferences,
  salonClock,
  services,
  hairColors,
}: {
  customerMessage: string;
  history: Record<string, unknown>[];
  customerPreferences: Record<string, unknown>;
  salonClock: ReturnType<typeof getSalonClock>;
  services: Record<string, unknown>[];
  hairColors: Record<string, unknown>[];
}): AgentPlan | null {
  const explicitIntent = isExplicitCreateBookingIntent(customerMessage);
  const activeFlow = isOngoingCreateBookingFlow(history);

  const lastAssistant = lastAssistantMessage(history);
  const affirmativeAfterBookingOffer =
    /^(yes|yeah|yep|sure|okay|ok|that works|do it|go ahead)$/i.test(customerMessage.trim()) &&
    /\b(book|booking|appointment)\b/i.test(lastAssistant);

  if (!explicitIntent && !activeFlow && !affirmativeAfterBookingOffer) {
    return null;
  }

  const plan = parseBookingSummaryFromAssistantHistory(history);
  plan.action = "create_booking";

  const userEntries: Array<{ text: string; prompt: string }> = [];
  for (let i = 0; i < history.length; i++) {
    if (cleanString(history[i]?.role).toLowerCase() !== "user") continue;
    userEntries.push({
      text: cleanString(history[i]?.content),
      prompt: previousAssistantForIndex(history, i),
    });
  }
  userEntries.push({ text: customerMessage, prompt: lastAssistant });

  const combinedUserText = userEntries.map((entry) => entry.text).join("\n");

  // Service: customer text first. If the user says "book it", allow the
  // immediately previous assistant recommendation to supply the selected service.
  const serviceFromUser = findUniqueServiceFromText(combinedUserText, services);
  if (serviceFromUser) {
    plan.service_id = cleanString(serviceFromUser.id);
    plan.service_name = cleanString(serviceFromUser.name);
  } else if (!plan.service_name && /\b(book it|book that|book this|yes|that works)\b/i.test(customerMessage)) {
    const serviceFromAssistant = findUniqueServiceFromText(lastAssistant, services);
    if (serviceFromAssistant) {
      plan.service_id = cleanString(serviceFromAssistant.id);
      plan.service_name = cleanString(serviceFromAssistant.name);
    }
  }

  for (const entry of userEntries) {
    const promptLower = entry.prompt.toLowerCase();

    const email = extractEmailFromText(entry.text);
    if (email) plan.email = email;

    const phone = extractPhoneFromText(entry.text);
    if (phone) plan.phone = phone;

    const date = extractDateFromText(entry.text, salonClock);
    if (date) plan.booking_date = date;

    const time = extractTimeFromText(entry.text);
    if (time) plan.start_time = time;

    const shortAnswer = entry.text.trim().toLowerCase();
    const promptAsksColor =
      promptLower.includes("hair color") ||
      promptLower.includes("color code") ||
      promptLower.includes("which color") ||
      promptLower.includes("what color");
    const textMentionsColor = /\bcolou?r\b/i.test(entry.text);
    const exactColorAnswer = hairColors.some((row) => {
      const code = cleanString(row.code).toLowerCase();
      const name = cleanString(row.name).toLowerCase();
      return shortAnswer === code || shortAnswer === name;
    });

    if (promptAsksColor || textMentionsColor || exactColorAnswer) {
      const color = findColorCodeFromText(entry.text, hairColors);
      if (color) plan.hair_color_code = color;
    }

    const name = extractNameFromText(
      entry.text,
      promptLower.includes("full name") ||
        promptLower.includes("name for the booking") ||
        promptLower.includes("what name"),
    );
    if (name) plan.customer_name = name;
  }

  // Reuse known safe preferences where they map directly to booking fields.
  if (!plan.booking_date) {
    const prefDate = cleanString(customerPreferences.datePreference ?? customerPreferences.date_preference);
    const resolved = extractDateFromText(prefDate, salonClock);
    if (resolved) plan.booking_date = resolved;
  }

  if (!plan.hair_color_code) {
    const prefColor = cleanString(customerPreferences.color);
    const color = findColorCodeFromText(prefColor, hairColors);
    if (color) plan.hair_color_code = color;
  }

  return plan;
}

function bookingCollectedFields(plan: AgentPlan): string[] {
  const fields: string[] = [];
  if (cleanString(plan.service_id) || cleanString(plan.service_name)) fields.push("service");
  if (cleanString(plan.booking_date)) fields.push("appointment date");
  if (normalizeDbTime(plan.start_time)) fields.push("appointment time");
  if (cleanString(plan.hair_color_code)) fields.push("hair color");
  if (cleanString(plan.customer_name)) fields.push("full name");
  if (normalizePhone(plan.phone).length === 10) fields.push("phone number");
  if (isValidEmail(plan.email)) fields.push("email address");
  return fields;
}

function bookingDraftSummary(plan: AgentPlan): string {
  const parts: string[] = [];
  if (cleanString(plan.service_name)) parts.push(`Service: ${cleanString(plan.service_name)}`);
  if (cleanString(plan.booking_date)) parts.push(`Date: ${cleanString(plan.booking_date)}`);
  if (normalizeDbTime(plan.start_time)) parts.push(`Time: ${displayDbTime(plan.start_time)}`);
  if (cleanString(plan.hair_color_code)) parts.push(`Color: ${cleanString(plan.hair_color_code)}`);
  if (cleanString(plan.customer_name)) parts.push(`Name: ${cleanString(plan.customer_name)}`);

  return parts.length > 0 ? `Booking so far — ${parts.join("; ")}.` : "";
}

function questionForMissingBookingField(field: string): string {
  switch (field) {
    case "service":
      return "Which hairstyle or service would you like to book?";
    case "appointment date":
      return "What date would you like for your appointment?";
    case "appointment time":
      return "What time would you like? Please include AM or PM.";
    case "hair color":
      return "Which hair color would you like? You can give me the color code, such as 1B.";
    case "full name":
      return "What is your full name for the booking?";
    case "phone number":
      return "What 10-digit phone number should I use for the booking?";
    case "email address":
      return "What email address should I use for the booking?";
    default:
      return `Please provide your ${field}.`;
  }
}

function buildDeterministicBookingReply(
  result: AgentActionResult,
  plan: AgentPlan,
): string {
  if (result.status === "needs_input") {
    const field = result.missing_fields?.[0] || "booking information";
    const summary = bookingDraftSummary(plan);
    const question = questionForMissingBookingField(field);
    return summary ? `${summary}\n${question}` : question;
  }

  if (result.status === "completed") {
    const row = result.rows?.[0] as Record<string, unknown> | undefined;
    if (row) {
      const service = cleanString(row.service_name || plan.service_name) || "your service";
      const date = cleanString(row.booking_date || plan.booking_date);
      const time = displayDbTime(row.start_time || plan.start_time);
      const bookingId = cleanString(result.booking_id || row.id);
      return `Your booking has been submitted for ${service} on ${date} at ${time}. ` +
        `Your booking reference is ${bookingId}. The status is pending confirmation.`;
    }
    return result.message;
  }

  const summary = bookingDraftSummary(plan);
  return summary ? `${summary}\n${result.message}` : result.message;
}


async function loadActiveServicesForAgent(supabase: any) {
  const { data, error } = await supabase
    .from("services")
    .select(
      "id,name,category,description,price,duration_minutes,image_url,is_active",
    )
    .eq("is_active", true)
    .order("price", { ascending: true })
    .limit(150);

  if (error) throw new Error(error.message);
  return Array.isArray(data) ? data : [];
}

async function resolveServiceForAgent(
  supabase: any,
  serviceId?: string,
  serviceName?: string,
) {
  const id = cleanString(serviceId);
  if (id) {
    const { data, error } = await supabase
      .from("services")
      .select(
        "id,name,category,description,price,duration_minutes,image_url,is_active",
      )
      .eq("id", id)
      .maybeSingle();

    if (!error && data && data.is_active !== false) return data;
  }

  const wanted = cleanString(serviceName).toLowerCase();
  if (!wanted) return null;

  const services = await loadActiveServicesForAgent(supabase);

  const exact = services.find(
    (service: any) => cleanString(service.name).toLowerCase() === wanted,
  );
  if (exact) return exact;

  const contains = services.find((service: any) => {
    const name = cleanString(service.name).toLowerCase();
    return name.includes(wanted) || wanted.includes(name);
  });
  if (contains) return contains;

  const words = wanted.split(/\s+/).filter((word) => word.length >= 3);
  return services.find((service: any) => {
    const name = cleanString(service.name).toLowerCase();
    return words.length > 0 && words.every((word) => name.includes(word));
  }) ?? null;
}

async function validateHairColorForAgent(
  supabase: any,
  code: string,
) {
  const wanted = cleanString(code);
  if (!wanted) return null;

  const { data, error } = await supabase
    .from("hair_colors")
    .select("code,name,is_active")
    .eq("code", wanted)
    .eq("is_active", true)
    .maybeSingle();

  if (error || !data) return null;
  return data;
}

async function hasBookingConflictForAgent(
  supabase: any,
  bookingDate: string,
  startTime: string,
  excludeBookingId?: string,
): Promise<boolean> {
  const { data, error } = await supabase
    .from("bookings")
    .select("id,booking_date,start_time,status")
    .eq("booking_date", bookingDate)
    .limit(250);

  if (error) throw new Error(error.message);

  const normalizedTime = normalizeDbTime(startTime);

  return (Array.isArray(data) ? data : []).some((row: any) => {
    if (
      excludeBookingId &&
      cleanString(row.id) === cleanString(excludeBookingId)
    ) {
      return false;
    }

    const status = cleanString(row.status).toLowerCase();
    if (["cancelled", "canceled", "declined"].includes(status)) return false;

    return normalizeDbTime(row.start_time) === normalizedTime;
  });
}

async function findDuplicateBookingForAgent(
  supabase: any,
  phone: string,
  serviceId: string,
  bookingDate: string,
  startTime: string,
) {
  const normalizedPhone = normalizePhone(phone);
  if (!normalizedPhone) return null;

  const { data, error } = await supabase
    .from("bookings")
    .select("*")
    .eq("booking_date", bookingDate)
    .eq("service_id", serviceId)
    .limit(100);

  if (error) return null;

  return (Array.isArray(data) ? data : []).find((row: any) => {
    const status = cleanString(row.status).toLowerCase();
    if (["cancelled", "canceled", "declined"].includes(status)) return false;

    return normalizePhone(row.phone) === normalizedPhone &&
      normalizeDbTime(row.start_time) === normalizeDbTime(startTime);
  }) ?? null;
}

type SlotCheck = {
  slot: Record<string, unknown> | null;
  dateHasManagedSlots: boolean;
  tableAvailable: boolean;
};

async function findMatchingOpenSlotForAgent(
  supabase: any,
  date: string,
  startTime: string,
): Promise<SlotCheck> {
  const normalizedStart = normalizeDbTime(startTime);

  const { data, error } = await supabase
    .from("availability_slots")
    .select("*")
    .eq("slot_date", date)
    .limit(150);

  if (error) {
    return {
      slot: null,
      dateHasManagedSlots: false,
      tableAvailable: false,
    };
  }

  const allRows = Array.isArray(data) ? data : [];
  const openRows = allRows.filter((row: any) => row.is_available === true);
  const slot = openRows.find(
    (row: any) => normalizeDbTime(row.start_time) === normalizedStart,
  ) ?? null;

  return {
    slot,
    dateHasManagedSlots: allRows.length > 0,
    tableAvailable: true,
  };
}

async function claimAvailabilitySlotForAgent(
  supabase: any,
  slot: Record<string, unknown> | null,
) {
  if (!slot?.id) return { claimed: true, row: null };

  const { data, error } = await supabase
    .from("availability_slots")
    .update({ is_available: false })
    .eq("id", slot.id)
    .eq("is_available", true)
    .select("*")
    .maybeSingle();

  if (error || !data) {
    return { claimed: false, row: null };
  }

  return { claimed: true, row: data };
}

async function releaseAvailabilitySlotForAgent(
  supabase: any,
  date: unknown,
  startTime: unknown,
) {
  const targetDate = normalizeDateOnly(date);
  const targetTime = normalizeDbTime(startTime);
  if (!targetDate || !targetTime) return;

  try {
    await supabase
      .from("availability_slots")
      .update({ is_available: true })
      .eq("slot_date", targetDate)
      .eq("start_time", targetTime);
  } catch (_) {
    // Non-fatal. Booking state remains authoritative.
  }
}

async function enrichBookingForAgent(supabase: any, row: any) {
  let serviceName = "";
  let price: unknown = null;

  if (row?.service_id) {
    const { data } = await supabase
      .from("services")
      .select("name,price")
      .eq("id", row.service_id)
      .maybeSingle();

    if (data) {
      serviceName = cleanString(data.name);
      price = data.price;
    }
  }

  return {
    source_table: "bookings",
    id: row?.id,
    customer_name: cleanString(row?.customer_name),
    service_id: row?.service_id,
    service_name: serviceName,
    price,
    booking_date: row?.booking_date,
    start_time: row?.start_time,
    end_time: row?.end_time,
    hair_color_code: row?.hair_color_code,
    status: row?.status,
    notes: row?.notes,
  };
}

async function findOwnBookingsForAgent(
  supabase: any,
  phone?: string,
  email?: string,
  bookingId?: string,
) {
  const normalizedPhone = normalizePhone(phone);
  const normalizedEmail = normalizeEmail(email);
  const id = cleanString(bookingId);

  if (!normalizedPhone && !normalizedEmail) {
    return [];
  }

  let query = supabase
    .from("bookings")
    .select("*")
    .order("created_at", { ascending: false })
    .limit(200);

  if (id) query = query.eq("id", id);

  const { data, error } = await query;
  if (error) throw new Error(error.message);

  const matched = (Array.isArray(data) ? data : []).filter((row: any) => {
    const phoneMatches = normalizedPhone &&
      normalizePhone(row.phone) === normalizedPhone;
    const emailMatches = normalizedEmail &&
      normalizeEmail(row.email) === normalizedEmail;
    return Boolean(phoneMatches || emailMatches);
  });

  return await Promise.all(
    matched.slice(0, 10).map((row: any) => enrichBookingForAgent(supabase, row)),
  );
}

async function fetchVerifiedBookingForAgent(
  supabase: any,
  bookingId: string,
  phone: string,
) {
  const id = cleanString(bookingId);
  const normalizedPhone = normalizePhone(phone);
  if (!id || !normalizedPhone) return null;

  const { data, error } = await supabase
    .from("bookings")
    .select("*")
    .eq("id", id)
    .maybeSingle();

  if (error || !data) return null;
  if (normalizePhone(data.phone) !== normalizedPhone) return null;
  return data;
}

async function createBookingForAgent(
  supabase: any,
  plan: AgentPlan,
  salonClock: ReturnType<typeof getSalonClock>,
): Promise<AgentActionResult> {
  const missing: string[] = [];
  const customerName = cleanString(plan.customer_name);
  const phone = cleanString(plan.phone);
  const targetDate = resolveDateExpression(plan.booking_date, salonClock);
  const targetTime = normalizeDbTime(plan.start_time);

  // Match the required fields used by the existing Flutter BookingPage.
  // Keep this order so Faithi asks for one useful missing field at a time.
  if (!cleanString(plan.service_id) && !cleanString(plan.service_name)) {
    missing.push("service");
  }
  if (!targetDate) missing.push("appointment date");
  if (!targetTime) missing.push("appointment time");
  if (!cleanString(plan.hair_color_code)) missing.push("hair color");
  if (!customerName) missing.push("full name");
  if (normalizePhone(phone).length !== 10) missing.push("phone number");
  if (!isValidEmail(plan.email)) missing.push("email address");

  if (missing.length > 0) {
    return {
      action: "create_booking",
      performed: false,
      status: "needs_input",
      message: `Booking is not ready yet. Ask for ${missing[0]}.`,
      missing_fields: missing,
      rows: [],
    };
  }

  if (targetDate < salonClock.isoDate) {
    return {
      action: "create_booking",
      performed: false,
      status: "blocked",
      message: "The requested appointment date is in the past. Ask for a future date.",
      rows: [],
    };
  }

  const service = await resolveServiceForAgent(
    supabase,
    plan.service_id,
    plan.service_name,
  );

  if (!service) {
    return {
      action: "create_booking",
      performed: false,
      status: "blocked",
      message: "The requested service could not be matched to an active Faith Hair Style service. Ask the customer to choose an offered service.",
      rows: [],
    };
  }

  const colorCode = cleanString(plan.hair_color_code);
  if (colorCode) {
    const color = await validateHairColorForAgent(supabase, colorCode);
    if (!color) {
      return {
        action: "create_booking",
        performed: false,
        status: "blocked",
        message: `Hair color ${colorCode} is not confirmed as available. Ask the customer to choose an available color.`,
        rows: [],
      };
    }
  }

  const duplicate = await findDuplicateBookingForAgent(
    supabase,
    phone,
    cleanString(service.id),
    targetDate,
    targetTime,
  );

  if (duplicate) {
    const safe = await enrichBookingForAgent(supabase, duplicate);
    return {
      action: "create_booking",
      performed: true,
      status: "completed",
      message: `This booking already exists as booking ${cleanString(duplicate.id)}. Do not create a duplicate.`,
      booking_id: cleanString(duplicate.id),
      rows: [safe],
    };
  }

  const conflict = await hasBookingConflictForAgent(
    supabase,
    targetDate,
    targetTime,
  );

  if (conflict) {
    return {
      action: "create_booking",
      performed: false,
      status: "blocked",
      message: "That appointment time is already booked. Offer another live opening.",
      rows: [],
    };
  }

  const slotCheck = await findMatchingOpenSlotForAgent(
    supabase,
    targetDate,
    targetTime,
  );

  if (
    slotCheck.tableAvailable &&
    slotCheck.dateHasManagedSlots &&
    !slotCheck.slot
  ) {
    return {
      action: "create_booking",
      performed: false,
      status: "blocked",
      message: "That time is not an available salon slot. Check the live availability and offer a listed opening.",
      rows: [],
    };
  }

  const claim = await claimAvailabilitySlotForAgent(supabase, slotCheck.slot);
  if (!claim.claimed) {
    return {
      action: "create_booking",
      performed: false,
      status: "blocked",
      message: "That appointment slot was just taken. Check the live availability again and offer another opening.",
      rows: [],
    };
  }

  const duration = Number(service.duration_minutes);
  const slotEnd = normalizeDbTime((slotCheck.slot as any)?.end_time);
  const endTime = slotEnd || addMinutesToTime(
    targetTime,
    Number.isFinite(duration) && duration > 0 ? duration : 60,
  );

  const payload = {
    customer_name: customerName,
    phone: normalizePhone(phone),
    email: normalizeEmail(plan.email),
    service_id: service.id,
    booking_date: targetDate,
    start_time: targetTime,
    end_time: endTime,
    status: "pending",
    hair_color_code: colorCode || null,
    notes: cleanString(plan.notes),
  };

  const { data: booking, error } = await supabase
    .from("bookings")
    .insert(payload)
    .select("*")
    .single();

  if (error || !booking) {
    if (slotCheck.slot) {
      await releaseAvailabilitySlotForAgent(
        supabase,
        targetDate,
        targetTime,
      );
    }

    console.error("AGENT CREATE BOOKING ERROR:", error);

    return {
      action: "create_booking",
      performed: false,
      status: "error",
      message: "The booking could not be saved right now. Ask the customer to try again in a moment.",
      rows: [],
    };
  }

  const safe = await enrichBookingForAgent(supabase, booking);

  return {
    action: "create_booking",
    performed: true,
    status: "completed",
    message: `Booking ${cleanString(booking.id)} was created successfully for ${cleanString(service.name)} on ${targetDate} at ${displayDbTime(targetTime)}. It is pending confirmation.`,
    booking_id: cleanString(booking.id),
    rows: [safe],
  };
}

async function findBookingForAgent(
  supabase: any,
  plan: AgentPlan,
): Promise<AgentActionResult> {
  if (!normalizePhone(plan.phone) && !normalizeEmail(plan.email)) {
    return {
      action: "find_booking",
      performed: false,
      status: "needs_input",
      message: "To protect privacy, ask for the phone number or email used for the booking.",
      missing_fields: ["phone number or email"],
      rows: [],
    };
  }

  try {
    const rows = await findOwnBookingsForAgent(
      supabase,
      plan.phone,
      plan.email,
      plan.booking_id,
    );

    return {
      action: "find_booking",
      performed: true,
      status: "completed",
      message: rows.length > 0
        ? `Found ${rows.length} matching booking(s).`
        : "No matching booking was found with those details.",
      rows,
    };
  } catch (error) {
    console.error("AGENT FIND BOOKING ERROR:", error);
    return {
      action: "find_booking",
      performed: false,
      status: "error",
      message: "The booking could not be checked right now. Ask the customer to try again in a moment.",
      rows: [],
    };
  }
}

async function cancelBookingForAgent(
  supabase: any,
  plan: AgentPlan,
): Promise<AgentActionResult> {
  const missing: string[] = [];
  if (!cleanString(plan.booking_id)) missing.push("booking ID");
  if (normalizePhone(plan.phone).length < 10) missing.push("booking phone number");

  if (missing.length > 0) {
    return {
      action: "cancel_booking",
      performed: false,
      status: "needs_input",
      message: `Cancellation needs ${missing[0]}.`,
      missing_fields: missing,
      rows: [],
    };
  }

  const booking = await fetchVerifiedBookingForAgent(
    supabase,
    cleanString(plan.booking_id),
    cleanString(plan.phone),
  );

  if (!booking) {
    return {
      action: "cancel_booking",
      performed: false,
      status: "blocked",
      message: "The booking could not be verified with that booking ID and phone number.",
      rows: [],
    };
  }

  const currentStatus = cleanString(booking.status).toLowerCase();
  if (["cancelled", "canceled"].includes(currentStatus)) {
    return {
      action: "cancel_booking",
      performed: true,
      status: "completed",
      message: "That booking is already cancelled.",
      rows: [await enrichBookingForAgent(supabase, booking)],
      booking_id: cleanString(booking.id),
    };
  }

  const { data: updated, error } = await supabase
    .from("bookings")
    .update({ status: "cancelled" })
    .eq("id", booking.id)
    .select("*")
    .single();

  if (error || !updated) {
    console.error("AGENT CANCEL BOOKING ERROR:", error);
    return {
      action: "cancel_booking",
      performed: false,
      status: "error",
      message: "The booking could not be cancelled right now. Ask the customer to try again in a moment.",
      rows: [],
    };
  }

  await releaseAvailabilitySlotForAgent(
    supabase,
    booking.booking_date,
    booking.start_time,
  );

  return {
    action: "cancel_booking",
    performed: true,
    status: "completed",
    message: `Booking ${cleanString(booking.id)} has been cancelled.`,
    booking_id: cleanString(booking.id),
    rows: [await enrichBookingForAgent(supabase, updated)],
  };
}

async function rescheduleBookingForAgent(
  supabase: any,
  plan: AgentPlan,
  salonClock: ReturnType<typeof getSalonClock>,
): Promise<AgentActionResult> {
  const missing: string[] = [];
  const bookingId = cleanString(plan.booking_id);
  const phone = cleanString(plan.phone);
  const targetDate = resolveDateExpression(plan.new_date, salonClock);
  const targetTime = normalizeDbTime(plan.new_start_time);

  if (!bookingId) missing.push("booking ID");
  if (normalizePhone(phone).length < 10) missing.push("booking phone number");
  if (!targetDate) missing.push("new appointment date");
  if (!targetTime) missing.push("new appointment time");

  if (missing.length > 0) {
    return {
      action: "reschedule_booking",
      performed: false,
      status: "needs_input",
      message: `Rescheduling needs ${missing[0]}.`,
      missing_fields: missing,
      rows: [],
    };
  }

  if (targetDate < salonClock.isoDate) {
    return {
      action: "reschedule_booking",
      performed: false,
      status: "blocked",
      message: "The new appointment date cannot be in the past.",
      rows: [],
    };
  }

  const booking = await fetchVerifiedBookingForAgent(
    supabase,
    bookingId,
    phone,
  );

  if (!booking) {
    return {
      action: "reschedule_booking",
      performed: false,
      status: "blocked",
      message: "The booking could not be verified with that booking ID and phone number.",
      rows: [],
    };
  }

  const conflict = await hasBookingConflictForAgent(
    supabase,
    targetDate,
    targetTime,
    bookingId,
  );

  if (conflict) {
    return {
      action: "reschedule_booking",
      performed: false,
      status: "blocked",
      message: "The requested new time is already booked. Offer another live opening.",
      rows: [],
    };
  }

  const slotCheck = await findMatchingOpenSlotForAgent(
    supabase,
    targetDate,
    targetTime,
  );

  if (
    slotCheck.tableAvailable &&
    slotCheck.dateHasManagedSlots &&
    !slotCheck.slot
  ) {
    return {
      action: "reschedule_booking",
      performed: false,
      status: "blocked",
      message: "The requested new time is not an available salon slot. Check live availability and offer another opening.",
      rows: [],
    };
  }

  const claim = await claimAvailabilitySlotForAgent(supabase, slotCheck.slot);
  if (!claim.claimed) {
    return {
      action: "reschedule_booking",
      performed: false,
      status: "blocked",
      message: "That new appointment slot was just taken. Check live availability again.",
      rows: [],
    };
  }

  let durationMinutes = 60;
  const { data: service } = await supabase
    .from("services")
    .select("duration_minutes")
    .eq("id", booking.service_id)
    .maybeSingle();

  if (service && Number(service.duration_minutes) > 0) {
    durationMinutes = Number(service.duration_minutes);
  }

  const slotEnd = normalizeDbTime((slotCheck.slot as any)?.end_time);
  const newEndTime = slotEnd || addMinutesToTime(targetTime, durationMinutes);

  const oldDate = booking.booking_date;
  const oldTime = booking.start_time;

  const { data: updated, error } = await supabase
    .from("bookings")
    .update({
      booking_date: targetDate,
      start_time: targetTime,
      end_time: newEndTime,
      status: "pending",
    })
    .eq("id", booking.id)
    .select("*")
    .single();

  if (error || !updated) {
    if (slotCheck.slot) {
      await releaseAvailabilitySlotForAgent(supabase, targetDate, targetTime);
    }

    console.error("AGENT RESCHEDULE BOOKING ERROR:", error);

    return {
      action: "reschedule_booking",
      performed: false,
      status: "error",
      message: "The booking could not be rescheduled right now. Ask the customer to try again in a moment.",
      rows: [],
    };
  }

  await releaseAvailabilitySlotForAgent(supabase, oldDate, oldTime);

  return {
    action: "reschedule_booking",
    performed: true,
    status: "completed",
    message: `Booking ${bookingId} has been moved to ${targetDate} at ${displayDbTime(targetTime)} and is pending confirmation.`,
    booking_id: bookingId,
    rows: [await enrichBookingForAgent(supabase, updated)],
  };
}

async function updateBookingForAgent(
  supabase: any,
  plan: AgentPlan,
): Promise<AgentActionResult> {
  const missing: string[] = [];
  const bookingId = cleanString(plan.booking_id);
  const phone = cleanString(plan.phone);

  if (!bookingId) missing.push("booking ID");
  if (normalizePhone(phone).length < 10) missing.push("booking phone number");

  if (missing.length > 0) {
    return {
      action: "update_booking",
      performed: false,
      status: "needs_input",
      message: `Updating the booking needs ${missing[0]}.`,
      missing_fields: missing,
      rows: [],
    };
  }

  const booking = await fetchVerifiedBookingForAgent(
    supabase,
    bookingId,
    phone,
  );

  if (!booking) {
    return {
      action: "update_booking",
      performed: false,
      status: "blocked",
      message: "The booking could not be verified with that booking ID and phone number.",
      rows: [],
    };
  }

  const updates: Record<string, unknown> = {};

  if (cleanString(plan.customer_name)) {
    updates.customer_name = cleanString(plan.customer_name);
  }

  if (plan.email !== undefined) {
    updates.email = cleanString(plan.email);
  }

  if (plan.notes !== undefined) {
    updates.notes = cleanString(plan.notes);
  }

  if (cleanString(plan.hair_color_code)) {
    const color = await validateHairColorForAgent(
      supabase,
      cleanString(plan.hair_color_code),
    );

    if (!color) {
      return {
        action: "update_booking",
        performed: false,
        status: "blocked",
        message: `Hair color ${cleanString(plan.hair_color_code)} is not confirmed as available.`,
        rows: [],
      };
    }

    updates.hair_color_code = cleanString(plan.hair_color_code);
  }

  if (cleanString(plan.service_id) || cleanString(plan.service_name)) {
    const service = await resolveServiceForAgent(
      supabase,
      plan.service_id,
      plan.service_name,
    );

    if (!service) {
      return {
        action: "update_booking",
        performed: false,
        status: "blocked",
        message: "The requested replacement service is not an active Faith Hair Style service.",
        rows: [],
      };
    }

    updates.service_id = service.id;

    const duration = Number(service.duration_minutes);
    if (Number.isFinite(duration) && duration > 0) {
      updates.end_time = addMinutesToTime(booking.start_time, duration);
    }
  }

  if (Object.keys(updates).length === 0) {
    return {
      action: "update_booking",
      performed: false,
      status: "needs_input",
      message: "Ask what booking detail the customer wants to change, such as service, hair color, name, email, or notes.",
      missing_fields: ["detail to update"],
      rows: [],
    };
  }

  const { data: updated, error } = await supabase
    .from("bookings")
    .update(updates)
    .eq("id", booking.id)
    .select("*")
    .single();

  if (error || !updated) {
    console.error("AGENT UPDATE BOOKING ERROR:", error);
    return {
      action: "update_booking",
      performed: false,
      status: "error",
      message: "The booking could not be updated right now. Ask the customer to try again in a moment.",
      rows: [],
    };
  }

  return {
    action: "update_booking",
    performed: true,
    status: "completed",
    message: `Booking ${bookingId} was updated successfully.`,
    booking_id: bookingId,
    rows: [await enrichBookingForAgent(supabase, updated)],
  };
}

async function executeAgentAction(
  supabase: any,
  plan: AgentPlan,
  salonClock: ReturnType<typeof getSalonClock>,
): Promise<AgentActionResult> {
  try {
    switch (plan.action) {
      case "find_booking":
        return await findBookingForAgent(supabase, plan);
      case "create_booking":
        return await createBookingForAgent(supabase, plan, salonClock);
      case "cancel_booking":
        return await cancelBookingForAgent(supabase, plan);
      case "reschedule_booking":
        return await rescheduleBookingForAgent(supabase, plan, salonClock);
      case "update_booking":
        return await updateBookingForAgent(supabase, plan);
      default:
        return {
          action: "conversation",
          performed: false,
          status: "not_needed",
          message: "No write action is needed for this request.",
          rows: [],
        };
    }
  } catch (error) {
    console.error("AGENT ACTION ERROR:", error);
    return {
      action: plan.action,
      performed: false,
      status: "error",
      message: "I could not complete that action right now. Ask the customer to try again in a moment.",
      rows: [],
    };
  }
}

async function buildAgentPlan(
  model: ChatOpenAI,
  customerMessage: string,
  history: Record<string, unknown>[],
  customerPreferences: Record<string, unknown>,
  salonClock: ReturnType<typeof getSalonClock>,
  services: Record<string, unknown>[],
  availability: Record<string, unknown>[],
): Promise<AgentPlan> {
  const plannerPrompt = `
You are the private action planner for Faithi, the Faith Hair Style salon agent.
Return ONLY one JSON object. Do not write prose before or after it.

Allowed action values:
- conversation
- find_booking
- create_booking
- cancel_booking
- reschedule_booking
- update_booking

Choose conversation for normal questions, recommendations, prices, colors, pictures, hours, policies, preparation, or availability questions when no booking record should be changed.

Choose create_booking only when the customer clearly wants Faithi to actually submit/create/book an appointment.
For create_booking, all required fields are: exact service, appointment date, appointment time, hair color, full name, 10-digit phone number, and valid email address.
Never claim a new booking is ready if one of those fields is missing.
Choose find_booking when the customer wants to check an existing booking or booking status.
Choose cancel_booking only when the customer clearly wants an existing booking cancelled.
Choose reschedule_booking only when the customer clearly wants an existing booking moved to another date/time.
Choose update_booking when the customer wants an existing booking detail changed without changing date/time, such as service, hair color, name, email, or notes.

Never invent customer identity, phone, email, booking ID, service, date, time, color, or consent.
Use the conversation history to understand short replies like "yes", "10", "Saturday", "1B", or "book it".
If the customer says "why", "why not", "how come", "what do you mean", or "explain that",
treat it as a follow-up to the immediately previous assistant statement. Choose conversation unless
the customer is clearly requesting a database-changing action. The final response must explain the
reason and must not merely repeat the prior answer.
A prior assistant suggestion is NOT customer consent by itself.
For relative dates, convert them using the current salon date when confident; otherwise leave the field empty.
When a value is unknown, omit it from the JSON instead of guessing.

Current salon date/time:
${JSON.stringify(salonClock)}

Known customer preferences:
${JSON.stringify(customerPreferences)}

Active services:
${JSON.stringify(services.map((service) => ({
    id: service.id,
    name: service.name,
    price: service.price,
    duration_minutes: service.duration_minutes,
  })).slice(0, 100))}

Current open availability:
${JSON.stringify(availability.slice(0, 30))}

Recent conversation history:
${JSON.stringify(history.slice(-10))}

Current customer message:
${customerMessage}

JSON fields you may use:
{
  "action": "conversation|find_booking|create_booking|cancel_booking|reschedule_booking|update_booking",
  "customer_name": "",
  "phone": "",
  "email": "",
  "service_id": "",
  "service_name": "",
  "booking_id": "",
  "booking_date": "YYYY-MM-DD or natural date",
  "start_time": "time",
  "new_date": "YYYY-MM-DD or natural date",
  "new_start_time": "time",
  "hair_color_code": "",
  "notes": "",
  "reason": "short internal reason"
}
`;

  try {
    const response = await model.invoke([
      {
        role: "system",
        content: "You are a strict JSON action planner. Output JSON only.",
      },
      {
        role: "user",
        content: plannerPrompt,
      },
    ]);

    const raw = textFromLangChainContent(response.content);
    const parsed = extractFirstJsonObject(raw);
    return normalizeAgentPlan(parsed);
  } catch (error) {
    console.error("AGENT PLAN ERROR:", error);
    return { action: "conversation" };
  }
}

const AgentGraphState = new StateSchema({
  customerMessage: z.string(),
  plan: z.any().optional(),
  actionResult: z.any().optional(),
  reply: z.string().optional(),
});

async function runFaithiLangGraphAgent({
  supabase,
  model,
  customerMessage,
  history,
  customerPreferences,
  salonClock,
  services,
  availability,
  liveSalonContext,
}: {
  supabase: any;
  model: ChatOpenAI;
  customerMessage: string;
  history: Record<string, unknown>[];
  customerPreferences: Record<string, unknown>;
  salonClock: ReturnType<typeof getSalonClock>;
  services: Record<string, unknown>[];
  availability: Record<string, unknown>[];
  liveSalonContext: string;
}) {
  const workflow = new StateGraph(AgentGraphState)
    .addNode(
      "plan",
      async () => ({
        plan: await buildAgentPlan(
          model,
          customerMessage,
          history,
          customerPreferences,
          salonClock,
          services,
          availability,
        ),
      }),
      { retryPolicy: { maxAttempts: 2 } },
    )
    .addNode(
      "execute",
      async (state) => ({
        actionResult: await executeAgentAction(
          supabase,
          normalizeAgentPlan(state.plan),
          salonClock,
        ),
      }),
    )
    .addNode(
      "respond",
      async (state) => {
        const plan = normalizeAgentPlan(state.plan);
        const actionResult = state.actionResult as AgentActionResult | undefined;

        const actionContext = actionResult
          ? `\n\nAGENT ACTION RESULT:\n${JSON.stringify(actionResult)}\n\nIMPORTANT: If performed=true, clearly tell the customer the action was completed. If status=needs_input, ask only the FIRST missing field. If status=blocked, explain the customer-facing reason and offer the best next step. Never claim an action happened unless performed=true.`
          : "\n\nAGENT ACTION RESULT:\nNo database write action was required for this request.";

        const messages = [
          {
            role: "system",
            content: FAITHI_SYSTEM_PROMPT,
          },
          {
            role: "system",
            content: liveSalonContext + actionContext,
          },
          ...history,
          {
            role: "user",
            content: customerMessage,
          },
        ];

        try {
          const response = await model.invoke(messages as any);
          const reply = removeThinking(
            textFromLangChainContent(response.content),
          );

          if (!reply) {
            throw new Error("LangChain returned an empty Faithi response.");
          }

          return {
            reply,
            plan,
            actionResult,
          };
        } catch (responseError) {
          console.error("AGENT RESPONSE ERROR:", responseError);

          // Important: a write action may already have completed. Never lose
          // that fact just because the final natural-language generation failed.
          if (actionResult) {
            return {
              reply: actionResult.message,
              plan,
              actionResult,
            };
          }

          throw responseError;
        }
      },
      { retryPolicy: { maxAttempts: 2 } },
    )
    .addEdge(START, "plan")
    .addEdge("plan", "execute")
    .addEdge("execute", "respond")
    .addEdge("respond", END)
    .compile();

  const result = await workflow.invoke({
    customerMessage,
  });

  return {
    reply: cleanString(result.reply),
    plan: normalizeAgentPlan(result.plan),
    actionResult: result.actionResult as AgentActionResult | undefined,
  };
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
    // CURRENT SALON DATE / TIME
    // ========================================================

    const salonTimeZone =
      Deno.env.get("SALON_TIME_ZONE") ||
      DEFAULT_SALON_TIME_ZONE;

    const salonClock =
      getSalonClock(salonTimeZone);

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
        : body.context?.customer_preferences &&
            typeof body.context.customer_preferences ===
              "object"
          ? body.context.customer_preferences
          : {};

    // ========================================================
    // LOAD LIVE SALON SERVICES
    // ========================================================

    const {
      data: servicesData,
      error: servicesError,
    } = await supabase
      .from("services")
      .select("*")
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
        .select("*")
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
        salonClock.isoDate;

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
    // LOAD HOURS / FAQ / TESTIMONIALS FOR WEBSITE KNOWLEDGE
    // ========================================================

    const loadedHours = await loadOptionalTableRows(
      supabase,
      ["salon_hours", "hours"],
      30,
    );
    const salonHours = loadedHours.rows;

    const loadedFaqs = await loadOptionalTableRows(
      supabase,
      ["faqs", "faq"],
      60,
    );
    const faqs = loadedFaqs.rows;

    const loadedTestimonials = await loadOptionalTableRows(
      supabase,
      ["testimonials"],
      40,
    );
    const testimonials = loadedTestimonials.rows;

    const websiteKnowledge = buildWebsiteKnowledge(
      businessInfo,
      faqs,
      testimonials,
      salonHours,
    );

    // ========================================================
    // LOAD APPOINTMENTS / BOOKINGS
    // ========================================================

    let appointments: any[] = [];
    let appointmentTables: string[] = [];

    try {
      const loaded = await loadAppointmentRows(
        supabase,
        salonClock.isoDate,
      );

      appointments = loaded.appointments;
      appointmentTables = loaded.loadedTables;
    } catch (error) {
      console.error(
        "Appointments error:",
        error,
      );
    }

    const todayAppointments = appointments.filter(
      (item) => item.date === salonClock.isoDate,
    );

    // Customer-facing AI receives schedule details without customer identity.
    // Verified customer-specific booking lookup is handled by the agent actions.
    const publicAppointments = appointments.map((item) => ({
      source_table: item.source_table,
      id: item.id,
      date: item.date,
      time: item.time,
      service: item.service,
      status: item.status,
      braid_size: item.braid_size,
      braid_length: item.braid_length,
      color: item.color,
    }));

    const publicTodayAppointments = publicAppointments.filter(
      (item) => item.date === salonClock.isoDate,
    );

    // ========================================================
    // LIVE CONTEXT FOR QWEN
    // ========================================================

    const liveSalonContext = `
CURRENT CUSTOMER PREFERENCES:

${JSON.stringify(
  customerPreferences,
)}

CURRENT SALON DATE AND TIME:

${JSON.stringify(
  salonClock,
)}

TODAY'S APPOINTMENTS:

${JSON.stringify(
  publicTodayAppointments,
)}

CURRENT/FUTURE APPOINTMENTS:

${JSON.stringify(
  publicAppointments,
)}

APPOINTMENT TABLES FOUND:

${JSON.stringify(
  appointmentTables,
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

WEBSITE KNOWLEDGE (FAITH HAIR STYLE OWN WEBSITE / APP):

${JSON.stringify(
  websiteKnowledge,
)}

FAQ SOURCE TABLE:

${JSON.stringify(loadedFaqs.table)}

TESTIMONIAL SOURCE TABLE:

${JSON.stringify(loadedTestimonials.table)}

HOURS SOURCE TABLE:

${JSON.stringify(loadedHours.table)}

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

CURRENT SALON DATE AND TIME is authoritative for date/time questions.

When appointment data is present, use it instead of saying you cannot
access appointments or the appointment page.

When the customer refers to Faith Hair Style's homepage, website, platform,
app, gallery, booking page, or social page, use WEBSITE KNOWLEDGE plus the
live salon tables. Do not call the salon's own website an inaccessible
external page.

Public business contact details from WEBSITE KNOWLEDGE may be shared.
Never expose another customer's phone number, email address, or other private
booking/contact details.

Do not invent missing salon facts.

If information is unavailable, tell the customer it needs confirmation.
`;

    // ========================================================
    // LANGCHAIN + LANGGRAPH AGENT
    // ========================================================

    let reply = "";
    let agentPlan: AgentPlan = {
      action: "conversation",
    };
    let agentActionResult: AgentActionResult | undefined;
    let agentEngine = "langgraph";

    // Resolve references to Faith Hair Style's own homepage/app before the
    // model runs. This fixes replies such as "I can't access external pages"
    // when the customer is actually referring to this salon's own website.
    const deterministicWebsiteReply = buildOwnWebsiteReferenceReply({
      customerMessage,
      history,
      websiteKnowledge,
    });

    if (deterministicWebsiteReply) {
      reply = deterministicWebsiteReply;
      agentEngine = "deterministic_website_context";
    }

    // Handle short explanatory follow-ups such as "why" deterministically
    // when the previous statement was about appointment availability.
    // This prevents Faithi from simply repeating the same availability answer.
    const deterministicWhyReply = !reply
      ? await buildAvailabilityWhyReply({
          supabase,
          customerMessage,
          history,
          salonClock,
          salonHours,
          appointments,
          availability,
        })
      : "";

    if (deterministicWhyReply) {
      reply = deterministicWhyReply;
      agentEngine = "deterministic_followup";
    }

    // New-booking collection is intentionally deterministic. This prevents
    // a model-planner failure from skipping required customer information.
    // LangGraph/LangChain remain active for the rest of Faithi's agent flow.
    if (!reply) {
      const deterministicBookingPlan = buildDeterministicCreateBookingPlan({
        customerMessage,
        history,
        customerPreferences,
        salonClock,
        services,
        hairColors,
      });

      if (deterministicBookingPlan) {
        agentPlan = deterministicBookingPlan;
        agentActionResult = await executeAgentAction(
          supabase,
          agentPlan,
          salonClock,
        );
        reply = buildDeterministicBookingReply(
          agentActionResult,
          agentPlan,
        );
        agentEngine = "deterministic_booking";
      }
    }

    if (!reply) {
      try {
        const langChainModel = new ChatOpenAI({
        model: MODEL,
        apiKey: HF_TOKEN,
        temperature: 0.3,
        maxRetries: 1,
        configuration: {
          baseURL: HF_BASE_URL,
        },
      });

      const agentResult = await runFaithiLangGraphAgent({
        supabase,
        model: langChainModel,
        customerMessage,
        history,
        customerPreferences,
        salonClock,
        services,
        availability,
        liveSalonContext,
      });

      reply = removeThinking(
        cleanString(agentResult.reply),
      );

      agentPlan = agentResult.plan;
      agentActionResult = agentResult.actionResult;
    } catch (agentError) {
      console.error(
        "LANGGRAPH AGENT ERROR — USING LEGACY FALLBACK:",
        agentError,
      );

        agentEngine = "legacy_fallback";
      }
    }

    // ========================================================
    // LEGACY HUGGING FACE FALLBACK
    // Preserves the original behavior if LangChain/LangGraph
    // is temporarily unavailable.
    // ========================================================

    if (!reply) {
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

      const hfData =
        await hfResponse.json();

      reply =
        removeThinking(
          cleanString(
            hfData?.choices?.[0]
              ?.message?.content,
          ),
        );
    }

    if (!reply) {
      throw new Error(
        "Faithi returned an empty response.",
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
      agentActionResult?.rows &&
      agentActionResult.rows.length > 0
    ) {
      structuredRows =
        agentActionResult.rows;
    }

    if (
      structuredRows.length === 0 &&
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

    // If the user is asking about appointments and no service rows
    // were selected, return privacy-safe appointment rows to the frontend.
    if (
      structuredRows.length === 0 &&
      containsAny(customerMessage, [
        "appointment",
        "appointments",
        "booking",
        "bookings",
        "schedule",
        "today",
        "tomorrow",
      ])
    ) {
      structuredRows = appointments
        .slice(0, 10)
        .map((item) => ({
          source_table: item.source_table,
          id: item.id,
          date: item.date,
          time: item.time,
          service: item.service,
          status: item.status,
          // Privacy-safe general schedule row. Customer identity is intentionally omitted.
          braid_size: item.braid_size,
          braid_length: item.braid_length,
          color: item.color,
        }));
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

          agent: {
            framework:
              "langchain+langgraph",

            engine:
              agentEngine,

            planned_action:
              agentPlan.action,

            performed:
              agentActionResult?.performed ?? false,

            action_status:
              agentActionResult?.status ?? "not_needed",

            booking_id:
              agentActionResult?.booking_id ?? null,

            missing_fields:
              agentActionResult?.missing_fields ?? [],

            required_booking_fields:
              agentPlan.action === "create_booking"
                ? [...REQUIRED_BOOKING_FIELDS]
                : [],

            collected_booking_fields:
              agentPlan.action === "create_booking"
                ? bookingCollectedFields(agentPlan)
                : [],
          },

          salon_data: {
            services_loaded:
              services.length,

            colors_loaded:
              hairColors.length,

            availability_loaded:
              availability.length,

            appointments_loaded:
              appointments.length,

            business_info_loaded:
              businessInfo.length,

            policies_loaded:
              policies.length,

            hours_loaded:
              salonHours.length,

            faqs_loaded:
              faqs.length,

            testimonials_loaded:
              testimonials.length,

            website_knowledge_enabled:
              true,

            today_appointments_loaded:
              todayAppointments.length,

            appointment_tables:
              appointmentTables,

            current_date:
              salonClock.isoDate,

            current_time:
              salonClock.displayTime,

            time_zone:
              salonClock.timeZone,
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