// supabase/functions/chat-assistant/index.ts
// FaithCo database-powered assistant
// No OpenAI key or external AI service required.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type SalonService = {
  id?: string;
  name?: string;
  description?: string;
  category?: string;
  price?: string | number;
  duration_minutes?: string | number;
  image_url?: string;
  is_active?: boolean;
};

type HairColor = {
  id?: string;
  code?: string;
  name?: string;
  description?: string;
  is_active?: boolean;
};

type ChatMessage = {
  role?: string;
  content?: string;
};

type RequestBody = {
  message?: string;
  services?: SalonService[];
  hair_colors?: HairColor[];
  chatHistory?: ChatMessage[];
};

type AssistantResponse = {
  reply: string;
  intent:
    | "greeting"
    | "services"
    | "price"
    | "duration"
    | "color"
    | "recommendation"
    | "booking"
    | "help"
    | "unknown";
  service_name: string | null;
  should_open_booking: boolean;
};

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function cleanText(value: unknown): string {
  if (typeof value !== "string") {
    return "";
  }

  return value.trim();
}

function normalize(value: unknown): string {
  return cleanText(value)
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function formatPrice(value: unknown): string {
  if (value === null || value === undefined || value === "") {
    return "Price unavailable";
  }

  const numericValue = Number(value);

  if (Number.isFinite(numericValue)) {
    const decimals = Number.isInteger(numericValue) ? 0 : 2;
    return `$${numericValue.toFixed(decimals)}`;
  }

  const text = cleanText(value);

  if (!text) {
    return "Price unavailable";
  }

  return text.startsWith("$") ? text : `$${text}`;
}

function formatDuration(value: unknown): string {
  const minutes = Number(value);

  if (!Number.isFinite(minutes) || minutes <= 0) {
    return "Duration unavailable";
  }

  if (minutes < 60) {
    return `${Math.round(minutes)} minutes`;
  }

  const hours = Math.floor(minutes / 60);
  const remainingMinutes = Math.round(minutes % 60);

  if (remainingMinutes === 0) {
    return `${hours} ${hours === 1 ? "hour" : "hours"}`;
  }

  return `${hours} ${
    hours === 1 ? "hour" : "hours"
  } ${remainingMinutes} minutes`;
}

function sanitizeServices(value: unknown): SalonService[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((item) => item && typeof item === "object")
    .map((item) => {
      const service = item as SalonService;

      return {
        id: cleanText(service.id),
        name: cleanText(service.name),
        description: cleanText(service.description),
        category: cleanText(service.category),
        price: service.price ?? "",
        duration_minutes: service.duration_minutes ?? "",
        image_url: cleanText(service.image_url),
        is_active: service.is_active !== false,
      };
    })
    .filter((service) => service.name && service.is_active !== false);
}

function sanitizeColors(value: unknown): HairColor[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .filter((item) => item && typeof item === "object")
    .map((item) => {
      const color = item as HairColor;

      return {
        id: cleanText(color.id),
        code: cleanText(color.code),
        name: cleanText(color.name),
        description: cleanText(color.description),
        is_active: color.is_active !== false,
      };
    })
    .filter(
      (color) =>
        (color.code || color.name) &&
        color.is_active !== false,
    );
}

function hasAny(text: string, phrases: string[]): boolean {
  return phrases.some((phrase) => text.includes(phrase));
}

function isGreeting(message: string): boolean {
  const text = normalize(message);

  return [
    "hello",
    "hi",
    "hey",
    "good morning",
    "good afternoon",
    "good evening",
    "how are you",
  ].some(
    (phrase) =>
      text === phrase ||
      text.startsWith(`${phrase} `),
  );
}

function isBookingRequest(message: string): boolean {
  const text = normalize(message);

  return hasAny(text, [
    "book",
    "booking",
    "appointment",
    "schedule",
    "reserve",
    "reservation",
    "book it",
    "book this",
    "make an appointment",
  ]);
}

function isPriceRequest(message: string): boolean {
  const text = normalize(message);

  return hasAny(text, [
    "price",
    "prices",
    "cost",
    "costs",
    "how much",
    "charge",
    "charges",
    "rate",
    "rates",
  ]);
}

function isDurationRequest(message: string): boolean {
  const text = normalize(message);

  return hasAny(text, [
    "how long",
    "duration",
    "how many hours",
    "how many minutes",
    "time does it take",
    "take to do",
  ]);
}

function isServiceListRequest(message: string): boolean {
  const text = normalize(message);

  return hasAny(text, [
    "what services",
    "which services",
    "services do you offer",
    "hairstyles do you offer",
    "show services",
    "show hairstyles",
    "list services",
    "list hairstyles",
    "what do you offer",
    "available styles",
    "available services",
  ]);
}

function isColorRequest(message: string): boolean {
  const text = normalize(message);

  return hasAny(text, [
    "hair color",
    "hair colour",
    "color",
    "colour",
    "shade",
    "what color is",
    "what colour is",
  ]);
}

function isRecommendationRequest(message: string): boolean {
  const text = normalize(message);

  return hasAny(text, [
    "recommend",
    "recommendation",
    "suggest",
    "best hairstyle",
    "best style",
    "what should i get",
    "which style",
    "help me choose",
    "under $",
    "budget",
    "wedding",
    "birthday",
    "vacation",
    "school",
    "work",
    "short hair",
    "long hair",
    "kids",
    "child",
    "daughter",
  ]);
}

function findServiceFromText(
  message: string,
  services: SalonService[],
): SalonService | null {
  const text = normalize(message);

  if (!text) {
    return null;
  }

  const directMatches = services
    .filter((service) => {
      const name = normalize(service.name);

      return name && text.includes(name);
    })
    .sort(
      (a, b) =>
        normalize(b.name).length -
        normalize(a.name).length,
    );

  if (directMatches.isNotEmpty) {
    return directMatches.first;
  }

  const aliases: Record<string, string[]> = {
    knotless: ["knotless"],
    fulani: ["fulani"],
    lemonade: ["lemonade"],
    twist: ["twist", "twists"],
    loc: ["loc", "locs"],
    cornrow: ["cornrow", "cornrows"],
    kids: ["kids", "kid", "child", "children", "daughter"],
    braid: ["braid", "braids", "braiding"],
  };

  for (const entry of Object.entries(aliases)) {
    const keyword = entry[0];
    const words = entry[1];

    if (!words.some((word) => text.includes(word))) {
      continue;
    }

    const matchingService = services.find((service) => {
      const searchable = normalize(
        `${service.name ?? ""} ${service.category ?? ""}`,
      );

      return searchable.includes(keyword);
    });

    if (matchingService) {
      return matchingService;
    }
  }

  const messageWords = text
    .split(" ")
    .filter((word) => word.length >= 4);

  let bestService: SalonService | null = null;
  let bestScore = 0;

  for (const service of services) {
    const searchable = normalize(
      `${service.name ?? ""} ${service.category ?? ""} ${
        service.description ?? ""
      }`,
    );

    let score = 0;

    for (const word of messageWords) {
      if (searchable.includes(word)) {
        score += word.length;
      }
    }

    if (score > bestScore) {
      bestScore = score;
      bestService = service;
    }
  }

  return bestScore >= 5 ? bestService : null;
}

function findServiceFromHistory(
  history: ChatMessage[],
  services: SalonService[],
): SalonService | null {
  for (let index = history.length - 1; index >= 0; index--) {
    const content = cleanText(history[index]?.content);

    if (!content) {
      continue;
    }

    const service = findServiceFromText(content, services);

    if (service) {
      return service;
    }
  }

  return null;
}

function findHairColor(
  message: string,
  colors: HairColor[],
): HairColor | null {
  const text = normalize(message);
  const words = text.split(" ");

  for (const color of colors) {
    const code = normalize(color.code);
    const name = normalize(color.name);

    if (
      (code && words.includes(code)) ||
      (name && text.includes(name))
    ) {
      return color;
    }
  }

  return null;
}

function extractBudget(message: string): number | null {
  const text = message.toLowerCase();

  const patterns = [
    /under\s*\$?\s*(\d+(?:\.\d+)?)/i,
    /below\s*\$?\s*(\d+(?:\.\d+)?)/i,
    /less than\s*\$?\s*(\d+(?:\.\d+)?)/i,
    /budget(?:\s+is|\s+of)?\s*\$?\s*(\d+(?:\.\d+)?)/i,
    /\$(\d+(?:\.\d+)?)/,
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);

    if (match?.[1]) {
      const amount = Number(match[1]);

      if (Number.isFinite(amount)) {
        return amount;
      }
    }
  }

  return null;
}

