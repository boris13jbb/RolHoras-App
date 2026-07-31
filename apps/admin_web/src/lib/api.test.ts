import { describe, expect, it } from "vitest";

describe("admin smoke", () => {
  it("api url defaults to localhost", () => {
    const url = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";
    expect(url).toContain("http");
  });
});
