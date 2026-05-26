const { useState, useEffect, useCallback, useRef, useMemo } = React;

/* ══════════════════════════════════════════════
   TICKER TEXT
   Each side has its own ticker inside the panel.
   Dev panel clips dev text, PM panel clips PM text.
   Inner edges fade out to create the transformation
   illusion at the boundary.
   ══════════════════════════════════════════════ */

const devLines = [
  '$ nudge "deploy to staging before 5pm"',
  'git push origin main && nudge task "tag release v2.1"',
  '> stt: "fix the auth middleware" → intent: task (96%)',
  'nudge alarm "review PR #247 in 30 minutes"',
  '$ nudge save "Redis cache TTL is 3600s for user sessions"',
  'pipeline: voice 340ms → intent 120ms → agent 280ms = 740ms',
  'nudge soul add "the API = payments microservice"',
  '$ nudge "create a ticket for the memory leak in worker pool"',
];

const pmLines = [
  '✓ Deploy to staging before 5pm added to your tasks',
  '✓ Release v2.1 tagged, task marked complete',
  '✓ "Fix auth middleware" added to sprint backlog',
  '⏰ Reminder set: Review PR #247 in 30 minutes',
  '📝 Saved to knowledge base: Redis cache TTL note',
  '✓ Done in 740ms. Voice → action, no typing needed',
  '🧠 Learned: "the API" now means payments microservice',
  '🎫 Ticket created: Memory leak in worker pool',
];

const rowConfigs = [
  { y: 5, speed: 35, idx: 0 },
  { y: 16, speed: 28, idx: 1 },
  { y: 27, speed: 40, idx: 2 },
  { y: 40, speed: 32, idx: 3 },
  { y: 53, speed: 38, idx: 4 },
  { y: 64, speed: 30, idx: 5 },
  { y: 76, speed: 42, idx: 6 },
  { y: 88, speed: 34, idx: 7 },
];

/* Ticker row that scrolls inside a panel */
function TickerRow({ y, speed, text, direction, color, font }) {
  const repeated = Array(6).fill(text).join('            ');
  const anim = direction === 'ltr' ? 'tLTR' : 'tRTL';
  return (
    <div style={{
      position: 'absolute', top: `${y}%`, left: '-50%', width: '200%',
      height: 18, pointerEvents: 'none', overflow: 'visible',
    }}>
      <div style={{
        whiteSpace: 'nowrap', fontFamily: font, fontSize: 12,
        color, lineHeight: '18px',
        animation: `${anim} ${speed}s linear infinite`,
      }}>
        {repeated}
      </div>
    </div>
  );
}

/* Dev side tickers (inside the dark panel) */
function DevTickers() {
  return (
    <div style={{
      position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none', zIndex: 1,
      maskImage: 'linear-gradient(to right, black 0%, black 60%, transparent 100%)',
      WebkitMaskImage: 'linear-gradient(to right, black 0%, black 60%, transparent 100%)',
    }}>
      {rowConfigs.map((r, i) => {
        const opacity = [0.16, 0.07, 0.14, 0.05, 0.12, 0.06, 0.15, 0.08][i];
        return <TickerRow key={i} y={r.y} speed={r.speed}
          text={devLines[r.idx % devLines.length]}
          direction={i % 2 === 0 ? 'rtl' : 'ltr'}
          color={`rgba(255,107,53,${opacity})`}
          font="var(--mono)" />;
      })}
    </div>
  );
}

/* PM side tickers (inside the light panel) */
function PMTickers() {
  return (
    <div style={{
      position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none', zIndex: 1,
      maskImage: 'linear-gradient(to left, black 0%, black 60%, transparent 100%)',
      WebkitMaskImage: 'linear-gradient(to left, black 0%, black 60%, transparent 100%)',
    }}>
      {rowConfigs.map((r, i) => {
        const opacity = [0.16, 0.07, 0.14, 0.05, 0.12, 0.06, 0.15, 0.08][i];
        return <TickerRow key={i} y={r.y} speed={r.speed}
          text={pmLines[r.idx % pmLines.length]}
          direction={i % 2 === 0 ? 'rtl' : 'ltr'}
          color={`rgba(26,26,46,${opacity})`}
          font="var(--body)" />;
      })}
    </div>
  );
}

/* ══════════════════════════════════════════════
   DOWNLOAD POPOVER
   ══════════════════════════════════════════════ */
