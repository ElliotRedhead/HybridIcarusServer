import socket
import sys

def get_server_version(ip="127.0.0.1", port=27015):
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
            
        print("Final response starts with:", d[:5])
        
        if d.startswith(b'\xFF\xFF\xFF\xFFI'):
            idx = 6
            def get_string(idx):
                end = d.find(b'\x00', idx)
                return d[idx:end].decode('utf-8', errors='ignore'), end + 1
            name, idx = get_string(idx)
            map_name, idx = get_string(idx)
            folder, idx = get_string(idx)
            game, idx = get_string(idx)
            idx += 2 # ID
            idx += 1 # Players
            idx += 1 # Max
            idx += 1 # Bots
            idx += 1 # Server type
            idx += 1 # Environment
            idx += 1 # Visibility
            idx += 1 # VAC
            version, idx = get_string(idx)
            return version
    except Exception as e:
        print("Exception:", e)
        pass
    return "Unknown"

print("Version:", get_server_version())
