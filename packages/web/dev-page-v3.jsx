const { useState, useEffect, useRef } = React;

function dV(th = 0.2) {
  const r = useRef(null); const [v, setV] = useState(false);
  useEffect(() => { const el = r.current; if (!el) return;
    const o = new IntersectionObserver(([e]) => { if (e.isIntersecting) { setV(true); o.disconnect(); } }, { threshold: th });
    o.observe(el); return () => o.disconnect(); }, []); return [r, v];
}
function dC(t, dur = 900, active = false) {
  const [v, setV] = useState(0);
  useEffect(() => { if (!active) return; const t0 = performance.now(); let raf;
    const tick = (n) => { const p = Math.min((n - t0) / dur, 1); setV(Math.round((1 - Math.pow(1 - p, 3)) * t)); if (p < 1) raf = requestAnimationFrame(tick); };
    raf = requestAnimationFrame(tick); return () => cancelAnimationFrame(raf); }, [t, dur, active]); return v;
}

const D = { bg: '#0A0A0A', bg2: '#0E0E0E', card: '#141414', border: '#1E1E1E', t1: '#EDEDED', t2: '#A3A3A3', t3: '#666' };

function DCopy({ text, label }) {
  const [c, setC] = useState(false);
  return <button onClick={() => { navigator.clipboard.writeText(text).catch(() => {}); setC(true); setTimeout(() => setC(false), 2000); }}
    style={{ display: 'inline-flex', alignItems: 'center', gap: 12, padding: '14px 24px', borderRadius: 8,
      background: D.card, border: `1px solid ${D.border}`, fontFamily: 'var(--mono)', fontSize: 14, color: D.t1, transition: 'all 0.2s' }}
    onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--accent)'; e.currentTarget.style.boxShadow = '0 0 20px rgba(255,107,53,0.1)'; }}
    onMouseLeave={e => { e.currentTarget.style.borderColor = D.border; e.currentTarget.style.boxShadow = 'none'; }}>
    <span>{label}</span><span style={{ color: c ? 'var(--green)' : D.t3, fontSize: 12 }}>{c ? '✓ copied' : '⎘'}</span></button>;
}

function DevNav({ onSwitch, m }) {
  return <nav style={{ position: 'sticky', top: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    padding: '0 48px', height: 60, background: 'rgba(10,10,10,0.88)', backdropFilter: 'blur(16px)',
    borderBottom: `1px solid ${D.border}`, fontSize: 14, opacity: m ? 1 : 0, transition: 'opacity 0.3s' }}>
    <div style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 20, display: 'flex', alignItems: 'center', gap: 8, letterSpacing: '-0.02em' }}>
      <span style={{ color: 'var(--accent)', fontSize: 10 }}>●</span> nudge</div>
    <div style={{ display: 'flex', gap: 32, color: D.t2, fontWeight: 500 }}>
      {['Features', 'Skills', 'Pricing'].map(l => <a key={l} href={`#d-${l.toLowerCase()}`} style={{ color: D.t2, transition: 'color 0.2s' }}
        onMouseEnter={e => e.currentTarget.style.color = D.t1} onMouseLeave={e => e.currentTarget.style.color = D.t2}>{l}</a>)}
      <a href="https://github.com/chiruu12/nudge" target="_blank" rel="noopener" style={{ color: D.t2, transition: 'color 0.2s' }}
        onMouseEnter={e => e.currentTarget.style.color = D.t1} onMouseLeave={e => e.currentTarget.style.color = D.t2}>GitHub ⭐</a></div>
    <button onClick={onSwitch} style={{ fontSize: 13, color: D.t3, fontFamily: 'var(--mono)', padding: '6px 16px', border: `1px solid ${D.border}`, borderRadius: 8, transition: 'all 0.2s' }}
      onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--accent)'; e.currentTarget.style.color = D.t1; }}
      onMouseLeave={e => { e.currentTarget.style.borderColor = D.border; e.currentTarget.style.color = D.t3; }}>[pm →]</button></nav>;
}

