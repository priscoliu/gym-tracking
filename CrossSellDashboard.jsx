import { useState } from "react";

const CLASSES = [
  "Property", "Casualty", "Marine", "Aviation", "Energy",
  "Construction", "Fin. Lines", "Prof. Indemnity", "Cyber",
  "Health", "Life", "Trade Credit", "Political Risk", "Environmental", "Terrorism"
];

const RAW = {
  "Property|Casualty": 68, "Property|Marine": 31, "Property|Aviation": 12,
  "Property|Energy": 22, "Property|Construction": 41, "Property|Fin. Lines": 28,
  "Property|Prof. Indemnity": 19, "Property|Cyber": 15, "Property|Health": 24,
  "Property|Life": 18, "Property|Trade Credit": 14, "Property|Political Risk": 9,
  "Property|Environmental": 17, "Property|Terrorism": 11,
  "Casualty|Marine": 18, "Casualty|Aviation": 8, "Casualty|Energy": 16,
  "Casualty|Construction": 38, "Casualty|Fin. Lines": 22, "Casualty|Prof. Indemnity": 21,
  "Casualty|Cyber": 18, "Casualty|Health": 20, "Casualty|Life": 14,
  "Casualty|Trade Credit": 9, "Casualty|Political Risk": 6,
  "Casualty|Environmental": 12, "Casualty|Terrorism": 8,
  "Marine|Aviation": 14, "Marine|Energy": 26, "Marine|Construction": 12,
  "Marine|Fin. Lines": 16, "Marine|Prof. Indemnity": 11, "Marine|Cyber": 8,
  "Marine|Health": 7, "Marine|Life": 5, "Marine|Trade Credit": 22,
  "Marine|Political Risk": 18, "Marine|Environmental": 14, "Marine|Terrorism": 9,
  "Aviation|Energy": 11, "Aviation|Construction": 7, "Aviation|Fin. Lines": 9,
  "Aviation|Prof. Indemnity": 8, "Aviation|Cyber": 5, "Aviation|Health": 4,
  "Aviation|Life": 3, "Aviation|Trade Credit": 7, "Aviation|Political Risk": 11,
  "Aviation|Environmental": 5, "Aviation|Terrorism": 13,
  "Energy|Construction": 19, "Energy|Fin. Lines": 12, "Energy|Prof. Indemnity": 9,
  "Energy|Cyber": 8, "Energy|Health": 6, "Energy|Life": 4,
  "Energy|Trade Credit": 11, "Energy|Political Risk": 16, "Energy|Environmental": 21,
  "Energy|Terrorism": 12,
  "Construction|Fin. Lines": 14, "Construction|Prof. Indemnity": 16,
  "Construction|Cyber": 9, "Construction|Health": 8, "Construction|Life": 5,
  "Construction|Trade Credit": 7, "Construction|Political Risk": 6,
  "Construction|Environmental": 19, "Construction|Terrorism": 7,
  "Fin. Lines|Prof. Indemnity": 61, "Fin. Lines|Cyber": 44, "Fin. Lines|Health": 16,
  "Fin. Lines|Life": 11, "Fin. Lines|Trade Credit": 18, "Fin. Lines|Political Risk": 14,
  "Fin. Lines|Environmental": 8, "Fin. Lines|Terrorism": 6,
  "Prof. Indemnity|Cyber": 52, "Prof. Indemnity|Health": 14, "Prof. Indemnity|Life": 9,
  "Prof. Indemnity|Trade Credit": 11, "Prof. Indemnity|Political Risk": 8,
  "Prof. Indemnity|Environmental": 6, "Prof. Indemnity|Terrorism": 5,
  "Cyber|Health": 12, "Cyber|Life": 7, "Cyber|Trade Credit": 9,
  "Cyber|Political Risk": 7, "Cyber|Environmental": 5, "Cyber|Terrorism": 6,
  "Health|Life": 58, "Health|Trade Credit": 11, "Health|Political Risk": 6,
  "Health|Environmental": 7, "Health|Terrorism": 4,
  "Life|Trade Credit": 9, "Life|Political Risk": 5, "Life|Environmental": 4,
  "Life|Terrorism": 3,
  "Trade Credit|Political Risk": 29, "Trade Credit|Environmental": 8, "Trade Credit|Terrorism": 11,
  "Political Risk|Environmental": 12, "Political Risk|Terrorism": 21,
  "Environmental|Terrorism": 9,
};

