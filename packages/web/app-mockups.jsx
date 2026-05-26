const { useState } = React;
const MAC = '-apple-system, BlinkMacSystemFont, "SF Pro", "Helvetica Neue", sans-serif';
const A = '#FF6B35';
const G = '#22C55E';

/* ── Shared data ── */
const devTasks = [
  { done: true, t: 'Morning standup' },
  { done: false, t: 'Review the PR' },
  { done: false, t: 'Email design team' },
  { done: false, t: 'Fix API bug' },
];
const devAlarms = [
  { time: '3:00 PM', label: 'Call dentist', active: true },
  { time: '5:30 PM', label: 'Team sync' },
  { time: '9:00 AM', label: 'Standup' },
];
const devNotes = [
  { title: 'API needs OAuth2', body: 'The new endpoint requires OAuth2 tokens for auth.', ago: '1h ago' },
  { title: 'Deploy: run tests first', body: 'Always run full suite before tagging a release.', ago: 'yesterday' },
  { title: 'Figma token: cf_xxx', body: 'Access token for the design system API.', ago: '2 days ago' },
];
const devActivity = [
  { type: 'alarm', color: '#F59E0B', text: 'Set for 3:00 PM. call dentist', ago: '2m ago' },
  { type: 'task', color: G, text: 'Review the PR before EOD', ago: '14m' },
  { type: 'note', color: '#3B82F6', text: 'API key is in 1Password', ago: '1h' },
  { type: 'answer', color: '#A855F7', text: 'Found 2 notes about deployment', ago: '2h' },
];

/* ── Tab icons ── */
const tabIcons = {
  home: <svg width="18" height="18" viewBox="0 0 16 16" fill="none"><rect x="6" y="2" width="4" height="8" rx="2" fill="currentColor"/><path d="M4 8a4 4 0 008 0" stroke="currentColor" strokeWidth="1.5" fill="none"/><line x1="8" y1="13" x2="8" y2="15" stroke="currentColor" strokeWidth="1.5"/></svg>,
  tasks: <svg width="18" height="18" viewBox="0 0 16 16" fill="none"><polyline points="4 8 7 11 12 5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  alarms: <svg width="18" height="18" viewBox="0 0 16 16" fill="none"><circle cx="8" cy="9" r="5" stroke="currentColor" strokeWidth="1.5"/><line x1="8" y1="6" x2="8" y2="9" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/><line x1="8" y1="9" x2="10" y2="9" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round"/></svg>,
  notes: <svg width="18" height="18" viewBox="0 0 16 16" fill="none"><rect x="3" y="2" width="10" height="12" rx="2" stroke="currentColor" strokeWidth="1.5"/><line x1="5.5" y1="5" x2="10.5" y2="5" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/><line x1="5.5" y1="7.5" x2="10.5" y2="7.5" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/><line x1="5.5" y1="10" x2="8.5" y2="10" stroke="currentColor" strokeWidth="1" strokeLinecap="round"/></svg>,
  settings: <svg width="18" height="18" viewBox="0 0 16 16" fill="none"><circle cx="8" cy="8" r="2" stroke="currentColor" strokeWidth="1.5"/><path d="M8 2v1.5M8 12.5V14M2 8h1.5M12.5 8H14M3.8 3.8l1.1 1.1M11.1 11.1l1.1 1.1M3.8 12.2l1.1-1.1M11.1 4.9l1.1-1.1" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round"/></svg>,
};
const tabList = [
  { id: 'home', label: 'nudge' },
  { id: 'tasks', label: 'tasks' },
  { id: 'alarms', label: 'alarms' },
  { id: 'notes', label: 'notes' },
  { id: 'settings', label: 'settings' },
];

/* ════════════════════════════════════════════
   DARK DASHBOARD
   ════════════════════════════════════════════ */
const Dk = { bg: '#141820', card: '#1C2230', border: '#2A3040', t1: '#E8ECF2', t2: '#8892A4', t3: '#505A6E' };

function DkCard({ children, style: s }) {
  return <div style={{ background: Dk.card, borderRadius: 14, padding: '14px 16px', border: `1px solid ${Dk.border}`, ...s }}>{children}</div>;
}