/* ═══ HERO ═══ */
function DevHero({ m }) {
  const lines = [
    <><span style={{ color: D.t3 }}>$ </span>nudge</>,
    <span style={{ color: D.t3 }}>v0.1.0 · cmd+shift+n · groq</span>, '',
    <><span className="rec-dot" /> Recording... <span style={{ color: D.t3 }}>(1.2s)</span></>,
    <><span style={{ color: 'var(--accent)' }}>→ </span>STT: <span style={{ color: 'var(--accent)' }}>"remind me to push the fix"</span> <span style={{ color: D.t3 }}>(340ms)</span></>,
    <><span style={{ color: 'var(--accent)' }}>→ </span>Intent: <span style={{ color: 'var(--accent)' }}>alarm</span> <span style={{ color: D.t3 }}>(92%) · 120ms</span></>,
    <><span style={{ color: 'var(--accent)' }}>→ </span>Agent: <span style={{ color: 'var(--accent)' }}>set_alarm</span><span style={{ color: D.t3 }}>(&quot;Push fix&quot;, 2h) · 280ms</span></>,
    <span style={{ color: 'var(--green)' }}>✓ Total: 740ms</span>,
  ];
  return (
    <section className="scanlines r-pad r-text-sm" style={{ position: 'relative', padding: '100px 48px 80px', minHeight: '90vh',
      display: 'flex', flexDirection: 'column', alignItems: 'center', background: D.bg, opacity: m ? 1 : 0, transition: 'opacity 0.4s' }}>
      <div style={{ textAlign: 'center', maxWidth: 720, zIndex: 3 }}>
        <h1 style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 64, lineHeight: 1.06, letterSpacing: '-0.03em', marginBottom: 20 }}>
          Hackable voice assistant for&nbsp;developers.</h1>
        <p style={{ fontSize: 18, color: D.t2, marginBottom: 40, lineHeight: 1.7, maxWidth: 560, margin: '0 auto 40px' }}>
          Open source. Self-hosted. Infinitely extensible. Fork it, extend it, make it yours.</p>
        <div style={{ display: 'flex', gap: 14, justifyContent: 'center', flexWrap: 'wrap' }}>
          <DCopy text="pip install nudge-ai" label="$ pip install nudge-ai" />
          <a href="https://github.com/chiruu12/nudge" target="_blank" rel="noopener" style={{ display: 'inline-flex', alignItems: 'center', gap: 8,
            padding: '14px 24px', borderRadius: 8, border: `1px solid ${D.border}`, fontSize: 14, fontWeight: 500, color: D.t2, transition: 'all 0.2s' }}
            onMouseEnter={e => { e.currentTarget.style.borderColor = D.t3; e.currentTarget.style.color = D.t1; }}
            onMouseLeave={e => { e.currentTarget.style.borderColor = D.border; e.currentTarget.style.color = D.t2; }}>⭐ Star on GitHub</a></div>
      </div>
      <div style={{ marginTop: 56, width: '100%', maxWidth: 620, zIndex: 3, border: `1px solid ${D.border}`, borderRadius: 12, overflow: 'hidden', background: D.bg }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '12px 16px', borderBottom: `1px solid ${D.border}`, background: D.bg2 }}>
          {['#EF4444','#F59E0B','#22C55E'].map(c => <div key={c} style={{ width: 12, height: 12, borderRadius: '50%', background: c }} />)}
          <span style={{ marginLeft: 12, fontFamily: 'var(--mono)', fontSize: 12, color: D.t3 }}>nudge · session</span></div>
        <div style={{ padding: '20px 24px', fontFamily: 'var(--mono)', fontSize: 14, lineHeight: 2 }}>
          {lines.map((l, i) => <div key={i} style={{ minHeight: l === '' ? 12 : 'auto' }}>{l}</div>)}
          <span className="cursor-blink" style={{ color: D.t3 }}>█</span></div>
      </div>
    </section>
  );
}

/* ═══ SOCIAL PROOF ═══ */
function DevSocial() {
  return <section style={{ padding: '40px 48px', background: D.bg2, borderTop: `1px solid ${D.border}`, borderBottom: `1px solid ${D.border}` }}>
    <div style={{ maxWidth: 800, margin: '0 auto', textAlign: 'center' }}>
      <p style={{ fontSize: 13, color: D.t3, marginBottom: 20, letterSpacing: 0.5 }}>Works with any LLM provider. Or bring your own.</p>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 40, flexWrap: 'wrap' }}>
        {['Groq', 'OpenAI', 'Anthropic', 'Ollama', 'LM Studio', 'Fireworks'].map(p =>
          <span key={p} style={{ fontFamily: 'var(--mono)', fontSize: 14, color: D.t2, fontWeight: 500 }}>{p}</span>
        )}</div>
    </div>
  </section>;
}

