import React from "react";

export default function SurfaceCard({ className = "", children }) {
  return <section className={`surface-card ${className}`.trim()}>{children}</section>;
}
