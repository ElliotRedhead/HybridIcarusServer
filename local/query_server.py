"""Query an Icarus server over the Steam A2S_INFO protocol and print its status."""
import socket
import sys

A2S_INFO = bytes.fromhex("FFFFFFFF54536F7572636520456E67696E6520517565727900")


def query_server(ip, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    s.sendto(A2S_INFO, (ip, port))
    d, _ = s.recvfrom(4096)

    # Server may reply with a challenge that must be echoed back
    if d.startswith(b'\xFF\xFF\xFF\xFFA'):
        s.sendto(A2S_INFO + d[5:9], (ip, port))
        d, _ = s.recvfrom(4096)

    if not d.startswith(b'\xFF\xFF\xFF\xFFI'):
        raise ValueError(f"Unexpected response: {d[:5]!r}")

    idx = 6

    def get_string(idx):
        end = d.find(b'\x00', idx)
        return d[idx:end].decode('utf-8', errors='ignore'), end + 1

    name, idx = get_string(idx)
    map_name, idx = get_string(idx)
    _folder, idx = get_string(idx)
    game, idx = get_string(idx)
    idx += 2  # App ID
    players, max_players = d[idx], d[idx + 1]
    idx += 7  # Players, max players, bots, server type, environment, visibility, VAC
    version, idx = get_string(idx)

    print(f"Name:    {name}")
    print(f"Map:     {map_name}")
    print(f"Game:    {game}")
    print(f"Players: {players}/{max_players}")
    print(f"Version: {version}")


if __name__ == "__main__":
    ip = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 27015
    try:
        query_server(ip, port)
    except Exception as e:
        print(f"Server offline or unreachable at {ip}:{port} ({e})")
        sys.exit(1)
