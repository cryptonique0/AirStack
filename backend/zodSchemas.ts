import { z } from "zod";

export const AddWalletSchema = z.object({
  wallet: z.string().min(1, "Wallet address is required").regex(/^0x[a-fA-F0-9]{40}$/i, "Invalid wallet address"),
  name: z.string().optional(),
});

export const RemoveWalletSchema = z.object({
  wallet: z.string().min(1, "Wallet address is required").regex(/^0x[a-fA-F0-9]{40}$/i, "Invalid wallet address"),
});

// Add more schemas as needed
