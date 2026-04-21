import React, { useState } from 'react';
import MainLayout from '../components/MainLayout';
import { useNotifications } from '../context/NotificationContext';
import { useTheme } from '../context/ThemeContext';

const Alerts = () => {
    const { isDarkMode } = useTheme();
    const { notifications, clearAllNotifications } = useNotifications();
    const [activeFilter, setActiveFilter] = useState('All');
    const [searchText, setSearchText] = useState('');

    const filters = ['All', 'Critical', 'Warning', 'System'];

    const textColor = isDarkMode ? '#ffffff' : '#1a1a1a';
    const labelColor = isDarkMode ? '#ffffff' : '#4a4a4a';

    const filteredAlerts = notifications.filter(alert => {
        const matchesFilter = activeFilter === 'All' || alert.severity === activeFilter;
        const matchesSearch = searchText === '' ||
            alert.title.toLowerCase().includes(searchText.toLowerCase()) ||
            alert.description.toLowerCase().includes(searchText.toLowerCase()) ||
            alert.source.toLowerCase().includes(searchText.toLowerCase());
        return matchesFilter && matchesSearch;
    });

    const getColorClasses = (color) => {
        const colors = {
            red: { icon: 'text-red-500', badge: 'text-red-400 bg-red-500/15 border-red-500/30' },
            amber: { icon: 'text-amber-400', badge: 'text-amber-300 bg-amber-500/15 border-amber-500/30' },
            cyan: { icon: 'text-cyan-400', badge: 'text-cyan-300 bg-cyan-500/15 border-cyan-500/30' }
        };
        return colors[color];
    };

    return (
        <MainLayout title="Alerts & Logs" subtitle="System Diagnostics & Event Log">
            <div className="flex flex-col h-full overflow-y-auto custom-scrollbar p-6 gap-6 pb-20">
                <div className="glass-panel p-5 rounded-xl border border-white/5 shrink-0">
                    <div className="flex items-center justify-between gap-6 flex-wrap">
                        <div className="flex gap-2 flex-wrap">
                            {filters.map((filter) => (
                                <button
                                    key={filter}
                                    onClick={() => setActiveFilter(filter)}
                                    className={`px-4 py-2 rounded-lg text-xs font-bold uppercase tracking-wider transition-all ${activeFilter === filter
                                        ? 'bg-primary text-background-dark shadow-[0_0_15px_rgba(60,230,25,0.4)]'
                                        : 'bg-white/5 text-white/60 hover:bg-white/10 hover:text-white'
                                        }`}
                                >
                                    {filter}
                                </button>
                            ))}
                        </div>
                        <div className="flex items-center gap-4 flex-wrap">
                            <div className="relative group">
                                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-white/40 group-focus-within:text-primary transition-colors">search</span>
                                <input
                                    type="text"
                                    placeholder="Search logs..."
                                    value={searchText}
                                    onChange={(e) => setSearchText(e.target.value)}
                                    className="bg-background-dark border border-white/10 rounded-lg pl-10 pr-4 py-2 text-xs text-white placeholder-white/20 focus:outline-none focus:border-primary/50 focus:ring-1 focus:ring-primary/50 transition-all w-64"
                                />
                            </div>
                            {notifications.length > 0 && (
                                <button
                                    onClick={clearAllNotifications}
                                    className="flex items-center gap-2 px-4 py-2 bg-red-500/10 hover:bg-red-500/20 rounded-lg border border-red-500/20 text-red-400 text-xs font-bold transition-all"
                                >
                                    <span className="material-symbols-outlined text-sm">delete_sweep</span>
                                    Clear All ({notifications.length})
                                </button>
                            )}
                        </div>
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-4 gap-6 flex-1 min-h-0">
                    <div className="lg:col-span-3 glass-panel rounded-xl border border-white/5 flex flex-col overflow-hidden">
                        <div style={{ backgroundColor: isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' }} className="grid grid-cols-[1fr_2fr_1fr_1fr_1fr] gap-4 px-6 py-4 border-b border-white/10">
                            <div style={{ color: labelColor }} className="text-[11px] font-bold uppercase tracking-widest">Severity</div>
                            <div style={{ color: labelColor }} className="text-[11px] font-bold uppercase tracking-widest">Message</div>
                            <div style={{ color: labelColor }} className="text-[11px] font-bold uppercase tracking-widest">Source</div>
                            <div style={{ color: labelColor }} className="text-[11px] font-bold uppercase tracking-widest">Time</div>
                            <div style={{ color: labelColor }} className="text-[11px] font-bold uppercase tracking-widest">Action</div>
                        </div>
                        <div className="flex-1 overflow-y-auto custom-scrollbar">
                            {filteredAlerts.length > 0 ? (
                                filteredAlerts.map((alert) => {
                                    const colorClass = getColorClasses(alert.color);
                                    return (
                                        <div key={alert.id} style={{ borderColor: isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' }} className="grid grid-cols-[1fr_2fr_1fr_1fr_1fr] gap-4 px-6 py-4 border-b items-center hover:bg-primary/5 transition-colors">
                                            <div className="flex items-center gap-2">
                                                <span className={`material-symbols-outlined text-lg ${colorClass.icon}`}>{alert.icon}</span>
                                                <span className={`font-bold text-xs uppercase px-2 py-1 rounded border ${colorClass.badge}`}>{alert.severity}</span>
                                            </div>
                                            <div>
                                                <p style={{ color: textColor }} className="font-bold text-sm">{alert.title}</p>
                                                <p style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }} className="text-[10px] mt-1">{alert.description}</p>
                                            </div>
                                            <div style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }} className="font-mono text-xs">{alert.source}</div>
                                            <div style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }} className="font-mono text-xs">{alert.timestamp}</div>
                                            <button className="text-primary hover:text-white hover:bg-primary/20 border border-primary/30 hover:border-primary/50 px-3 py-1.5 rounded text-[10px] font-bold uppercase transition-all">Resolve</button>
                                        </div>
                                    );
                                })
                            ) : (
                                <div style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }} className="flex items-center justify-center h-32 italic">No alerts found</div>
                            )}
                        </div>
                        <div style={{ backgroundColor: isDarkMode ? 'rgba(60,230,25,0.05)' : 'rgba(60,230,25,0.02)' }} className="p-4 border-t border-white/10">
                            <span style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }} className="text-[10px] font-mono uppercase">Showing {filteredAlerts.length} of {notifications.length}</span>
                        </div>
                    </div>

                    <div className="glass-panel rounded-xl border border-white/5 p-6 flex flex-col gap-6">
                        <div>
                            <h3 style={{ color: labelColor }} className="text-sm font-bold uppercase tracking-wider mb-5">System Health</h3>
                            <div className="space-y-5">
                                <div>
                                    <div className="flex justify-between text-xs mb-2">
                                        <span className="text-primary font-bold">Critical</span>
                                        <span className="text-primary font-bold">{notifications.filter(a => a.severity === 'Critical').length}</span>
                                    </div>
                                    <div className="w-full bg-background-dark/60 h-2 rounded-full overflow-hidden border border-white/10">
                                        <div className="bg-red-500 h-full" style={{ width: `${Math.min((notifications.filter(a => a.severity === 'Critical').length / 10) * 100, 100)}%` }}></div>
                                    </div>
                                </div>
                                <div>
                                    <div className="flex justify-between text-xs mb-2">
                                        <span className="text-amber-300 font-bold">Warning</span>
                                        <span className="text-amber-300 font-bold">{notifications.filter(a => a.severity === 'Warning').length}</span>
                                    </div>
                                    <div className="w-full bg-background-dark/60 h-2 rounded-full overflow-hidden border border-white/10">
                                        <div className="bg-amber-400 h-full" style={{ width: `${Math.min((notifications.filter(a => a.severity === 'Warning').length / 10) * 100, 100)}%` }}></div>
                                    </div>
                                </div>
                                <div>
                                    <div className="flex justify-between text-xs mb-2">
                                        <span className="text-cyan-300 font-bold">System</span>
                                        <span className="text-cyan-300 font-bold">{notifications.filter(a => a.severity === 'System').length}</span>
                                    </div>
                                    <div className="w-full bg-background-dark/60 h-2 rounded-full overflow-hidden border border-white/10">
                                        <div className="bg-cyan-400 h-full" style={{ width: `${Math.min((notifications.filter(a => a.severity === 'System').length / 10) * 100, 100)}%` }}></div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div style={{ borderColor: isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)' }} className="border-t pt-5">
                            <h3 style={{ color: labelColor }} className="text-sm font-bold uppercase tracking-wider mb-4">Summary</h3>
                            <div className="space-y-3">
                                <div className="flex items-center justify-between p-3 bg-red-500/10 border border-red-500/20 rounded-lg">
                                    <span className="text-red-300 font-bold text-xs">Critical</span>
                                    <span className="text-white font-bold text-lg">{notifications.filter(a => a.severity === 'Critical').length}</span>
                                </div>
                                <div className="flex items-center justify-between p-3 bg-amber-500/10 border border-amber-500/20 rounded-lg">
                                    <span className="text-amber-300 font-bold text-xs">Warning</span>
                                    <span className="text-white font-bold text-lg">{notifications.filter(a => a.severity === 'Warning').length}</span>
                                </div>
                                <div className="flex items-center justify-between p-3 bg-cyan-400/10 border border-cyan-400/20 rounded-lg">
                                    <span className="text-cyan-300 font-bold text-xs">System</span>
                                    <span className="text-white font-bold text-lg">{notifications.filter(a => a.severity === 'System').length}</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </MainLayout>
    );
};

export default Alerts;

