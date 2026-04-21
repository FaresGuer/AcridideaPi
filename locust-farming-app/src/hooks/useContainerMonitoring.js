import { useEffect, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import { useNotifications } from '../context/NotificationContext';
import { monitorAllContainers, generateAlertFromSensorData } from '../services/alertService';
import { apiRequest, authHeaders } from '../services/api';

/**
 * Hook pour monitorer les containers et générer des alertes
 * Lancez ce hook dans le dashboard ou un composant parent pour commencer le monitoring
 */
export const useContainerMonitoring = (enabled = true) => {
    const { token } = useAuth();
    const { addNotification } = useNotifications();
    const trackedAlertsRef = new Map(); // Pour éviter les doublons

    const checkContainers = useCallback(async () => {
        if (!token || !enabled) return;

        try {
            const containers = await apiRequest('/containers', { headers: authHeaders(token) });

            for (const container of containers) {
                try {
                    const data = await apiRequest(`/containers/${container.id}/data`, { headers: authHeaders(token) });
                    const alerts = generateAlertFromSensorData(data, container.name, container.id);

                    for (const alert of alerts) {
                        // Utiliser un ID unique basé sur le type d'alerte et le sensor
                        const alertKey = `${container.id}-${alert.sensor}-${alert.severity}`;
                        const lastTracked = trackedAlertsRef.get(alertKey);

                        // Ne créer une notification que si c'est une nouvelle alerte (toutes les 30 secondes max)
                        if (!lastTracked || Date.now() - lastTracked > 30000) {
                            addNotification(alert);
                            trackedAlertsRef.set(alertKey, Date.now());
                        }
                    }
                } catch (err) {
                    console.error(`Failed to check container ${container.id}:`, err);
                }
            }
        } catch (err) {
            console.error('Container monitoring error:', err);
        }
    }, [token, enabled, addNotification]);

    useEffect(() => {
        if (!enabled || !token) return;

        // Check immediately
        checkContainers();

        // Then check every 5 seconds
        const timer = setInterval(checkContainers, 5000);

        return () => clearInterval(timer);
    }, [token, enabled, checkContainers]);
};

