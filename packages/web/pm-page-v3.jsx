const { useState, useEffect, useRef, useMemo } = React;

function pV(th = 0.2) {
  const r = useRef(null); const [v, setV] = useState(false);
  useEffect(() => { const el = r.current; if (!el) return;
    const o = new IntersectionObserver(([e]) => { if (e.isIntersecting) { setV(true); o.disconnect(); } }, { threshold: th });
    o.observe(el); return () => o.disconnect(); }, []); return [r, v];
}

const P = { bg: '#FAFAFA', bg2: '#fff', card: '#fff', border: '#E8EAF0', t1: '#1A1A2E', t2: '#4A4A6A', t3: '#9CA3AF' };

function PC({ children, style: s, glow }) {
  return <div style={{ background: P.card, borderRadius: 16, padding: 24, border: `1px solid ${glow ? 'var(--accent)' : P.border}`,
    boxShadow: glow ? '0 0 30px rgba(255,107,53,0.08)' : '0 2px 12px rgba(0,0,0,0.04)', transition: 'all 0.2s', ...s }}>{children}</div>;
}

function PMWave({ opacity = 0.06, count = 50 }) {
  const bars = useMemo(() => Array.from({ length: count }, (_, i) => ({ h: 20 + Math.sin(i * 0.4) * 20 + (i % 5) * 3, d: (i * 0.06).toFixed(2), dur: (1.4 + (i % 4) * 0.3).toFixed(1) })), [count]);
  return <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, display: 'flex', alignItems: 'flex-end', justifyContent: 'center', gap: 3, height: 80, overflow: 'hidden', pointerEvents: 'none' }}>
    {bars.map((b, i) => <div key={i} style={{ width: 3, borderRadius: 3, height: `${b.h}%`, background: 'var(--accent)', opacity, animation: `waveBar ${b.dur}s ease-in-out ${b.d}s infinite alternate` }} />)}</div>;
}

/* ═══ NAV ═══ */
function PMNav({ onSwitch, m }) {
  return <nav style={{ position: 'sticky', top: 0, zIndex: 50, display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    padding: '0 48px', height: 64, background: 'rgba(250,250,250,0.9)', backdropFilter: 'blur(16px)',
    borderBottom: `1px solid ${P.border}`, fontSize: 14, color: P.t2,
    opacity: m ? 1 : 0, transform: m ? 'none' : 'translateY(-8px)', transition: 'all 0.6s var(--ease)' }}>
    <div style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 20, color: P.t1, display: 'flex', alignItems: 'center', gap: 8, letterSpacing: '-0.02em' }}>
      <span style={{ color: 'var(--accent)', fontSize: 10 }}>●</span> nudge</div>
    <div style={{ display: 'flex', gap: 32, fontWeight: 500 }}>
      {[['Features', '#p-feat'], ['Skills', '#p-skills'], ['Pricing', '#p-price']].map(([l, h]) =>
        <a key={l} href={h} style={{ color: P.t2, transition: 'color 0.2s' }}
          onMouseEnter={e => e.currentTarget.style.color = P.t1} onMouseLeave={e => e.currentTarget.style.color = P.t2}>{l}</a>)}</div>
    <button onClick={onSwitch} style={{ fontSize: 13, color: P.t3, fontFamily: 'var(--mono)', padding: '6px 16px', border: `1px solid ${P.border}`, borderRadius: 8, transition: 'all 0.2s' }}
      onMouseEnter={e => { e.currentTarget.style.borderColor = 'var(--accent)'; e.currentTarget.style.color = P.t1; }}
      onMouseLeave={e => { e.currentTarget.style.borderColor = P.border; e.currentTarget.style.color = P.t3; }}>Dev ⌨</button></nav>;
}

