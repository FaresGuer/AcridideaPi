import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { useNotifications } from '../context/NotificationContext';

const MainLayout = ({ children, title, subtitle }) => {
    const location = useLocation();
    const { notifications, clearAllNotifications } = useNotifications();
    const [showNotificationPanel, setShowNotificationPanel] = useState(false);

    const isActive = (path) => {
        return location.pathname === path ? 'bg-primary/20 text-white' : 'text-white/60 hover:bg-white/5 hover:text-white';
    };

    return (
        <div className="bg-background-dark text-white font-display flex h-screen w-full overflow-hidden selection:bg-primary/30">
            {/* Sidebar */}
            <aside className="w-64 flex flex-col border-r border-white/10 bg-surface-dark shrink-0 transition-all duration-300">
                {/* Logo Area */}
                <div className="p-6 flex items-center gap-3 border-b border-white/5">
                    <div className="size-10 bg-primary/20 rounded-lg flex items-center justify-center border border-primary/20 shadow-[0_0_15px_rgba(60,230,25,0.1)]">
                        <span className="material-symbols-outlined text-primary">bug_report</span>
                    </div>
                    <div>
                        <h1 className="text-sm font-bold leading-none tracking-wide text-white">Smart Locust</h1>
                        <p className="text-[10px] text-primary uppercase tracking-widest mt-1 font-bold">Farming System</p>
                    </div>
                </div>

                {/* Navigation Links */}
                <nav className="flex-1 px-4 py-6 space-y-2 overflow-y-auto custom-scrollbar">
                    <Link to="/dashboard" className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all group ${isActive('/dashboard')}`}>
                        <span className="material-symbols-outlined text-[20px] group-hover:text-primary transition-colors">grid_view</span>
                        <span className="text-sm font-medium tracking-wide">Dashboard</span>
                    </Link>

                    <Link to="/predictive" className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all group ${isActive('/predictive')}`}>
                        <span className="material-symbols-outlined text-[20px] group-hover:text-primary transition-colors">query_stats</span>
                        <span className="text-sm font-medium tracking-wide">Analytics</span>
                    </Link>

                    <Link to="/harvest" className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all group ${isActive('/harvest')}`}>
                        <span className="material-symbols-outlined text-[20px] group-hover:text-primary transition-colors">potted_plant</span>
                        <span className="text-sm font-medium tracking-wide">Harvest & Logistics</span>
                    </Link>

                    <Link to="/alerts" className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all group ${isActive('/alerts')}`}>
                        <span className="material-symbols-outlined text-[20px] group-hover:text-primary transition-colors">notifications_active</span>
                        <span className="text-sm font-medium tracking-wide">Alerts & Logs</span>
                    </Link>

                    <div className="pt-4 mt-4 border-t border-white/5">
                        <span className="text-[10px] text-white/30 uppercase tracking-widest font-bold px-4 mb-2 block">System</span>
                        <Link to="/profile" className={`flex items-center gap-3 px-4 py-3 rounded-lg transition-all group ${isActive('/profile')}`}>
                            <span className="material-symbols-outlined text-[20px] group-hover:text-primary transition-colors">settings</span>
                            <span className="text-sm font-medium tracking-wide">Settings</span>
                        </Link>
                    </div>
                </nav>

                {/* User Profile Snippet */}
                <div className="p-4 border-t border-white/10 bg-black/20">
                    <div className="flex items-center gap-3 p-3 rounded-lg bg-white/5 border border-white/5 hover:border-primary/20 transition-all cursor-pointer">
                        <div className="size-8 rounded-full bg-slate-700 border border-white/10 overflow-hidden">
                            <img alt="User" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAajpuWivku-MIxYj9_OBcKIkJMxpcV_4W83uE3hivs8QSqUalabV6KToYUxKe5bHqIv9ISZubyZek4w3tQsnzF5eKflfbm2x8oAjfi0XvzCUEgUtHHx0CMp_VjtITNnKkvmUdObHJnQ6c5ih57xeoVqYj-sDwPumukdzjf_bHdWsQHkBHoqC-m2Y8uJXmDmBLbpbW1q2W7ehFR4bmPQ_vaPr94zqTSs4MeGu-VfrZX25I1h4JRTO7K73Ene3SmWhAPISEpznH6v5g" />
                        </div>
                        <div className="flex-1 min-w-0">
                            <p className="text-xs font-bold text-white truncate">Admin Operations</p>
                            <p className="text-[10px] text-primary truncate">● Online</p>
                        </div>
                        <Link to="/login" className="material-symbols-outlined text-white/40 hover:text-red-400 text-xs transition-colors">logout</Link>
                    </div>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1 flex flex-col min-w-0 bg-background-dark relative">
                {/* Background Grid Overlay */}
                <div className="absolute inset-0 grid-overlay opacity-10 pointer-events-none"></div>

                {/* Header */}
                <header className="h-16 border-b border-white/10 bg-surface-dark/80 backdrop-blur-md px-8 flex items-center justify-between shrink-0 z-20 relative">
                    <div className="flex flex-col">
                        <div className="flex items-center gap-2 text-[10px] text-white/40 uppercase tracking-widest font-mono">
                            <span>System</span>
                            <span className="material-symbols-outlined text-[10px]">chevron_right</span>
                            <span className="text-primary">{title || 'Dashboard'}</span>
                        </div>
                        <h2 className="text-lg font-bold text-white tracking-tight">{subtitle || title || 'Overview'}</h2>
                    </div>

                    <div className="flex items-center gap-6">
                        <div className="hidden md:flex items-center gap-2 px-3 py-1.5 rounded bg-primary/10 border border-primary/20">
                            <span className="relative flex h-2 w-2">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-primary opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2 w-2 bg-primary"></span>
                            </span>
                            <span className="text-[10px] font-bold text-primary tracking-widest uppercase">System Nominal</span>
                        </div>

                        <div className="h-8 w-px bg-white/10 mx-2"></div>

                        <div className="flex items-center gap-3">
                            <button className="size-9 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-white/60 hover:text-white transition-all">
                                <span className="material-symbols-outlined text-[20px]">help</span>
                            </button>
                            <div className="relative">
                                <button
                                    onClick={() => setShowNotificationPanel(!showNotificationPanel)}
                                    className="size-9 rounded-full bg-white/5 hover:bg-white/10 flex items-center justify-center text-white/60 hover:text-white transition-all relative"
                                >
                                    <span className="material-symbols-outlined text-[20px]">notifications</span>
                                    {notifications.length > 0 && (
                                        <span className="absolute top-1 right-1 size-5 bg-red-500 rounded-full border border-background-dark flex items-center justify-center text-xs font-bold text-white">
                                            {notifications.length > 9 ? '9+' : notifications.length}
                                        </span>
                                    )}
                                </button>

                                {/* Notification Panel */}
                                {showNotificationPanel && (
                                    <div className="absolute right-0 top-12 w-96 bg-surface-dark border border-white/10 rounded-lg shadow-xl z-50 max-h-96 overflow-y-auto flex flex-col">
                                        <div className="sticky top-0 bg-surface-dark border-b border-white/10 p-4 flex items-center justify-between">
                                            <h3 className="text-sm font-bold text-white">Notifications ({notifications.length})</h3>
                                            {notifications.length > 0 && (
                                                <button
                                                    onClick={() => {
                                                        clearAllNotifications();
                                                        setShowNotificationPanel(false);
                                                    }}
                                                    className="text-xs text-red-400 hover:text-red-300 font-bold uppercase flex items-center gap-1"
                                                >
                                                    <span className="material-symbols-outlined text-sm">delete_sweep</span>
                                                    Clear
                                                </button>
                                            )}
                                        </div>
                                        {notifications.length > 0 ? (
                                            notifications.slice(0, 10).map((notif) => {
                                                const iconColor = notif.color === 'red' ? 'text-red-500' : notif.color === 'amber' ? 'text-amber-400' : 'text-cyan-400';
                                                return (
                                                    <div key={notif.id} className="border-b border-white/5 p-4 hover:bg-white/5 transition-colors">
                                                        <div className="flex gap-3">
                                                            <span className={`material-symbols-outlined text-lg ${iconColor}`}>
                                                                {notif.icon}
                                                            </span>
                                                            <div className="flex-1 min-w-0">
                                                                <p className="text-xs font-bold text-white">{notif.title}</p>
                                                                <p className="text-[10px] text-white/60 mt-1 line-clamp-2">{notif.description}</p>
                                                                <p className="text-[9px] text-white/40 mt-2">{notif.source} • {notif.timestamp}</p>
                                                            </div>
                                                        </div>
                                                    </div>
                                                );
                                            })
                                        ) : (
                                            <div className="p-4 text-center text-white/40 text-xs">No notifications</div>
                                        )}
                                        {notifications.length > 10 && (
                                            <Link
                                                to="/alerts"
                                                className="p-3 text-center text-primary text-xs font-bold hover:bg-white/5 border-t border-white/5"
                                                onClick={() => setShowNotificationPanel(false)}
                                            >
                                                View All Alerts →
                                            </Link>
                                        )}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </header>

                {/* Content Area */}
                <div className="flex-1 overflow-hidden relative z-10">
                    {children}
                </div>
            </main>
        </div>
    );
};

export default MainLayout;
