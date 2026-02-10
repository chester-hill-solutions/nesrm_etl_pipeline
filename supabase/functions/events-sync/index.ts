import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { DOMParser } from "https://deno.land/x/deno_dom@v0.1.45/deno-dom-wasm.ts";

const OLP_EVENTS_URL = "https://ontarioliberal.ca/events/";
const OLP_HOSTNAME = new URL(OLP_EVENTS_URL).hostname;
const OLP_UTM_PARAMS = {
  utm_source: "data.teamnate.ca",
  utm_medium: "referral",
  utm_campaign: "events-hub",
};
const MAX_OLP_EVENTS = 40;

type ListingSummary = {
  title: string;
  entryDate: string;
  timeRange: string | null;
  type: string | null;
  excerpt: string | null;
  detailUrl: string | null;
};

type EventDetail = {
  url: string | null;
  description: string | null;
  startDate: string | null;
  endDate: string | null;
  locationName: string | null;
  locationAddress: string | null;
  cost: string | null;
  isTicketed: boolean;
  keywords: string[] | undefined;
};

type Event = {
  id: string;
  slug: string;
  name: string;
  description: string;
  start_date: string;
  end_date: string;
  location_name: string | null;
  location_address: string | null;
  category: string | null;
  source: "olp";
  is_external: boolean;
  external_url: string | null;
  is_ticketed: boolean;
  cost: string | null;
  tags: string[] | null;
  status: "active" | "archived";
  last_synced_at: string | null;
  sync_error: string | null;
};

type EventSyncResult = {
  success: boolean;
  added: number;
  updated: number;
  archived: number;
  errors: number;
  errorMessages: string[];
  syncedAt: string;
};

function isAgmEvent(event: {
  name?: string;
  title?: string;
  category?: string | null;
  type?: string | null;
  tags?: string[] | null;
}): boolean {
  const title = event.name?.toLowerCase() ?? event.title?.toLowerCase() ?? "";
  const category = event.category?.toLowerCase() ?? event.type?.toLowerCase() ?? "";
  const tags = event.tags ?? [];

  const agmWordPattern = /\bagm\b/i;
  const annualGeneralMeetingPattern = /\bannual\s+general\s+meeting\b/i;

  if (agmWordPattern.test(title) || annualGeneralMeetingPattern.test(title)) {
    return true;
  }

  if (category && (agmWordPattern.test(category) || annualGeneralMeetingPattern.test(category))) {
    return true;
  }

  if (
    tags.length > 0 &&
    tags.some((tag) => {
      const tagLower = tag.toLowerCase();
      return agmWordPattern.test(tagLower) || annualGeneralMeetingPattern.test(tagLower);
    })
  ) {
    return true;
  }

  return false;
}

function extractListingSummary(anchor: Element): ListingSummary | null {
  const wrapper = anchor.querySelector(".event-wrapper");
  if (!wrapper) return null;

  const title = wrapper.querySelector("h2")?.textContent?.trim();
  if (!title) return null;

  const entryDate =
    wrapper.querySelector(".entry-date")?.textContent?.replace(/\s+/g, " ").trim() ?? "";
  const timeRange =
    wrapper.querySelector(".time")?.textContent?.replace(/\s+/g, " ").trim() ?? null;
  const type = wrapper.querySelector(".type")?.textContent?.trim() ?? null;
  const excerpt = wrapper.querySelector(".excerpt")?.textContent?.trim() ?? null;
  const detailUrl = anchor.getAttribute("href") ?? null;

  return {
    title,
    entryDate,
    timeRange,
    type,
    excerpt,
    detailUrl,
  };
}

function extractLocationFromHtml(document: Document): {
  locationName: string | null;
  locationAddress: string | null;
} {
  let locationElement = document.querySelector(".location");

  if (!locationElement) {
    locationElement =
      (document.querySelector('[class*="location"]') as Element | null) ??
      (document.querySelector('[class*="venue"]') as Element | null) ??
      null;
  }

  if (!locationElement) {
    return { locationName: null, locationAddress: null };
  }

  const addressSpan = locationElement.querySelector("span");
  const fullText = locationElement.textContent?.trim() || "";
  const addressText = addressSpan?.textContent?.trim() || "";

  let locationName: string | null = fullText;
  if (addressText) {
    if (fullText.includes(addressText)) {
      locationName = fullText.replace(addressText, "").trim();
    } else {
      const normalizedAddress = addressText.replace(/\s+/g, " ");
      const normalizedFull = fullText.replace(/\s+/g, " ");
      if (normalizedFull.includes(normalizedAddress)) {
        locationName = normalizedFull.replace(normalizedAddress, "").trim();
      } else {
        locationName = fullText;
      }
    }
  }

  if (locationName) {
    const cleaned = locationName.replace(/\s+/g, " ").trim();
    locationName = cleaned || null;
  } else {
    locationName = null;
  }
  const locationAddress = addressText || null;

  if (
    locationAddress?.toLowerCase() === "virtual" ||
    locationName?.toLowerCase().includes("zoom")
  ) {
    return { locationName: locationName || "Virtual", locationAddress: null };
  }

  return { locationName, locationAddress };
}