function DkHomeTab() {
  return (
    <React.Fragment>
      <div style={{ display: 'grid', gridTemplateColumns: '200px 1fr 160px', gap: 12, padding: '20px 20px 12px' }}>
        <DkCard>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <span style={{ color: Dk.t2, fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>{tabIcons.tasks} tasks</span>
            <span style={{ fontSize: 11, color: Dk.t3, background: Dk.border, borderRadius: 10, padding: '1px 8px', fontWeight: 600 }}>{devTasks.length}</span></div>
          {devTasks.map((t, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '5px 0', fontSize: 13, color: t.done ? Dk.t3 : Dk.t1, textDecoration: t.done ? 'line-through' : 'none' }}>
              <div style={{ width: 16, height: 16, borderRadius: 4, flexShrink: 0, background: t.done ? A : 'transparent', border: t.done ? 'none' : `1.5px solid ${Dk.t3}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {t.done && <span style={{ color: '#fff', fontSize: 10 }}>✓</span>}</div>{t.t}</div>))}
        </DkCard>
        <DkCard>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <span style={{ color: Dk.t2, fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>{tabIcons.alarms} alarms</span>
            <span style={{ fontSize: 11, color: Dk.t3, background: Dk.border, borderRadius: 10, padding: '1px 8px', fontWeight: 600 }}>{devAlarms.length}</span></div>
          {devAlarms.map((a, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'baseline', gap: 8, padding: '4px 0' }}>
              <div style={{ fontFamily: 'var(--mono)', fontSize: 14, fontWeight: 700, color: i === 0 ? Dk.t1 : Dk.t3 }}>{a.time}</div>
              {i === 0 && <span style={{ width: 6, height: 6, borderRadius: '50%', background: A }}></span>}
              <div style={{ fontSize: 12, color: Dk.t2 }}>{a.label}</div></div>))}
        </DkCard>
        <DkCard style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <div style={{ width: 48, height: 48, borderRadius: '50%', background: 'rgba(255,107,53,0.12)', border: `2px solid ${A}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="22" height="22" viewBox="0 0 16 16" fill="none"><rect x="6" y="2" width="4" height="8" rx="2" fill={A}/><path d="M4 8a4 4 0 008 0" stroke={A} strokeWidth="1.5" fill="none"/><line x1="8" y1="13" x2="8" y2="15" stroke={A} strokeWidth="1.5"/></svg></div>
          <span style={{ fontSize: 11, color: Dk.t2 }}>press to speak</span>
          <span style={{ fontSize: 11, color: A, fontStyle: 'italic', textAlign: 'center', lineHeight: 1.3 }}>"remind me to call the dentist at 3pm"</span>
        </DkCard>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '200px 1fr', gap: 12, padding: '0 20px 12px' }}>
        <DkCard>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <span style={{ color: '#3B82F6', fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>{tabIcons.notes} notes</span>
            <span style={{ fontSize: 11, color: Dk.t3, background: Dk.border, borderRadius: 10, padding: '1px 8px', fontWeight: 600 }}>{devNotes.length}</span></div>
          {devNotes.map((n, i) => (
            <div key={i} style={{ padding: '6px 0', borderTop: i > 0 ? `1px solid ${Dk.border}` : 'none' }}>
              <div style={{ fontSize: 12, color: Dk.t1, fontWeight: 500 }}>{n.title}</div>
              <div style={{ fontSize: 10, color: Dk.t3, marginTop: 2 }}>{n.ago}</div></div>))}
        </DkCard>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div style={{ fontSize: 12, color: Dk.t2, fontWeight: 600 }}>recent activity</div>
          <div style={{ background: Dk.card, borderRadius: 10, padding: '10px 14px', border: `1px solid ${Dk.border}`, fontSize: 13, color: Dk.t3, fontStyle: 'italic' }}>search anything you've said...</div>
          {devActivity.map((a, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 0' }}>
              <span style={{ fontSize: 10, fontWeight: 700, color: a.color, padding: '2px 8px', background: `${a.color}18`, borderRadius: 6, whiteSpace: 'nowrap' }}>{a.type}</span>
              <span style={{ fontSize: 13, color: Dk.t1, flex: 1 }}>{a.text}</span>
              <span style={{ fontSize: 11, color: Dk.t3 }}>{a.ago}</span></div>))}
        </div>
      </div>
    </React.Fragment>
  );
}

function DkTasksTab() {
  const [tasks, setTasks] = useState(devTasks);
  const toggle = (idx) => setTasks(ts => ts.map((t, i) => i === idx ? { ...t, done: !t.done } : t));
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Dk.t1, marginBottom: 8 }}>All Tasks</div>
      {tasks.map((t, i) => (
        <div key={i} onClick={() => toggle(i)} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderRadius: 10,
          background: Dk.card, border: `1px solid ${Dk.border}`, cursor: 'pointer', transition: 'background 0.15s' }}
          onMouseEnter={e => e.currentTarget.style.background = '#222838'}
          onMouseLeave={e => e.currentTarget.style.background = Dk.card}>
          <div style={{ width: 20, height: 20, borderRadius: 5, flexShrink: 0, background: t.done ? A : 'transparent', border: t.done ? 'none' : `2px solid ${Dk.t3}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.15s' }}>
            {t.done && <span style={{ color: '#fff', fontSize: 12 }}>✓</span>}</div>
          <span style={{ fontSize: 14, color: t.done ? Dk.t3 : Dk.t1, textDecoration: t.done ? 'line-through' : 'none', transition: 'all 0.15s' }}>{t.t}</span>
        </div>))}
    </div>
  );
}

function DkAlarmsTab() {
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Dk.t1, marginBottom: 8 }}>Alarms</div>
      {devAlarms.map((a, i) => (
        <DkCard key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div>
            <div style={{ fontFamily: 'var(--mono)', fontSize: 18, fontWeight: 700, color: Dk.t1 }}>{a.time}</div>
            <div style={{ fontSize: 13, color: Dk.t2, marginTop: 2 }}>{a.label}</div></div>
          <div style={{ width: 38, height: 22, borderRadius: 11, background: i === 0 ? G : Dk.border, position: 'relative' }}>
            <div style={{ width: 18, height: 18, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: i === 0 ? 18 : 2, boxShadow: '0 1px 3px rgba(0,0,0,0.3)' }} /></div>
        </DkCard>))}
    </div>
  );
}

function DkNotesTab() {
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Dk.t1, marginBottom: 8 }}>Knowledge Base</div>
      {devNotes.map((n, i) => (
        <DkCard key={i}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ fontSize: 14, fontWeight: 600, color: A }}>{n.title}</span>
            <span style={{ fontSize: 11, color: Dk.t3 }}>{n.ago}</span></div>
          <div style={{ fontSize: 13, color: Dk.t2, lineHeight: 1.5 }}>{n.body}</div>
        </DkCard>))}
    </div>
  );
}

function DkSettingsTab() {
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 12 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Dk.t1, marginBottom: 4 }}>Settings</div>
      {[
        { label: 'Launch at login', on: true },
        { label: 'Global hotkey', val: '⌘⇧N' },
        { label: 'Notifications', on: true },
        { label: 'Sound effects', on: false },
      ].map((s, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: Dk.card, borderRadius: 10, border: `1px solid ${Dk.border}` }}>
          <span style={{ color: Dk.t1, fontSize: 13 }}>{s.label}</span>
          {s.val ? <span style={{ fontFamily: 'var(--mono)', fontSize: 12, color: A, padding: '4px 10px', background: 'rgba(255,107,53,0.08)', borderRadius: 4 }}>{s.val}</span>
            : <div style={{ width: 38, height: 22, borderRadius: 11, background: s.on ? G : Dk.border, position: 'relative' }}>
                <div style={{ width: 18, height: 18, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: s.on ? 18 : 2, boxShadow: '0 1px 3px rgba(0,0,0,0.3)' }} /></div>}
        </div>))}
      <div style={{ fontSize: 14, fontWeight: 600, color: Dk.t1, marginTop: 8 }}>Preset</div>
      <div style={{ display: 'flex', gap: 8 }}>
        {['Fast', 'Default', 'Offline'].map((p, i) => (
          <button key={p} style={{ flex: 1, padding: 10, borderRadius: 8, fontSize: 12, fontWeight: 600,
            background: i === 0 ? A : Dk.card, color: i === 0 ? '#fff' : Dk.t2,
            border: i === 0 ? 'none' : `1px solid ${Dk.border}`, cursor: 'pointer', fontFamily: MAC }}>{p}</button>))}
      </div>
    </div>
  );
}

function DashboardDark() {
  const [tab, setTab] = useState('home');
  const content = { home: <DkHomeTab />, tasks: <DkTasksTab />, alarms: <DkAlarmsTab />, notes: <DkNotesTab />, settings: <DkSettingsTab /> };
  return (
    <div style={{ width: 680, minHeight: 480, borderRadius: 18, overflow: 'hidden', background: Dk.bg,
      boxShadow: '0 0 0 1px rgba(255,255,255,0.06), 0 24px 60px rgba(0,0,0,0.6)',
      fontFamily: MAC, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1 }}>{content[tab]}</div>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 4, padding: '12px 20px 16px', borderTop: `1px solid ${Dk.border}` }}>
        {tabList.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '8px 16px', borderRadius: 10, border: 'none', cursor: 'pointer',
            background: tab === t.id ? 'rgba(255,107,53,0.1)' : 'transparent',
            color: tab === t.id ? A : Dk.t3, fontFamily: MAC, fontSize: 10, fontWeight: 500, transition: 'all 0.15s',
          }}>{tabIcons[t.id]}{t.label}</button>))}
      </div>
    </div>
  );
}

/* ════════════════════════════════════════════
   LIGHT DASHBOARD
   ════════════════════════════════════════════ */
const Lt = { bg: '#F0F2F5', card: '#fff', border: '#E2E5EB', t1: '#1D1D1F', t2: '#6E6E73', t3: '#AEAEB2' };
const pmTasks = [
  { done: true, t: 'Morning standup' },
  { done: false, t: 'Review budget proposal' },
  { done: false, t: 'Prep Q4 presentation' },
  { done: false, t: 'Email design team' },
];
const pmAlarms = [
  { time: '3:00 PM', label: 'Call dentist' },
  { time: '5:30 PM', label: 'Team sync' },
];
const pmNotes = [
  { title: 'Q4 budget approved', body: 'CFO approved the engineering budget for Q4.', ago: '1h ago' },
  { title: 'Team offsite Dec 15', body: 'Booked Mountain View venue for full-day offsite.', ago: 'yesterday' },
];
const pmActivity = [
  { type: 'alarm', color: '#F59E0B', text: 'Set for 3:00 PM. call dentist', ago: '2m ago' },
  { type: 'task', color: G, text: 'Prep Q4 presentation', ago: '14m' },
  { type: 'note', color: '#3B82F6', text: 'Budget approved by CFO', ago: '1h' },
];

function LtCard({ children, style: s }) {
  return <div style={{ background: Lt.card, borderRadius: 14, padding: '14px 16px', border: `1px solid ${Lt.border}`, ...s }}>{children}</div>;
}

function LtHomeTab() {
  return (
    <React.Fragment>
      <div style={{ display: 'grid', gridTemplateColumns: '200px 1fr 160px', gap: 12, padding: '20px 20px 12px' }}>
        <LtCard>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <span style={{ color: Lt.t2, fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>{tabIcons.tasks} tasks</span>
            <span style={{ fontSize: 11, color: Lt.t3, background: Lt.border, borderRadius: 10, padding: '1px 8px', fontWeight: 600 }}>{pmTasks.length}</span></div>
          {pmTasks.map((t, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '5px 0', fontSize: 13, color: t.done ? Lt.t3 : Lt.t1, textDecoration: t.done ? 'line-through' : 'none' }}>
              <div style={{ width: 16, height: 16, borderRadius: 4, flexShrink: 0, background: t.done ? A : 'transparent', border: t.done ? 'none' : `1.5px solid ${Lt.t3}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {t.done && <span style={{ color: '#fff', fontSize: 10 }}>✓</span>}</div>{t.t}</div>))}
        </LtCard>
        <LtCard>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <span style={{ color: Lt.t2, fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>{tabIcons.alarms} alarms</span>
            <span style={{ fontSize: 11, color: Lt.t3, background: Lt.border, borderRadius: 10, padding: '1px 8px', fontWeight: 600 }}>{pmAlarms.length}</span></div>
          {pmAlarms.map((a, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'baseline', gap: 8, padding: '6px 0' }}>
              <div style={{ fontFamily: 'var(--mono)', fontSize: 15, fontWeight: 700, color: i === 0 ? Lt.t1 : Lt.t3 }}>{a.time}</div>
              {i === 0 && <span style={{ width: 6, height: 6, borderRadius: '50%', background: A }}></span>}
              <div style={{ fontSize: 13, color: Lt.t2 }}>{a.label}</div></div>))}
        </LtCard>
        <LtCard style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
          <div style={{ width: 48, height: 48, borderRadius: '50%', background: 'rgba(255,107,53,0.06)', border: `2px solid ${A}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <svg width="22" height="22" viewBox="0 0 16 16" fill="none"><rect x="6" y="2" width="4" height="8" rx="2" fill={A}/><path d="M4 8a4 4 0 008 0" stroke={A} strokeWidth="1.5" fill="none"/><line x1="8" y1="13" x2="8" y2="15" stroke={A} strokeWidth="1.5"/></svg></div>
          <span style={{ fontSize: 11, color: Lt.t2 }}>press to speak</span>
          <span style={{ fontSize: 11, color: A, fontStyle: 'italic', textAlign: 'center', lineHeight: 1.3 }}>"remind me to call the dentist"</span>
        </LtCard>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '200px 1fr', gap: 12, padding: '0 20px 12px' }}>
        <LtCard>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
            <span style={{ color: '#3B82F6', fontSize: 12, fontWeight: 600, display: 'flex', alignItems: 'center', gap: 6 }}>{tabIcons.notes} notes</span>
            <span style={{ fontSize: 11, color: Lt.t3, background: Lt.border, borderRadius: 10, padding: '1px 8px', fontWeight: 600 }}>{pmNotes.length}</span></div>
          {pmNotes.map((n, i) => (
            <div key={i} style={{ padding: '6px 0', borderTop: i > 0 ? `1px solid ${Lt.border}` : 'none' }}>
              <div style={{ fontSize: 12, color: Lt.t1, fontWeight: 500 }}>{n.title}</div>
              <div style={{ fontSize: 10, color: Lt.t3, marginTop: 2 }}>{n.ago}</div></div>))}
        </LtCard>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <div style={{ fontSize: 12, color: Lt.t2, fontWeight: 600 }}>recent activity</div>
          <div style={{ background: Lt.card, borderRadius: 10, padding: '10px 14px', border: `1px solid ${Lt.border}`, fontSize: 13, color: Lt.t3, fontStyle: 'italic' }}>search anything you've said...</div>
          {pmActivity.map((a, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 0' }}>
              <span style={{ fontSize: 10, fontWeight: 700, color: a.color, padding: '2px 8px', background: `${a.color}10`, borderRadius: 6, whiteSpace: 'nowrap' }}>{a.type}</span>
              <span style={{ fontSize: 13, color: Lt.t1, flex: 1 }}>{a.text}</span>
              <span style={{ fontSize: 11, color: Lt.t3 }}>{a.ago}</span></div>))}
        </div>
      </div>
    </React.Fragment>
  );
}

function LtTasksTab() {
  const [tasks, setTasks] = useState(pmTasks);
  const toggle = (idx) => setTasks(ts => ts.map((t, i) => i === idx ? { ...t, done: !t.done } : t));
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Lt.t1, marginBottom: 8 }}>All Tasks</div>
      {tasks.map((t, i) => (
        <div key={i} onClick={() => toggle(i)} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', borderRadius: 10,
          background: Lt.card, border: `1px solid ${Lt.border}`, cursor: 'pointer', transition: 'background 0.15s' }}
          onMouseEnter={e => e.currentTarget.style.background = '#F5F5F7'}
          onMouseLeave={e => e.currentTarget.style.background = Lt.card}>
          <div style={{ width: 20, height: 20, borderRadius: 5, flexShrink: 0, background: t.done ? A : 'transparent', border: t.done ? 'none' : `2px solid ${Lt.t3}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', transition: 'all 0.15s' }}>
            {t.done && <span style={{ color: '#fff', fontSize: 12 }}>✓</span>}</div>
          <span style={{ fontSize: 14, color: t.done ? Lt.t3 : Lt.t1, textDecoration: t.done ? 'line-through' : 'none' }}>{t.t}</span>
        </div>))}
    </div>
  );
}

function LtAlarmsTab() {
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Lt.t1, marginBottom: 8 }}>Alarms</div>
      {pmAlarms.map((a, i) => (
        <LtCard key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div><div style={{ fontFamily: 'var(--mono)', fontSize: 18, fontWeight: 700, color: Lt.t1 }}>{a.time}</div>
            <div style={{ fontSize: 13, color: Lt.t2, marginTop: 2 }}>{a.label}</div></div>
          <div style={{ width: 38, height: 22, borderRadius: 11, background: i === 0 ? G : Lt.border, position: 'relative' }}>
            <div style={{ width: 18, height: 18, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: i === 0 ? 18 : 2, boxShadow: '0 1px 3px rgba(0,0,0,0.15)' }} /></div>
        </LtCard>))}
    </div>
  );
}