/* ═══ HERO ═══ */
function PMHero({ m }) {
  const [showDL, setShowDL] = React.useState(false);
  return (
    <section className="r-pad r-text-sm" style={{ position: 'relative', overflow: 'hidden', padding: '100px 48px 80px', minHeight: '90vh',
      display: 'flex', flexDirection: 'column', alignItems: 'center', background: P.bg }}>
      <PMWave opacity={0.05} />
      <div style={{ textAlign: 'center', maxWidth: 640, zIndex: 2,
        opacity: m ? 1 : 0, transform: m ? 'none' : 'translateY(24px) scale(0.97)', transition: 'all 0.7s var(--ease)' }}>
        <h1 style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 64, lineHeight: 1.08, letterSpacing: '-0.03em', marginBottom: 20, color: P.t1 }}>
          Your brain has better things to&nbsp;do.</h1>
        <p style={{ fontSize: 19, color: P.t2, lineHeight: 1.7, maxWidth: 480, margin: '0 auto 40px' }}>
          Voice-first assistant that captures, organizes, and remembers. So you can focus on what actually matters.</p>
        <div style={{ display: 'flex', gap: 14, justifyContent: 'center', flexWrap: 'wrap' }}>
          <button style={{ padding: '16px 40px', borderRadius: 14, background: 'var(--accent)', color: '#fff', fontSize: 16, fontWeight: 600,
            boxShadow: '0 4px 20px rgba(255,107,53,0.25)', transition: 'transform 0.15s, box-shadow 0.2s' }}
            onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 6px 28px rgba(255,107,53,0.35)'; }}
            onMouseLeave={e => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = '0 4px 20px rgba(255,107,53,0.25)'; }}
            onClick={() => setShowDL(true)}>Download for Mac</button>
          <DownloadPopover show={showDL} onClose={() => setShowDL(false)} dark={false} />
          <button style={{ padding: '16px 28px', borderRadius: 14, border: `1px solid ${P.border}`, fontSize: 16, fontWeight: 500, color: P.t2, transition: 'all 0.2s', background: 'transparent' }}
            onMouseEnter={e => { e.currentTarget.style.borderColor = P.t3; e.currentTarget.style.color = P.t1; }}
            onMouseLeave={e => { e.currentTarget.style.borderColor = P.border; e.currentTarget.style.color = P.t2; }}>See it in action</button></div>
      </div>
      <div style={{ marginTop: 56, width: '100%', maxWidth: 560, zIndex: 2,
        opacity: m ? 1 : 0, transform: m ? 'none' : 'translateY(32px) scale(0.96)', transition: 'all 0.7s var(--ease) 0.12s' }}>
        <PC style={{ padding: 20, borderRadius: 20, boxShadow: '0 8px 40px rgba(0,0,0,0.08)' }}>
          <div className="r-grid-3" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr auto', gap: 14 }}>
            <PC style={{ padding: '14px 16px', background: '#F8F9FC', border: 'none', boxShadow: 'none', borderRadius: 12 }}>
              <div style={{ fontSize: 10, fontFamily: 'var(--mono)', color: P.t3, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 1 }}>tasks</div>
              {[{ d: true, t: 'Standup' }, { d: false, t: 'Review PR' }, { d: false, t: 'Email team' }].map((x, i) =>
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 13, lineHeight: 2, color: x.d ? P.t3 : P.t1, textDecoration: x.d ? 'line-through' : 'none' }}>
                  <span style={{ color: x.d ? 'var(--accent)' : P.t3, fontSize: 11 }}>{x.d ? '■' : '□'}</span>{x.t}</div>)}</PC>
            <PC style={{ padding: '14px 16px', background: '#F8F9FC', border: 'none', boxShadow: 'none', borderRadius: 12 }}>
              <div style={{ fontSize: 10, fontFamily: 'var(--mono)', color: P.t3, marginBottom: 8, textTransform: 'uppercase', letterSpacing: 1 }}>alarms</div>
              {[{ time: '3:00 PM', l: 'Call dentist' }, { time: '5:30 PM', l: 'Team sync' }].map((a, i) =>
                <div key={i} style={{ marginBottom: 10 }}>
                  <div style={{ fontFamily: 'var(--mono)', fontSize: 12, color: 'var(--accent)' }}>{a.time}</div>
                  <div style={{ fontSize: 13, color: P.t2 }}>{a.l}</div></div>)}</PC>
            <PC style={{ padding: '14px 16px', background: '#F8F9FC', border: 'none', boxShadow: 'none', borderRadius: 12, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8, minWidth: 72 }}>
              <div style={{ width: 44, height: 44, borderRadius: '50%', background: 'var(--accent)', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 4px 16px rgba(255,107,53,0.3)' }}>
                <svg width="18" height="18" viewBox="0 0 16 16" fill="none"><rect x="6" y="2" width="4" height="8" rx="2" fill="#fff"/><path d="M4 8a4 4 0 008 0" stroke="#fff" strokeWidth="1.5" fill="none"/><line x1="8" y1="13" x2="8" y2="15" stroke="#fff" strokeWidth="1.5"/></svg></div>
              <span style={{ fontSize: 10, color: P.t3 }}>speak</span></PC></div>
          <div style={{ marginTop: 14, padding: '12px 16px', background: '#F8F9FC', borderRadius: 12, fontStyle: 'italic', fontSize: 14, color: P.t2 }}>
            "remind me to call the dentist at 3pm"</div></PC></div>
    </section>
  );
}