function findRecommendedServices(
  message: string,
  services: SalonService[],
): SalonService[] {
  const text = normalize(message);
  const budget = extractBudget(message);

  let results = [...services];

  if (budget !== null) {
    results = results.filter((service) => {
      const price = Number(service.price);

      return Number.isFinite(price) && price <= budget;
    });
  }

  const keywordGroups: string[][] = [];

  if (
    hasAny(text, [
      "kids",
      "kid",
      "child",
      "children",
      "daughter",
      "school",
    ])
  ) {
    keywordGroups.push([
      "kid",
      "kids",
      "child",
      "children",
      "school",
    ]);
  }

  if (
    hasAny(text, [
      "wedding",
      "birthday",
      "party",
      "event",
      "special occasion",
    ])
  ) {
    keywordGroups.push([
      "fulani",
      "lemonade",
      "knotless",
      "braid",
      "style",
    ]);
  }

  if (
    hasAny(text, [
      "protective",
      "long lasting",
      "last long",
      "vacation",
    ])
  ) {
    keywordGroups.push([
      "knotless",
      "braid",
      "twist",
      "protective",
    ]);
  }

  if (hasAny(text, ["short hair", "short natural hair"])) {
    keywordGroups.push([
      "cornrow",
      "twist",
      "braid",
      "natural",
    ]);
  }

  if (keywordGroups.length > 0) {
    const filtered = results.filter((service) => {
      const searchable = normalize(
        `${service.name ?? ""} ${service.category ?? ""} ${
          service.description ?? ""
        }`,
      );

      return keywordGroups.some((group) =>
        group.some((keyword) =>
          searchable.includes(keyword)
        )
      );
    });

    if (filtered.length > 0) {
      results = filtered;
    }
  }

  return results
    .sort((a, b) => {
      const priceA = Number(a.price);
      const priceB = Number(b.price);

      if (
        Number.isFinite(priceA) &&
        Number.isFinite(priceB)
      ) {
        return priceA - priceB;
      }

      return cleanText(a.name).localeCompare(
        cleanText(b.name),
      );
    })
    .slice(0, 3);
}

