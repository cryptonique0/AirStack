import { Request, Response, NextFunction } from "express";

// Centralized error handler middleware
export function errorHandler(err: any, req: Request, res: Response, next: NextFunction) {
  // Log error details (could be enhanced for production)
  // console.error(err);
  const status = err.status || 500;
  res.status(status).json({
    success: false,
    error: err.message || "Internal Server Error",
    details: process.env.NODE_ENV === "development" ? err.stack : undefined
  });
}
