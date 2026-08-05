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
  </div>
  
  <div class="instructions">
    <h3>How to Connect:</h3>
    <p>1. Open Icarus and click <strong>Play</strong>.</p>
    <p>2. Select <strong>Dedicated Servers</strong>.</p>
    <p>3. Click <strong>Direct Connect</strong>.</p>
    <p>4. Enter Address: <strong>${duckdns_domain}.duckdns.org:17777</strong></p>
  </div>

  <script>
    async function checkStatus() {
      try {
        let hostOnline = false;
        let tunnelOnline = false;
        
        try {
          const healthRes = await fetch("/health.json");
          const healthData = await healthRes.json();
          hostOnline = healthData.host === "online";
          tunnelOnline = healthData.tunnel === "online";
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

        setStatus("tunnel-status", hostOnline);
        setStatus("server-status", tunnelOnline);

      } catch (err) {
        console.error("Status check encountered an error", err);
      }
    }
    
    checkStatus();
    setInterval(checkStatus, 30000);
  </script>
</body>
</html>