const CLIENTS = [
  { id: "C-10291", name: "Acme Global Corp", industry: "Manufacturing", tier: "Tier 1", products: ["Property", "Casualty", "Construction"] },
  { id: "C-10445", name: "PT Alpha Indonesia", industry: "Energy", tier: "Tier 2", products: ["Marine", "Energy", "Political Risk"] },
  { id: "C-10512", name: "Northern Trust Bank", industry: "Financial Services", tier: "Tier 1", products: ["Fin. Lines", "Prof. Indemnity"] },
  { id: "C-10678", name: "Meridian Tech Ltd", industry: "Technology", tier: "Tier 2", products: ["Cyber", "Prof. Indemnity"] },
  { id: "C-10734", name: "Atlas Shipping Co", industry: "Logistics", tier: "Tier 3", products: ["Marine"] },
  { id: "C-10801", name: "Crestwood Capital", industry: "Financial Services", tier: "Tier 1", products: ["Fin. Lines", "Prof. Indemnity", "Cyber", "Health"] },
];

function getScore(a, b) {
  return RAW[`${a}|${b}`] || RAW[`${b}|${a}`] || 0;
}

function getColor(val) {
  if (val === 0) return "#F9FAFB";
  const stops = [
    [1,  [237, 233, 254]],
    [20, [221, 214, 254]],
    [40, [196, 181, 253]],
    [60, [167, 139, 250]],
    [80, [124,  58, 237]],
  ];
  for (let i = 1; i < stops.length; i++) {
    if (val <= stops[i][0]) {
      const t = (val - stops[i-1][0]) / (stops[i][0] - stops[i-1][0]);
      const [r1,g1,b1] = stops[i-1][1];
      const [r2,g2,b2] = stops[i][1];
      return `rgb(${Math.round(r1+(r2-r1)*t)},${Math.round(g1+(g2-g1)*t)},${Math.round(b1+(b2-b1)*t)})`;
    }
  }
  return "rgb(124,58,237)";
}

function getRecommendations(client) {
  const has = new Set(client.products);
  const scores = {};
  CLASSES.forEach(c => {
    if (!has.has(c)) {
      let total = 0, count = 0;
      client.products.forEach(p => {
        const s = getScore(p, c);
        if (s > 0) { total += s; count++; }
      });
      if (count > 0) scores[c] = Math.round(total / count);
    }
  });
  return Object.entries(scores)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([cls, score]) => ({
      cls, score,
      based_on: client.products.filter(p => getScore(p, cls) > 15).slice(0, 2)
    }));
}

const TIER_STYLE = {
  "Tier 1": { background: "#F5F3FF", color: "#7C3AED" },
  "Tier 2": { background: "#DBEAFE", color: "#1D4ED8" },
  "Tier 3": { background: "#F3F4F6", color: "#6B7280" },
};

