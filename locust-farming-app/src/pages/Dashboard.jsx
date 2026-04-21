import React, { useEffect, useMemo, useState } from 'react';
import MainLayout from '../components/MainLayout';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { apiRequest, authHeaders } from '../services/api';
import { useContainerMonitoring } from '../hooks/useContainerMonitoring';
import {
    ResponsiveContainer,
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    Label,
} from 'recharts';

const POLL_INTERVAL_MS = 5000;
const MAX_HISTORY_POINTS = 120;

const sensorMeta = {
    temperature: { label: 'Temperature', unit: '°C', color: '#f97316' },
    humidity: { label: 'Humidity', unit: '%', color: '#3b82f6' },
    light_level: { label: 'Luminosity', unit: 'lux', color: '#eab308' },
    gas_level: { label: 'Gas', unit: 'ppm', color: '#f97316' },
};

const sensorIcons = {
    temperature: 'thermostat',
    humidity: 'water_drop',
    light_level: 'light_mode',
    gas_level: 'air',
};

function formatChartTime(isoDate) {
    const d = new Date(isoDate);
    return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function getCurrentValue(data, key) {
    const value = data?.[key];
    return Number.isFinite(value) ? value : null;
}

function getTrendPercent(historyRows, key) {
    const values = historyRows
        .map((row) => row?.[key])
        .filter((value) => Number.isFinite(value));

    if (values.length < 2) {
        return null;
    }

    const previous = values[values.length - 2];
    const current = values[values.length - 1];
    if (!Number.isFinite(previous) || previous === 0) {
        return null;
    }

    return ((current - previous) / Math.abs(previous)) * 100;
}

function buildMobileStyleSeries(historyRows, key, currentValue) {
    const values = historyRows
        .map((row) => row?.[key])
        .filter((value) => Number.isFinite(value))
        .slice(-7);

    const seriesValues = values.length > 0
        ? values
        : (Number.isFinite(currentValue) ? Array.from({ length: 7 }, () => currentValue) : []);

    return seriesValues.map((value, index) => ({
        index,
        label: ['00:00', '04:00', '08:00', '12:00', '16:00', '20:00', '24:00'][index] ?? '',
        [key]: value,
    }));
}

const Dashboard = () => {
    const { token } = useAuth();
    const { isDarkMode } = useTheme();
    const [containers, setContainers] = useState([]);
    const [selectedContainerId, setSelectedContainerId] = useState('');
    const [currentData, setCurrentData] = useState(null);
    const [history, setHistory] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    const [sensorFilter, setSensorFilter] = useState('All');
    const [dateFilter, setDateFilter] = useState('');

    // Enable container monitoring for alerts
    useContainerMonitoring(true);

    // Theme-aware colors
    const textColor = isDarkMode ? '#ffffff' : '#1a1a1a';
    const labelColor = isDarkMode ? '#ffffff' : '#4a4a4a';
    const gridColor = isDarkMode ? 'rgba(100,100,100,0.3)' : 'rgba(100,100,100,0.2)';

    const loadContainers = async () => {
        if (!token) return;
        const data = await apiRequest('/containers', { headers: authHeaders(token) });
        setContainers(data);
        if (data.length > 0 && !selectedContainerId) {
            setSelectedContainerId(String(data[0].id));
        }
    };

    const loadHistory = async (containerId) => {
        if (!token || !containerId) return;
        try {
            const histResponse = await apiRequest(`/containers/${containerId}/data/history?hours=24`, { headers: authHeaders(token) });
            const rows = Array.isArray(histResponse.history) ? histResponse.history : [];
            const formattedHistory = rows
                .filter((h) => h.timestamp)
                .map((h) => ({
                    timestamp: h.timestamp,
                    time: formatChartTime(h.timestamp),
                    temperature: h.temperature ?? null,
                    humidity: h.humidity ?? null,
                    light_level: h.light_level ?? null,
                    gas_level: h.gas_level ?? null,
                }))
                .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
            setHistory(formattedHistory);
        } catch (err) {
            console.error('Failed to load historical data:', err);
            setHistory([]);
        }
    };

    const loadCurrentData = async (containerId) => {
        if (!token || !containerId) return;
        try {
            const data = await apiRequest(`/containers/${containerId}/data`, { headers: authHeaders(token) });
            setCurrentData({
                last_updated: data.last_updated ?? null,
                temperature: data.temperature ?? null,
                humidity: data.humidity ?? null,
                light_level: data.light_level ?? null,
                gas_level: data.gas_level ?? null,
            });
        } catch (err) {
            console.error('Failed to load current container data:', err);
        }
    };

    useEffect(() => {
        const run = async () => {
            setLoading(true);
            setError('');
            try {
                await loadContainers();
            } catch (err) {
                setError(err.message || 'Failed to load containers');
            } finally {
                setLoading(false);
            }
        };
        run();
    }, [token]);

    // Load initial DB history when container changes
    useEffect(() => {
        if (!selectedContainerId || !token) return;
        setHistory([]);
        Promise.all([
            loadCurrentData(selectedContainerId),
            loadHistory(selectedContainerId),
        ]);
    }, [selectedContainerId, token]);

        // Poll DB history every 5 seconds.
    useEffect(() => {
        if (!selectedContainerId || !token) return;

        let active = true;
        const fetchLoop = async () => {
            try {
                await Promise.all([
                    loadCurrentData(selectedContainerId),
                    loadHistory(selectedContainerId),
                ]);
            } catch (err) {
                if (active) {
                    setError(err.message || 'Failed to load sensor data');
                }
            }
        };

        fetchLoop();
        const timer = setInterval(fetchLoop, POLL_INTERVAL_MS);

        return () => {
            active = false;
            clearInterval(timer);
        };
    }, [selectedContainerId, token]);

    const kpis = useMemo(() => {
        if (!currentData) return [];
        return [
            {
                key: 'temperature',
                title: 'Temperature',
                value: currentData.temperature,
                suffix: 'degC',
                icon: 'thermostat',
            },
            {
                key: 'humidity',
                title: 'Humidity',
                value: currentData.humidity,
                suffix: '%',
                icon: 'humidity_percentage',
            },
            {
                key: 'light_level',
                title: 'Luminosity',
                value: currentData.light_level,
                suffix: 'lux',
                icon: 'light_mode',
            },
        ];
    }, [currentData]);

    const logs = useMemo(() => {
        return history
            .flatMap((row) =>
                Object.keys(sensorMeta).map((key) => ({
                    id: `${row.timestamp}-${key}`,
                    key: key,
                    timestamp: row.timestamp,
                    sensor: sensorMeta[key].label,
                    value: row[key],
                    unit: sensorMeta[key].unit,
                }))
            )
            .filter((log) => log.value !== null)
            .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    }, [history]);

    const chartSeriesBySensor = useMemo(() => {
        return Object.fromEntries(
            Object.keys(sensorMeta).map((key) => [
                key,
                buildMobileStyleSeries(history, key, currentData?.[key]),
            ])
        );
    }, [history, currentData]);

    const filteredLogs = useMemo(() => {
        return logs.filter((log) => {
            const matchesSensor = sensorFilter === 'All' || log.sensor === sensorFilter;
            const matchesDate = !dateFilter || log.timestamp.startsWith(dateFilter);
            return matchesSensor && matchesDate;
        });
    }, [logs, sensorFilter, dateFilter]);

    return (
        <MainLayout title="Dashboard" subtitle="Shared Live Monitoring">
            <div className="flex flex-col h-full min-h-0 overflow-y-auto custom-scrollbar p-6 gap-6 pb-24">
            <div className="glass-panel p-4 rounded-xl border border-white/5 flex items-center gap-4 flex-wrap">
                    <label htmlFor="container-select" style={{ color: labelColor }} className="text-xs uppercase tracking-wider font-semibold">
                        Container
                    </label>
                    <select
                        id="container-select"
                        className="bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-sm text-white"
                        value={selectedContainerId}
                        onChange={(e) => {
                            setHistory([]);
                            setSelectedContainerId(e.target.value);
                        }}
                    >
                        {containers.length === 0 && <option value="">No container available</option>}
                        {containers.map((container) => (
                            <option key={container.id} value={String(container.id)}>
                                {container.name}
                            </option>
                        ))}
                    </select>
                    <span className="text-xs text-white/50">Auto-refresh every {POLL_INTERVAL_MS / 1000}s</span>
                </div>

                {loading && <div className="text-white/70">Loading dashboard...</div>}
                {error && <div className="text-red-400 text-sm">{error}</div>}

                {!loading && !error && (
                    <>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                            {kpis.map((kpi) => (
                                <div key={kpi.key} className="glass-panel p-5 rounded-xl border border-white/5">
                                    <div className="flex justify-between items-center">
                                        <p style={{ color: labelColor }} className="text-xs uppercase tracking-wider font-semibold">
                                            {kpi.title}
                                        </p>
                                        <span className="material-symbols-outlined text-primary">{kpi.icon}</span>
                                    </div>
                                    <h3 style={{ color: textColor }} className="text-3xl font-black mt-2">
                                        {kpi.value !== null && kpi.value !== undefined ? kpi.value.toFixed(1) : '--'}
                                        <span className="text-sm" style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }}> {kpi.suffix}</span>
                                    </h3>
                                </div>
                            ))}
                        </div>

                        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                            {Object.entries(sensorMeta).map(([key, meta]) => (
                                <div
                                    key={key}
                                    className="rounded-[24px] bg-white p-5 shadow-[0_4px_16px_rgba(0,0,0,0.04)] border border-black/5"
                                >
                                    <div className="flex items-start gap-3">
                                        <div
                                            className="flex h-10 w-10 items-center justify-center rounded-full"
                                            style={{ backgroundColor: `${meta.color}1A`, color: meta.color }}
                                        >
                                            <span className="material-symbols-outlined text-[20px]">{sensorIcons[key]}</span>
                                        </div>
                                        <div className="min-w-0 flex-1">
                                            <p className="text-[16px] font-bold leading-tight text-black">{meta.label}</p>
                                            <div className="mt-1 flex items-end gap-1.5">
                                                <span className="text-[24px] font-bold leading-none" style={{ color: meta.color }}>
                                                    {getCurrentValue(currentData, key) !== null ? getCurrentValue(currentData, key).toFixed(1) : '--'}
                                                </span>
                                                <span className="pb-0.5 text-[14px] font-semibold text-[#757575]">{meta.unit}</span>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-1.5 rounded-xl bg-[#4CAF501A] px-2.5 py-1 text-[#4CAF50]">
                                            <span className="material-symbols-outlined text-[14px]">trending_up</span>
                                            <span className="text-[12px] font-bold">
                                                {(() => {
                                                    const trend = getTrendPercent(history, key);
                                                    if (trend === null) return '--';
                                                    const prefix = trend > 0 ? '+' : '';
                                                    return `${prefix}${trend.toFixed(1)}%`;
                                                })()}
                                            </span>
                                        </div>
                                    </div>

                                    <div className="mt-5 h-[120px]">
                                        <ResponsiveContainer width="100%" height="100%">
                                            <AreaChart data={chartSeriesBySensor[key]} margin={{ top: 8, right: 6, left: -10, bottom: 0 }}>
                                                <defs>
                                                    <linearGradient id={`${key}-fill`} x1="0" y1="0" x2="0" y2="1">
                                                        <stop offset="5%" stopColor={meta.color} stopOpacity={0.18} />
                                                        <stop offset="95%" stopColor={meta.color} stopOpacity={0.03} />
                                                    </linearGradient>
                                                </defs>
                                                <CartesianGrid stroke="#EDEDED" strokeDasharray="0" vertical={false} />
                                                <XAxis
                                                    dataKey="label"
                                                    stroke="#757575"
                                                    tick={{ fontSize: 10, fill: '#757575' }}
                                                    tickLine={false}
                                                    axisLine={{ stroke: '#D9D9D9' }}
                                                    interval={0}
                                                >
                                                    <Label value="Time" offset={-2} position="insideBottom" fill="#757575" fontSize={10} />
                                                </XAxis>
                                                <YAxis
                                                    stroke="#757575"
                                                    tick={{ fontSize: 10, fill: '#757575' }}
                                                    tickLine={false}
                                                    axisLine={{ stroke: '#D9D9D9' }}
                                                    width={36}
                                                >
                                                    <Label value={`${meta.label} (${meta.unit})`} angle={-90} position="insideLeft" fill="#757575" fontSize={10} />
                                                </YAxis>
                                                <Tooltip
                                                    contentStyle={{
                                                        borderRadius: '14px',
                                                        border: '1px solid #E5E7EB',
                                                        boxShadow: '0 10px 30px rgba(0,0,0,0.08)',
                                                    }}
                                                    labelStyle={{ color: '#111827', fontWeight: 700 }}
                                                    formatter={(value) => [value, meta.label]}
                                                />
                                                <Area
                                                    type="monotone"
                                                    dataKey={key}
                                                    stroke={meta.color}
                                                    strokeWidth={3}
                                                    fill={`url(#${key}-fill)`}
                                                    dot={false}
                                                    connectNulls
                                                />
                                            </AreaChart>
                                        </ResponsiveContainer>
                                    </div>
                                </div>
                            ))}
                        </div>

                        <div className="glass-panel p-6 rounded-xl border border-white/5">
                            <div className="flex flex-wrap gap-4 items-center justify-between mb-4">
                                <h3 style={{ color: labelColor }} className="text-sm font-bold uppercase tracking-wider">Detailed Sensor Logs</h3>
                                <div className="flex gap-3 flex-wrap">
                                    <select
                                        className="bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-xs text-white"
                                        value={sensorFilter}
                                        onChange={(e) => setSensorFilter(e.target.value)}
                                    >
                                        <option value="All">All Sensors</option>
                                        <option value="Temperature">Temperature</option>
                                        <option value="Humidity">Humidity</option>
                                        <option value="Luminosity">Luminosity</option>
                                        <option value="Gas">Gas</option>
                                    </select>
                                    <input
                                        type="date"
                                        className="bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-xs text-white"
                                        value={dateFilter}
                                        onChange={(e) => setDateFilter(e.target.value)}
                                    />
                                </div>
                            </div>

                            <div className="overflow-auto max-h-[420px] rounded-lg border border-white/10">
                                <table className="w-full text-sm">
                                    <thead style={{ backgroundColor: isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' }} className="sticky top-0">
                                        <tr>
                                            <th style={{ color: labelColor }} className="text-left p-3">Timestamp</th>
                                            <th style={{ color: labelColor }} className="text-left p-3">Sensor</th>
                                            <th style={{ color: labelColor }} className="text-left p-3">Value</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {filteredLogs.slice(0, MAX_HISTORY_POINTS).map((log) => (
                                            <tr key={log.id} style={{ borderColor: isDarkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' }} className="border-t">
                                                <td style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }} className="p-3">{new Date(log.timestamp).toLocaleString()}</td>
                                                <td style={{ color: textColor }} className="p-3">{log.sensor}</td>
                                                <td style={{ color: '#3ce619' }} className="p-3 font-semibold">{log.value} {log.unit}</td>
                                            </tr>
                                        ))}
                                        {filteredLogs.length === 0 && (
                                            <tr>
                                                <td colSpan={3} style={{ color: isDarkMode ? '#ffffff99' : '#1a1a1a99' }} className="p-4 text-center">No logs for current filters.</td>
                                            </tr>
                                        )}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </>
                )}
            </div>
        </MainLayout>
    );
};

export default Dashboard;