function buildServiceDetails(service: SalonService): string {
  const lines = [
    service.name ?? "Service",
    `Price: ${formatPrice(service.price)}`,
    `Estimated duration: ${formatDuration(
      service.duration_minutes,
    )}`,
  ];

  if (service.description) {
    lines.push(service.description);
  }

  return lines.join("\n");
}

function buildServiceList(
  services: SalonService[],
): string {
  if (services.length === 0) {
    return "I could not find any active services right now.";
  }

  const grouped = new Map<string, SalonService[]>();

  for (const service of services) {
    const category =
      cleanText(service.category) || "Other services";

    if (!grouped.has(category)) {
      grouped.set(category, []);
    }

    grouped.get(category)?.push(service);
  }

  const sections: string[] = [];

  for (const [category, categoryServices] of grouped) {
    const serviceLines = categoryServices
      .map(
        (service) =>
          `• ${service.name} — ${formatPrice(
            service.price,
          )} — ${formatDuration(
            service.duration_minutes,
          )}`,
      )
      .join("\n");

    sections.push(`${category}\n${serviceLines}`);
  }

  return (
    `Here are our available services:\n\n` +
    sections.join("\n\n") +
    "\n\nTell me the name of a service for more details."
  );
}

function buildColorList(colors: HairColor[]): string {
  if (colors.length === 0) {
    return "I could not find any available hair colors right now.";
  }

  const list = colors
    .slice(0, 20)
    .map((color) => {
      const code = color.code
        ? `Color ${color.code}`
        : "Color";

      const name = color.name || "Unnamed shade";

      return `• ${code}: ${name}`;
    })
    .join("\n");

  return (
    `Here are the available hair colors:\n\n${list}\n\n` +
    "Tell me the color code for more information."
  );
}

function buildRecommendationResponse(
  message: string,
  services: SalonService[],
): AssistantResponse {
  const recommendations = findRecommendedServices(
    message,
    services,
  );

  const budget = extractBudget(message);

  if (recommendations.length === 0) {
    if (budget !== null) {
      return {
        reply:
          `I could not find an available service at or below $${budget}. ` +
          "Please ask about another budget or view all available services.",
        intent: "recommendation",
        service_name: null,
        should_open_booking: false,
      };
    }

    return {
      reply:
        "I need a little more information to recommend the best style. " +
        "What is your budget, occasion, or preferred hairstyle?",
      intent: "recommendation",
      service_name: null,
      should_open_booking: false,
    };
  }

  const lines = recommendations.map((service, index) => {
    return (
      `${index + 1}. ${service.name}\n` +
      `   ${formatPrice(service.price)} • ${formatDuration(
        service.duration_minutes,
      )}` +
      (service.description
        ? `\n   ${service.description}`
        : "")
    );
  });

  return {
    reply:
      `Based on what you described, these may be good options:\n\n` +
      lines.join("\n\n") +
      "\n\nWhich one would you like to learn more about or book?",
    intent: "recommendation",
    service_name:
      recommendations.length === 1
        ? recommendations[0].name ?? null
        : null,
    should_open_booking: false,
  };
}