const css = `
  *, *::before, *::after { box-sizing: border-box; }

  :root {
    --space-1: 4px;
    --space-2: 8px;
    --space-3: 12px;
    --space-4: 16px;
    --space-5: 20px;
    --space-6: 24px;
    --r-card: 10px;
    --r-sm: 6px;
    --r-pill: 99px;
    --shadow: 0 1px 3px rgba(0,0,0,0.06), 0 4px 12px rgba(0,0,0,0.04);
    --violet: #7C3AED;
    --violet-light: #EDE9FE;
    --violet-mid: #8B5CF6;
    --violet-dark: #4C1D95;
    --text: #1E293B;
    --text-body: #374151;
    --text-muted: #9CA3AF;
    --border: #E5E7EB;
    --border-light: #F3F4F6;
    --surface: #F9FAFB;
  }

  .heatmap-scroll::-webkit-scrollbar { height: 8px; }
  .heatmap-scroll::-webkit-scrollbar-track { background: var(--border-light); border-radius: var(--r-pill); }
  .heatmap-scroll::-webkit-scrollbar-thumb { background: #C4B5FD; border-radius: var(--r-pill); }
  .heatmap-scroll::-webkit-scrollbar-thumb:hover { background: var(--violet-mid); }

  .client-row {
    padding: 7px 10px;
    border-radius: var(--r-sm);
    cursor: pointer;
    border: 1px solid transparent;
    transition: background 0.12s, border-color 0.12s;
  }
  .client-row:hover { background: var(--surface); }
  .client-row.active { background: var(--violet-light); border-color: #DDD6FE; }

  .heatmap-cell {
    transition: transform 0.1s, box-shadow 0.1s;
    cursor: pointer;
  }
  .heatmap-cell:hover {
    transform: scale(1.18);
    box-shadow: 0 4px 12px rgba(124, 58, 237, 0.3);
    z-index: 10;
    position: relative;
  }

  input.search-input {
    width: 100%;
    padding: 7px 10px 7px 28px;
    border: 1px solid var(--border);
    border-radius: var(--r-sm);
    font-size: 12px;
    color: var(--text-body);
    background: var(--surface);
    font-family: inherit;
    transition: border-color 0.15s, box-shadow 0.15s;
    outline: none;
  }
  input.search-input:focus {
    border-color: #A78BFA;
    box-shadow: 0 0 0 3px rgba(167, 139, 250, 0.15);
  }
`;