/* ═══ SPEED ═══ */
function PMSpeed() {
  const [ref, vis] = pV(0.3);
  return (
    <section ref={ref} style={{ padding: '80px 48px', background: P.bg2, borderTop: `1px solid ${P.border}`, borderBottom: `1px solid ${P.border}` }}>
      <div style={{ maxWidth: 700, margin: '0 auto', opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, textAlign: 'center', marginBottom: 48, color: P.t1 }}>4× faster than typing</h2>
        <div className="r-grid-2" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: P.t3, marginBottom: 12, textTransform: 'uppercase', letterSpacing: 1 }}>Keyboard</div>
            <div style={{ fontFamily: 'var(--heading)', fontSize: 48, fontWeight: 800, color: P.t3, marginBottom: 8 }}>~30s</div>
            <div style={{ height: 8, background: '#E5E7EB', borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ height: '100%', background: '#D1D5DB', borderRadius: 4, width: vis ? '25%' : '0%', transition: 'width 1.2s ease-out' }} /></div>
            <div style={{ fontSize: 13, color: P.t3, marginTop: 8 }}>Open app → type → save</div></div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--accent)', marginBottom: 12, textTransform: 'uppercase', letterSpacing: 1 }}>With Nudge</div>
            <div style={{ fontFamily: 'var(--heading)', fontSize: 48, fontWeight: 800, color: 'var(--accent)', marginBottom: 8 }}>~3s</div>
            <div style={{ height: 8, background: 'rgba(255,107,53,0.1)', borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ height: '100%', background: 'var(--accent)', borderRadius: 4, width: vis ? '100%' : '0%', transition: 'width 1s ease-out 0.3s' }} /></div>
            <div style={{ fontSize: 13, color: P.t2, marginTop: 8 }}>Just speak it</div></div></div>
      </div>
    </section>
  );
}

