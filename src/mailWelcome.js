// sendTeamWelcome.js
import path from "path";
import logger from "simple-logs-sai-node";

const sendTeamWelcome = async (payload) => {
  const response = await fetch(process.env.WELCOME_EMAIL_ENDPOINT, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Request failed (${response.status}): ${text}`);
  } else {
    logger.log("mailWelcome ok");
  }

  // Try JSON first, fall back to text if needed
  const contentType = response.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return response.json();
  }

  return response.text();
};
sendTeamWelcome.__module = path.basename(import.meta.url);
export { sendTeamWelcome };
