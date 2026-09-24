<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Icarus Server Status</title>
  <style>
    body { font-family: sans-serif; text-align: center; margin-top: 50px; background-color: #1a1a24; color: #ffffff; } 
    .status-container { display: flex; justify-content: center; gap: 40px; margin-bottom: 20px; flex-wrap: wrap; }
    .status-item { background: #2c2c3e; padding: 20px; border-radius: 10px; width: 250px; box-shadow: 0 4px 6px rgba(0,0,0,0.3); }
    .status-item h2 { margin-top: 0; font-size: 1.2em; color: #b0b0c0; }
    .status-item span { font-size: 1.5em; font-weight: bold; }
    .instructions { font-size: 14px; color: #aaaaaa; max-width: 450px; margin: 40px auto; line-height: 1.5; background: #222230; padding: 15px; border-radius: 8px; border-left: 4px solid #4caf50; text-align: left; }
    h1 { color: #f0a500; font-size: 2.5em; margin-bottom: 40px; text-transform: uppercase; letter-spacing: 2px;}
  </style>
</head>
<body>
  <h1>Icarus Dedicated Server</h1>
  
  <div class="status-container">
    <div class="status-item">
      <h2>Gateway Tunnel</h2>
      <span id="tunnel-status">Loading...</span>
    </div>
    <div class="status-item">
      <h2>Game Server</h2>
      <span id="server-status">Loading...</span>
    </div>
    <div class="status-item">
      <h2>Server Version</h2>
      <span id="server-version">Loading...</span>
    </div>
  </div>
  
  <div class="instructions">
    <h3>How to Connect:</h3>
    <p>1. Open Steam and go to <strong>View</strong> > <strong>Game Servers</strong>.</p>
    <p>2. Go to the <strong>Favorites</strong> tab and click <strong>+</strong> (Add a Server).</p>
    <p>3. Enter Address: <strong>${duckdns_domain}.duckdns.org:27015</strong> and save.</p>
    <p>4. Open Icarus and click <strong>Play</strong>.</p>
    <p>5. Select <strong>Dedicated Servers</strong>.</p>
    <p>6. Select the server from your <strong>Favorites</strong> list and join!</p>
  </div>

  <script>
    async function checkStatus() {
      try {
        let gatewayOnline = false;
        let gameServerOnline = false;
        let serverVersion = "Unknown";
        
        try {
          // Append timestamp to prevent browser caching of the status
          const healthRes = await fetch(`/health.json?t=$${Date.now()}`);
          const healthData = await healthRes.json();
          gatewayOnline = healthData.gateway === "online";
          gameServerOnline = healthData.server === "online";
          if (healthData.version) {
            serverVersion = healthData.version;
          }
        } catch (err) {
          console.warn("Could not fetch health.json");
        }

        const setStatus = (id, isOnline) => {
          const el = document.getElementById(id);
          if (isOnline) {
            el.innerText = "Online";
            el.style.color = "#4caf50";
          } else {
            el.innerText = "Offline";
            el.style.color = "#f44336";
          }
        };

        setStatus("tunnel-status", gatewayOnline);
        setStatus("server-status", gameServerOnline);

        const versionEl = document.getElementById("server-version");
        if (serverVersion !== "Unknown") {
          versionEl.innerHTML = `<a href="https://steamdb.info/patchnotes/$${serverVersion}/" target="_blank" style="color: #ffffff; text-decoration: underline;">$${serverVersion}</a>`;
        } else {
          versionEl.innerText = "Unknown";
          versionEl.style.color = "#aaaaaa";
        }

      } catch (err) {
        console.error("Status check encountered an error", err);
      }
    }
    
    checkStatus();
    setInterval(checkStatus, 30000);
  </script>
</body>
</html>
