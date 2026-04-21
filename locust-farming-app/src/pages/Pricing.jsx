import React, { useState } from 'react';
import { Link } from 'react-router-dom';

const plans = [
  {
    id: 'starter',
    name: 'Starter',
    tagline: 'Perfect for small farms getting started',
    monthlyPrice: 49, 
    yearlyPrice: 39,
    color: 'sage',
    icon: 'eco',
    badge: null,
    features: [
      { label: '1 Container', included: true },
      { label: 'Basic Sensor Monitoring', included: true },
      { label: 'Temperature & Humidity Alerts', included: true },
      { label: 'Daily Reports', included: true },
      { label: 'Email Support', included: true },
      { label: 'AI Behavioral Analysis', included: false },
      { label: 'Predictive Intelligence', included: false },
      { label: 'Multi-Container Management', included: false },
      { label: 'API Access', included: false },
      { label: 'Dedicated Account Manager', included: false },
    ],
  },
  {
    id: 'professional',
    name: 'Professional',
    tagline: 'For growing operations that need more power',
    monthlyPrice: 149,
    yearlyPrice: 119,
    color: 'primary',
    icon: 'agriculture',
    badge: 'Most Popular',
    features: [
      { label: 'Up to 5 Containers', included: true },
      { label: 'Advanced Sensor Monitoring', included: true },
      { label: 'Real-time Alerts & Notifications', included: true },
      { label: 'Daily & Weekly Reports', included: true },
      { label: 'Priority Email & Chat Support', included: true },
      { label: 'AI Behavioral Analysis', included: true },
      { label: 'Predictive Intelligence', included: true },
      { label: 'Multi-Container Management', included: true },
      { label: 'API Access', included: false },
      { label: 'Dedicated Account Manager', included: false },
    ],
  },
  {
    id: 'enterprise',
    name: 'Enterprise',
    tagline: 'Full-scale industrial farming operations',
    monthlyPrice: 399,
    yearlyPrice: 319,
    color: 'amber',
    icon: 'factory',
    badge: 'Best Value',
    features: [
      { label: 'Unlimited Containers', included: true },
      { label: 'Full Sensor Suite + IoT Integration', included: true },
      { label: 'Real-time Alerts & SMS', included: true },
      { label: 'Custom Reports & Analytics', included: true },
      { label: '24/7 Priority Support + SLA', included: true },
      { label: 'AI Behavioral Analysis', included: true },
      { label: 'Predictive Intelligence', included: true },
      { label: 'Multi-Container Management', included: true },
      { label: 'Full API Access', included: true },
      { label: 'Dedicated Account Manager', included: true },
    ],
  },
];

const colorMap = {
  sage: {
    accent: '#a2b89d',
    glow: 'rgba(162,184,157,0.25)',
    badge: 'bg-[#a2b89d]/20 text-[#a2b89d]',
    button: 'border border-[#a2b89d]/40 text-[#a2b89d] hover:bg-[#a2b89d]/10',
    check: 'text-[#a2b89d]',
    border: 'border-[#a2b89d]/30',
    selectedBorder: 'border-[#a2b89d]',
    iconBg: 'bg-[#a2b89d]/10 text-[#a2b89d]',
  },
  primary: {
    accent: '#3ce619',
    glow: 'rgba(60,230,25,0.3)',
    badge: 'bg-primary/20 text-primary',
    button: 'bg-primary text-background-dark hover:bg-primary/90',
    check: 'text-primary',
    border: 'border-primary/30',
    selectedBorder: 'border-primary',
    iconBg: 'bg-primary/10 text-primary',
  },
  amber: {
    accent: '#ffc107',
    glow: 'rgba(255,193,7,0.25)',
    badge: 'bg-amber-alert/20 text-amber-alert',
    button: 'border border-amber-alert/40 text-amber-alert hover:bg-amber-alert/10',
    check: 'text-amber-alert',
    border: 'border-amber-alert/30',
    selectedBorder: 'border-amber-alert',
    iconBg: 'bg-amber-alert/10 text-amber-alert',
  },
};

