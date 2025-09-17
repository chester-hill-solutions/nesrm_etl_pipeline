import logger from "simple-logs-sai-node";

async function longestSubstringMatch(text, word) {
  text = text.toLowerCase();
  word = word.toLowerCase();

  let maxLen = 0;
  for (let i = 0; i < word.length; i++) {
    for (let j = i + 1; j <= word.length; j++) {
      const sub = word.slice(i, j);
      if (text.includes(sub)) {
        maxLen = Math.max(maxLen, sub.length);
      }
    }
  }
  return maxLen;
}

async function scoreNameSet(email, { firstname, surname }) {
  logger.dev.log("scoreNameSet", email, firstname, surname);
  const firstScore = await longestSubstringMatch(email, firstname);
  const lastScore = await longestSubstringMatch(email, surname);
  logger.dev.log("scores", firstScore + lastScore);
  return firstScore + lastScore;
}

async function bestMatch(email, setA, setB) {
  logger.dev.log("bestMatch", email, setA, setB);
  if (setA.firstname == setB.firstname && setA.surname == setB.surname)
    return setA;
  const scoreA = await scoreNameSet(email, setA);
  const scoreB = await scoreNameSet(email, setB);
  if (scoreA > scoreB) return setA;
  if (scoreB > scoreA) return setB;
  if (setA.firstname.length > setB.firstname.length) {
  }
  const output = {
    firstname:
      setA.firstname.length > setB.firstname.length
        ? setA.firstname
        : setB.firstname,
    surname:
      setA.surname.length > setB.surname.length ? setA.surname : setB.surname,
  };
  return output;
}

export { bestMatch };