function createResponse(
  message: string,
  services: SalonService[],
  colors: HairColor[],
  history: ChatMessage[],
): AssistantResponse {
  const serviceFromMessage = findServiceFromText(
    message,
    services,
  );

  const serviceFromHistory = findServiceFromHistory(
    history,
    services,
  );

  const selectedService =
    serviceFromMessage ?? serviceFromHistory;

  const color = findHairColor(message, colors);

  if (isGreeting(message)) {
    return {
      reply:
        "Hello! Welcome to FaithCo. I can help you view hairstyles, check prices, understand hair colors, get recommendations, or book an appointment.",
      intent: "greeting",
      service_name: null,
      should_open_booking: false,
    };
  }

  if (isBookingRequest(message)) {
    if (!selectedService) {
      return {
        reply:
          "I would be happy to help you book. Which hairstyle or service would you like?",
        intent: "booking",
        service_name: null,
        should_open_booking: false,
      };
    }

    return {
      reply:
        `Great choice!\n\n${buildServiceDetails(
          selectedService,
        )}\n\nI will open the booking page for you now.`,
      intent: "booking",
      service_name: selectedService.name ?? null,
      should_open_booking: true,
    };
  }

  if (isServiceListRequest(message)) {
    return {
      reply: buildServiceList(services),
      intent: "services",
      service_name: null,
      should_open_booking: false,
    };
  }

  if (isColorRequest(message)) {
    if (color) {
      const description = color.description
        ? `\n\n${color.description}`
        : "";

      return {
        reply:
          `Hair color ${color.code ?? ""} is ${
            color.name ?? "an available shade"
          }.${description}\n\nWould you like help choosing a hairstyle for this color?`,
        intent: "color",
        service_name: null,
        should_open_booking: false,
      };
    }

    return {
      reply: buildColorList(colors),
      intent: "color",
      service_name: null,
      should_open_booking: false,
    };
  }

  if (selectedService && isPriceRequest(message)) {
    return {
      reply:
        `${selectedService.name} costs ${formatPrice(
          selectedService.price,
        )} and normally takes ${formatDuration(
          selectedService.duration_minutes,
        )}.\n\nWould you like to book this service?`,
      intent: "price",
      service_name: selectedService.name ?? null,
      should_open_booking: false,
    };
  }

  if (selectedService && isDurationRequest(message)) {
    return {
      reply:
        `${selectedService.name} normally takes about ${formatDuration(
          selectedService.duration_minutes,
        )}.\n\nThe exact time can depend on hair length, size, and style details.`,
      intent: "duration",
      service_name: selectedService.name ?? null,
      should_open_booking: false,
    };
  }

  if (selectedService) {
    return {
      reply:
        `${buildServiceDetails(
          selectedService,
        )}\n\nWould you like to book this service?`,
      intent: "services",
      service_name: selectedService.name ?? null,
      should_open_booking: false,
    };
  }

  if (isRecommendationRequest(message)) {
    return buildRecommendationResponse(
      message,
      services,
    );
  }

  if (
    hasAny(normalize(message), [
      "help",
      "what can you do",
      "how can you help",
    ])
  ) {
    return {
      reply:
        "I can help you:\n\n" +
        "• View available hairstyles\n" +
        "• Check prices and durations\n" +
        "• Explain hair color codes\n" +
        "• Recommend styles based on your budget or occasion\n" +
        "• Open the booking page\n\n" +
        "Try asking: “How much are knotless braids?”",
      intent: "help",
      service_name: null,
      should_open_booking: false,
    };
  }

  return {
    reply:
      "I can help with FaithCo hairstyles, prices, durations, hair colors, recommendations, and bookings. " +
      "Please ask about a specific hairstyle, or say “show me all services.”",
    intent: "unknown",
    service_name: null,
    should_open_booking: false,
  };
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  if (request.method !== "POST") {
    return jsonResponse(
      {
        error: "Method not allowed.",
      },
      405,
    );
  }

  try {
    let body: RequestBody;

    try {
      body = await request.json() as RequestBody;
    } catch {
      return jsonResponse(
        {
          error: "Invalid JSON request.",
          reply: "Please send a valid message.",
        },
        400,
      );
    }

    const message = cleanText(body.message).slice(
      0,
      3000,
    );

    if (!message) {
      return jsonResponse(
        {
          error: "Message is required.",
          reply: "Please enter a question.",
        },
        400,
      );
    }

    const services = sanitizeServices(body.services);
    const colors = sanitizeColors(body.hair_colors);

    const history = Array.isArray(body.chatHistory)
      ? body.chatHistory
          .filter(
            (item) =>
              item &&
              typeof item === "object" &&
              cleanText(item.content),
          )
          .slice(-12)
      : [];

    const result = createResponse(
      message,
      services,
      colors,
      history,
    );

    return jsonResponse(result);
  } catch (error) {
    console.error(
      "FaithCo assistant error:",
      error,
    );

    return jsonResponse(
      {
        error: "Unexpected server error.",
        reply:
          "I’m sorry, I could not process your request. Please try again.",
      },
      500,
    );
  }
});