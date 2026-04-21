import React, { createContext, useState, useContext, useEffect, useMemo } from 'react';
import { API_BASE_URL, apiRequest, authHeaders } from '../services/api';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(localStorage.getItem('token'));
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (token) {
            apiRequest('/users/me', {
                headers: authHeaders(token),
            })
                .then((data) => setUser(data))
                .catch(() => {
                    logout();
                })
                .finally(() => setLoading(false));
        } else {
            setLoading(false);
        }
    }, [token]);

    const login = async (email, password) => {
        const formData = new FormData();
        formData.append('username', email);
        formData.append('password', password);

        const data = await apiRequest('/token', {
            method: 'POST',
            body: formData,
        });

        if (data.requires_two_factor) {
            throw new Error('Two-factor authentication is enabled for this account. Please disable it from mobile first.');
        }

        if (!data.access_token) {
            throw new Error('Login failed: missing access token');
        }

        localStorage.setItem('token', data.access_token);
        setToken(data.access_token);
    };

    const register = async (userData) => {
        return apiRequest('/register', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(userData),
        });
    };

    const logout = () => {
        localStorage.removeItem('token');
        setToken(null);
        setUser(null);
    };

    const contextValue = useMemo(() => ({
        user,
        token,
        login,
        logout,
        register,
        loading,
        apiBaseUrl: API_BASE_URL,
    }), [user, token, loading]);

    return (
        <AuthContext.Provider value={contextValue}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
