import { apiRequest, authHeaders } from './api';

/**
 * Moniteur pour générer des alertes basées sur les valeurs des capteurs
 * Thresholds:
 * - Temperature: Critical < 15°C ou > 35°C | Warning < 20°C ou > 30°C
 * - Humidity: Critical < 20% ou > 95% | Warning < 40% ou > 80%
 * - Luminosity: Critical < 100 Lux ou > 1000 Lux | Warning < 300 Lux ou > 900 Lux
 */

export const ALERT_THRESHOLDS = {
    temperature: {
        critical: { min: 15, max: 35 },
        warning: { min: 20, max: 30 },
    },
    humidity: {
        critical: { min: 20, max: 95 },
        warning: { min: 40, max: 80 },
    },
    light_level: {
        critical: { min: 100, max: 1000 },
        warning: { min: 300, max: 900 },
    },
};

export function generateAlertFromSensorData(containerData, containerName, containerId) {
    const alerts = [];

    // Temperature checks
    if (containerData.temperature !== null && containerData.temperature !== undefined) {
        const temp = containerData.temperature;
        if (temp < ALERT_THRESHOLDS.temperature.critical.min || temp > ALERT_THRESHOLDS.temperature.critical.max) {
            alerts.push({
                id: `${containerId}-temp-critical-${Date.now()}`,
                severity: 'Critical',
                title: 'Temperature Critical',
                description: `Temperature is ${temp}°C. Critical range: ${ALERT_THRESHOLDS.temperature.critical.min}-${ALERT_THRESHOLDS.temperature.critical.max}°C`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: 'thermostat',
                color: 'red',
                sensor: 'temperature',
                value: temp,
            });
        } else if (temp < ALERT_THRESHOLDS.temperature.warning.min || temp > ALERT_THRESHOLDS.temperature.warning.max) {
            alerts.push({
                id: `${containerId}-temp-warning-${Date.now()}`,
                severity: 'Warning',
                title: 'Temperature Deviation',
                description: `Temperature is ${temp}°C. Optimal range: ${ALERT_THRESHOLDS.temperature.warning.min}-${ALERT_THRESHOLDS.temperature.warning.max}°C`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: 'thermostat',
                color: 'amber',
                sensor: 'temperature',
                value: temp,
            });
        }
    }

    // Humidity checks
    if (containerData.humidity !== null && containerData.humidity !== undefined) {
        const hum = containerData.humidity;
        if (hum < ALERT_THRESHOLDS.humidity.critical.min || hum > ALERT_THRESHOLDS.humidity.critical.max) {
            alerts.push({
                id: `${containerId}-hum-critical-${Date.now()}`,
                severity: 'Critical',
                title: 'Humidity Critical',
                description: `Humidity is ${hum}%. Critical range: ${ALERT_THRESHOLDS.humidity.critical.min}-${ALERT_THRESHOLDS.humidity.critical.max}%`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: 'humidity_percentage',
                color: 'red',
                sensor: 'humidity',
                value: hum,
            });
        } else if (hum < ALERT_THRESHOLDS.humidity.warning.min || hum > ALERT_THRESHOLDS.humidity.warning.max) {
            alerts.push({
                id: `${containerId}-hum-warning-${Date.now()}`,
                severity: 'Warning',
                title: 'Humidity Deviation',
                description: `Humidity is ${hum}%. Optimal range: ${ALERT_THRESHOLDS.humidity.warning.min}-${ALERT_THRESHOLDS.humidity.warning.max}%`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: 'humidity_percentage',
                color: 'amber',
                sensor: 'humidity',
                value: hum,
            });
        }
    }

    // Light level checks
    if (containerData.light_level !== null && containerData.light_level !== undefined) {
        const light = containerData.light_level;
        if (light < ALERT_THRESHOLDS.light_level.critical.min || light > ALERT_THRESHOLDS.light_level.critical.max) {
            alerts.push({
                id: `${containerId}-light-critical-${Date.now()}`,
                severity: 'Critical',
                title: 'Luminosity Critical',
                description: `Luminosity is ${light} Lux. Critical range: ${ALERT_THRESHOLDS.light_level.critical.min}-${ALERT_THRESHOLDS.light_level.critical.max} Lux`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: 'light_mode',
                color: 'red',
                sensor: 'light_level',
                value: light,
            });
        } else if (light < ALERT_THRESHOLDS.light_level.warning.min || light > ALERT_THRESHOLDS.light_level.warning.max) {
            alerts.push({
                id: `${containerId}-light-warning-${Date.now()}`,
                severity: 'Warning',
                title: 'Luminosity Deviation',
                description: `Luminosity is ${light} Lux. Optimal range: ${ALERT_THRESHOLDS.light_level.warning.min}-${ALERT_THRESHOLDS.light_level.warning.max} Lux`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: 'light_mode',
                color: 'amber',
                sensor: 'light_level',
                value: light,
            });
        }
    }

    return alerts;
}

export async function monitorAllContainers(token, onAlertsGenerated) {
    try {
        const containers = await apiRequest('/containers', { headers: authHeaders(token) });

        const allAlerts = [];
        for (const container of containers) {
            try {
                const data = await apiRequest(`/containers/${container.id}/data`, { headers: authHeaders(token) });
                const alerts = generateAlertFromSensorData(data, container.name, container.id);
                allAlerts.push(...alerts);
            } catch (err) {
                console.error(`Failed to fetch data for container ${container.id}:`, err);
            }
        }

        if (allAlerts.length > 0 && onAlertsGenerated) {
            onAlertsGenerated(allAlerts);
        }

        return allAlerts;
    } catch (err) {
        console.error('Failed to monitor containers:', err);
        return [];
    }
}

