// sendTeamWelcome.js

export const sendTeamWelcome = async (payload) => {
  const response = await fetch(
    "https://primary-production-a6b4.up.railway.app/webhook/team-welcome",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    }
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Request failed (${response.status}): ${text}`
    );
  }

  // Try JSON first, fall back to text if needed
  const contentType = response.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    return response.json();
  }

  return response.text();
};

