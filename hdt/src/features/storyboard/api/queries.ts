/**
 * Storyboard generation is entirely mutation-driven (no cached server lists),
 * so this file only holds the shared query-key namespace for consistency with
 * the rest of the codebase.
 */
export const STORYBOARD_KEYS = {
  all: ['storyboard'] as const,
} as const
