${duckdns_domain}.duckdns.org {
    # Dashboard reverse proxy
    handle /dashboard/* {
        uri strip_prefix /dashboard
        reverse_proxy 127.0.0.1:7501
    }

    # Serve the status web page
    handle /* {
        root * /usr/share/caddy
        file_server
    }
}

${duckdns_domain}.duckdns.org:7500 {
    reverse_proxy 127.0.0.1:7501
}