async function fetchOlpEventDetail(url: string): Promise<EventDetail | null> {
  try {
    const response = await fetch(url, {
      headers: { Accept: "text/html", "User-Agent": "data.teamnate.ca/edge-function" },
    });

    if (!response.ok) {
      const body = await response.text().catch(() => "");
      throw new Error(
        `OLP event detail error ${response.status} for ${url}: ${body || response.statusText}`
      );
    }

    const html = await response.text();
    const document = new DOMParser().parseFromString(html, "text/html");
    if (!document) {
      throw new Error("Failed to parse HTML");
    }

    const htmlLocation = extractLocationFromHtml(document);

    const scripts = Array.from(document.querySelectorAll('script[type="application/ld+json"]'));
    let jsonLdLocationName: string | null = null;
    let jsonLdLocationAddress: string | null = null;
    let jsonLdStartDate: string | null = null;
    let jsonLdEndDate: string | null = null;
    let jsonLdDescription: string | null = null;
    let jsonLdUrl: string | null = null;
    let jsonLdCost: string | null = null;
    let jsonLdIsTicketed = false;
    let jsonLdKeywords: string[] | undefined = undefined;

    for (const script of scripts) {
      const raw = script.textContent?.trim();
      if (!raw) continue;

      let parsed;
      try {
        parsed = JSON.parse(raw);
      } catch {
        continue;
      }

      const eventNode = findEventNode(parsed);
      if (!eventNode) {
        continue;
      }

      const offers = Array.isArray(eventNode.offers) ? eventNode.offers[0] : eventNode.offers;
      const address =
        typeof eventNode.location?.address === "string"
          ? eventNode.location.address
          : [
              eventNode.location?.address?.streetAddress,
              eventNode.location?.address?.addressLocality,
              eventNode.location?.address?.addressRegion,
              eventNode.location?.address?.postalCode,
            ]
              .filter(Boolean)
              .join(", ");

      jsonLdLocationName = eventNode.location?.name ?? null;
      jsonLdLocationAddress = address || null;
      jsonLdStartDate = eventNode.startDate ?? null;
      jsonLdEndDate = eventNode.endDate ?? null;
      jsonLdDescription = eventNode.description ?? null;
      jsonLdUrl = eventNode.url ?? null;
      jsonLdCost =
        typeof offers?.price === "number"
          ? `${offers.priceCurrency ?? "CAD"} ${offers.price}`
          : (offers?.price ??
            (typeof offers?.priceSpecification?.price === "number"
              ? `${offers.priceSpecification.priceCurrency ?? "CAD"} ${offers.priceSpecification.price}`
              : null));
      jsonLdIsTicketed = Boolean(offers?.price || offers?.priceSpecification?.price);
      jsonLdKeywords = normalizeKeywords(eventNode.keywords);
      break;
    }

    const locationName = jsonLdLocationName ?? htmlLocation.locationName;
    const locationAddress = jsonLdLocationAddress ?? htmlLocation.locationAddress;

    return {
      url: jsonLdUrl ?? url,
      description: jsonLdDescription ?? null,
      startDate: jsonLdStartDate ?? null,
      endDate: jsonLdEndDate ?? null,
      locationName,
      locationAddress,
      cost: jsonLdCost,
      isTicketed: jsonLdIsTicketed,
      keywords: jsonLdKeywords,
    };
  } catch (error) {
    console.error("Error fetching OLP event detail:", error);
    return null;
  }
}

type EventNode = {
  "@type"?: string;
  url?: string;
  description?: string | null;
  startDate?: string | null;
  endDate?: string | null;
  location?: {
    name?: string;
    address?:
      | string
      | {
          streetAddress?: string;
          addressLocality?: string;
          addressRegion?: string;
          postalCode?: string;
        };
  };
  offers?:
    | Array<{
        price?: number;
        priceCurrency?: string;
        priceSpecification?: {
          price?: number;
          priceCurrency?: string;
        };
      }>
    | {
        price?: number;
        priceCurrency?: string;
        priceSpecification?: {
          price?: number;
          priceCurrency?: string;
        };
      };
  keywords?: string | string[];
  [key: string]: unknown;
};

