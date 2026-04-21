import React from 'react';
import { Link } from 'react-router-dom';

const LandingPage = () => {
    return (
        <>
            {/* Top Navigation */}
            <header className="sticky top-0 z-50 w-full border-b border-sage/10 bg-background-dark/80 backdrop-blur-md px-6 lg:px-20 py-4">
                <div className="max-w-7xl mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-3">
                        <div className="p-2 bg-primary/10 rounded-lg">
                            <span className="material-symbols-outlined text-primary text-2xl">agriculture</span>
                        </div>
                        <h2 className="text-xl font-bold tracking-tight text-white">Smart Locust Farming</h2>
                    </div>
                    <nav className="hidden md:flex items-center gap-10">
                        <a className="text-sage hover:text-primary transition-colors text-sm font-medium" href="#">Technology</a>
                        <a className="text-sage hover:text-primary transition-colors text-sm font-medium" href="#">Analytics</a>
                        <a className="text-sage hover:text-primary transition-colors text-sm font-medium" href="#">Sustainability</a>
                        <Link className="text-sage hover:text-primary transition-colors text-sm font-medium" to="/pricing">Pricing</Link>
                    </nav>
                    <div className="flex gap-4">
                        <Link to="/login" className="text-sage hover:text-primary px-4 py-2 text-sm font-medium transition-colors">
                            Login
                        </Link>
                        <button className="bg-primary hover:bg-primary/90 text-background-dark px-6 py-2.5 rounded-lg font-bold text-sm transition-all shadow-[0_0_20px_rgba(60,230,25,0.2)]">
                            Request a Demo
                        </button>
                    </div>
                </div>
            </header>

            <main className="max-w-7xl mx-auto px-6 lg:px-20">
                {/* Hero Section */}
                <section className="py-16 lg:py-24 grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
                    <div className="flex flex-col gap-8">
                        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 border border-primary/20 w-fit">
                            <span className="relative flex h-2 w-2">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
                            </span>
                            <span className="text-primary text-xs font-bold uppercase tracking-widest">Live System Active</span>
                        </div>
                        <div className="space-y-4">
                            <h1 className="text-5xl lg:text-7xl font-black leading-[1.1] tracking-tight text-white">
                                Precision Locust <br /><span className="text-primary">Cultivation.</span>
                            </h1>
                            <p className="text-sage text-lg lg:text-xl max-w-xl leading-relaxed">
                                The Future of Sustainable Protein Production. Our industrial-grade AI platform optimizes every stage of locust farming for maximum yield and minimum waste.
                            </p>
                        </div>
                        <div className="flex flex-col sm:flex-row gap-4">
                            <button className="bg-primary text-background-dark px-8 py-4 rounded-xl font-bold text-lg hover:scale-[1.02] transition-transform">
                                Request a Demo
                            </button>
                            <button className="border border-sage/30 text-white px-8 py-4 rounded-xl font-bold text-lg hover:bg-white/5 transition-colors flex items-center justify-center gap-2">
                                <span className="material-symbols-outlined">play_circle</span>
                                System Tour
                            </button>
                        </div>
                    </div>
                    <div className="relative group">
                        <div className="absolute -inset-1 bg-gradient-to-r from-primary/20 to-sage/20 rounded-2xl blur-xl opacity-50 group-hover:opacity-100 transition duration-1000"></div>
                        <div className="relative aspect-video lg:aspect-square rounded-2xl overflow-hidden border border-sage/20 shadow-2xl bg-slate-custom">
                            <img className="w-full h-full object-cover opacity-80 mix-blend-luminosity hover:mix-blend-normal transition-all duration-700" data-alt="Modern indoor insect farming facility with green lighting" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBphzkJIF9DkPkfARjirXn6OorCoVAeUeh0k_K-i9sL3cSNzTU5whkDERYz70ECfT4F9owqLS79ZudcQEmBucTii9SSi1MFifYlSye9dZeH9O4Ip-ZTGyDHsD2rDG35wIFeJaqJNLGJ9iwQMl-cmxoZpyb8VmJYrV952vQydSknvX_1qOdgpebVq7liX3jR5mqyCHtXWJD3433I3WPOcHk7XnrsHTMqpFAhPMCEZEQzKuONMvheCH4IyTojoIx44VpvL8qFcqIxKT4" alt="Facility" />
                            <div className="absolute bottom-6 left-6 right-6 glass-panel p-4 rounded-xl flex justify-between items-center">
                                <div className="flex items-center gap-3">
                                    <div className="w-10 h-10 rounded-full bg-primary/20 flex items-center justify-center text-primary">
                                        <span className="material-symbols-outlined">sensors</span>
                                    </div>
                                    <div>
                                        <p className="text-white text-sm font-bold tracking-tight">Node 08-B Active</p>
                                        <p className="text-sage text-xs">Stability: 99.4%</p>
                                    </div>
                                </div>
                                <div className="h-8 w-24 flex items-end gap-1 px-2">
                                    <div className="w-1 h-3 bg-primary rounded-full"></div>
                                    <div className="w-1 h-5 bg-primary rounded-full"></div>
                                    <div className="w-1 h-2 bg-primary rounded-full"></div>
                                    <div className="w-1 h-6 bg-primary rounded-full"></div>
                                    <div className="w-1 h-4 bg-primary rounded-full"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

                {/* Real-time Environmental Control */}
                <section className="py-20 border-y border-sage/5">
                    <div className="flex flex-col md:flex-row justify-between items-end gap-6 mb-12">
                        <div className="space-y-2">
                            <h2 className="text-3xl font-bold text-white">Environmental Control</h2>
                            <p className="text-sage">Autonomous regulation of habitat parameters in real-time.</p>
                        </div>
                        <div className="flex gap-2">
                            <span className="px-3 py-1 rounded bg-slate-custom text-sage text-xs font-mono">UTC 14:32:01</span>
                            <span className="px-3 py-1 rounded bg-slate-custom text-primary text-xs font-mono font-bold tracking-tighter">CALIBRATED</span>
                        </div>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        {/* Temperature */}
                        <div className="glass-panel p-8 rounded-2xl group hover:border-primary/30 transition-all">
                            <div className="flex justify-between items-start mb-6">
                                <div className="p-3 bg-orange-500/10 rounded-xl text-orange-500">
                                    <span className="material-symbols-outlined">thermostat</span>
                                </div>
                                <span className="text-primary text-sm font-bold flex items-center gap-1">
                                    <span className="material-symbols-outlined text-xs">trending_up</span>
                                    +0.5%
                                </span>
                            </div>
                            <p className="text-sage text-sm font-medium mb-1">Temperature</p>
                            <div className="flex items-baseline gap-2">
                                <h3 className="text-4xl font-black text-white">24.2°C</h3>
                                <span className="text-sage text-sm">Target: 24.0°C</span>
                            </div>
                            <div className="mt-6 h-1 w-full bg-slate-custom rounded-full overflow-hidden">
                                <div className="h-full bg-orange-500 w-[78%]"></div>
                            </div>
                        </div>
                        {/* Humidity */}
                        <div className="glass-panel p-8 rounded-2xl group hover:border-primary/30 transition-all border-l-4 border-l-primary/40">
                            <div className="flex justify-between items-start mb-6">
                                <div className="p-3 bg-blue-500/10 rounded-xl text-blue-500">
                                    <span className="material-symbols-outlined">humidity_percentage</span>
                                </div>
                                <span className="text-red-500 text-sm font-bold flex items-center gap-1">
                                    <span className="material-symbols-outlined text-xs">trending_down</span>
                                    -2.1%
                                </span>
                            </div>
                            <p className="text-sage text-sm font-medium mb-1">Humidity</p>
                            <div className="flex items-baseline gap-2">
                                <h3 className="text-4xl font-black text-white">65%</h3>
                                <span className="text-sage text-sm">Target: 68%</span>
                            </div>
                            <div className="mt-6 h-1 w-full bg-slate-custom rounded-full overflow-hidden">
                                <div className="h-full bg-blue-500 w-[65%]"></div>
                            </div>
                        </div>
                        {/* Air Quality */}
                        <div className="glass-panel p-8 rounded-2xl group hover:border-primary/30 transition-all">
                            <div className="flex justify-between items-start mb-6">
                                <div className="p-3 bg-primary/10 rounded-xl text-primary">
                                    <span className="material-symbols-outlined">air</span>
                                </div>
                                <span className="text-sage text-sm font-bold">Stable</span>
                            </div>
                            <p className="text-sage text-sm font-medium mb-1">Air Quality</p>
                            <div className="flex items-baseline gap-2">
                                <h3 className="text-4xl font-black text-white">Optimal</h3>
                                <span className="text-sage text-sm">CO2: 412ppm</span>
                            </div>
                            <div className="mt-6 h-1 w-full bg-slate-custom rounded-full overflow-hidden">
                                <div className="h-full bg-primary w-[92%]"></div>
                            </div>
                        </div>
                    </div>
                </section>

                {/* AI Behavioral Analysis Section */}
                <section className="py-24 grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
                    <div className="order-2 lg:order-1 relative">
                        <div className="absolute -top-10 -left-10 w-40 h-40 bg-primary/10 blur-[80px]"></div>
                        <div className="relative bg-slate-custom rounded-2xl overflow-hidden border border-sage/20 aspect-video shadow-2xl">
                            <img className="w-full h-full object-cover opacity-60" data-alt="Digital heatmap visualization showing population density patterns" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAAcSe57Utlmt42bBIXAAfMegENdDe8E9oBnOvEufWBqkoc_8GEdsJLzl7Db0vDS-5T3F9tDINsTYv3qiDeWXgCGLH5RbrLfa6nS14GmQShpCDpjtGuQtYS15kjclCBwfAfZ3mHUgMtaVJvm9HLTb4322gfuRger00We-xQeXUO_KTgC9pyqWNx2OdFKgzdAKLeHtys6RHpmgcyI7bb7ING9fOZQH6W-1GHXf2N6B5wWCm6XlP0Z5AVQz7ouCv8EK3e-j-zKpMyR08" alt="Analysis" />
                            <div className="absolute inset-0 bg-gradient-to-t from-background-dark via-transparent to-transparent"></div>
                            {/* Mock AI Overlay */}
                            <div className="absolute inset-0 p-6 flex flex-col justify-between">
                                <div className="flex justify-between">
                                    <div className="bg-black/50 backdrop-blur p-2 rounded text-[10px] font-mono text-primary flex items-center gap-2">
                                        <span className="h-1.5 w-1.5 rounded-full bg-primary animate-pulse"></span>
                                        AI_CAM_04 FEED
                                    </div>
                                    <div className="bg-primary/90 text-background-dark px-2 py-1 rounded text-[10px] font-bold">SWARM PREDICTION: LOW</div>
                                </div>
                                <div className="grid grid-cols-3 gap-4">
                                    <div className="h-20 border border-primary/20 rounded bg-black/30 backdrop-blur flex flex-col items-center justify-center">
                                        <span className="text-xs text-sage">ACTIVITY</span>
                                        <span className="text-xl font-bold text-white">88%</span>
                                    </div>
                                    <div className="h-20 border border-primary/20 rounded bg-black/30 backdrop-blur flex flex-col items-center justify-center">
                                        <span className="text-xs text-sage">HEALTH</span>
                                        <span className="text-xl font-bold text-primary">96.2%</span>
                                    </div>
                                    <div className="h-20 border border-primary/20 rounded bg-black/30 backdrop-blur flex flex-col items-center justify-center">
                                        <span className="text-xs text-sage">STRESS</span>
                                        <span className="text-xl font-bold text-white">2.4%</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div className="order-1 lg:order-2 space-y-6">
                        <div className="p-2 bg-primary/10 rounded-lg w-fit text-primary mb-4">
                            <span className="material-symbols-outlined text-3xl">psychology</span>
                        </div>
                        <h2 className="text-4xl font-bold text-white leading-tight">AI-Driven Behavioral Analysis</h2>
                        <p className="text-sage text-lg leading-relaxed">
                            Our machine vision systems monitor locust movement 24/7. By analyzing activity patterns, we can detect early signs of stress or health issues before they affect production.
                        </p>
                        <ul className="space-y-4">
                            <li className="flex items-start gap-3">
                                <span className="material-symbols-outlined text-primary mt-1">check_circle</span>
                                <span className="text-white">Predictive Swarming Prevention: AI identifies density triggers.</span>
                            </li>
                            <li className="flex items-start gap-3">
                                <span className="material-symbols-outlined text-primary mt-1">check_circle</span>
                                <span className="text-white">Health Monitoring: Detect anomalies in locomotion and coloration.</span>
                            </li>
                            <li className="flex items-start gap-3">
                                <span className="material-symbols-outlined text-primary mt-1">check_circle</span>
                                <span className="text-white">Growth Stage Tracking: Automated lifecycle identification.</span>
                            </li>
                        </ul>
                    </div>
                </section>

                {/* Automated Feeding Systems */}
                <section className="py-24 bg-slate-custom/30 rounded-[2.5rem] px-8 lg:px-16 border border-sage/10 mb-20">
                    <div className="max-w-3xl mx-auto text-center mb-16 space-y-4">
                        <h2 className="text-4xl font-bold text-white">Automated Feeding Systems</h2>
                        <p className="text-sage">Precision nutrition delivered with industrial accuracy to minimize waste and maximize growth efficiency.</p>
                    </div>
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                        <div className="relative flex flex-col items-center text-center group">
                            <div className="w-16 h-16 rounded-2xl bg-slate-custom border border-sage/20 flex items-center justify-center mb-6 group-hover:border-primary/50 transition-colors">
                                <span className="material-symbols-outlined text-primary text-3xl">inventory_2</span>
                            </div>
                            <h4 className="text-white font-bold mb-2">Inventory Sync</h4>
                            <p className="text-sage text-sm">Real-time tracking of feedstock levels and replenishment.</p>
                            <div className="hidden md:block absolute top-8 -right-4 w-8 h-[2px] bg-sage/20"></div>
                        </div>
                        <div className="relative flex flex-col items-center text-center group">
                            <div className="w-16 h-16 rounded-2xl bg-slate-custom border border-sage/20 flex items-center justify-center mb-6 group-hover:border-primary/50 transition-colors">
                                <span className="material-symbols-outlined text-primary text-3xl">science</span>
                            </div>
                            <h4 className="text-white font-bold mb-2">Nutrient Mix</h4>
                            <p className="text-sage text-sm">Dynamic formula adjustment based on colony life-cycle stage.</p>
                            <div className="hidden md:block absolute top-8 -right-4 w-8 h-[2px] bg-sage/20"></div>
                        </div>
                        <div className="relative flex flex-col items-center text-center group">
                            <div className="w-16 h-16 rounded-2xl bg-slate-custom border border-sage/20 flex items-center justify-center mb-6 group-hover:border-primary/50 transition-colors">
                                <span className="material-symbols-outlined text-primary text-3xl">schedule</span>
                            </div>
                            <h4 className="text-white font-bold mb-2">Precision Timing</h4>
                            <p className="text-sage text-sm">Automated dispersal schedules synchronized with circadian cycles.</p>
                            <div className="hidden md:block absolute top-8 -right-4 w-8 h-[2px] bg-sage/20"></div>
                        </div>
                        <div className="relative flex flex-col items-center text-center group">
                            <div className="w-16 h-16 rounded-2xl bg-slate-custom border border-sage/20 flex items-center justify-center mb-6 group-hover:border-primary/50 transition-colors">
                                <span className="material-symbols-outlined text-primary text-3xl">cleaning_services</span>
                            </div>
                            <h4 className="text-white font-bold mb-2">Waste Reduction</h4>
                            <p className="text-sage text-sm">Minimizes unconsumed material by 40% vs manual methods.</p>
                        </div>
                    </div>
                    <div className="mt-16 p-6 bg-background-dark/50 rounded-2xl border border-primary/10 flex flex-col md:flex-row items-center justify-between gap-6">
                        <div className="flex items-center gap-4">
                            <div className="size-12 rounded-full bg-primary/20 flex items-center justify-center text-primary">
                                <span className="material-symbols-outlined">data_thresholding</span>
                            </div>
                            <div>
                                <p className="text-white font-bold">Optimization Report Available</p>
                                <p className="text-sage text-sm">System calculated 14% improvement in FCR this month.</p>
                            </div>
                        </div>
                        <button className="text-primary font-bold hover:underline flex items-center gap-2">
                            Download Full Logistics Report
                            <span className="material-symbols-outlined text-sm">arrow_forward</span>
                        </button>
                    </div>
                </section>
            </main>

            {/* Footer */}
            <footer className="bg-slate-custom py-20 border-t border-sage/10">
                <div className="max-w-7xl mx-auto px-6 lg:px-20">
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-12">
                        <div className="col-span-1 md:col-span-2 space-y-6">
                            <div className="flex items-center gap-3">
                                <span className="material-symbols-outlined text-primary text-3xl">agriculture</span>
                                <h2 className="text-2xl font-bold text-white">Smart Locust Farming</h2>
                            </div>
                            <p className="text-sage max-w-sm leading-relaxed">
                                Leading the global transition to sustainable protein through advanced industrial automation and biological intelligence.
                            </p>
                            <div className="flex gap-4">
                                <a className="w-10 h-10 rounded-lg bg-background-dark flex items-center justify-center text-sage hover:text-primary transition-colors border border-sage/10" href="#">
                                    <span className="material-symbols-outlined text-xl">public</span>
                                </a>
                                <a className="w-10 h-10 rounded-lg bg-background-dark flex items-center justify-center text-sage hover:text-primary transition-colors border border-sage/10" href="#">
                                    <span className="material-symbols-outlined text-xl">share</span>
                                </a>
                                <a className="w-10 h-10 rounded-lg bg-background-dark flex items-center justify-center text-sage hover:text-primary transition-colors border border-sage/10" href="#">
                                    <span className="material-symbols-outlined text-xl">hub</span>
                                </a>
                            </div>
                        </div>
                        <div>
                            <h4 className="text-white font-bold mb-6">System</h4>
                            <ul className="space-y-4 text-sage text-sm">
                                <li><Link className="hover:text-primary" to="/dashboard">Dashboard</Link></li>
                                <li><a className="hover:text-primary" href="#">Remote Control</a></li>
                                <li><a className="hover:text-primary" href="#">IoT Integration</a></li>
                                <li><a className="hover:text-primary" href="#">Compliance</a></li>
                            </ul>
                        </div>
                        <div>
                            <h4 className="text-white font-bold mb-6">Resources</h4>
                            <ul className="space-y-4 text-sage text-sm">
                                <li><a className="hover:text-primary" href="#">Whitepapers</a></li>
                                <li><a class="hover:text-primary" href="#">Research Papers</a></li>
                                <li><a class="hover:text-primary" href="#">API Documentation</a></li>
                                <li><a class="hover:text-primary" href="#">Privacy Policy</a></li>
                            </ul>
                        </div>
                    </div>
                    <div className="mt-20 pt-8 border-t border-sage/10 flex flex-col md:flex-row justify-between items-center gap-4">
                        <p className="text-sage text-xs">© 2024 Smart Locust Farming. All industrial rights reserved.</p>
                        <div className="flex gap-6 text-xs text-sage">
                            <span className="flex items-center gap-1"><span className="h-2 w-2 rounded-full bg-primary"></span> System Status: Online</span>
                            <span>Version 4.2.0-Alpha</span>
                        </div>
                    </div>
                </div>
            </footer>
        </>
    );
};

export default LandingPage;
