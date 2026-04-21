const fs = require('fs');
const https = require('https');
const path = require('path');

// Use forward slashes for cross-platform compatibility
// The file is located at: C:/Users/Nihel/.gemini/antigravity/brain/0454885a-af28-4adb-bd3c-cf62616ee423/.system_generated/steps/40/output.txt
const screensFile = 'C:/Users/Nihel/.gemini/antigravity/brain/0454885a-af28-4adb-bd3c-cf62616ee423/.system_generated/steps/40/output.txt';

async function main() {
    try {
        if (!fs.existsSync(screensFile)) {
            console.error('Screens file not found at:', screensFile);
            process.exit(1);
        }

        const content = fs.readFileSync(screensFile, 'utf8');
        let data;
        try {
            data = JSON.parse(content);
        } catch (e) {
            console.error('Failed to parse JSON:', e);
            // Try stripping line numbers if they exist (just in case)
            const cleanContent = content.replace(/^\d+:\s*/gm, '');
            data = JSON.parse(cleanContent);
        }

        if (!data.screens) {
            console.error('No screens found in JSON');
            process.exit(1);
        }

        // Target directories inside locust-farming-app
        const assetsDir = path.join(__dirname, 'locust-farming-app', 'public', 'assets', 'screens');
        const htmlDir = path.join(__dirname, 'locust-farming-app', 'src', 'screens_html');

        if (!fs.existsSync(assetsDir)) fs.mkdirSync(assetsDir, { recursive: true });
        if (!fs.existsSync(htmlDir)) fs.mkdirSync(htmlDir, { recursive: true });

        console.log(`Found ${data.screens.length} screens.`);

        for (const screen of data.screens) {
            const safeName = screen.title.replace(/[^a-z0-9]/gi, '_').toLowerCase();

            // Download Image
            if (screen.screenshot?.downloadUrl) {
                await downloadFile(screen.screenshot.downloadUrl, path.join(assetsDir, `${safeName}.png`));
            }

            // Download HTML
            if (screen.htmlCode?.downloadUrl) {
                await downloadFile(screen.htmlCode.downloadUrl, path.join(htmlDir, `${safeName}.html`));
            }
        }

    } catch (err) {
        console.error('Fatal Error:', err);
    }
}

function downloadFile(url, dest) {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(dest);
        https.get(url, (response) => {
            if (response.statusCode !== 200) {
                console.error(`Failed to download ${url}: ${response.statusCode}`);
                file.close();
                fs.unlink(dest, () => { });
                resolve(); // resolve anyway to continue
                return;
            }
            response.pipe(file);
            file.on('finish', () => {
                file.close();
                console.log(`Downloaded: ${path.basename(dest)}`);
                resolve();
            });
        }).on('error', (err) => {
            fs.unlink(dest, () => { });
            console.error(`Error downloading ${path.basename(dest)}: ${err.message}`);
            resolve(); // resolve anyway
        });
    });
}

main();