function findEventNode(data: unknown): EventNode | null {
  if (!data) return null;
  if (Array.isArray(data)) {
    for (const entry of data) {
      const node = findEventNode(entry);
      if (node) return node;
    }
    return null;
  }

  if (typeof data === "object") {
    const maybeEvent = data as Record<string, unknown>;
    const type = maybeEvent["@type"];
    if (typeof type === "string" && type.toLowerCase().includes("event")) {
      return maybeEvent as EventNode;
    }
    if (
      Array.isArray(type) &&
      type.some((value) => typeof value === "string" && value.toLowerCase().includes("event"))
    ) {
      return maybeEvent;
    }
    for (const value of Object.values(maybeEvent)) {
      const node = findEventNode(value);
      if (node) return node;
    }
  }

  return null;
}

function normalizeKeywords(keywords: unknown): string[] | undefined {
  if (!keywords) return undefined;
  if (Array.isArray(keywords)) {
    return keywords
      .flatMap((value) => (typeof value === "string" ? value.split(",") : []))
      .map((value) => value.trim());
  }
  if (typeof keywords === "string") {
    return keywords
      .split(",")
      .map((value) => value.trim())
      .filter(Boolean);
  }
  return undefined;
}

function withOlpUtmParams(rawUrl: string | null): string | null {
  if (!rawUrl) return null;
  try {
    const resolved = new URL(rawUrl, OLP_EVENTS_URL);
    if (!resolved.hostname.endsWith(OLP_HOSTNAME)) {
      return resolved.toString();
    }
    for (const [key, value] of Object.entries(OLP_UTM_PARAMS)) {
      resolved.searchParams.set(key, value);
    }
    return resolved.toString();
  } catch {
    return rawUrl;
  }
}

function getEasternOffset(dateString: string): string {
  const testDate = new Date(`${dateString} 12:00:00`);
  if (Number.isNaN(testDate.getTime())) {
    return "-0500";
  }
  const month = testDate.getUTCMonth();
  const isDst = month >= 2 && month <= 10;
  return isDst ? "-0400" : "-0500";
}

function buildIso(
  dateText: string,
  timeRange: string | null,
  position: "start" | "end"
): string | null {
  const cleanedDate = dateText.replace(/^[A-Za-zÀ-ÿ]+,\s*/, "").trim();
  if (!cleanedDate) {
    return null;
  }

  if (!timeRange) {
    if (position === "start") {
      const fallbackTime = "6:00 PM";
      const offset = getEasternOffset(cleanedDate);
      const parseTarget = `${cleanedDate} ${fallbackTime} GMT${offset}`;
      const parsed = new Date(parseTarget);
      return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
    }
    return null;
  }

  const timeSegments = timeRange
    .split(/—|–|-/)
    .map((segment) => segment.trim())
    .filter(Boolean);

  if (position === "end") {
    if (timeSegments.length < 2) {
      return null;
    }
    const endTime = timeSegments[1];
    if (!endTime || !/am|pm/i.test(endTime)) {
      return null;
    }
    const offset = getEasternOffset(cleanedDate);
    const parseTarget = `${cleanedDate} ${endTime} GMT${offset}`;
    const parsed = new Date(parseTarget);
    return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
  }

  const startTime = timeSegments[0];
  const fallbackTime = "6:00 PM";
  const timeString = startTime && /am|pm/i.test(startTime) ? startTime : fallbackTime;
  const offset = getEasternOffset(cleanedDate);
  const parseTarget = `${cleanedDate} ${timeString} GMT${offset}`;
  const parsed = new Date(parseTarget);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed.toISOString();
}

function slugify(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
}

function slugifyFromUrl(url: string): string {
  try {
    const parsed = new URL(url);
    const segments = parsed.pathname.split("/").filter(Boolean);
    const last = segments[segments.length - 1] ?? parsed.hostname;
    return slugify(last);
  } catch {
    return slugify(url);
  }
}

function buildOlpEvent(
  summary: ListingSummary,
  detail: EventDetail | null
): Omit<Event, "created_at" | "updated_at"> | null {
  const startDate = detail?.startDate ?? buildIso(summary.entryDate, summary.timeRange, "start");
  const endDate =
    detail?.endDate ??
    buildIso(summary.entryDate, summary.timeRange, "end") ??
    (startDate ? new Date(new Date(startDate).getTime() + 2 * 60 * 60 * 1000).toISOString() : null);

  if (!startDate) {
    return null;
  }

  const slug = summary.detailUrl ? slugifyFromUrl(summary.detailUrl) : slugify(summary.title);
  const id = `olp-${slug}-${startDate.slice(0, 10)}`;

  const category = summary.type ? `olp:${summary.type}` : null;

  return {
    id,
    slug: `olp-${slug}`,
    name: summary.title,
    description: detail?.description ?? summary.excerpt ?? "",
    start_date: startDate,
    end_date: endDate ?? startDate,
    location_name: detail?.locationName ?? "Ontario Liberal Party",
    location_address: detail?.locationAddress ?? null,
    category,
    source: "olp",
    is_external: true,
    external_url: withOlpUtmParams(summary.detailUrl ?? detail?.url ?? null),
    is_ticketed:
      detail?.isTicketed ??
      (summary.type ? summary.type.toLowerCase().includes("ticket") : false) ??
      false,
    cost: detail?.cost ?? null,
    tags: detail?.keywords ?? null,
    status: "active" as const,
    last_synced_at: null,
    sync_error: null,
  };
}