function LtNotesTab() {
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Lt.t1, marginBottom: 8 }}>Knowledge Base</div>
      {pmNotes.map((n, i) => (
        <LtCard key={i}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ fontSize: 14, fontWeight: 600, color: A }}>{n.title}</span>
            <span style={{ fontSize: 11, color: Lt.t3 }}>{n.ago}</span></div>
          <div style={{ fontSize: 13, color: Lt.t2, lineHeight: 1.5 }}>{n.body}</div>
        </LtCard>))}
    </div>
  );
}

function LtSettingsTab() {
  return (
    <div style={{ padding: 20, display: 'flex', flexDirection: 'column', gap: 12 }}>
      <div style={{ fontSize: 16, fontWeight: 700, color: Lt.t1, marginBottom: 4 }}>Settings</div>
      {[
        { label: 'Launch at login', on: true },
        { label: 'Global hotkey', val: '⌘⇧N' },
        { label: 'Notifications', on: true },
        { label: 'Sound effects', on: false },
      ].map((s, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 14px', background: Lt.card, borderRadius: 10, border: `1px solid ${Lt.border}` }}>
          <span style={{ color: Lt.t1, fontSize: 13 }}>{s.label}</span>
          {s.val ? <span style={{ fontFamily: 'var(--mono)', fontSize: 12, color: A, padding: '4px 10px', background: 'rgba(255,107,53,0.06)', borderRadius: 6 }}>{s.val}</span>
            : <div style={{ width: 38, height: 22, borderRadius: 11, background: s.on ? G : Lt.border, position: 'relative' }}>
                <div style={{ width: 18, height: 18, borderRadius: '50%', background: '#fff', position: 'absolute', top: 2, left: s.on ? 18 : 2, boxShadow: '0 1px 3px rgba(0,0,0,0.15)' }} /></div>}
        </div>))}
      <div style={{ fontSize: 14, fontWeight: 600, color: Lt.t1, marginTop: 8 }}>Preset</div>
      <div style={{ display: 'flex', gap: 8 }}>
        {['Fast', 'Default', 'Offline'].map((p, i) => (
          <button key={p} style={{ flex: 1, padding: 10, borderRadius: 10, fontSize: 12, fontWeight: 600,
            background: i === 0 ? A : Lt.card, color: i === 0 ? '#fff' : Lt.t2,
            border: i === 0 ? 'none' : `1px solid ${Lt.border}`, cursor: 'pointer', fontFamily: MAC }}>{p}</button>))}
      </div>
    </div>
  );
}