/* ═══ HOW IT WORKS ═══ */
function PMPipeline() {
  const [ref, vis] = pV(0.3);
  const steps = [
    { icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="none"><rect x="9" y="3" width="6" height="10" rx="3" stroke="var(--accent)" strokeWidth="1.5"/><path d="M6 12a6 6 0 0012 0" stroke="var(--accent)" strokeWidth="1.5" fill="none"/></svg>, l: 'You speak', s: 'Just talk naturally' },
    { icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="none"><path d="M3 12h2l3-6 4 12 3-8 2 4h4" stroke="var(--accent)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>, l: 'We listen', s: 'Instant transcription' },
    { icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="var(--accent)" strokeWidth="1.5"/><circle cx="12" cy="12" r="2" fill="var(--accent)"/></svg>, l: 'We understand', s: 'Your words, your way' },
    { icon: <svg width="28" height="28" viewBox="0 0 24 24" fill="none"><polyline points="5 13 9 17 19 7" stroke="var(--accent)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>, l: "It's done", s: 'Zero effort' },
  ];
  return (
    <section id="p-how" ref={ref} style={{ padding: '100px 48px', background: P.bg }}>
      <div style={{ maxWidth: 800, margin: '0 auto', textAlign: 'center' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, color: P.t1, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>How it works</h2>
        <p style={{ color: P.t2, marginBottom: 56, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>Voice to action, under a second.</p>
        <div className="r-pipeline" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 0 }}>
          {steps.map((s, i) => (
            <React.Fragment key={i}>
              <PC style={{ padding: '28px 20px', minWidth: 140, textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14,
                opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(16px)', transition: `all 0.5s var(--ease) ${i * 0.1}s` }}>
                {s.icon}
                <div style={{ fontFamily: 'var(--heading)', fontWeight: 600, fontSize: 16, color: P.t1 }}>{s.l}</div>
                <div style={{ fontSize: 13, color: P.t3 }}>{s.s}</div></PC>
              {i < steps.length - 1 && <div className="pipe-conn" style={{ opacity: vis ? 1 : 0, transition: `opacity 0.4s ease ${0.2 + i * 0.1}s` }} />}
            </React.Fragment>))}</div>
      </div>
    </section>
  );
}

/* ═══ FEATURES ═══ */
function PMFeatures() {
  const [ref, vis] = pV(0.15);
  const feats = [
    { t: 'Never forget a task', d: 'Speak and it\'s captured. No app switching, no typing, no forgetting at the end of a meeting.', q: 'remind me to prep for standup' },
    { t: 'Alarms that get you', d: '"3pm", "after lunch", "before the standup". Nudge understands time the way you say it.', q: 'call the dentist at 3pm' },
    { t: 'Your second brain', d: 'Save decisions, context, notes. All by voice. Recall instantly when the question comes up.', q: 'save: budget approved by CFO' },
    { t: 'Learns your language', d: '"High priority" means what YOU mean. "The team" means YOUR team. Nudge adapts.', q: 'high priority = before end of day' },
    { t: 'Always one hotkey away', d: 'Works system-wide on Mac. In a meeting? In Slack? One shortcut. Always there.', q: null },
    { t: 'Zero setup', d: 'Install, speak, done. No configuration required. Free AI providers included.', q: null },
  ];
  return (
    <section id="p-feat" ref={ref} style={{ padding: '100px 48px', background: P.bg2 }}>
      <div style={{ maxWidth: 900, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, color: P.t1, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>What you get</h2>
        <p style={{ color: P.t2, marginBottom: 48, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>Everything you need to stop managing and start doing.</p>
        <div className="r-grid-2" style={{ display: 'grid', gridTemplateColumns: 'repeat(2,1fr)', gap: 16 }}>
          {feats.map((f, i) => (
            <PC key={i} style={{ opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(16px)', transition: `all 0.5s var(--ease) ${i * 0.06}s` }}>
              <h3 style={{ fontFamily: 'var(--heading)', fontSize: 18, fontWeight: 600, color: P.t1, marginBottom: 8 }}>{f.t}</h3>
              <p style={{ fontSize: 15, color: P.t2, lineHeight: 1.6, marginBottom: f.q ? 14 : 0 }}>{f.d}</p>
              {f.q && <div style={{ fontSize: 13, color: 'var(--accent)', fontStyle: 'italic', padding: '10px 16px', background: 'rgba(255,107,53,0.04)', borderRadius: 10 }}>"{f.q}"</div>}
            </PC>))}</div>
      </div>
    </section>
  );
}

/* ═══ SKILLS ═══ */
function PMSkills() {
  const [ref, vis] = pV(0.2);
  const skills = [
    { t: 'Writing Style', d: 'Nudge learns how you write. Emails, messages, notes. Everything it produces sounds like you.', tag: 'STYLE' },
    { t: 'Personal Context', d: 'Who\'s on your team? What projects are you running? Skills ask once, remember always.', tag: 'CTX' },
    { t: 'Communication Preferences', d: 'How do you refer to yourself? Formal or casual? Nudge matches your tone.', tag: 'TONE' },
    { t: 'Project Knowledge', d: 'What are you working on this quarter? Skills connect the dots so Nudge gives smarter suggestions.', tag: 'PROJ' },
  ];
  return (
    <section id="p-skills" ref={ref} style={{ padding: '100px 48px', background: P.bg }}>
      <div style={{ maxWidth: 800, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, color: P.t1, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Nudge Skills</h2>
        <p style={{ color: P.t2, marginBottom: 48, maxWidth: 520, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>
          The more Nudge knows about you, the less you need to explain. Skills learn how you work.</p>
        <div className="r-grid-2" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          {skills.map((s, i) => (
            <PC key={i} style={{ opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(14px)', transition: `all 0.5s var(--ease) ${i * 0.08}s` }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
                <span style={{ fontSize: 11, color: 'var(--accent)', padding: '3px 10px', background: 'rgba(255,107,53,0.06)', borderRadius: 6, fontWeight: 600 }}>{s.tag}</span>
                <h3 style={{ fontFamily: 'var(--heading)', fontSize: 17, fontWeight: 600, color: P.t1 }}>{s.t}</h3></div>
              <p style={{ fontSize: 14, color: P.t2, lineHeight: 1.6 }}>{s.d}</p></PC>))}</div>
      </div>
    </section>
  );
}

/* ═══ INTEGRATIONS ═══ */
function PMIntegrations() {
  const [ref, vis] = pV(0.2);
  const items = [
    { name: 'Slack', desc: 'Voice commands right in your channels.', status: 'Coming soon' },
    { name: 'WhatsApp', desc: 'Voice notes → structured tasks.', status: 'Coming soon' },
    { name: 'Calendar', desc: 'Voice-to-event, no clicks needed.', status: 'Coming soon' },
    { name: 'Email', desc: 'Compose and send by speaking.', status: 'Coming soon' },
  ];
  return (
    <section ref={ref} style={{ padding: '100px 48px', background: P.bg2 }}>
      <div style={{ maxWidth: 800, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, color: P.t1, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Integrations</h2>
        <p style={{ color: P.t2, marginBottom: 48, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>Nudge where you already work.</p>
        <div className="r-grid-2" style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 16 }}>
          {items.map((it, i) => (
            <PC key={i} style={{ textAlign: 'center', padding: '28px 16px',
              opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(12px)', transition: `all 0.5s var(--ease) ${i * 0.08}s` }}>
              <div style={{ fontFamily: 'var(--heading)', fontSize: 18, fontWeight: 600, color: P.t1, marginBottom: 8 }}>{it.name}</div>
              <p style={{ fontSize: 13, color: P.t2, lineHeight: 1.5, marginBottom: 12 }}>{it.desc}</p>
              <span style={{ fontSize: 11, fontWeight: 600, color: 'var(--accent)', padding: '4px 12px', background: 'rgba(255,107,53,0.06)', borderRadius: 20 }}>{it.status}</span>
            </PC>))}</div>
        <div style={{ textAlign: 'center', marginTop: 32, opacity: vis ? 1 : 0, transition: 'opacity 0.5s ease 0.4s' }}>
          <button style={{ padding: '12px 32px', borderRadius: 12, background: 'var(--accent)', color: '#fff', fontSize: 14, fontWeight: 600,
            boxShadow: '0 2px 12px rgba(255,107,53,0.2)', transition: 'transform 0.15s' }}
            onMouseEnter={e => e.currentTarget.style.transform = 'translateY(-1px)'}
            onMouseLeave={e => e.currentTarget.style.transform = 'none'}>Join the waitlist</button></div>
      </div>
    </section>
  );
}

/* ═══ PRICING ═══ */
function PMPricing() {
  const [ref, vis] = pV(0.2);
  const tiers = [
    { name: 'Free', price: '$0', sub: 'forever', desc: 'Get started, no strings attached.', accent: false,
      items: ['All core features', 'Bring your own API keys', 'Basic Skills setup', 'Community support'],
      cta: 'Download free' },
    { name: 'Pro', price: '$9', sub: '/mo', desc: 'We handle the infra. You focus.', accent: true,
      items: ['Everything in Free', 'Managed STT & LLM', 'No API keys needed', 'Usage dashboard', 'Managed Skills', 'Priority support'],
      cta: 'Get Pro' },
    { name: 'Team', price: 'Custom', sub: '', desc: 'For teams that move together.', accent: false,
      items: ['Everything in Pro', 'Team management', 'Shared knowledge base', 'Admin controls', 'Dedicated support'],
      cta: 'Contact us' },
  ];
  return (
    <section id="p-price" ref={ref} style={{ padding: '100px 48px', background: P.bg }}>
      <div style={{ maxWidth: 960, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 12, textAlign: 'center', color: P.t1, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>
          Don't want to manage the tech?</h2>
        <p style={{ textAlign: 'center', color: P.t2, marginBottom: 48, opacity: vis ? 1 : 0, transition: 'opacity 0.6s ease 0.1s' }}>
          Start free. Upgrade when you want us to handle everything.</p>
        <div className="r-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 16 }}>
          {tiers.map((t, i) => (
            <PC key={i} glow={t.accent} style={{ padding: '32px 28px', position: 'relative',
              opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(16px)', transition: `all 0.5s var(--ease) ${i * 0.08}s` }}>
              {t.accent && <div style={{ position: 'absolute', top: -11, left: '50%', transform: 'translateX(-50%)',
                background: 'var(--accent)', color: '#fff', fontSize: 11, fontWeight: 600, padding: '3px 14px', borderRadius: 20 }}>Popular</div>}
              <div style={{ fontFamily: 'var(--heading)', fontSize: 20, fontWeight: 700, color: P.t1, marginBottom: 4 }}>{t.name}</div>
              <div style={{ marginBottom: 4 }}>
                <span style={{ fontFamily: 'var(--heading)', fontSize: 36, fontWeight: 800, color: P.t1 }}>{t.price}</span>
                <span style={{ fontSize: 14, color: P.t3 }}>{t.sub}</span></div>
              <p style={{ fontSize: 14, color: P.t2, marginBottom: 24 }}>{t.desc}</p>
              {t.items.map((it, j) => (
                <div key={j} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0', fontSize: 14, color: P.t1,
                  borderTop: j > 0 ? `1px solid ${P.border}` : 'none' }}>
                  <span style={{ color: 'var(--green)' }}>✓</span>{it}</div>))}
              <button style={{ marginTop: 20, width: '100%', padding: '12px', borderRadius: 10, fontSize: 14, fontWeight: 600,
                background: t.accent ? 'var(--accent)' : 'transparent', color: t.accent ? '#fff' : P.t2,
                border: t.accent ? 'none' : `1px solid ${P.border}`, transition: 'all 0.2s' }}>{t.cta}</button></PC>))}</div>
      </div>
    </section>
  );
}

/* ═══ TESTIMONIALS ═══ */
function PMTestimonials() {
  const [ref, vis] = pV(0.2);
  const quotes = [
    { q: 'I used to lose half my action items by the end of the day. Now I just speak them and they\'re captured.', n: 'Sarah M.', r: 'Product Lead', init: 'S' },
    { q: 'My team thought I had a secret assistant. I do. It\'s Nudge.', n: 'James K.', r: 'Eng Manager', init: 'J' },
    { q: 'Zero learning curve. Installed it Monday, my whole team was using it by Wednesday.', n: 'Maria L.', r: 'Director of Ops', init: 'M' },
  ];
  return (
    <section ref={ref} style={{ padding: '100px 48px', background: P.bg2 }}>
      <div style={{ maxWidth: 900, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 48, textAlign: 'center', color: P.t1, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Loved by teams</h2>
        <div className="r-grid-3" style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 16 }}>
          {quotes.map((q, i) => (
            <PC key={i} style={{ opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(12px)', transition: `all 0.5s var(--ease) ${i * 0.1}s` }}>
              <p style={{ fontSize: 15, color: P.t1, lineHeight: 1.7, marginBottom: 20 }}>"{q.q}"</p>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ width: 40, height: 40, borderRadius: '50%', background: 'rgba(255,107,53,0.08)', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 16, color: 'var(--accent)' }}>{q.init}</div>
                <div><div style={{ fontWeight: 600, color: P.t1, fontSize: 14 }}>{q.n}</div>
                  <div style={{ fontSize: 13, color: P.t3 }}>{q.r}</div></div></div></PC>))}</div>
      </div>
    </section>
  );
}

/* ═══ FAQ ═══ */
function PMFAQ() {
  const [ref, vis] = pV(0.2);
  const [open, setOpen] = useState(null);
  const faqs = [
    { q: 'Is it really free to start?', a: 'Yes. Free tier has all core features. Pro is for those who want managed infrastructure and no API keys.' },
    { q: 'What are Skills?', a: 'Skills learn your writing style, vocabulary, team context, and projects. The more Nudge knows, the less you explain.' },
    { q: 'When are Slack and WhatsApp coming?', a: 'Both are in development. Join the waitlist above and we\'ll notify you as soon as they\'re ready.' },
    { q: 'Is my data private?', a: 'Yes. Free tier runs everything locally. Pro routes through secure managed infrastructure.' },
    { q: 'What\'s the difference between Pro and Team?', a: 'Team adds shared knowledge bases, admin controls, and dedicated support for organizations.' },
  ];
  return (
    <section ref={ref} style={{ padding: '100px 48px', background: P.bg }}>
      <div style={{ maxWidth: 640, margin: '0 auto' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 700, fontSize: 36, marginBottom: 36, textAlign: 'center', color: P.t1, opacity: vis ? 1 : 0, transition: 'opacity 0.6s' }}>Questions?</h2>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10, opacity: vis ? 1 : 0, transition: 'opacity 0.5s ease 0.1s' }}>
          {faqs.map((f, i) => (
            <PC key={i} style={{ padding: 0, overflow: 'hidden', cursor: 'pointer', borderRadius: 14 }}>
              <button onClick={() => setOpen(open === i ? null : i)} style={{ width: '100%', padding: '18px 24px', textAlign: 'left', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                fontSize: 15, fontWeight: 600, color: P.t1, background: 'transparent' }}>
                <span>{f.q}</span><span style={{ color: P.t3, fontSize: 18, transition: 'transform 0.2s', transform: open === i ? 'rotate(45deg)' : 'none' }}>+</span></button>
              {open === i && <div style={{ padding: '0 24px 18px', fontSize: 15, color: P.t2, lineHeight: 1.7 }}>{f.a}</div>}</PC>))}</div>
      </div>
    </section>
  );
}

/* ═══ CTA ═══ */
function PMCTA() {
  const [ref, vis] = pV(0.3);
  const [showDL, setShowDL] = React.useState(false);
  return (
    <section ref={ref} style={{ padding: '100px 48px 48px', background: P.bg2, position: 'relative', overflow: 'hidden', textAlign: 'center' }}>
      <PMWave opacity={0.07} count={60} />
      <div style={{ maxWidth: 520, margin: '0 auto', zIndex: 2, position: 'relative', opacity: vis ? 1 : 0, transform: vis ? 'none' : 'translateY(16px)', transition: 'all 0.7s var(--ease)' }}>
        <h2 style={{ fontFamily: 'var(--heading)', fontWeight: 800, fontSize: 44, marginBottom: 32, color: P.t1, letterSpacing: '-0.02em' }}>
          Ready to think out loud?</h2>
        <button style={{ padding: '18px 48px', borderRadius: 16, background: 'var(--accent)', color: '#fff', fontSize: 17, fontWeight: 600,
          boxShadow: '0 4px 20px rgba(255,107,53,0.25)', transition: 'transform 0.15s, box-shadow 0.2s' }}
          onMouseEnter={e => { e.currentTarget.style.transform = 'translateY(-2px)'; e.currentTarget.style.boxShadow = '0 6px 28px rgba(255,107,53,0.35)'; }}
          onMouseLeave={e => { e.currentTarget.style.transform = 'none'; e.currentTarget.style.boxShadow = '0 4px 20px rgba(255,107,53,0.25)'; }}
          onClick={() => setShowDL(true)}>Download for Mac</button></div>
      <DownloadPopover show={showDL} onClose={() => setShowDL(false)} dark={false} />
      <div style={{ marginTop: 56, fontSize: 14, color: P.t3 }}>Open source · MIT licensed · Built with ❤ by chiruu12</div>
    </section>
  );
}

function PMPage({ mounted, onSwitch }) {
  return <div style={{ background: P.bg, minHeight: '100vh' }}>
    <PMNav onSwitch={onSwitch} m={mounted} />
    <PMHero m={mounted} />
    <PMSpeed />
    <PMPipeline />
    <PMFeatures />
    <PMSkills />
    <PMIntegrations />
    <PMPricing />
    <PMTestimonials />
    <PMFAQ />
    <PMCTA />
  </div>;
}

Object.assign(window, { PMPage });
