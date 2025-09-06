class HttpError extends Error {
  constructor(
    message,
    statusCode = 500,
    { stack = null, details = null, originalError = null } = {}
  ) {
    super(message);
    this.name = "HttpError";
    this.statusCode = statusCode;
    this.details = details;
    this.stack = stack;

    //original error exists so you can pass the error source
    if (originalError) {
      // Preserve original error info
      this.originalMessage = originalError.message;
      this.originalStack = originalError.stack;
    }
  }
}

export default HttpError;
