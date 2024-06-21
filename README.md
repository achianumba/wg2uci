# wg2uci

wg2uci uses a [wg-quick](https://git.zx2c4.com/wireguard-tools/about/src/man/wg-quick.8) (WireGuard) configuration file to generate a shell script that configures a WireGuard interface and its peers.

## Usage

Download [wg2uci](wg2uci):

```shell
curl -O https://raw.githubusercontent.com/achianumba/wg2uci/main/wg2uci
```

Make `wg2uci` executable:

```shell
chmod +x wg2uci
```

Generate a UCI interface/network script:

```shell
./wg2uci <wg0.conf | ./wg0.conf | /etc/wireguard/wg0.conf>
```

Configure a WireGuard interface/network using the generated script

```
./config-INTERFACE.sh
```

## Additional *.conf file fields

`wg2uci` treats the below comments `*.conf` file as config fields instead of comments:

- `# InterfaceName`: A valid UNIX interface name placed above the `[Interface]` header. E.g. `# InterfaceName = wg0`. The `*.conf` file's name is set as the interface's in the absence of the `InterfaceName` comment.
  
- `# Description`: A one-word description of a peer placed above a `[Peer]` header. E.g. `# Description = GitHub CDNs`.


## Limitations

- Doesn't parse `PostUp` and `PostDown` directives.
- Doesn't quite handle multiple AllowedIPs when written on multiple lines (yet) instead of as a comma-separated list
- Doesn't add the interface to a firewall zone