const Pricing = () => {
  const [yearly, setYearly] = useState(false);
  const [selected, setSelected] = useState('professional');
  const [hovered, setHovered] = useState(null);

  // Helper to get brand colors dynamically if needed, though colorMap handles most.
  // We use Slate-900 for headings, Slate-600 for body text.

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans selection:bg-primary/30">
      {/* Header */}
      <header className="sticky top-0 z-50 w-full border-b border-slate-200 bg-white/80 backdrop-blur-md px-6 lg:px-20 py-4 transition-all duration-300">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <Link to="/" className="flex items-center gap-3 group">
            <div className="p-2 bg-primary/10 rounded-lg group-hover:bg-primary/20 transition-colors">
              <span className="material-symbols-outlined text-primary text-2xl">agriculture</span>
            </div>
            <h2 className="text-xl font-bold tracking-tight text-slate-900">Smart Locust Farming</h2>
          </Link>
          <nav className="hidden md:flex items-center gap-10">
            <Link to="/" className="text-slate-500 hover:text-primary transition-colors text-sm font-medium">Home</Link>
            <a className="text-slate-500 hover:text-primary transition-colors text-sm font-medium" href="#">Technology</a>
            <a className="text-slate-500 hover:text-primary transition-colors text-sm font-medium" href="#">Analytics</a>
            <span className="text-primary text-sm font-bold border-b-2 border-primary pb-0.5">Pricing</span>
          </nav>
          <div className="flex gap-4">
            <Link to="/login" className="text-slate-600 hover:text-primary px-4 py-2 text-sm font-medium transition-colors">Login</Link>
            <Link to="/login" className="bg-primary hover:bg-primary/90 text-white shadow-lg shadow-primary/30 px-6 py-2.5 rounded-lg font-bold text-sm transition-all hover:scale-105 active:scale-95">
              Get Started
            </Link>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 lg:px-20 py-20">

        {/* Hero section */}
        <div className="text-center mb-16 space-y-6">
          <div
            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-primary/20 bg-primary/5 text-primary text-xs font-bold uppercase tracking-widest shadow-sm"
            style={{ animation: 'fadeSlideDown 0.6s ease both' }}
          >
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
            </span>
            Transparent Pricing
          </div>
          <h1
            className="text-5xl lg:text-7xl font-black leading-tight tracking-tight text-slate-900"
            style={{ animation: 'fadeSlideDown 0.7s ease both' }}
          >
            Choose Your <br />
            <span className="text-primary drop-shadow-sm">Growth Plan</span>
          </h1>
          <p
            className="text-slate-600 text-lg lg:text-xl max-w-2xl mx-auto leading-relaxed"
            style={{ animation: 'fadeSlideDown 0.8s ease both' }}
          >
            Scale your locust farming operation with the right tools. Every plan includes our core monitoring platform — upgrade anytime.
          </p>

          {/* Billing toggle */}
          <div
            className="inline-flex items-center gap-4 bg-white border border-slate-200 shadow-sm rounded-2xl px-6 py-3 mt-4"
            style={{ animation: 'fadeSlideDown 0.9s ease both' }}
          >
            <span className={`text-sm font-semibold transition-colors ${!yearly ? 'text-slate-900' : 'text-slate-400'}`}>Monthly</span>
            <button
              onClick={() => setYearly(v => !v)}
              className="relative w-12 h-6 rounded-full transition-colors duration-300 focus:outline-none"
              style={{ background: yearly ? '#3ce619' : '#e2e8f0' }}
            >
              <span
                className="absolute top-1 left-1 w-4 h-4 rounded-full bg-white shadow-md transition-transform duration-300"
                style={{ transform: yearly ? 'translateX(24px)' : 'translateX(0)' }}
              />
            </button>
            <span className={`text-sm font-semibold transition-colors ${yearly ? 'text-slate-900' : 'text-slate-400'}`}>
              Yearly
              <span className="ml-2 text-xs bg-primary/10 text-primary border border-primary/20 px-2 py-0.5 rounded-full font-bold">Save 20%</span>
            </span>
          </div>
        </div>

        {/* Plans grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 lg:gap-8 mb-24">
          {plans.map((plan, i) => {
            const c = colorMap[plan.color];
            const isSelected = selected === plan.id;
            const isHovered = hovered === plan.id;
            const active = isSelected || isHovered;

            return (
              <div
                key={plan.id}
                onClick={() => setSelected(plan.id)}
                onMouseEnter={() => setHovered(plan.id)}
                onMouseLeave={() => setHovered(null)}
                className="relative cursor-pointer rounded-3xl border transition-all duration-300 flex flex-col overflow-hidden group bg-white"
                style={{
                  animation: `fadeSlideUp ${0.5 + i * 0.15}s ease both`,
                  borderColor: isSelected ? c.accent : isHovered ? c.accent + '60' : 'transparent',
                  // Light mode shadows
                  boxShadow: isSelected
                    ? `0 20px 40px -10px ${c.accent}30, 0 0 0 1px ${c.accent}`
                    : isHovered
                    ? `0 10px 30px -10px rgba(0,0,0,0.1)`
                    : '0 4px 6px -1px rgba(0,0,0,0.05), 0 2px 4px -1px rgba(0,0,0,0.03)',
                  transform: isSelected ? 'scale(1.03) translateY(-4px)' : isHovered ? 'scale(1.01) translateY(-2px)' : 'scale(1)',
                  zIndex: isSelected ? 10 : 1,
                }}
              >
                 {/* Top Colored Bar/Gradient for depth in Light Mode */}
                 <div className="h-1.5 w-full" style={{ background: c.accent }} />

                {/* Badge */}
                {plan.badge && (
                  <div className="absolute top-6 right-6">
                    <span className={`text-[10px] font-black uppercase tracking-widest px-2.5 py-1 rounded-full border ${c.badge.replace('bg-', 'bg-opacity-10 border-opacity-20 ')}`}>
                      {plan.badge}
                    </span>
                  </div>
                )}

                <div className="p-8 flex flex-col flex-1">
                  {/* Icon & name */}
                  <div className="flex items-center gap-4 mb-6">
                    <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${c.iconBg} transition-transform duration-300 ${active ? 'scale-110 rotate-3' : ''}`}>
                      <span className="material-symbols-outlined text-2xl" style={{ color: c.accent }}>{plan.icon}</span>
                    </div>
                    <div>
                      <h3 className="text-xl font-black text-slate-900">{plan.name}</h3>
                      <p className="text-slate-500 text-xs leading-snug mt-0.5 font-medium">{plan.tagline}</p>
                    </div>
                  </div>

                  {/* Price */}
                  <div className="mb-8 p-4 rounded-2xl bg-slate-50 border border-slate-100">
                    <div className="flex items-end gap-1.5">
                      <span
                        className="text-5xl font-black transition-all duration-300 tracking-tight"
                        style={{ color: isSelected ? c.accent : '#0f172a' }} // slate-900
                      >
                        ${yearly ? plan.yearlyPrice : plan.monthlyPrice}
                      </span>
                      <span className="text-slate-400 text-sm mb-2 font-medium">/mo</span>
                    </div>
                    {yearly && (
                      <p className="text-slate-500 text-xs mt-2 flex items-center gap-1.5 font-medium">
                        <span className="material-symbols-outlined text-sm font-bold" style={{ color: c.accent }}>savings</span>
                        Billed annually — save ${(plan.monthlyPrice - plan.yearlyPrice) * 12}/yr
                      </p>
                    )}
                  </div>

                  {/* Features */}
                  <ul className="space-y-3.5 mb-8 flex-1">
                    {plan.features.map((f, fi) => (
                      <li key={fi} className="flex items-center gap-3">
                        {f.included ? (
                          <div className={`p-0.5 rounded-full flex-shrink-0 ${c.iconBg}`}>
                             <span className="material-symbols-outlined text-sm font-bold" style={{ color: c.accent }}>check</span>
                          </div>
                        ) : (
                          <span className="material-symbols-outlined text-base flex-shrink-0 text-slate-200">close</span>
                        )}
                        <span className={`text-sm font-medium ${f.included ? 'text-slate-700' : 'text-slate-400/80 decoration-slate-300'}`}>
                          {f.label}
                        </span>
                      </li>
                    ))}
                  </ul>

                  {/* CTA */}
                  <Link
                    to="/login"
                    onClick={e => e.stopPropagation()}
                    className={`w-full py-3.5 rounded-xl font-bold text-sm text-center transition-all duration-200 flex items-center justify-center gap-2 ${isSelected ? 'shadow-lg shadow-' + plan.color + '/20' : ''}`}
                    style={{
                      backgroundColor: isSelected ? c.accent : 'transparent',
                      color: isSelected ? '#142111' : c.accent, // Text dark on bright buttons
                      border: isSelected ? 'none' : `1px solid ${c.accent}`,
                    }}
                  >
                    {isSelected ? (
                      <>
                        <span className="material-symbols-outlined text-base">check</span>
                        Selected — Get Started
                      </>
                    ) : (
                      <>
                        Choose {plan.name}
                        <span className="material-symbols-outlined text-base">arrow_forward</span>
                      </>
                    )}
                  </Link>
                </div>
              </div>
            );
          })}
        </div>

        {/* Feature comparison table */}
        <div
          className="mb-24"
          style={{ animation: 'fadeSlideUp 1.1s ease both' }}
        >
          <h2 className="text-3xl font-bold text-slate-900 text-center mb-3">Full Feature Comparison</h2>
          <p className="text-slate-500 text-center mb-12">See exactly what's included in every plan</p>

          <div className="rounded-2xl overflow-hidden border border-slate-200 bg-white shadow-sm">
            {/* Table header */}
            <div className="grid grid-cols-4 bg-slate-50/80 border-b border-slate-200">
              <div className="p-5 text-slate-500 text-sm font-bold uppercase tracking-wider">Feature</div>
              {plans.map(p => {
                const c = colorMap[p.color];
                return (
                  <div key={p.id} className="p-5 text-center">
                    <span className="text-sm font-black" style={{ color: c.accent }}>{p.name}</span>
                  </div>
                );
              })}
            </div>

            {/* Rows */}
            {plans[2].features.map((f, i) => (
              <div
                key={i}
                className="grid grid-cols-4 border-b border-slate-100 last:border-0 hover:bg-slate-50/50 transition-colors"
              >
                <div className="p-4 text-slate-700 text-sm flex items-center gap-2 font-medium pl-6">
                  {f.label}
                   {/* Optional info icon could go here */}
                </div>
                {plans.map(plan => (
                  <div key={plan.id} className="p-4 flex items-center justify-center border-l border-slate-50">
                    {plan.features[i].included ? (
                      <span
                        className="material-symbols-outlined text-xl"
                        style={{ color: colorMap[plan.color].accent }}
                      >
                        check_circle
                      </span>
                    ) : (
                      <span className="w-3 h-0.5 rounded-full bg-slate-200 block" />
                    )}
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>

        {/* FAQ */}
        <div className="mb-24" style={{ animation: 'fadeSlideUp 1.2s ease both' }}>
          <h2 className="text-3xl font-bold text-slate-900 text-center mb-3">Frequently Asked Questions</h2>
          <p className="text-slate-500 text-center mb-12">Everything you need to know about our plans</p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-4xl mx-auto">
            {[
              { q: 'Can I switch plans anytime?', a: 'Yes, you can upgrade or downgrade your plan at any time. Changes take effect immediately and billing is prorated.' },
              { q: 'Is there a free trial?', a: 'All plans include a 14-day free trial. No credit card required to get started.' },
              { q: 'What happens if I exceed container limits?', a: "You'll be notified when approaching your limit. Upgrading unlocks additional containers instantly." },
              { q: 'Do you offer on-premise deployment?', a: 'Enterprise clients can request a fully on-premise solution. Contact our sales team for a custom quote.' },
            ].map((item, i) => (
              <div
                key={i}
                className="bg-white border border-slate-200 shadow-sm rounded-2xl p-6 hover:border-primary/40 hover:shadow-md transition-all duration-200 group"
              >
                <div className="flex items-start gap-3">
                  <div className="mt-1 p-2 bg-slate-50 rounded-lg text-slate-400 group-hover:text-primary group-hover:bg-primary/5 transition-colors flex-shrink-0">
                    <span className="material-symbols-outlined text-base">help</span>
                  </div>
                  <div>
                    <h4 className="text-slate-900 font-bold mb-2">{item.q}</h4>
                    <p className="text-slate-600 text-sm leading-relaxed">{item.a}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* CTA Banner (Kept Dark/Strong for Contrast) */}
        <div
          className="relative rounded-3xl overflow-hidden border border-slate-200 mb-10 group"
          style={{
            background: '#142111', // Keeping brand dark green for footer CTA pop
            boxShadow: '0 20px 40px -10px rgba(20, 33, 17, 0.4)',
            animation: 'fadeSlideUp 1.3s ease both',
          }}
        >
          <div className="absolute top-0 right-0 w-[500px] h-full bg-gradient-to-l from-primary/10 to-transparent opacity-60"></div>
          <div className="relative z-10 p-12 lg:p-16 flex flex-col lg:flex-row items-center justify-between gap-8 text-center lg:text-left">
            <div className="space-y-4">
              <h2 className="text-4xl font-black text-white">Ready to scale your farm?</h2>
              <p className="text-slate-300 text-lg max-w-xl">
                Join 200+ industrial locust farms already optimizing production with our AI-powered platform.
              </p>
            </div>
            <div className="flex flex-col sm:flex-row gap-4 flex-shrink-0">
              <Link
                to="/login"
                className="bg-primary text-background-dark px-8 py-4 rounded-xl font-black text-base hover:bg-white hover:text-background-dark transition-all transform hover:scale-105 shadow-xl shadow-primary/20 whitespace-nowrap"
              >
                Start Free Trial
              </Link>
              <button className="border border-white/20 text-white px-8 py-4 rounded-xl font-bold text-base hover:bg-white/10 transition-colors whitespace-nowrap">
                Talk to Sales
              </button>
            </div>
          </div>
        </div>

      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-slate-200 py-12">
        <div className="max-w-7xl mx-auto px-6 lg:px-20 flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="flex items-center gap-3">
            <div className="p-1.5 bg-slate-100 rounded-lg">
                <span className="material-symbols-outlined text-primary text-xl">agriculture</span>
            </div>
            <span className="text-slate-900 font-bold text-sm">Smart Locust Farming</span>
          </div>
          <p className="text-slate-500 text-xs">© 2024 Smart Locust Farming. All industrial rights reserved.</p>
          <div className="flex gap-6 text-xs text-slate-500 font-medium">
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-green-500 inline-block animate-pulse"></span>
              System Status: Online
            </span>
            <span>Version 4.2.0</span>
          </div>
        </div>
      </footer>

      {/* CSS animations */}
      <style>{`
        @keyframes fadeSlideDown {
          from { opacity: 0; transform: translateY(-24px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes fadeSlideUp {
          from { opacity: 0; transform: translateY(32px); }
          to   { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  );
};

export default Pricing;



