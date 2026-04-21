import React, { useEffect, useMemo, useState } from 'react';
import MainLayout from '../components/MainLayout';
import { useAuth } from '../context/AuthContext';
import { apiRequest, authHeaders } from '../services/api';
import {
    Area,
    AreaChart,
    CartesianGrid,
    Line,
    LineChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from 'recharts';

const HISTORY_HOURS = 24;

function formatTime(iso) {
    if (!iso) return '--';
    return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function avg(values) {
    const valid = values.filter((v) => typeof v === 'number');
    if (valid.length === 0) return null;
    return valid.reduce((a, b) => a + b, 0) / valid.length;
}

const PredictiveIntelligence = () => {
    const { token } = useAuth();
    const [containers, setContainers] = useState([]);
    const [selectedContainerId, setSelectedContainerId] = useState('');
    const [history, setHistory] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        if (!token) return;
        const run = async () => {
            setLoading(true);
            setError('');
            try {
                const rows = await apiRequest('/containers', { headers: authHeaders(token) });
                setContainers(rows);
                if (rows.length > 0) {
                    setSelectedContainerId(String(rows[0].id));
                }
            } catch (err) {
                setError(err.message || 'Failed to load containers');
            } finally {
                setLoading(false);
            }
        };
        run();
    }, [token]);

    useEffect(() => {
        if (!token || !selectedContainerId) return;

        const loadHistory = async () => {
            try {
                const res = await apiRequest(
                    `/containers/${selectedContainerId}/data/history?hours=${HISTORY_HOURS}`,
                    { headers: authHeaders(token) }
                );
                const points = (res.history || [])
                    .filter((h) => h.timestamp)
                    .map((h) => ({
                        timestamp: h.timestamp,
                        time: formatTime(h.timestamp),
                        temperature: h.temperature,
                        humidity: h.humidity,
                        light_level: h.light_level,
                    }));
                setHistory(points);
            } catch (err) {
                setError(err.message || 'Failed to load history');
            }
        };

        loadHistory();
        const timer = setInterval(loadHistory, 10000);
        return () => clearInterval(timer);
    }, [token, selectedContainerId]);

    const metrics = useMemo(() => {
        const temps = history.map((h) => h.temperature);
        const hums = history.map((h) => h.humidity);
        const lights = history.map((h) => h.light_level);

        const avgTemp = avg(temps);
        const avgHum = avg(hums);
        const avgLight = avg(lights);

        const healthScore = Math.max(
            0,
            Math.min(
                100,
                100 - (Math.abs((avgTemp ?? 24) - 24) * 4 + Math.abs((avgHum ?? 60) - 60) * 0.8)
            )
        );

        const lastTemp = temps.filter((v) => typeof v === 'number').slice(-1)[0];
        const riskLevel =
            lastTemp == null
                ? 'UNKNOWN'
                : lastTemp < 15 || lastTemp > 35
                    ? 'HIGH'
                    : lastTemp < 20 || lastTemp > 30
                        ? 'MEDIUM'
                        : 'LOW';

        return {
            avgTemp,
            avgHum,
            avgLight,
            healthScore,
            riskLevel,
        };
    }, [history]);

    const forecastSeries = useMemo(() => {
        const base = history.slice(-12).map((h) => ({ time: h.time, actual: h.temperature, predicted: null }));
        const recent = history.slice(-6).map((h) => h.temperature).filter((v) => typeof v === 'number');
        const baseline = avg(recent);

        if (baseline == null) {
            return base;
        }

        const synthetic = [
            { time: '+10m', actual: null, predicted: baseline },
            { time: '+20m', actual: null, predicted: baseline + 0.2 },
            { time: '+30m', actual: null, predicted: baseline + 0.3 },
        ];

        return [...base, ...synthetic];
    }, [history]);

    const activitySeries = useMemo(() => {
        return history.slice(-24).map((h) => {
            const t = typeof h.temperature === 'number' ? h.temperature : 24;
            const humidity = typeof h.humidity === 'number' ? h.humidity : 60;
            const activity = Math.max(0, Math.min(100, 100 - Math.abs(t - 28) * 4 - Math.abs(humidity - 60) * 0.7));
            return {
                time: h.time,
                activity: Number(activity.toFixed(1)),
            };
        });
    }, [history]);

    return (
        <MainLayout title="Analytics" subtitle="Database-backed insights from live container history">
            <div className="flex flex-col h-full overflow-y-auto custom-scrollbar p-6 gap-6 pb-24">
                <div className="glass-panel p-4 rounded-xl border border-white/5 flex items-center gap-4 flex-wrap">
                    <label htmlFor="container-select" className="text-xs uppercase tracking-wider font-semibold text-white/80">
                        Container
                    </label>
                    <select
                        id="container-select"
                        className="bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-sm text-white"
                        value={selectedContainerId}
                        onChange={(e) => setSelectedContainerId(e.target.value)}
                    >
                        {containers.length === 0 && <option value="">No container available</option>}
                        {containers.map((container) => (
                            <option key={container.id} value={String(container.id)}>
                                {container.name}
                            </option>
                        ))}
                    </select>
                </div>

                {loading && <div className="text-white/70">Loading analytics...</div>}
                {error && <div className="text-red-400 text-sm">{error}</div>}

                {!loading && !error && (
                    <>
                        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                            <div className="glass-panel p-5 rounded-xl border border-white/5">
                                <p className="text-xs uppercase tracking-wider text-white/60">Avg Temperature</p>
                                <h3 className="text-3xl font-black text-white mt-2">{metrics.avgTemp?.toFixed(1) ?? '--'} degC</h3>
                            </div>
                            <div className="glass-panel p-5 rounded-xl border border-white/5">
                                <p className="text-xs uppercase tracking-wider text-white/60">Avg Humidity</p>
                                <h3 className="text-3xl font-black text-white mt-2">{metrics.avgHum?.toFixed(1) ?? '--'} %</h3>
                            </div>
                            <div className="glass-panel p-5 rounded-xl border border-white/5">
                                <p className="text-xs uppercase tracking-wider text-white/60">Health Score</p>
                                <h3 className="text-3xl font-black text-primary mt-2">{metrics.healthScore.toFixed(1)}%</h3>
                            </div>
                            <div className="glass-panel p-5 rounded-xl border border-white/5">
                                <p className="text-xs uppercase tracking-wider text-white/60">Risk Level</p>
                                <h3 className="text-3xl font-black mt-2 text-amber-400">{metrics.riskLevel}</h3>
                            </div>
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                            <div className="glass-panel p-6 rounded-xl border border-white/5 h-[360px]">
                                <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-4">Temperature Forecast</h3>
                                <ResponsiveContainer width="100%" height="90%">
                                    <AreaChart data={forecastSeries}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(100,100,100,0.3)" />
                                        <XAxis dataKey="time" stroke="#999" tick={{ fontSize: 10 }} />
                                        <YAxis stroke="#999" tick={{ fontSize: 10 }} />
                                        <Tooltip />
                                        <Line type="monotone" dataKey="actual" stroke="#22d3ee" strokeWidth={3} dot={false} connectNulls />
                                        <Area type="monotone" dataKey="predicted" stroke="#a855f7" fill="#a855f7" fillOpacity={0.18} connectNulls />
                                    </AreaChart>
                                </ResponsiveContainer>
                            </div>

                            <div className="glass-panel p-6 rounded-xl border border-white/5 h-[360px]">
                                <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-4">Activity Pattern (Derived)</h3>
                                <ResponsiveContainer width="100%" height="90%">
                                    <LineChart data={activitySeries}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(100,100,100,0.3)" />
                                        <XAxis dataKey="time" stroke="#999" tick={{ fontSize: 10 }} />
                                        <YAxis stroke="#999" tick={{ fontSize: 10 }} domain={[0, 100]} />
                                        <Tooltip />
                                        <Line type="monotone" dataKey="activity" stroke="#3ce619" strokeWidth={2} dot={false} connectNulls />
                                    </LineChart>
                                </ResponsiveContainer>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </MainLayout>
    );
};

export default PredictiveIntelligence;
