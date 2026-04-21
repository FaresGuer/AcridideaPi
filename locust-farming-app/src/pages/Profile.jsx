import React, { useEffect, useState } from 'react';
import MainLayout from '../components/MainLayout';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { apiRequest, authHeaders } from '../services/api';

const Profile = () => {
    const { token, user } = useAuth();
    const { isDarkMode, toggleTheme } = useTheme();

    const [containers, setContainers] = useState([]);
    const [selectedContainerId, setSelectedContainerId] = useState('');
    const [thresholds, setThresholds] = useState({
        target_temperature: 25,
        target_humidity: 60,
        target_light_level: 75,
    });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [message, setMessage] = useState('');

    useEffect(() => {
        if (!token) return;

        const load = async () => {
            setLoading(true);
            setMessage('');
            try {
                const rows = await apiRequest('/containers', { headers: authHeaders(token) });
                setContainers(rows);
                if (rows.length > 0) {
                    const firstId = String(rows[0].id);
                    setSelectedContainerId(firstId);
                }
            } catch (err) {
                setMessage(err.message || 'Failed to load containers');
            } finally {
                setLoading(false);
            }
        };

        load();
    }, [token]);

    useEffect(() => {
        if (!token || !selectedContainerId) return;

        const loadData = async () => {
            try {
                const data = await apiRequest(`/containers/${selectedContainerId}/data`, {
                    headers: authHeaders(token),
                });
                setThresholds({
                    target_temperature: data.target_temperature ?? 25,
                    target_humidity: data.target_humidity ?? 60,
                    target_light_level: data.target_light_level ?? 75,
                });
            } catch (err) {
                setMessage(err.message || 'Failed to load container thresholds');
            }
        };

        loadData();
    }, [token, selectedContainerId]);

    const saveThresholds = async () => {
        if (!token || !selectedContainerId) return;
        setSaving(true);
        setMessage('');
        try {
            await apiRequest(`/containers/${selectedContainerId}/data`, {
                method: 'PUT',
                headers: {
                    ...authHeaders(token),
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(thresholds),
            });
            setMessage('Thresholds saved successfully.');
        } catch (err) {
            setMessage(err.message || 'Failed to save thresholds');
        } finally {
            setSaving(false);
        }
    };

    return (
        <MainLayout title="Settings" subtitle="User profile and DB-backed container thresholds">
            <div className="flex flex-col h-full overflow-y-auto custom-scrollbar p-6 gap-6 pb-24">
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <div className="glass-panel p-6 rounded-xl border border-white/5">
                        <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-4">User Profile</h3>
                        <div className="space-y-3 text-sm">
                            <p className="text-white/80"><span className="text-white/50">Name:</span> {user?.full_name || '--'}</p>
                            <p className="text-white/80"><span className="text-white/50">Email:</span> {user?.email || '--'}</p>
                            <p className="text-white/80"><span className="text-white/50">Role:</span> {user?.role || '--'}</p>
                            <p className="text-white/80"><span className="text-white/50">Status:</span> {user?.is_active ? 'Active' : 'Inactive'}</p>
                        </div>

                        <div className="mt-6 pt-4 border-t border-white/10 flex items-center justify-between">
                            <span className="text-xs text-white/60 uppercase tracking-wider">Theme Mode</span>
                            <button
                                onClick={toggleTheme}
                                className={`w-12 h-6 rounded-full relative p-1 transition-all ${isDarkMode ? 'bg-primary' : 'bg-amber-500'}`}
                            >
                                <div className={`absolute top-1 size-4 rounded-full bg-white transition-all ${isDarkMode ? 'right-1' : 'left-1'}`}></div>
                            </button>
                        </div>
                    </div>

                    <div className="glass-panel p-6 rounded-xl border border-white/5">
                        <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-4">Container Thresholds</h3>

                        {loading ? (
                            <div className="text-white/60 text-sm">Loading...</div>
                        ) : (
                            <>
                                <label className="block text-xs text-white/60 mb-2 uppercase tracking-wider">Container</label>
                                <select
                                    className="w-full bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-sm text-white mb-4"
                                    value={selectedContainerId}
                                    onChange={(e) => setSelectedContainerId(e.target.value)}
                                >
                                    {containers.length === 0 && <option value="">No container available</option>}
                                    {containers.map((c) => (
                                        <option key={c.id} value={String(c.id)}>{c.name}</option>
                                    ))}
                                </select>

                                <div className="space-y-4">
                                    <div>
                                        <label className="block text-xs text-white/60 mb-2 uppercase tracking-wider">Target Temperature (degC)</label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            className="w-full bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-sm text-white"
                                            value={thresholds.target_temperature}
                                            onChange={(e) => setThresholds((prev) => ({ ...prev, target_temperature: Number(e.target.value) }))}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-white/60 mb-2 uppercase tracking-wider">Target Humidity (%)</label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            className="w-full bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-sm text-white"
                                            value={thresholds.target_humidity}
                                            onChange={(e) => setThresholds((prev) => ({ ...prev, target_humidity: Number(e.target.value) }))}
                                        />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-white/60 mb-2 uppercase tracking-wider">Target Luminosity (lux)</label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            className="w-full bg-background-dark border border-white/10 rounded-lg px-3 py-2 text-sm text-white"
                                            value={thresholds.target_light_level}
                                            onChange={(e) => setThresholds((prev) => ({ ...prev, target_light_level: Number(e.target.value) }))}
                                        />
                                    </div>
                                </div>

                                <button
                                    onClick={saveThresholds}
                                    disabled={saving || !selectedContainerId}
                                    className={`mt-5 w-full py-2.5 rounded-lg font-bold text-xs uppercase tracking-widest transition-all ${saving ? 'bg-primary/40 text-black/70' : 'bg-primary text-background-dark hover:bg-primary/90'}`}
                                >
                                    {saving ? 'Saving...' : 'Save Thresholds'}
                                </button>
                            </>
                        )}

                        {message && (
                            <div className="mt-4 text-xs text-white/70">{message}</div>
                        )}
                    </div>
                </div>
            </div>
        </MainLayout>
    );
};

export default Profile;