export default function CrossSellDashboard() {
  const [hoveredCell, setHoveredCell] = useState(null);
  const [selectedClient, setSelectedClient] = useState(CLIENTS[2]);
  const [search, setSearch] = useState("");

  const filtered = CLIENTS.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.id.toLowerCase().includes(search.toLowerCase())
  );

  const recs = getRecommendations(selectedClient);
  const CELL = 34;

  return (
    <>
      <style>{css}</style>

      <div style={{
        fontFamily: "'DM Sans', 'Segoe UI', sans-serif",
        background: "#F3F4F6",
        minHeight: "100vh",
        padding: "var(--space-6)",
      }}>

        {/* Header */}
        <div style={{ marginBottom: 20 }}>
          <div style={{ display: "flex", alignItems: "baseline", gap: 8, marginBottom: 3 }}>
            <span style={{ fontSize: 18, fontWeight: 700, color: "var(--text)", letterSpacing: "-0.3px" }}>
              Cross-sell Intelligence
            </span>
            <span style={{
              fontSize: 10, fontWeight: 600, color: "var(--violet)",
              background: "var(--violet-light)", border: "1px solid #DDD6FE",
              padding: "2px 7px", borderRadius: "var(--r-pill)", letterSpacing: "0.3px",
            }}>
              MOCK
            </span>
          </div>
          <p style={{ fontSize: 12, color: "var(--text-muted)", margin: 0 }}>
            Product co-occurrence at global class level · Illustrative data
          </p>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "1fr 340px", gap: 16, alignItems: "start" }}>

          {/* LEFT — Heatmap */}
          <div style={{
            background: "#fff",
            borderRadius: "var(--r-card)",
            boxShadow: "var(--shadow)",
            padding: "var(--space-5)",
          }}>
            <div style={{ marginBottom: 20 }}>
              {/* Title row — legend sits on this line */}
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 3 }}>
                <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text)" }}>
                  Co-occurrence Matrix
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}>
                  <span style={{ fontSize: 10, color: "var(--text-muted)" }}>Low</span>
                  <div style={{
                    width: 80, height: 8, borderRadius: 4,
                    background: "linear-gradient(to right, #F5F3FF, #7C3AED)"
                  }}/>
                  <span style={{ fontSize: 10, color: "var(--text-muted)" }}>High</span>
                </div>
              </div>
              <div style={{ fontSize: 11, color: "var(--text-muted)" }}>
                % of shared clients between any two product classes
              </div>
            </div>

            <div className="heatmap-scroll" style={{ overflowX: "auto" }}>
              <div style={{ display: "inline-block" }}>
                {/* Column headers */}
                <div style={{ display: "flex", marginLeft: CELL * 2.6 }}>
                  {CLASSES.map((c, j) => (
                    <div key={j} style={{ width: CELL, flexShrink: 0 }}>
                      <div style={{
                        fontSize: 9, color: "#6B7280", fontWeight: 600,
                        writingMode: "vertical-rl", transform: "rotate(180deg)",
                        height: 80, display: "flex", alignItems: "flex-start",
                        paddingBottom: 4, whiteSpace: "nowrap"
                      }}>{c}</div>
                    </div>
                  ))}
                </div>

                {/* Rows */}
                {CLASSES.map((row, i) => (
                  <div key={i} style={{ display: "flex", alignItems: "center" }}>
                    <div style={{
                      width: CELL * 2.6, flexShrink: 0, fontSize: 10,
                      color: "var(--text-body)", fontWeight: 600,
                      textAlign: "right", paddingRight: 8, whiteSpace: "nowrap"
                    }}>{row}</div>

                    {CLASSES.map((col, j) => {
                      if (j < i) return <div key={j} style={{ width: CELL, height: CELL, flexShrink: 0 }} />;

                      if (i === j) return (
                        <div key={j} style={{
                          width: CELL, height: CELL, flexShrink: 0,
                          background: "var(--border-light)", margin: 1, borderRadius: 5,
                          display: "flex", alignItems: "center", justifyContent: "center"
                        }}>
                          <div style={{ width: 5, height: 5, background: "#D1D5DB", borderRadius: 2 }}/>
                        </div>
                      );

                      const val = getScore(row, col);
                      return (
                        <div
                          key={j}
                          className="heatmap-cell"
                          onMouseEnter={() => setHoveredCell({ row: i, col: j, val, r: row, c: col })}
                          onMouseLeave={() => setHoveredCell(null)}
                          style={{
                            width: CELL, height: CELL, flexShrink: 0,
                            background: getColor(val),
                            margin: 1, borderRadius: 5,
                            display: "flex", alignItems: "center", justifyContent: "center",
                            fontSize: 9, fontWeight: 700,
                            color: val > 35 ? "rgba(255,255,255,0.9)" : "rgba(0,0,0,0.4)",
                          }}
                        >
                          {val > 0 ? val : ""}
                        </div>
                      );
                    })}
                  </div>
                ))}
              </div>
            </div>

            {hoveredCell && (
              <div style={{
                marginTop: 12, padding: "7px 12px",
                background: "var(--text)", borderRadius: 8, display: "inline-block"
              }}>
                <span style={{ fontSize: 12, color: "#fff" }}>
                  <strong>{hoveredCell.r}</strong>{" + "}<strong>{hoveredCell.c}</strong>
                  {" → "}
                  <span style={{ color: "#C4B5FD" }}>{hoveredCell.val}% co-occurrence</span>
                </span>
              </div>
            )}
          </div>

          {/* RIGHT panel */}
          <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>

            {/* Client lookup */}
            <div style={{
              background: "#fff",
              borderRadius: "var(--r-card)",
              boxShadow: "var(--shadow)",
              padding: "var(--space-4)",
            }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: "var(--text)", marginBottom: 10 }}>
                Client Lookup
              </div>

              <div style={{ position: "relative", marginBottom: 8 }}>
                <svg style={{ position: "absolute", left: 9, top: "50%", transform: "translateY(-50%)", pointerEvents: "none" }}
                  width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#9CA3AF" strokeWidth="2.5">
                  <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <input
                  className="search-input"
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                  placeholder="Search client name or ID…"
                />
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
                {filtered.map(c => (
                  <div
                    key={c.id}
                    className={`client-row${selectedClient.id === c.id ? " active" : ""}`}
                    onClick={() => { setSelectedClient(c); setSearch(""); }}
                  >
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <div>
                        <div style={{ fontSize: 12, fontWeight: 600, color: "var(--text)" }}>{c.name}</div>
                        <div style={{ fontSize: 10, color: "var(--text-muted)", marginTop: 1 }}>
                          {c.id} · {c.industry}
                        </div>
                      </div>
                      <span style={{
                        fontSize: 10, fontWeight: 600,
                        padding: "2px 7px", borderRadius: "var(--r-pill)",
                        flexShrink: 0, marginLeft: 8,
                        ...TIER_STYLE[c.tier],
                      }}>{c.tier}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Client detail */}
            {selectedClient && (
              <div style={{
                background: "#fff",
                borderRadius: "var(--r-card)",
                boxShadow: "var(--shadow)",
                padding: "var(--space-4)",
              }}>
                <div style={{ marginBottom: 14 }}>
                  <div style={{ fontSize: 14, fontWeight: 700, color: "var(--text)", letterSpacing: "-0.2px" }}>
                    {selectedClient.name}
                  </div>
                  <div style={{ fontSize: 11, color: "var(--text-muted)", marginTop: 2 }}>
                    {selectedClient.industry} · {selectedClient.tier}
                  </div>
                </div>

                {/* Current products */}
                <div style={{ marginBottom: 14 }}>
                  <div style={{
                    fontSize: 10, fontWeight: 700, color: "var(--text-muted)",
                    textTransform: "uppercase", letterSpacing: "0.6px", marginBottom: 8
                  }}>
                    Current — {selectedClient.products.length} class{selectedClient.products.length > 1 ? "es" : ""}
                  </div>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 5 }}>
                    {selectedClient.products.map(p => (
                      <span key={p} style={{
                        padding: "3px 9px", borderRadius: "var(--r-pill)",
                        fontSize: 11, fontWeight: 600,
                        background: "var(--violet-light)", color: "var(--violet)",
                        border: "1px solid #DDD6FE",
                      }}>{p}</span>
                    ))}
                  </div>
                </div>

                <div style={{ borderTop: "1px solid var(--border-light)", marginBottom: 14 }}/>

                {/* Recommendations */}
                <div>
                  <div style={{
                    fontSize: 10, fontWeight: 700, color: "var(--text-muted)",
                    textTransform: "uppercase", letterSpacing: "0.6px", marginBottom: 10
                  }}>
                    Recommended · Top {recs.length}
                  </div>

                  <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
                    {recs.map((r, idx) => (
                      <div key={r.cls} style={{
                        padding: idx === 0 ? "11px 12px" : "8px 12px",
                        borderRadius: "var(--r-card)",
                        border: `1px solid ${idx === 0 ? "#DDD6FE" : "var(--border-light)"}`,
                        background: idx === 0 ? "#FAFAFF" : "var(--surface)",
                        display: "flex", alignItems: "center", gap: 10,
                      }}>
                        <div style={{
                          width: 20, height: 20, borderRadius: "var(--r-sm)", flexShrink: 0,
                          background: "var(--border-light)",
                          display: "flex", alignItems: "center", justifyContent: "center",
                          fontSize: 10, fontWeight: 700,
                          color: idx === 0 ? "var(--violet)" : "var(--text-muted)",
                        }}>#{idx + 1}</div>

                        <div style={{ flex: 1, minWidth: 0 }}>
                          <div style={{
                            fontSize: idx === 0 ? 13 : 12,
                            fontWeight: idx === 0 ? 700 : 600,
                            color: "var(--text)", marginBottom: 2,
                          }}>{r.cls}</div>
                          {r.based_on.length > 0 && (
                            <div style={{ fontSize: 10, color: "var(--text-muted)" }}>
                              {r.based_on.join(", ")}
                            </div>
                          )}
                        </div>

                        <div style={{ textAlign: "right", flexShrink: 0 }}>
                          <div style={{
                            fontSize: idx === 0 ? 14 : 12,
                            fontWeight: 700, color: "var(--violet)",
                          }}>{r.score}%</div>
                          <div style={{ width: 40, height: 3, background: "var(--violet-light)", borderRadius: "var(--r-pill)", marginTop: 3 }}>
                            <div style={{ width: `${r.score}%`, height: "100%", borderRadius: "var(--r-pill)", background: "var(--violet-mid)" }}/>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>

                  <div style={{ marginTop: 10, fontSize: 10, color: "#D1D5DB" }}>
                    Score = avg co-occurrence with client's existing classes
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}