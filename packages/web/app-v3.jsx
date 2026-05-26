const { useState, useEffect } = React;

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [phase, setPhase] = useState(() => {
    if (t.skipIntro) return 'page';
    return localStorage.getItem('nudge-persona') ? 'page' : 'split';
  });
  const [persona, setPersona] = useState(() => localStorage.getItem('nudge-persona') || 'dev');
  const [mounted, setMounted] = useState(false);

  useEffect(() => { document.documentElement.style.setProperty('--accent', t.accentColor); }, [t.accentColor]);
  useEffect(() => { document.body.classList.toggle('no-scanlines', !t.scanLines); }, [t.scanLines]);

  useEffect(() => {
    if (phase === 'page') {
      setMounted(false);
      /* Set body bg to match persona */
      document.body.style.background = persona === 'pm' ? '#FAFAFA' : '#0A0A0A';
      const timer = setTimeout(() => setMounted(true), 60);
      return () => clearTimeout(timer);
    } else {
      document.body.style.background = '#080808';
    }
  }, [phase, persona]);

  const handleSelect = (side) => {
    setPersona(side);
    localStorage.setItem('nudge-persona', side);
    setTimeout(() => setPhase('page'), 50);
  };

  const handleSwitch = () => {
    setMounted(false);
    window.scrollTo({ top: 0, behavior: 'smooth' });
    setTimeout(() => {
      const next = persona === 'dev' ? 'pm' : 'dev';
      setPersona(next);
      localStorage.setItem('nudge-persona', next);
      document.body.style.background = next === 'pm' ? '#FAFAFA' : '#0A0A0A';
      setTimeout(() => setMounted(true), 60);
    }, 300);
  };

  const handleReset = () => {
    localStorage.removeItem('nudge-persona');
    document.body.style.background = '#080808';
    setPhase('split');
  };

  if (phase === 'split') {
    return (
      <React.Fragment>
        <SplitIntro onSelect={handleSelect} />
        <TweaksPanel title="Tweaks">
          <TweakSection label="Theme">
            <TweakColor label="Accent" options={['#FF6B35', '#3B82F6', '#10B981', '#F59E0B']}
              value={t.accentColor} onChange={v => setTweak('accentColor', v)} />
          </TweakSection>
        </TweaksPanel>
      </React.Fragment>
    );
  }

  return (
    <React.Fragment>
      {persona === 'dev'
        ? <DevPage mounted={mounted} onSwitch={handleSwitch} />
        : <PMPage mounted={mounted} onSwitch={handleSwitch} />}
      <TweaksPanel title="Tweaks">
        <TweakSection label="Theme">
          <TweakColor label="Accent" options={['#FF6B35', '#3B82F6', '#10B981', '#F59E0B']}
            value={t.accentColor} onChange={v => setTweak('accentColor', v)} />
          {persona === 'dev' && <TweakToggle label="Scan lines" value={t.scanLines} onChange={v => setTweak('scanLines', v)} />}
        </TweakSection>
        <TweakSection label="Navigation">
          <TweakToggle label="Skip intro" value={t.skipIntro} onChange={v => setTweak('skipIntro', v)} />
          <TweakButton label="Back to intro" onClick={handleReset} />
        </TweakSection>
      </TweaksPanel>
    </React.Fragment>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
