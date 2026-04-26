import React, { useEffect, useState } from 'react';
import MainLayout from '../components/MainLayout';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { apiRequest, authHeaders } from '../services/api';

const getInitials = (name = '', email = '') => {
    const source = (name || email || '').trim();
    if (!source) return '?';

    const parts = source.split(/\s+/).filter(Boolean);
    if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();

    return `${parts[0][0]}${parts[1][0]}`.toUpperCase();
};

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
    const [profile, setProfile] = useState({
        full_name: '',
        email: '',
        role: '',
        is_active: true,
        avatar_url: '',
    });
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [savingProfile, setSavingProfile] = useState(false);
    const [message, setMessage] = useState('');

    const panelClass = isDarkMode
        ? 'bg-slate-950/70 border-white/10 text-white'
        : 'bg-white/80 border-slate-200 text-slate-900';

    const labelClass = isDarkMode ? 'text-white/60' : 'text-slate-600';
    const valueClass = isDarkMode ? 'text-white/85' : 'text-slate-900';
    const mutedValueClass = isDarkMode ? 'text-white/70' : 'text-slate-600';

    const inputClass = isDarkMode
        ? 'w-full bg-white/5 border border-white/10 rounded-lg px-3 py-2 text-sm text-white placeholder:text-white/35 focus:outline-none focus:border-primary'
        : 'w-full bg-slate-50 border border-slate-300 rounded-lg px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:border-primary';

    const readonlyClass = isDarkMode
        ? `${inputClass} opacity-70 cursor-not-allowed`
        : `${inputClass} opacity-80 cursor-not-allowed`;

    useEffect(() => {
        setProfile({
            full_name: user?.full_name || '',
            email: user?.email || '',
            role: user?.role || '',
            is_active: user?.is_active ?? true,
            avatar_url: user?.avatar_url || user?.profile_picture_url || '',
        });
    }, [user]);

    useEffect(() => {
        if (!token) return;

        const load = async () => {
            setLoading(true);
            setMessage('');
            try {
                const rows = await apiRequest('/containers', { headers: authHeaders(token) });
                setContainers(rows);
                if (rows.length > 0) {
                    setSelectedContainerId(String(rows[0].id));
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

    const saveProfile = async () => {
        if (!token) return;

        setSavingProfile(true);
        setMessage('');

        try {
            const updated = await apiRequest('/users/me', {
                method: 'PUT',
                headers: {
                    ...authHeaders(token),
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    full_name: profile.full_name,
                    email: profile.email,
                    avatar_url: profile.avatar_url,
                    is_active: profile.is_active,
                }),
            });

            if (updated && typeof updated === 'object') {
                setProfile((prev) => ({
                    ...prev,
                    full_name: updated.full_name ?? prev.full_name,
                    email: updated.email ?? prev.email,
                    avatar_url: updated.avatar_url ?? updated.profile_picture_url ?? prev.avatar_url,
                    is_active: updated.is_active ?? prev.is_active,
                    role: updated.role ?? prev.role,
                }));
            }

            setMessage('Profile saved successfully.');
        } catch (err) {
            setMessage(err.message || 'Failed to save profile');
        } finally {
            setSavingProfile(false);
        }
    };

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
                    <div className={`glass-panel p-6 rounded-xl border ${panelClass}`}>
                        <h3 className={`text-sm font-bold uppercase tracking-wider mb-4 ${labelClass}`}>
                            User Profile
                        </h3>

                        <div className="flex items-center gap-4 mb-6">
                            <div className="size-20 rounded-full overflow-hidden border border-white/10 bg-black/20 flex items-center justify-center shrink-0">
                                {profile.avatar_url ? (
                                    <img
                                        src={profile.avatar_url}
                                        alt="Profile"
                                        className="size-full object-cover"
                                    />
                                ) : (
                                    <span className="text-xl font-bold text-white/80">
                                        {getInitials(profile.full_name, profile.email)}
                                    </span>
                                )}
                            </div>

                            <div className="flex-1">
                                <p className={`text-base font-semibold ${valueClass}`}>
                                    {profile.full_name || 'Unnamed user'}
                                </p>
                                <p className={`text-xs ${mutedValueClass}`}>
                                    {profile.email || 'No email set'}
                                </p>
                                <p className={`text-xs ${labelClass} mt-1`}>
                                    Role is read-only
                                </p>
                            </div>
                        </div>

                        <div className="space-y-4">
                            <div>
                                <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                    Full Name
                                </label>
                                <input
                                    type="text"
                                    className={inputClass}
                                    value={profile.full_name}
                                    onChange={(e) =>
                                        setProfile((prev) => ({ ...prev, full_name: e.target.value }))
                                    }
                                />
                            </div>

                            <div>
                                <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                    Email
                                </label>
                                <input
                                    type="email"
                                    className={inputClass}
                                    value={profile.email}
                                    onChange={(e) =>
                                        setProfile((prev) => ({ ...prev, email: e.target.value }))
                                    }
                                />
                            </div>

                            <div>
                                <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                    Profile Picture URL
                                </label>
                                <input
                                    type="url"
                                    className={inputClass}
                                    value={profile.avatar_url}
                                    onChange={(e) =>
                                        setProfile((prev) => ({ ...prev, avatar_url: e.target.value }))
                                    }
                                    placeholder="https://..."
                                />
                            </div>

                            <div>
                                <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                    Role
                                </label>
                                <input
                                    type="text"
                                    className={readonlyClass}
                                    value={profile.role || '--'}
                                    readOnly
                                />
                            </div>

                            <div>
                                <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                    Status
                                </label>
                                <select
                                    className={inputClass}
                                    value={profile.is_active ? 'active' : 'inactive'}
                                    onChange={(e) =>
                                        setProfile((prev) => ({
                                            ...prev,
                                            is_active: e.target.value === 'active',
                                        }))
                                    }
                                >
                                    <option value="active">Active</option>
                                    <option value="inactive">Inactive</option>
                                </select>
                            </div>
                        </div>

                        <div className="mt-6 pt-4 border-t border-white/10 flex items-center justify-between">
                            <span className={`text-xs uppercase tracking-wider ${labelClass}`}>
                                Theme Mode
                            </span>
                            <button
                                onClick={toggleTheme}
                                className={`w-12 h-6 rounded-full relative p-1 transition-all ${
                                    isDarkMode ? 'bg-primary' : 'bg-amber-500'
                                }`}
                            >
                                <div
                                    className={`absolute top-1 size-4 rounded-full bg-white transition-all ${
                                        isDarkMode ? 'right-1' : 'left-1'
                                    }`}
                                />
                            </button>
                        </div>

                        <button
                            onClick={saveProfile}
                            disabled={savingProfile}
                            className={`mt-5 w-full py-2.5 rounded-lg font-bold text-xs uppercase tracking-widest transition-all ${
                                savingProfile
                                    ? 'bg-primary/40 text-black/70'
                                    : 'bg-primary text-background-dark hover:bg-primary/90'
                            }`}
                        >
                            {savingProfile ? 'Saving Profile...' : 'Save Profile'}
                        </button>
                    </div>

                    <div className={`glass-panel p-6 rounded-xl border ${panelClass}`}>
                        <h3 className={`text-sm font-bold uppercase tracking-wider mb-4 ${labelClass}`}>
                            Container Thresholds
                        </h3>

                        {loading ? (
                            <div className={labelClass}>Loading...</div>
                        ) : (
                            <>
                                <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                    Container
                                </label>
                                <select
                                    className={`${inputClass} mb-4`}
                                    value={selectedContainerId}
                                    onChange={(e) => setSelectedContainerId(e.target.value)}
                                >
                                    {containers.length === 0 && <option value="">No container available</option>}
                                    {containers.map((c) => (
                                        <option key={c.id} value={String(c.id)}>
                                            {c.name}
                                        </option>
                                    ))}
                                </select>

                                <div className="space-y-4">
                                    <div>
                                        <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                            Target Temperature (degC)
                                        </label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            className={inputClass}
                                            value={thresholds.target_temperature}
                                            onChange={(e) =>
                                                setThresholds((prev) => ({
                                                    ...prev,
                                                    target_temperature: Number(e.target.value),
                                                }))
                                            }
                                        />
                                    </div>

                                    <div>
                                        <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                            Target Humidity (%)
                                        </label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            className={inputClass}
                                            value={thresholds.target_humidity}
                                            onChange={(e) =>
                                                setThresholds((prev) => ({
                                                    ...prev,
                                                    target_humidity: Number(e.target.value),
                                                }))
                                            }
                                        />
                                    </div>

                                    <div>
                                        <label className={`block text-xs mb-2 uppercase tracking-wider ${labelClass}`}>
                                            Target Luminosity (lux)
                                        </label>
                                        <input
                                            type="number"
                                            step="0.1"
                                            className={inputClass}
                                            value={thresholds.target_light_level}
                                            onChange={(e) =>
                                                setThresholds((prev) => ({
                                                    ...prev,
                                                    target_light_level: Number(e.target.value),
                                                }))
                                            }
                                        />
                                    </div>
                                </div>

                                <button
                                    onClick={saveThresholds}
                                    disabled={saving || !selectedContainerId}
                                    className={`mt-5 w-full py-2.5 rounded-lg font-bold text-xs uppercase tracking-widest transition-all ${
                                        saving
                                            ? 'bg-primary/40 text-black/70'
                                            : 'bg-primary text-background-dark hover:bg-primary/90'
                                    }`}
                                >
                                    {saving ? 'Saving...' : 'Save Thresholds'}
                                </button>
                            </>
                        )}

                        {message && <div className={`mt-4 text-xs ${labelClass}`}>{message}</div>}
                    </div>
                </div>
            </div>
        </MainLayout>
    );
};

export default Profile;