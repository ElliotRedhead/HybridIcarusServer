import socket
import struct

def query_server(ip="127.0.0.1", port=27015):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(2)
        req = bytes.fromhex("FFFFFFFF54536F7572636520456E67696E6520517565727900")
        s.sendto(req, (ip, port))
        d, _ = s.recvfrom(4096)
        
        if d.startswith(b'\xFF\xFF\xFF\xFFA'):
            challenge = d[5:9]
            s.sendto(req + challenge, (ip, port))
            d, _ = s.recvfrom(4096)
            
        if d.startswith(b'\xFF\xFF\xFF\xFFI'):
            idx = 6
            def get_string(idx):
                end = d.find(b'\x00', idx)
                return d[idx:end].decode('utf-8', errors='ignore'), end + 1
            name, idx = get_string(idx)
            map_name, idx = get_string(idx)
            folder, idx = get_string(idx)
            game, idx = get_string(idx)
            app_id = struct.unpack('<H', d[idx:idx+2])[0]
            idx += 2
            players = d[idx]
            idx += 1
            max_players = d[idx]
            idx += 1
            bots = d[idx]
            idx += 1
            server_type = d[idx:idx+1]
            idx += 1
            env = d[idx:idx+1]
            idx += 1
            vis = d[idx]
            idx += 1
            vac = d[idx]
            idx += 1
            version, idx = get_string(idx)
            print(f"Name: {name}")
            print(f"Map: {map_name}")
            print(f"Game: {game}")
            print(f"Players: {players}/{max_players}")
            print(f"Version: {version}")
    except Exception as e:
        print("Exception:", e)

query_server()
