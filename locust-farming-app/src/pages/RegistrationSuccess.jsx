import React from 'react';
import { useNavigate, Link } from 'react-router-dom';

const RegistrationSuccess = () => {
    const navigate = useNavigate();

    return (
        <div className="bg-background-dark text-white min-h-screen flex flex-col font-display">
            <div
                className="relative flex min-h-screen w-full flex-col overflow-x-hidden"
                data-alt="Dark blurred background of an automated greenhouse facility"
                style={{
                    backgroundImage: "linear-gradient(rgba(20, 33, 17, 0.85), rgba(20, 33, 17, 0.95)), url(https://lh3.googleusercontent.com/aida-public/AB6AXuClDXNoD9EftlqKZdYZwqpxzOAeP7FC9Rl9CaxrFk_ZpX6itNj4WGjDDIRCmBARj9s-aHI-1k4v9nIVoRUG83Cu0WrnjitLTSY1P0UhqEtHZfv8pjEMNbKkRRpiSZ-oAUhMQCZvwLLIYPSIJLaR7_XRCah6G50rT6_XFyDyJDnNujWW1_OUa4ieN08I0o0Nu6zbUm4gEnzu0ep7I_3BtiKwQL-lCAsBtQXuOf69S2HzDFHSNYEy1Oxsg0BViyO8FFAV-632a4IiBjw)",
                    backgroundSize: "cover",
                    backgroundPosition: "center"
                }}
            >
                {/* Top Navigation */}
                <header className="flex items-center justify-between whitespace-nowrap border-b border-white/10 px-6 md:px-10 py-4 glass-panel sticky top-0 z-50">
                    <div className="flex items-center gap-3 text-primary">
                        <span className="material-symbols-outlined text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>precision_manufacturing</span>
                        <h2 className="text-white text-lg font-bold uppercase tracking-wider">Smart Locust Farming</h2>
                    </div>
                    <div className="flex gap-3">
                        <button className="flex items-center justify-center rounded-lg h-10 w-10 bg-white/5 hover:bg-white/10 text-white transition-colors border border-white/10">
                            <span className="material-symbols-outlined text-xl">help_outline</span>
                        </button>
                        <button className="flex items-center justify-center rounded-lg h-10 w-10 bg-white/5 hover:bg-white/10 text-white transition-colors border border-white/10">
                            <span className="material-symbols-outlined text-xl">language</span>
                        </button>
                    </div>
                </header>

                {/* Main Content Area */}
                <main className="flex-1 flex items-center justify-center p-6 @container">
                    <div className="max-w-2xl w-full">
                        {/* Success Card */}
                        <div className="glass-panel rounded-xl overflow-hidden shadow-2xl border-t-4 border-t-primary">
                            <div className="p-8 md:p-12 flex flex-col items-center text-center">
                                {/* Success Icon */}
                                <div className="mb-6 relative">
                                    <div className="absolute inset-0 bg-primary/20 blur-2xl rounded-full"></div>
                                    <div className="relative flex items-center justify-center size-20 rounded-full bg-primary/10 border-2 border-primary text-primary">
                                        <span className="material-symbols-outlined text-5xl font-bold">check_circle</span>
                                    </div>
                                </div>
                                {/* Headline Section */}
                                <h1 className="text-3xl md:text-4xl font-bold text-white mb-4 tracking-tight uppercase">Registration Successful</h1>
                                <p className="text-sage text-lg mb-10 max-w-md font-light leading-relaxed">
                                    Your operator profile has been synchronized with the global locust swarm monitoring network.
                                </p>
                                {/* Account Summary Block */}
                                <div className="w-full bg-black/30 rounded-lg border border-white/5 p-6 mb-10 text-left">
                                    <h3 className="text-primary text-xs font-bold uppercase tracking-[0.2em] mb-4 flex items-center gap-2">
                                        <span className="material-symbols-outlined text-sm">badge</span>
                                        Account Summary
                                    </h3>
                                    <div className="space-y-4">
                                        <div className="flex justify-between items-center border-b border-white/5 pb-3">
                                            <span className="text-sage/70 text-sm uppercase tracking-wider">Role</span>
                                            <span className="text-white font-medium bg-primary/10 px-2 py-0.5 rounded border border-primary/20 text-xs">FARMER</span>
                                        </div>
                                        <div className="flex justify-between items-center border-b border-white/5 pb-3">
                                            <span className="text-sage/70 text-sm uppercase tracking-wider">User</span>
                                            <span className="text-white font-bold">Khalil Chouihi</span>
                                        </div>
                                        <div className="flex justify-between items-center border-b border-white/5 pb-3">
                                            <span className="text-sage/70 text-sm uppercase tracking-wider">Network Status</span>
                                            <div className="flex items-center gap-2">
                                                <div className="size-2 bg-primary rounded-full animate-pulse"></div>
                                                <span className="text-white text-sm">Active / Verified</span>
                                            </div>
                                        </div>
                                        <div className="flex justify-between items-center">
                                            <span className="text-sage/70 text-sm uppercase tracking-wider">Station ID</span>
                                            <span className="text-white font-mono text-sm tracking-widest">SLF-7742-X</span>
                                        </div>
                                    </div>
                                </div>
                                {/* CTA Section */}
                                <div className="w-full flex flex-col gap-4">
                                    <button
                                        onClick={() => navigate('/dashboard')}
                                        className="w-full py-4 bg-primary hover:bg-primary/90 text-background-dark font-bold text-lg rounded-lg shadow-[0_0_20px_rgba(60,230,25,0.3)] transition-all flex items-center justify-center gap-2 group uppercase tracking-wider"
                                    >
                                        Access Dashboard
                                        <span className="material-symbols-outlined group-hover:translate-x-1 transition-transform">arrow_forward</span>
                                    </button>
                                    <div className="flex items-center justify-center gap-6 mt-4">
                                        <Link to="/login" className="text-sage hover:text-primary text-sm font-medium transition-colors flex items-center gap-1 uppercase tracking-tighter">
                                            <span className="material-symbols-outlined text-base">login</span>
                                            Go to Login
                                        </Link>
                                        <div className="w-px h-4 bg-white/10"></div>
                                        <Link to="/profile" className="text-sage hover:text-primary text-sm font-medium transition-colors flex items-center gap-1 uppercase tracking-tighter">
                                            <span className="material-symbols-outlined text-base">settings</span>
                                            Manage Preferences
                                        </Link>
                                    </div>
                                </div>
                            </div>
                            {/* Progress Bar / Visual Detail */}
                            <div className="w-full h-1 bg-white/5 overflow-hidden">
                                <div className="w-full h-full bg-primary/40"></div>
                            </div>
                        </div>
                        {/* Footer Text */}
                        <footer className="mt-8 text-center">
                            <p className="text-sage/40 text-xs uppercase tracking-[0.3em]">
                                Welcome to the future of pest management
                            </p>
                        </footer>
                    </div>
                </main>

                {/* Decorative UI Elements */}
                <div className="fixed bottom-10 left-10 pointer-events-none opacity-20 hidden lg:block">
                    <div className="text-[10px] font-mono space-y-1 text-primary">
                        <p>SYNC_STATE: OK</p>
                        <p>AUTH_TOKEN: VERIFIED</p>
                        <p>NODE_CLUSTER: ASIA_PACIFIC_04</p>
                        <p>LATENCY: 14ms</p>
                    </div>
                </div>
                <div className="fixed bottom-10 right-10 pointer-events-none opacity-20 hidden lg:block">
                    <div className="size-32 border border-primary/30 rounded-full flex items-center justify-center">
                        <div className="size-24 border border-primary/20 rounded-full flex items-center justify-center animate-spin-slow">
                            <div className="size-2 bg-primary rounded-full absolute top-0"></div>
                        </div>
                        <span className="material-symbols-outlined text-primary/50 absolute">biotech</span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default RegistrationSuccess;