function DashboardLight() {
  const [tab, setTab] = useState('home');
  const content = { home: <LtHomeTab />, tasks: <LtTasksTab />, alarms: <LtAlarmsTab />, notes: <LtNotesTab />, settings: <LtSettingsTab /> };
  return (
    <div style={{ width: 680, minHeight: 480, borderRadius: 18, overflow: 'hidden', background: Lt.bg,
      boxShadow: '0 0 0 1px rgba(0,0,0,0.06), 0 24px 60px rgba(0,0,0,0.12)',
      fontFamily: MAC, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1 }}>{content[tab]}</div>
      <div style={{ display: 'flex', justifyContent: 'center', gap: 4, padding: '12px 20px 16px', borderTop: `1px solid ${Lt.border}` }}>
        {tabList.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)} style={{
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '8px 16px', borderRadius: 10, border: 'none', cursor: 'pointer',
            background: tab === t.id ? 'rgba(255,107,53,0.08)' : 'transparent',
            color: tab === t.id ? A : Lt.t3, fontFamily: MAC, fontSize: 10, fontWeight: 500,
          }}>{tabIcons[t.id]}{t.label}</button>))}
      </div>
    </div>
  );
}

/* ═══ CANVAS ═══ */
function AppMockups() {
  return (
    <DesignCanvas>
      <DCSection id="dev" title="Developer Dashboard (Dark)">
        <DCArtboard id="dev-dash" label="Dashboard" width={680} height={520}>
          <DashboardDark />
        </DCArtboard>
      </DCSection>
      <DCSection id="pm" title="Team Lead Dashboard (Light)">
        <DCArtboard id="pm-dash" label="Dashboard" width={680} height={520}>
          <DashboardLight />
        </DCArtboard>
      </DCSection>
    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<AppMockups />);
