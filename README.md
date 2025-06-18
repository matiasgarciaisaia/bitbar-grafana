# bitbar-grafana
[BitBar](https://getbitbar.com/) plugin to show [Grafana](https://grafana.com/) active [alerts](https://grafana.com/docs/alerting/rules/)

## Installation

To build the plugin, list the target hostname(s) in the `GRAFANA_HOSTS`
environment variable, separated by `,`. For example:

```bash
GRAFANA_HOSTS=my.grafana.host shards build
```

```bash
GRAFANA_HOSTS=my.grafana.host,another.grafana.host shards build
```

After that, copy the generated binary `bin/grafana` into the BitBar plugins
directory. Remember to set the execution permission!

This plugin looks for the Grafana API key from the macOS keychain. Make sure to
add an entry using the hostname as the entry name, and `apikey` as the account
name. Once the item is created, make sure to run the plugin executable at least
once and give permanent access to the keychain entry.

You can customise the alert's prefix by setting `GRAFANA_ALERT_PREFIX` environment
variable when building. It defaults to `Grafana: ` (whitespace included so you
can omit it if you want).

```bash
GRAFANA_HOSTS=my.grafana.host,another.grafana.host GRAFANA_ALERT_PREFIX='' shards build
```

You can also set the success or alert messages with
`GRAFANA_ALERT_SUCCESS_MESSAGE` and `GRAFANA_ALERT_ALERT_MESSAGE`.

```bash
GRAFANA_HOSTS=my.grafana.host,another.grafana.host GRAFANA_ALERT_PREFIX='' GRAFANA_ALERT_SUCCESS_MESSAGE='👍' GRAFANA_ALERT_ALERT_MESSAGE='🚨' shards build
```

## Contributors

- [Matias Garcia Isaia](https://github.com/matiasgarciaisaia) - maintainer
- [Juan Wajnerman](https://github.com/waj) - creator
