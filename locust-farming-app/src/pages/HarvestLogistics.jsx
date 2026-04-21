import React, { useEffect, useMemo, useState } from 'react';
import MainLayout from '../components/MainLayout';
import { useAuth } from '../context/AuthContext';
import { apiRequest, authHeaders } from '../services/api';

function computeReadiness(data) {
    if (!data) return 0;

    const t = typeof data.temperature === 'number' ? data.temperature : null;
    const h = typeof data.humidity === 'number' ? data.humidity : null;
    const l = typeof data.light_level === 'number' ? data.light_level : null;

    if (t == null || h == null || l == null) return 0;

    const tempScore = Math.max(0, 100 - Math.abs(t - 28) * 6);
    const humScore = Math.max(0, 100 - Math.abs(h - 60) * 2);
    const lightScore = Math.max(0, 100 - Math.abs(l - 500) * 0.1);

    return Math.round((tempScore + humScore + lightScore) / 3);
}

const HarvestLogistics = () => {
    const { token } = useAuth();
    const [containers, setContainers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        if (!token) return;

        const load = async () => {
            setLoading(true);
            setError('');
            try {
                const rows = await apiRequest('/containers', { headers: authHeaders(token) });
                const withReadiness = rows.map((c) => ({
                    ...c,
                    readiness: computeReadiness(c.data),
                }));
                withReadiness.sort((a, b) => b.readiness - a.readiness);
                setContainers(withReadiness);
            } catch (err) {
                setError(err.message || 'Failed to load containers');
            } finally {
                setLoading(false);
            }
        };

        load();
        const timer = setInterval(load, 15000);
        return () => clearInterval(timer);
    }, [token]);

    const summary = useMemo(() => {
        const ready = containers.filter((c) => c.readiness >= 75).length;
        const warning = containers.filter((c) => c.readiness >= 50 && c.readiness < 75).length;
        const low = containers.filter((c) => c.readiness < 50).length;
        return { ready, warning, low, total: containers.length };
    }, [containers]);

    return (
        <MainLayout title="Harvest & Logistics" subtitle="Database-backed operational readiness">
            <div className="flex flex-col h-full overflow-y-auto custom-scrollbar p-6 gap-6 pb-24">
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                    <div className="glass-panel p-5 rounded-xl border border-white/5">
                        <p className="text-xs uppercase tracking-wider text-white/60">Total Containers</p>
                        <h3 className="text-3xl font-black text-white mt-2">{summary.total}</h3>
                    </div>
                    <div className="glass-panel p-5 rounded-xl border border-white/5">
                        <p className="text-xs uppercase tracking-wider text-white/60">Ready Queue</p>
                        <h3 className="text-3xl font-black text-primary mt-2">{summary.ready}</h3>
                    </div>
                    <div className="glass-panel p-5 rounded-xl border border-white/5">
                        <p className="text-xs uppercase tracking-wider text-white/60">Needs Attention</p>
                        <h3 className="text-3xl font-black text-amber-400 mt-2">{summary.warning}</h3>
                    </div>
                    <div className="glass-panel p-5 rounded-xl border border-white/5">
                        <p className="text-xs uppercase tracking-wider text-white/60">Low Readiness</p>
                        <h3 className="text-3xl font-black text-red-400 mt-2">{summary.low}</h3>
                    </div>
                </div>

                {loading && <div className="text-white/70">Loading harvest data...</div>}
                {error && <div className="text-red-400 text-sm">{error}</div>}

                {!loading && !error && (
                    <div className="glass-panel rounded-xl border border-white/5 overflow-hidden">
                        <div className="grid grid-cols-[1.3fr_0.8fr_0.8fr_0.8fr_0.9fr] gap-4 px-6 py-4 border-b border-white/10 bg-white/5">
                            <div className="text-[11px] font-bold uppercase tracking-widest text-white/70">Container</div>
                            <div className="text-[11px] font-bold uppercase tracking-widest text-white/70">Temperature</div>
                            <div className="text-[11px] font-bold uppercase tracking-widest text-white/70">Humidity</div>
                            <div className="text-[11px] font-bold uppercase tracking-widest text-white/70">Luminosity</div>
                            <div className="text-[11px] font-bold uppercase tracking-widest text-white/70">Readiness</div>
                        </div>

                        <div className="max-h-[560px] overflow-y-auto custom-scrollbar">
                            {containers.map((container) => {
                                const d = container.data || {};
                                const readinessColor =
                                    container.readiness >= 75
                                        ? 'text-primary border-primary/40 bg-primary/10'
                                        : container.readiness >= 50
                                            ? 'text-amber-400 border-amber-400/40 bg-amber-400/10'
                                            : 'text-red-400 border-red-400/40 bg-red-400/10';

                                return (
                                    <div key={container.id} className="grid grid-cols-[1.3fr_0.8fr_0.8fr_0.8fr_0.9fr] gap-4 px-6 py-4 border-b border-white/5 items-center">
                                        <div>
                                            <p className="text-sm font-bold text-white">{container.name}</p>
                                            <p className="text-[10px] text-white/50">ID: {container.id}</p>
                                        </div>
                                        <div className="text-sm text-white/80">{typeof d.temperature === 'number' ? `${d.temperature.toFixed(1)} degC` : '--'}</div>
                                        <div className="text-sm text-white/80">{typeof d.humidity === 'number' ? `${d.humidity.toFixed(1)} %` : '--'}</div>
                                        <div className="text-sm text-white/80">{typeof d.light_level === 'number' ? `${d.light_level.toFixed(1)} lux` : '--'}</div>
                                        <div>
                                            <span className={`px-3 py-1 rounded-lg text-xs font-bold border ${readinessColor}`}>
                                                {container.readiness}%
                                            </span>
                                        </div>
                                    </div>
                                );
                            })}

                            {containers.length === 0 && (
                                <div className="px-6 py-8 text-sm text-white/60 text-center">No containers available.</div>
                            )}
                        </div>
                    </div>
                )}
            </div>
        </MainLayout>
    );
};

export default HarvestLogistics;