/* ═══ PIPELINE ═══ */
function DevPipeline() {
  const [ref, vis] = dV(0.3);
  const stages = [
    { icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><rect x="9" y="3" width="6" height="10" rx="3" stroke="var(--accent)" strokeWidth="1.5"/><path d="M6 12a6 6 0 0012 0" stroke="var(--accent)" strokeWidth="1.5" fill="none"/></svg>, l: 'Voice', ms: 340, tag: 'STT' },
    { icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="var(--accent)" strokeWidth="1.5"/><circle cx="12" cy="12" r="2" fill="var(--accent)"/></svg>, l: 'Intent', ms: 120, tag: 'NLU' },
    { icon: <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><polyline points="5 13 9 17 19 7" stroke="var(--accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>, l: 'Action', ms: 280, tag: 'ACT' },
  ];
  const counts = stages.map(s => dC(s.ms, 900, vis));
  return (
    <section ref={ref} style={{ padding: '100px 48px', background: D.bg }}>
      <div style={{ maxWidth: 800, margin: '0 auto', textAlign: 'center' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 16, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Sub-second pipeline</h2>
        <p style={{ color: D.t2, marginBottom: 56, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>Every step measured. Every millisecond earned.</p>
        <div className="r-pipeline" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0 }}>
          {stages.map((s, i) => (
            <React.Fragment key={i}>
              <div style={{ background: D.card, border: `1px solid ${D.border}`, borderRadius: 16, padding: '32px 28px', minWidth: 160,
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
                opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(16px)', transition: `all 0.5s var(--ease) ${i * 0.1}s` }}>
                {s.icon}
                <div style={{ fontFamily: 'var(--heading)', fontWeight: 600, fontSize: 17 }}>{s.l}</div>
                <div style={{ fontFamily: 'var(--mono)', fontSize: 24, color: 'var(--accent)', fontWeight: 700 }}>{counts[i]}ms</div>
                <div style={{ fontSize: 12, color: D.t3 }}>{s.tag}</div></div>
              {i < stages.length - 1 && <div className="pipe-conn" />}
            </React.Fragment>))}</div>
      </div>
    </section>
  );
}

/* ═══ FEATURES ═══ */
function DevFeatures() {
  const [ref, vis] = dV(0.15);
  const feats = [
    { t: 'Fork-Friendly', d: 'MIT licensed. Read every line, fork it, ship your own version. No black boxes.', code: 'git clone && make it yours' },
    { t: 'Plugin Architecture', d: 'Custom intents, custom agents. Extend the pipeline however you want.', code: 'nudge plugin add my-intent' },
    { t: 'YAML Config', d: 'One file controls everything. No GUI required. Version control your setup.', code: 'vim ~/.nudge/config.yaml' },
    { t: 'Soul System', d: 'Teach Nudge YOUR language. "Later" means what you mean. Not a dictionary.', code: 'nudge soul add "later=evening"' },
    { t: '6 Providers + BYOLLM', d: 'Groq, OpenAI, Anthropic, Ollama, LM Studio, Fireworks. Or plug in your own.', code: 'nudge config --provider ollama' },
    { t: 'Full Offline Mode', d: 'Air-gapped? No problem. Run everything locally with Ollama. Zero network.', code: 'nudge preset offline' },
  ];
  return (
    <section id="d-features" ref={ref} style={{ padding: '100px 48px', background: D.bg2 }}>
      <div style={{ maxWidth: 900, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Built to be extended</h2>
        <p style={{ color: D.t2, marginBottom: 48, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>Not a product. A platform. Every piece is yours to modify.</p>
        <div className="r-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 16 }}>
          {feats.map((f, i) => (
            <div key={i} style={{ background: D.card, border: `1px solid ${D.border}`, borderRadius: 14, padding: '28px 24px',
              display: 'flex', flexDirection: 'column', gap: 10,
              opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(14px)', transition: `all 0.5s var(--ease) ${i * 0.06}s` }}>
              <h3 style={{ fontFamily: 'var(--heading)', fontSize: 18, fontWeight: 600 }}>{f.t}</h3>
              <p style={{ fontSize: 14, color: D.t2, lineHeight: 1.6, flex: 1 }}>{f.d}</p>
              <div style={{ fontFamily: 'var(--mono)', fontSize: 12, color: D.t1, padding: '10px 14px', background: D.bg, borderRadius: 8, border: `1px solid ${D.border}` }}>
                <span style={{ color: D.t3 }}>$ </span>{f.code}</div></div>))}</div>
      </div>
    </section>
  );
}

/* ═══ SKILLS ═══ */
function DevSkills() {
  const [ref, vis] = dV(0.2);
  const skills = [
    { t: 'IDE Knowledge Transfer', d: 'Connect to Cursor, Claude Code, or Codex. Nudge learns your projects, codebase patterns, and dev context.', tag: 'IDE' },
    { t: 'Writing Style Calibration', d: 'Skills analyze how you write: commit messages, docs, emails. Adapt Nudge\'s output to match your voice.', tag: 'STYLE' },
    { t: 'Project Context Engine', d: 'What are you working on? Skills ask about your projects, priorities, and workflow to give smarter suggestions.', tag: 'CTX' },
    { t: 'Personal Vocabulary', d: 'Teach Nudge your team names, acronyms, project codenames. It remembers. You don\'t have to repeat yourself.', tag: 'VOCAB' },
  ];
  return (
    <section id="d-skills" ref={ref} style={{ padding: '100px 48px', background: D.bg }}>
      <div style={{ maxWidth: 800, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>
          Nudge Skills</h2>
        <p style={{ color: D.t2, marginBottom: 48, maxWidth: 560, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>
          Knowledge transfer from your favorite tools. Nudge learns how you work so it can work like you.</p>
        <div className="r-grid-2" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          {skills.map((s, i) => (
            <div key={i} style={{ background: D.card, border: `1px solid ${D.border}`, borderRadius: 14, padding: '28px 24px',
              opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(14px)', transition: `all 0.5s var(--ease) ${i * 0.08}s` }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
                <span style={{ fontFamily: 'var(--mono)', fontSize: 11, color: 'var(--accent)', padding: '3px 8px', background: 'rgba(255,107,53,0.08)', borderRadius: 4 }}>{s.tag}</span>
                <h3 style={{ fontFamily: 'var(--heading)', fontSize: 17, fontWeight: 600 }}>{s.t}</h3></div>
              <p style={{ fontSize: 14, color: D.t2, lineHeight: 1.6 }}>{s.d}</p></div>
          ))}</div>
        <p style={{ fontFamily: 'var(--mono)', fontSize: 13, color: D.t3, marginTop: 24 }}>
          Skills are included free with self-managed setup. Managed skills available with Pro.</p>
      </div>
    </section>
  );
}

/* ═══ COMPARISON ═══ */
function DevCompare() {
  const [ref, vis] = dV(0.2);
  const rows = [
    { f: 'Open source', n: true, s: false, a: false, g: false },
    { f: 'Self-hosted', n: true, s: false, a: false, g: false },
    { f: 'Sub-second', n: true, s: false, a: false, g: false },
    { f: 'BYOLLM', n: true, s: false, a: false, g: false },
    { f: 'Custom intents', n: true, s: false, a: false, g: false },
    { f: 'Offline mode', n: true, s: false, a: false, g: false },
  ];
  const ck = <span style={{ color: 'var(--green)' }}>✓</span>, cr = <span style={{ color: '#444' }}>✗</span>;
  return (
    <section id="d-compare" ref={ref} style={{ padding: '100px 48px', background: D.bg2 }}>
      <div style={{ maxWidth: 700, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 16, textAlign: 'center', opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Why Nudge</h2>
        <p style={{ textAlign: 'center', color: D.t2, marginBottom: 48, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>Every other voice assistant is a black box. This one is yours.</p>
        <div style={{ background: D.card, border: `1px solid ${D.border}`, borderRadius: 14, overflow: 'hidden',
          opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(16px)', transition: 'all 0.6s var(--ease)' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '2fr repeat(4,1fr)', padding: '16px 24px', fontSize: 13, borderBottom: `1px solid ${D.border}`, fontSize: 13, fontWeight: 600 }}>
            <span style={{ color: D.t3 }}>Feature</span>
            <span style={{ color: 'var(--accent)', textAlign: 'center' }}>Nudge</span>
            {['Siri', 'Alexa', 'Google'].map(n => <span key={n} style={{ color: D.t3, textAlign: 'center' }}>{n}</span>)}</div>
          {rows.map((r, i) => (
            <div key={i} style={{ display: 'grid', gridTemplateColumns: '2fr repeat(4,1fr)', padding: '14px 24px',
              borderBottom: i < rows.length - 1 ? `1px solid ${D.border}` : 'none', fontSize: 14, alignItems: 'center' }}>
              <span style={{ color: D.t1 }}>{r.f}</span>
              <span style={{ textAlign: 'center' }}>{r.n ? ck : cr}</span>
              <span style={{ textAlign: 'center' }}>{r.s ? ck : cr}</span>
              <span style={{ textAlign: 'center' }}>{r.a ? ck : cr}</span>
              <span style={{ textAlign: 'center' }}>{r.g ? ck : cr}</span></div>))}</div>
      </div>
    </section>
  );
}

/* ═══ PRICING ═══ */
function DevPricing() {
  const [ref, vis] = dV(0.2);
  const tiers = [
    { name: 'Free', price: '$0', sub: 'forever', desc: 'Self-managed. Full power.', accent: false,
      items: ['All core features', 'Bring your own API keys', '6 LLM providers', 'Full offline mode', 'Skills (self-setup)', 'Community support'],
      cta: 'pip install nudge-ai' },
    { name: 'Pro', price: '$9', sub: '/mo', desc: 'We handle the infra. You ship.', accent: true,
      items: ['Everything in Free', 'Managed STT & LLM', 'No API keys needed', 'Usage dashboard', 'Managed Skills', 'Priority support'],
      cta: 'Get Pro' },
    { name: 'Team', price: 'Custom', sub: '', desc: 'For teams that ship together.', accent: false,
      items: ['Everything in Pro', 'Team management', 'Shared knowledge base', 'Admin controls', 'SSO & audit logs', 'Dedicated support'],
      cta: 'Contact us' },
  ];
  return (
    <section id="d-pricing" ref={ref} style={{ padding: '100px 48px', background: D.bg }}>
      <div style={{ maxWidth: 960, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, textAlign: 'center', opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>
          Don't want to manage usage?</h2>
        <p style={{ textAlign: 'center', color: D.t2, marginBottom: 48, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>
          Free forever, or let us handle the heavy lifting.</p>
        <div className="r-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 16 }}>
          {tiers.map((t, i) => (
            <div key={i} style={{ background: D.card, border: t.accent ? '1.5px solid var(--accent)' : `1px solid ${D.border}`, borderRadius: 16, padding: '32px 28px',
              boxShadow: t.accent ? '0 0 40px rgba(255,107,53,0.06)' : 'none', position: 'relative',
              opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(16px)', transition: `all 0.5s var(--ease) ${i * 0.08}s` }}>
              {t.accent && <div style={{ position: 'absolute', top: -11, left: '50%', transform: 'translateX(-50%)',
                background: 'var(--accent)', color: '#fff', fontSize: 11, fontWeight: 600, padding: '3px 14px', borderRadius: 20 }}>Popular</div>}
              <div style={{ fontFamily: 'var(--heading)', fontSize: 20, fontWeight: 700, marginBottom: 4 }}>{t.name}</div>
              <div style={{ marginBottom: 4 }}>
                <span style={{ fontFamily: 'var(--heading)', fontSize: 36, fontWeight: 800 }}>{t.price}</span>
                <span style={{ fontSize: 14, color: D.t3 }}>{t.sub}</span></div>
              <p style={{ fontSize: 14, color: D.t2, marginBottom: 24 }}>{t.desc}</p>
              {t.items.map((it, j) => (
                <div key={j} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', fontSize: 13, color: D.t1,
                  borderTop: j > 0 ? `1px solid ${D.border}` : 'none' }}>
                  <span style={{ color: 'var(--green)' }}>✓</span>{it}</div>))}
              <button style={{ marginTop: 20, width: '100%', padding: '12px', borderRadius: 8, fontSize: 14, fontWeight: 600,
                fontFamily: t.accent ? 'var(--body)' : 'var(--mono)',
                background: t.accent ? 'var(--accent)' : 'transparent',
                color: t.accent ? '#fff' : D.t2,
                border: t.accent ? 'none' : `1px solid ${D.border}`,
                transition: 'all 0.2s' }}>{t.cta}</button></div>))}</div>
      </div>
    </section>
  );
}

/* ═══ TESTIMONIALS ═══ */
function DevTestimonials() {
  const [ref, vis] = dV(0.2);
  const quotes = [
    { q: 'Sub-second latency changed everything. Voice is now part of my dev flow.', a: '@karthik_dev', r: 'ML Engineer · Stealth AI' },
    { q: 'Fork-friendly architecture. I extended the pipeline with a custom agent in an afternoon.', a: '@maya_codes', r: 'Full-Stack · YC S24' },
    { q: 'Running fully offline with Ollama. Open source that actually respects privacy.', a: '@privacy_eng', r: 'Security Eng · Cloudflare' },
  ];
  return (
    <section ref={ref} style={{ padding: '100px 48px', background: D.bg2 }}>
      <div style={{ maxWidth: 900, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 48, textAlign: 'center', opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Developers love it</h2>
        <div className="r-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 16 }}>
          {quotes.map((q, i) => (
            <div key={i} style={{ background: D.card, border: `1px solid ${D.border}`, borderRadius: 14, padding: '28px 24px',
              opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(12px)', transition: `all 0.5s var(--ease) ${i * 0.1}s` }}>
              <p style={{ fontSize: 15, color: D.t1, lineHeight: 1.7, marginBottom: 20 }}>"{q.q}"</p>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 36, height: 36, borderRadius: '50%', background: '#1A1A1A', border: `1px solid ${D.border}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: 'var(--mono)', fontSize: 14, color: 'var(--accent)' }}>
                  {q.a[1].toUpperCase()}</div>
                <div><div style={{ fontFamily: 'var(--mono)', fontSize: 13, color: 'var(--accent)' }}>{q.a}</div>
                  <div style={{ fontSize: 12, color: D.t3 }}>{q.r}</div></div></div></div>))}</div>
      </div>
    </section>
  );
}

/* ═══ FAQ ═══ */
function DevFAQ() {
  const [ref, vis] = dV(0.2);
  const [open, setOpen] = useState(null);
  const faqs = [
    { q: 'Is it really free?', a: 'Yes. The core is MIT licensed and free forever. Pro is for those who want managed infrastructure.' },
    { q: 'What are Skills?', a: 'Skills sync context from your IDE (Cursor, Claude Code, Codex). They learn your projects, writing style, and vocabulary.' },
    { q: 'Can I run it fully offline?', a: 'Yes. Use the offline preset with Ollama. Zero network dependency.' },
    { q: 'What\'s the difference between Free and Pro?', a: 'Free: you bring your own API keys and manage providers. Pro: we handle STT, LLM, and give you a usage dashboard.' },
    { q: 'Can I extend it?', a: 'Absolutely. Custom intents, custom agents, plugin architecture. It\'s designed to be forked.' },
  ];
  return (
    <section ref={ref} style={{ padding: '100px 48px', background: D.bg }}>
      <div style={{ maxWidth: 640, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 40, textAlign: 'center', opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>FAQ</h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, opacity: vis ? 1 : 0, transition: 'opacity 0.5s ease 0.1s' }}>
          {faqs.map((f, i) => (
            <div key={i} style={{ background: D.card, border: `1px solid ${D.border}`, borderRadius: 12, overflow: 'hidden' }}>
              <button onClick={() => setOpen(open === i ? null : i)} style={{ width: '100%', padding: '18px 24px', textAlign: 'left', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                fontSize: 15, fontWeight: 600, color: D.t1, background: 'transparent' }}>
                <span>{f.q}</span><span style={{ color: D.t3, fontSize: 18, transition: 'transform 0.2s', transform: open === i ? 'rotate(45deg)' : 'none' }}>+</span></button>
              {open === i && <div style={{ padding: '0 24px 18px', fontSize: 15, color: D.t2, lineHeight: 1.7 }}>{f.a}</div>}</div>))}</div>
      </div>
    </section>
  );
}

/* ═══ CTA ═══ */
function DevCTA() {
  const [ref, vis] = dV(0.3);
  return (
    <section ref={ref} style={{ padding: '100px 48px 48px', background: D.bg2, textAlign: 'center' }}>
      <div style={{ maxWidth: 500, margin: '0 auto', opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 44, marginBottom: 32, letterSpacing: '-0.02em' }}>Ready to ship faster?</h2>
        <DCopy text="pip install nudge-ai" label="$ pip install nudge-ai" />
        <div style={{ marginTop: 56, fontSize: 13, color: D.t3 }}>open source · MIT licensed · built with ❤ by chiruu12</div></div>
    </section>
  );
}

function DevPage({ mounted, onSwitch }) {
  const [showDL, setShowDL] = React.useState(false);
  return <div style={{ background: D.bg, minHeight: '100vh' }}>
    <DevNav onSwitch={onSwitch} m={mounted} />
    <DevHero m={mounted} />
    <DevSocial />
    <DevPipeline />
    <DevFeatures />
    <DevSkills />
    <DevCompare />
    <DevPricing />
    <DevTestimonials />
    <DevFAQ />
    <DevCTA />
  </div>;
}

Object.assign(window, { DevPage });