async function fetchOlpEvents(): Promise<Omit<Event, "created_at" | "updated_at">[]> {
  try {
    const response = await fetch(OLP_EVENTS_URL, {
      headers: {
        Accept: "text/html",
        "User-Agent": "data.teamnate.ca/edge-function",
      },
    });

    if (!response.ok) {
      const body = await response.text().catch(() => "");
      throw new Error(
        `OLP events listing error ${response.status}: ${body || response.statusText}`
      );
    }

    const html = await response.text();
    const document = new DOMParser().parseFromString(html, "text/html");
    if (!document) {
      throw new Error("Failed to parse HTML");
    }

    const cards = Array.from(
      document.querySelectorAll("#events-listing .events-listing-single a")
    ).slice(0, MAX_OLP_EVENTS);

    const events: Omit<Event, "created_at" | "updated_at">[] = [];

    for (const card of cards) {
      const summary = extractListingSummary(card as Element);
      if (!summary) continue;

      if (isAgmEvent(summary)) {
        continue;
      }

      let detail: EventDetail | null = null;
      if (summary.detailUrl) {
        try {
          detail = await fetchOlpEventDetail(summary.detailUrl);
        } catch (error) {
          console.error("Error fetching event detail:", error);
        }
      }

      const record = buildOlpEvent(summary, detail);
      if (record) {
        if (!isAgmEvent(record)) {
          events.push(record);
        }
      }
    }

    return events;
  } catch (error) {
    console.error("Error fetching OLP events:", error);
    throw error;
  }
}

async function syncEvents(supabase: ReturnType<typeof createClient>): Promise<EventSyncResult> {
  const syncStartTime = new Date().toISOString();
  const result: EventSyncResult = {
    success: true,
    added: 0,
    updated: 0,
    archived: 0,
    errors: 0,
    errorMessages: [],
    syncedAt: syncStartTime,
  };

  try {
    const olpEvents = await fetchOlpEvents();

    const eventMap = new Map<string, Omit<Event, "created_at" | "updated_at">>();
    for (const event of olpEvents) {
      eventMap.set(event.id, event);
    }
    const deduplicatedEvents = Array.from(eventMap.values());

    for (const event of deduplicatedEvents) {
      try {
        const { data: existing, error: fetchError } = await supabase
          .from("events")
          .select("id")
          .eq("id", event.id)
          .maybeSingle();

        if (fetchError && fetchError.code !== "PGRST116") {
          throw fetchError;
        }

        const eventData = {
          ...event,
          last_synced_at: syncStartTime,
          sync_error: null,
        };

        if (existing) {
          const { error: updateError } = await supabase
            .from("events")
            .update(eventData)
            .eq("id", event.id);

          if (updateError) {
            result.errors++;
            result.errorMessages.push(`Failed to update event ${event.id}: ${updateError.message}`);
          } else {
            result.updated++;
          }
        } else {
          const { error: insertError } = await supabase.from("events").insert(eventData);

          if (insertError) {
            result.errors++;
            result.errorMessages.push(`Failed to insert event ${event.id}: ${insertError.message}`);
          } else {
            result.added++;
          }
        }
      } catch (error) {
        result.errors++;
        const errorMessage = error instanceof Error ? error.message : String(error);
        result.errorMessages.push(`Error syncing event ${event.id}: ${errorMessage}`);
        console.error(`Error syncing event ${event.id}:`, error);
      }
    }

    const cutoffDate = new Date(Date.parse(syncStartTime) - 24 * 60 * 60 * 1000).toISOString();
    const { data: archivedData, error: archiveError } = await supabase
      .from("events")
      .update({ status: "archived" })
      .eq("source", "olp")
      .eq("status", "active")
      .lt("last_synced_at", cutoffDate);

    if (archiveError) {
      result.errorMessages.push(`Failed to archive stale events: ${archiveError.message}`);
    } else {
      // Note: Supabase doesn't return count, so we'll estimate
      result.archived = 0; // Would need a separate query to get count
    }

    if (result.errors > 0) {
      result.success = false;
    }

    return result;
  } catch (error) {
    console.error("Error in syncEvents:", error);
    result.success = false;
    result.errors++;
    result.errorMessages.push(error instanceof Error ? error.message : String(error));
    return result;
  }
}

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({
          error: "Missing required environment variables",
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const result = await syncEvents(supabase);

    return new Response(JSON.stringify(result), {
      status: result.success ? 200 : 500,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        details: error instanceof Error ? error.message : "Unknown error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
