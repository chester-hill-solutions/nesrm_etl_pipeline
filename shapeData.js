const shapeData = (payload) => {
  const cleanString = (str) => {
    if (str === null || str === undefined) return undefined;
    const cleaned = String(str).trim();
    return cleaned === '' ? undefined : cleaned;
  };

  const shaped = {

  }

  console.log("Shape Data:", payload)  
  return true;
}

export default shapeData;
