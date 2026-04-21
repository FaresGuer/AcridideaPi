import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const RegisterContainer = () => {
    const navigate = useNavigate();
    const { register } = useAuth();
    const [fullName, setFullName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [error, setError] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);

    const handleRegister = async (e) => {
        e.preventDefault();
        setError('');

        if (password !== confirmPassword) {
            setError('Passwords do not match');
            return;
        }

        setIsSubmitting(true);
        try {
            await register({
                email,
                full_name: fullName,
                password,
                role: "FARMER"
            });
            // Navigate to success page
            navigate('/registration-success');
        } catch (err) {
            setError(err.message || 'Registration failed');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="bg-background-light dark:bg-background-dark min-h-screen flex flex-col items-center justify-center relative overflow-hidden font-display">
            {/* Background Layer */}
            <div className="bg-blur-image" data-alt="blurred high-tech automated vertical farm environment"></div>

            {/* Navigation / Top Bar */}
            <nav className="absolute top-0 w-full flex items-center justify-between px-8 py-6 z-10">
                <div className="flex items-center gap-3">
                    <Link to="/" className="text-primary size-8">
                        <svg fill="none" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
                            <path d="M44 4H30.6666V17.3334H17.3334V30.6666H4V44H44V4Z" fill="currentColor"></path>
                        </svg>
                    </Link>
                    <h1 className="text-white text-xl font-bold tracking-tight uppercase">Locust Farm <span className="text-primary/80">IOT</span></h1>
                </div>
                <div className="flex items-center gap-6">
                    <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-black/40 border border-primary/20">
                        <span className="size-2 bg-primary rounded-full animate-pulse"></span>
                        <span className="text-[10px] font-medium text-primary uppercase tracking-widest">System Online</span>
                    </div>
                    <button className="text-white/60 hover:text-white transition-colors">
                        <span className="material-symbols-outlined text-2xl">help</span>
                    </button>
                </div>
            </nav>

            {/* Main Registration Container */}
            <main className="w-full max-w-xl px-6 py-12 z-10">
                <div className="glass-card rounded-xl p-8 md:p-12 shadow-2xl relative overflow-hidden">
                    {/* Security Header Badge */}
                    <div className="flex justify-center mb-8">
                        <div className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary/10 border border-primary/30">
                            <span className="material-symbols-outlined text-primary text-sm">shield_lock</span>
                            <span className="text-[11px] font-bold text-primary uppercase tracking-widest">AES-256 Encrypted Connection</span>
                        </div>
                    </div>
                    {/* Form Title */}
                    <div className="text-center mb-10">
                        <h2 className="text-white text-3xl font-bold tracking-tight mb-2">Device Onboarding</h2>
                        <p className="text-white/50 text-sm font-light">Register your hardware container to the secure agricultural network.</p>
                    </div>

                    {/* Error Message */}
                    {error && (
                        <div className="bg-red-500/10 border border-red-500/20 text-red-500 text-[11px] p-3 rounded text-center uppercase tracking-wider mb-6">
                            {error}
                        </div>
                    )}

                    {/* Registration Form */}
                    <form className="space-y-5" onSubmit={handleRegister}>
                        {/* Full Name Field */}
                        <div className="space-y-1.5">
                            <label className="text-[11px] font-bold text-white/40 uppercase tracking-wider ml-1">Operator Full Name</label>
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-white/30 group-focus-within:text-primary transition-colors">
                                    <span className="material-symbols-outlined text-xl">person</span>
                                </div>
                                <input
                                    className="w-full bg-black/40 border border-white/10 rounded-lg py-4 pl-12 pr-4 text-white placeholder:text-white/20 focus:ring-1 focus:ring-primary focus:border-primary transition-all outline-none text-sm font-medium"
                                    placeholder="e.g. Erik Sorenson"
                                    type="text"
                                    required
                                    value={fullName}
                                    onChange={(e) => setFullName(e.target.value)}
                                />
                            </div>
                        </div>
                        {/* Email Field */}
                        <div className="space-y-1.5">
                            <label className="text-[11px] font-bold text-white/40 uppercase tracking-wider ml-1">Work Email Address</label>
                            <div className="relative group">
                                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-white/30 group-focus-within:text-primary transition-colors">
                                    <span className="material-symbols-outlined text-xl">mail</span>
                                </div>
                                <input
                                    className="w-full bg-black/40 border border-white/10 rounded-lg py-4 pl-12 pr-4 text-white placeholder:text-white/20 focus:ring-1 focus:ring-primary focus:border-primary transition-all outline-none text-sm font-medium"
                                    placeholder="operator@company.com"
                                    type="email"
                                    required
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                />
                            </div>
                        </div>
                        {/* Password and Confirm Password (Grid) */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                            <div className="space-y-1.5">
                                <label className="text-[11px] font-bold text-white/40 uppercase tracking-wider ml-1">Password</label>
                                <div className="relative group">
                                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-white/30 group-focus-within:text-primary transition-colors">
                                        <span className="material-symbols-outlined text-xl">lock</span>
                                    </div>
                                    <input
                                        className="w-full bg-black/40 border border-white/10 rounded-lg py-4 pl-12 pr-4 text-white placeholder:text-white/20 focus:ring-1 focus:ring-primary focus:border-primary transition-all outline-none text-sm font-medium"
                                        placeholder="Password"
                                        type="password"
                                        required
                                        value={password}
                                        onChange={(e) => setPassword(e.target.value)}
                                    />
                                </div>
                            </div>
                            <div className="space-y-1.5">
                                <label className="text-[11px] font-bold text-white/40 uppercase tracking-wider ml-1">Confirm Password</label>
                                <div className="relative group">
                                    <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-white/30 group-focus-within:text-primary transition-colors">
                                        <span className="material-symbols-outlined text-xl">lock_reset</span>
                                    </div>
                                    <input
                                        className="w-full bg-black/40 border border-white/10 rounded-lg py-4 pl-12 pr-4 text-white placeholder:text-white/20 focus:ring-1 focus:ring-primary focus:border-primary transition-all outline-none text-sm font-medium"
                                        placeholder="Confirm Password"
                                        type="password"
                                        required
                                        value={confirmPassword}
                                        onChange={(e) => setConfirmPassword(e.target.value)}
                                    />
                                </div>
                            </div>
                        </div>
                        {/* Registration Button */}
                        <div className="pt-6">
                            <button
                                className={`w-full ${isSubmitting ? 'bg-primary/50' : 'bg-primary'} hover:bg-primary/90 text-black font-bold py-4 rounded-lg flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(60,230,25,0.3)] transition-all active:scale-[0.98]`}
                                type="submit"
                                disabled={isSubmitting}
                            >
                                <span className="uppercase tracking-widest text-sm">{isSubmitting ? 'Processing...' : 'Register Container'}</span>
                                <span className="material-symbols-outlined">arrow_forward</span>
                            </button>
                        </div>
                    </form>
                    {/* Card Footer */}
                    <div className="mt-10 flex flex-col md:flex-row items-center justify-between border-t border-white/10 pt-6 gap-4">
                        <Link to="/login" className="text-[11px] font-medium text-primary hover:underline uppercase tracking-wider flex items-center gap-1">
                            <span className="material-symbols-outlined text-sm">login</span>
                            Already registered? Login
                        </Link>
                        <p className="text-[10px] text-white/30 uppercase tracking-tighter">Authorized Personnel Only</p>
                    </div>
                </div>
                {/* Bottom Global Info */}
                <div className="mt-8 flex justify-center gap-8">
                    <div className="flex flex-col items-center">
                        <span className="text-white/20 text-[10px] uppercase font-bold tracking-widest">Network Latency</span>
                        <span className="text-primary/70 text-xs font-medium">12ms</span>
                    </div>
                    <div className="flex flex-col items-center border-l border-white/10 pl-8">
                        <span className="text-white/20 text-[10px] uppercase font-bold tracking-widest">Uptime</span>
                        <span className="text-primary/70 text-xs font-medium">99.98%</span>
                    </div>
                    <div className="flex flex-col items-center border-l border-white/10 pl-8">
                        <span className="text-white/20 text-[10px] uppercase font-bold tracking-widest">Global Clusters</span>
                        <span className="text-primary/70 text-xs font-medium">Active</span>
                    </div>
                </div>
            </main>
            {/* Visual Accents */}
            <div className="fixed bottom-[-10%] left-[-5%] w-[40%] h-[40%] bg-primary/5 blur-[120px] rounded-full -z-10"></div>
            <div className="fixed top-[-10%] right-[-5%] w-[30%] h-[30%] bg-primary/10 blur-[100px] rounded-full -z-10"></div>
        </div>
    );
};

export default RegisterContainer;
