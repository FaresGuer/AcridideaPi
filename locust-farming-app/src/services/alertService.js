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
    gas_level: {
        critical: { min: 300, max: 3000 },
        warning: { min: 700, max: 2000 },
    },
};

const SENSOR_CONFIG = {
    temperature: {
        minField: 'target_temperature_min',
        maxField: 'target_temperature',
        title: 'Temperature',
        unit: '°C',
        icon: 'thermostat',
    },
    humidity: {
        minField: 'target_humidity_min',
        maxField: 'target_humidity',
        title: 'Humidity',
        unit: '%',
        icon: 'humidity_percentage',
    },
    light_level: {
        minField: 'target_light_level_min',
        maxField: 'target_light_level',
        title: 'Luminosity',
        unit: 'Lux',
        icon: 'light_mode',
    },
    gas_level: {
        minField: 'target_gas_level_min',
        maxField: 'target_gas_level',
        title: 'Gas Level',
        unit: 'ppm',
        icon: 'air',
    },
};

function isOutsideRange(value, min, max) {
    if (value === null || value === undefined) return false;
    if (min !== null && min !== undefined && value < min) return true;
    if (max !== null && max !== undefined && value > max) return true;
    return false;
}

function formatRange(min, max, unit) {
    if (min !== null && min !== undefined && max !== null && max !== undefined) {
        return `${min}-${max}${unit}`;
    }
    if (min !== null && min !== undefined) {
        return `>= ${min}${unit}`;
    }
    if (max !== null && max !== undefined) {
        return `<= ${max}${unit}`;
    }
    return `not configured`;
}

export function generateAlertFromSensorData(containerData, containerName, containerId) {
    const alerts = [];

    Object.entries(SENSOR_CONFIG).forEach(([sensor, cfg]) => {
        const value = containerData[sensor];
        if (value === null || value === undefined) {
            return;
        }

        // Prefer thresholds persisted in container_data. Fall back to legacy constants if missing.
        const warningMin = containerData[cfg.minField] ?? ALERT_THRESHOLDS[sensor]?.warning?.min ?? null;
        const warningMax = containerData[cfg.maxField] ?? ALERT_THRESHOLDS[sensor]?.warning?.max ?? null;
        const criticalMin = ALERT_THRESHOLDS[sensor]?.critical?.min ?? warningMin;
        const criticalMax = ALERT_THRESHOLDS[sensor]?.critical?.max ?? warningMax;

        if (isOutsideRange(value, criticalMin, criticalMax)) {
            alerts.push({
                id: `${containerId}-${sensor}-critical-${Date.now()}`,
                severity: 'Critical',
                title: `${cfg.title} Critical`,
                description: `${cfg.title} is ${value}${cfg.unit}. Critical range: ${formatRange(criticalMin, criticalMax, cfg.unit)}`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: cfg.icon,
                color: 'red',
                sensor,
                value,
            });
            return;
        }

        if (isOutsideRange(value, warningMin, warningMax)) {
            alerts.push({
                id: `${containerId}-${sensor}-warning-${Date.now()}`,
                severity: 'Warning',
                title: `${cfg.title} Deviation`,
                description: `${cfg.title} is ${value}${cfg.unit}. Container range: ${formatRange(warningMin, warningMax, cfg.unit)}`,
                source: containerName,
                timestamp: new Date().toLocaleTimeString(),
                icon: cfg.icon,
                color: 'amber',
                sensor,
                value,
            });
        }
    });

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