function DownloadPopover({ show, onClose, dark }) {
  if (!show) return null;
  const bg = dark ? '#1C1C1E' : '#fff';
  const bg2 = dark ? '#2C2C2E' : '#F8F9FA';
  const border = dark ? '#3A3A3C' : '#E5E7EB';
  const t1 = dark ? '#F5F5F7' : '#111';
  const t2 = dark ? '#A1A1A6' : '#6B7280';
  const t3 = dark ? '#636366' : '#9CA3AF';

  const appleIcon = <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83"/><path d="M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11"/></svg>;

  const chipIcon = <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.2">
    <rect x="4" y="4" width="8" height="8" rx="1.5" />
    <line x1="6" y1="4" x2="6" y2="2" /><line x1="8" y1="4" x2="8" y2="2" /><line x1="10" y1="4" x2="10" y2="2" />
    <line x1="6" y1="12" x2="6" y2="14" /><line x1="8" y1="12" x2="8" y2="14" /><line x1="10" y1="12" x2="10" y2="14" />
    <line x1="4" y1="6" x2="2" y2="6" /><line x1="4" y1="8" x2="2" y2="8" /><line x1="4" y1="10" x2="2" y2="10" />
    <line x1="12" y1="6" x2="14" y2="6" /><line x1="12" y1="8" x2="14" y2="8" /><line x1="12" y1="10" x2="14" y2="10" />
  </svg>;

  return ReactDOM.createPortal(
    <div style={{ position: 'fixed', inset: 0, zIndex: 99999, display: 'flex', alignItems: 'center', justifyContent: 'center' }} onClick={onClose}>
      <div style={{ position: 'fixed', inset: 0, background: dark ? 'rgba(0,0,0,0.75)' : 'rgba(0,0,0,0.65)', backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)' }} />
      <div onClick={e => e.stopPropagation()} style={{
        position: 'relative', background: bg, borderRadius: 20, padding: '36px 36px 28px',
        border: `1px solid ${border}`,
        boxShadow: dark ? '0 24px 64px rgba(0,0,0,0.6)' : '0 24px 64px rgba(0,0,0,0.15), 0 0 0 1px rgba(0,0,0,0.04)',
        width: 380, zIndex: 100000,
      }}>
        {/* Logo + title */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 6 }}>
          <div style={{ width: 40, height: 40, borderRadius: 10, background: 'var(--accent)', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 2px 8px rgba(255,107,53,0.3)' }}>
            <svg width="20" height="20" viewBox="0 0 16 16" fill="none"><rect x="6" y="2" width="4" height="8" rx="2" fill="#fff"/><path d="M4 8a4 4 0 008 0" stroke="#fff" strokeWidth="1.5" fill="none"/><line x1="8" y1="13" x2="8" y2="15" stroke="#fff" strokeWidth="1.5"/></svg>
          </div>
          <div>
            <div style={{ fontSize: 18, fontWeight: 700, color: t1, fontFamily: 'var(--heading)', letterSpacing: '-0.01em', whiteSpace: 'nowrap' }}>Download Nudge</div>
            <div style={{ fontSize: 12, color: t3 }}>v0.1.0 · macOS 14+</div>
          </div>
        </div>

        <div style={{ fontSize: 13, color: t2, margin: '16px 0 20px', lineHeight: 1.5 }}>
          Choose your Mac's chip. Not sure? Go with Apple Silicon if your Mac is from 2021 or later.
        </div>

        {/* Download options */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <button style={{
            padding: '16px 20px', borderRadius: 14, background: 'var(--accent)', color: '#fff',
            fontSize: 15, fontWeight: 600, border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'space-between',
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            boxShadow: '0 4px 12px rgba(255,107,53,0.25)',
            transition: 'transform 0.12s, box-shadow 0.2s',
          }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-1px)'; e.currentTarget.style.boxShadow = '0 6px 16px rgba(255,107,53,0.35)'; }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = '0 4px 12px rgba(255,107,53,0.25)'; }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {appleIcon}
              <div style={{ textAlign: 'left' }}>
                <div>Apple Silicon</div>
              </div>
            </div>
            <span style={{ fontSize: 11, background: 'rgba(255,255,255,0.2)', padding: '3px 10px', borderRadius: 20, fontWeight: 500 }}>Recommended</span>
          </button>

          <button style={{
            padding: '16px 20px', borderRadius: 14, background: bg2, color: t1, fontSize: 15, fontWeight: 600,
            border: `1px solid ${border}`, cursor: 'pointer',
            display: 'flex', alignItems: 'center', gap: 12,
            fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif',
            transition: 'border-color 0.2s, background 0.2s',
          }}
            onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--accent)'; }}
            onMouseLeave={e => { e.currentTarget.style.borderColor = border; }}>
            <span style={{ color: t2 }}>{chipIcon}</span>
            <div style={{ textAlign: 'left' }}>
              <div>Intel</div>
              <div style={{ fontSize: 11, fontWeight: 400, color: t3 }}>x86_64 · Pre-2021 Macs</div>
            </div>
          </button>
        </div>

        {/* Footer */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16, marginTop: 20, fontSize: 11, color: t3 }}>
          <span>Free</span>
          <span style={{ width: 3, height: 3, borderRadius: '50%', background: t3, opacity: 0.5 }}></span>
          <span>MIT Licensed</span>
          <span style={{ width: 3, height: 3, borderRadius: '50%', background: t3, opacity: 0.5 }}></span>
          <span>Open Source</span>
        </div>

        {/* Close */}
        <button onClick={onClose} style={{
          position: 'absolute', top: 14, right: 14, width: 30, height: 30,
          borderRadius: '50%', background: dark ? '#3A3A3C' : '#F0F0F0',
          border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
          color: t2, fontSize: 15, transition: 'background 0.15s',
        }}
          onMouseEnter={e => e.currentTarget.style.background = dark ? '#4A4A4C' : '#E5E5E5'}
          onMouseLeave={e => e.currentTarget.style.background = dark ? '#3A3A3C' : '#F0F0F0'}>✕</button>
      </div>
    </div>,
    document.body
  );
}

/* ══════════════════════════════════════════════
   SPLIT INTRO — DEV (LEFT), PM (RIGHT)
   ══════════════════════════════════════════════ */
function SplitIntro({ onSelect }) {
  const [hovered, setHovered] = useState(null);
  const [selecting, setSelecting] = useState(null);
  const [showDL, setShowDL] = useState(false);

  const handleSelect = useCallback((side) => {
    if (selecting) return;
    setSelecting(side);
    setTimeout(() => onSelect(side), side === 'dev' ? 450 : 700);
  }, [onSelect, selecting]);

  const devW = selecting === 'dev' ? '100%' : selecting === 'pm' ? '0%' : hovered === 'dev' ? '54%' : hovered === 'pm' ? '46%' : '50%';
  const pmW = selecting === 'pm' ? '100%' : selecting === 'dev' ? '0%' : hovered === 'pm' ? '54%' : hovered === 'dev' ? '46%' : '50%';
  const tr = selecting ? '0.7s var(--ease)' : '0.5s var(--ease)';

  return (
    <div style={{ position: 'relative', width: '100vw', height: '100vh', display: 'flex', overflow: 'hidden' }}>

      {/* ══ DEV (LEFT) ══ */}
      <div style={{
        position: 'relative', width: devW, height: '100%', background: '#0A0A0A',
        overflow: 'hidden', cursor: 'pointer', transition: `width ${tr}`,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      }}
        onClick={() => handleSelect('dev')}
        onMouseEnter={() => !selecting && setHovered('dev')}
        onMouseLeave={() => !selecting && setHovered(null)}>
        <DevTickers />
        <div style={{ position: 'relative', zIndex: 5, textAlign: 'center', padding: '0 40px', maxWidth: 480,
          opacity: selecting && selecting !== 'dev' ? 0 : 1, transition: 'opacity 0.3s' }}>
          <h2 className="r-split-text" style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 72, lineHeight: 0.95, letterSpacing: '-0.03em', color: '#EDEDED', marginBottom: 24 }}>
            I BUILD<br/>THINGS<span style={{ color: 'var(--accent)' }}>.</span></h2>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16,
            fontFamily: 'var(--mono)', fontSize: 12, color: '#888', letterSpacing: 2, textTransform: 'uppercase', marginBottom: 40 }}>
            <span>Open Source</span><span style={{ color: 'var(--accent)' }}>●</span>
            <span>Offline</span><span style={{ color: 'var(--accent)' }}>●</span>
            <span>Sub-Second</span></div>
          <div style={{ background: 'rgba(255,255,255,0.04)', border: '1px solid #2A2A2A', borderRadius: 10, padding: '14px 24px', marginBottom: 16,
            fontFamily: 'var(--mono)', fontSize: 15, color: '#A3A3A3', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span><span style={{ color: '#666' }}>$ </span>pip install nudge-ai</span>
            <span style={{ color: '#555', fontSize: 12 }}>⎘</span></div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16, fontFamily: 'var(--mono)', fontSize: 12, color: '#666' }}>
            <span>MIT LICENSE</span><span style={{ color: 'var(--accent)' }}>★ Star</span></div>
          <div style={{ marginTop: 48, display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-start' }}>
            <div style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid #2A2A2A', borderRadius: 8, padding: '10px 18px',
              fontFamily: 'var(--mono)', fontSize: 13, color: '#EDEDED' }}>$ nudge "create feature"</div>
            <div style={{ background: 'rgba(255,255,255,0.05)', border: '1px solid #2A2A2A', borderRadius: 8, padding: '10px 18px',
              fontFamily: 'var(--mono)', fontSize: 13 }}>
              <span style={{ color: 'var(--accent)' }}>→</span> <span style={{ color: '#A3A3A3' }}>latency:</span> <span style={{ color: 'var(--green)' }}>742ms</span></div>
          </div>
        </div>
      </div>

      {/* ══ PM (RIGHT) ══ */}
      <div style={{
        position: 'relative', width: pmW, height: '100%', background: '#FAFAFA',
        overflow: 'hidden', cursor: 'pointer', transition: `width ${tr}`,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      }}
        onClick={() => handleSelect('pm')}
        onMouseEnter={() => !selecting && setHovered('pm')}
        onMouseLeave={() => !selecting && setHovered(null)}>
        <PMTickers />
        <div style={{ position: 'relative', zIndex: 5, textAlign: 'center', padding: '0 40px', maxWidth: 480,
          opacity: selecting && selecting !== 'pm' ? 0 : 1, transition: 'opacity 0.3s' }}>
          <h2 className="r-split-text" style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 72, lineHeight: 0.95, letterSpacing: '-0.03em', color: '#1A1A2E', marginBottom: 24 }}>
            I RUN<br/>THINGS<span style={{ color: 'var(--accent)' }}>.</span></h2>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 16,
            fontSize: 13, color: '#6B7394', letterSpacing: 2, textTransform: 'uppercase', fontWeight: 600, marginBottom: 40 }}>
            <span>Intuitive</span><span style={{ color: 'var(--accent)' }}>●</span>
            <span>Productive</span><span style={{ color: 'var(--accent)' }}>●</span>
            <span>Voice-First</span></div>
          <button onClick={(e) => { e.stopPropagation(); setShowDL(true); }} style={{ padding: '18px 48px', borderRadius: 50, fontSize: 17, fontWeight: 700,
            background: 'var(--accent)', color: '#fff', boxShadow: '0 6px 24px rgba(255,107,53,0.3)',
            transition: 'transform 0.15s, box-shadow 0.2s', marginBottom: 16, letterSpacing: 0.3 }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 8px 32px rgba(255,107,53,0.4)'; }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = '0 6px 24px rgba(255,107,53,0.3)'; }}>
            Download for Mac</button>
          <div style={{ fontSize: 12, color: '#9CA3AF', letterSpacing: 1.5, textTransform: 'uppercase' }}>Compatible with macOS 14+</div>
          <div style={{ marginTop: 48, display: 'flex', flexDirection: 'column', gap: 10, alignItems: 'flex-end' }}>
            <div style={{ background: '#fff', border: '1px solid #E5E7EB', borderRadius: 12, padding: '12px 20px',
              display: 'flex', alignItems: 'center', gap: 10, boxShadow: '0 2px 8px rgba(0,0,0,0.04)', fontSize: 14, color: '#1A1A2E', fontWeight: 500 }}>
              <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--green)', flexShrink: 0 }}></span>
              ✓ Dentist appt set for 3:00 PM</div>
            <div style={{ background: '#fff', border: '1px solid #E5E7EB', borderRadius: 12, padding: '12px 20px',
              display: 'flex', alignItems: 'center', gap: 10, boxShadow: '0 2px 8px rgba(0,0,0,0.04)', fontSize: 14, color: '#4A4A6A', fontStyle: 'italic' }}>
              <span style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--accent)', flexShrink: 0 }}></span>
              "Remind me to buy coffee..."</div>
          </div>
        </div>
      </div>

      {/* ══ CENTER PILL ══ */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', zIndex: 20,
        opacity: selecting ? 0 : 1, transition: 'opacity 0.3s',
        display: 'flex', flexDirection: 'column', alignItems: 'center',
      }}>
        <div style={{
          background: 'rgba(40,40,40,0.6)',
          backdropFilter: 'blur(24px)', WebkitBackdropFilter: 'blur(24px)',
          borderRadius: 60, padding: '18px 44px',
          display: 'flex', alignItems: 'center', gap: 14,
          border: '1px solid rgba(255,255,255,0.1)',
          boxShadow: '0 8px 40px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.05)',
        }}>
          <span style={{ width: 16, height: 16, borderRadius: '50%', background: 'var(--accent)', flexShrink: 0,
            boxShadow: '0 0 12px rgba(255,107,53,0.4)' }}></span>
          <span style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 32, letterSpacing: '-0.02em', color: '#EDEDED' }}>nudge</span>
        </div>
        <div style={{
          marginTop: 18, fontFamily: 'var(--heading)', fontSize: 13, fontWeight: 700,
          letterSpacing: 4, textTransform: 'uppercase',
          color: 'rgba(255,255,255,0.5)', textShadow: '0 1px 2px rgba(0,0,0,0.3)',
        }}>Choose Your Side</div>
      </div>

      <DownloadPopover show={showDL} onClose={() => setShowDL(false)} dark={false} />

      <style>{`
        @keyframes tLTR { 0% { transform: translateX(-50%); } 100% { transform: translateX(0); } }
        @keyframes tRTL { 0% { transform: translateX(0); } 100% { transform: translateX(-50%); } }
      `}</style>
    </div>
  );
}

Object.assign(window, { SplitIntro, DownloadPopover });
