import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const Login = () => {
    const navigate = useNavigate();
    const { login } = useAuth();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [isSubmitting, setIsSubmitting] = useState(false);

    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setIsSubmitting(true);
        try {
            await login(email, password);
            navigate('/dashboard');
        } catch (err) {
            setError(err.message || 'Invalid credentials');
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="bg-background-dark text-white min-h-screen flex items-center justify-center overflow-hidden font-display relative">
            {/* Blurred Background Image */}
            <div className="fixed inset-0 z-0">
                <div className="absolute inset-0 bg-black/60 z-10"></div>
                <div
                    className="w-full h-full bg-cover bg-center scale-110 blur-md"
                    data-alt="Blurred high-tech automated vertical farm greenhouse"
                    style={{ backgroundImage: "url('https://lh3.googleusercontent.com/aida-public/AB6AXuAiBMDR0YMbGotws3nzfjFnPkJOiqJ1tELA9blXwJcr_hduHxfR5Z488s5cfZGMWlZTep5r-dju9tLzmkrZ3glWwqkaPz-TuXt76nA-75qCmqCWhsC9sVs6KzlrFrNk2ch82AfT9cD1vkhpIPQavPM0NLP5MVxMlveTWkl_VCNP9-qSIORSghK9J_0oIDO9ZDYupKJYtjvj0PScJR23RAChoiZZBRD6qcsIgVLL4ZnsMRlkIrT1AG1ej_FNo186BW4xBfZboR4S5vU')" }}
                >
                </div>
            </div>

            {/* Main Login Container */}
            <main className="relative z-20 w-full max-w-[440px] px-6">
                {/* Status Indicator Top */}
                <div className="flex items-center justify-center gap-2 mb-8 animate-pulse">
                    <span className="w-2 h-2 rounded-full bg-primary shadow-[0_0_8px_#3ce619]"></span>
                    <span className="text-[10px] uppercase tracking-[0.2em] text-primary/80 font-bold">System Online // Secure Link Established</span>
                </div>

                <div className="glass-card p-8 md:p-10 rounded-xl flex flex-col gap-8">
                    {/* Header */}
                    <div className="text-center">
                        <div className="flex justify-center mb-4">
                            <div className="p-3 rounded-lg border border-primary/30 bg-primary/5">
                                <span className="material-symbols-outlined text-primary text-4xl">precision_manufacturing</span>
                            </div>
                        </div>
                        <h1 className="text-2xl font-bold tracking-tight text-white mb-2 uppercase">Locust Login</h1>
                        <p className="text-white/50 text-sm font-light">Locust Farm IoT</p>
                    </div>

                    {/* Error Message */}
                    {error && (
                        <div className="bg-red-500/10 border border-red-500/20 text-red-500 text-[11px] p-3 rounded text-center uppercase tracking-wider">
                            {error}
                        </div>
                    )}

                    {/* Form */}
                    <form className="flex flex-col gap-5" onSubmit={handleLogin}>
                        {/* Email Field */}
                        <div className="flex flex-col gap-2">
                            <label className="text-[11px] uppercase tracking-widest text-primary/70 font-semibold ml-1">Operator Identifier</label>
                            <div className="input-glow flex items-center bg-black/40 border border-white/10 rounded-lg transition-all duration-300">
                                <div className="pl-4 pr-2 text-white/40">
                                    <span className="material-symbols-outlined text-[20px]">alternate_email</span>
                                </div>
                                <input
                                    className="bg-transparent border-none focus:ring-0 text-white placeholder:text-white/20 w-full py-4 text-sm font-medium outline-none"
                                    placeholder="operator@facility.io"
                                    type="email"
                                    required
                                    value={email}
                                    onChange={(e) => setEmail(e.target.value)}
                                />
                            </div>
                        </div>

                        {/* Password Field */}
                        <div className="flex flex-col gap-2">
                            <label className="text-[11px] uppercase tracking-widest text-primary/70 font-semibold ml-1">Password</label>
                            <div className="input-glow flex items-center bg-black/40 border border-white/10 rounded-lg transition-all duration-300">
                                <div className="pl-4 pr-2 text-white/40">
                                    <span className="material-symbols-outlined text-[20px]">lock</span>
                                </div>
                                <input
                                    className="bg-transparent border-none focus:ring-0 text-white placeholder:text-white/20 w-full py-4 text-sm font-medium outline-none"
                                    placeholder="Password"
                                    type="password"
                                    required
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                />
                            </div>
                        </div>

                        {/* Action Button */}
                        <button
                            className={`btn-glow mt-2 w-full ${isSubmitting ? 'bg-primary/50' : 'bg-primary'} text-background-dark py-4 rounded-lg font-bold uppercase tracking-wider text-sm transition-all duration-300 flex items-center justify-center gap-2 group`}
                            type="submit"
                            disabled={isSubmitting}
                        >
                            <span>{isSubmitting ? 'Authenticating...' : 'Initialize Access'}</span>
                            <span className="material-symbols-outlined text-[18px] group-hover:translate-x-1 transition-transform">terminal</span>
                        </button>
                    </form>

                    {/* Security Footer */}
                    <div className="flex flex-col items-center gap-6">
                        <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/5 border border-white/10">
                            <span className="material-symbols-outlined text-[14px] text-primary/80">encrypted</span>
                            <span className="text-[10px] text-white/40 uppercase tracking-tighter">AES-256 Encrypted Connection</span>
                        </div>
                        {/* Links */}
                        <div className="flex flex-col gap-3 items-center">
                            <Link to="/register-container" className="text-primary/70 hover:text-primary text-xs font-medium transition-colors duration-200 flex items-center gap-1 uppercase tracking-wide">
                                <span className="material-symbols-outlined text-[14px]">add_box</span>
                                Register New Container
                            </Link>
                            <a className="text-white/30 hover:text-white/60 text-[10px] uppercase tracking-widest transition-colors duration-200" href="#">
                                Forgot Credentials?
                            </a>
                        </div>
                    </div>
                </div>

                {/* System Meta */}
                <div className="mt-8 flex justify-between text-[10px] text-white/20 uppercase tracking-[0.2em] font-medium px-2">
                    <div>Node: US-EAST-04</div>
                    <div>v4.2.0-stable</div>
                </div>
            </main>
        </div>
    );
};

export default Login;
