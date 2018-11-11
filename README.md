# VControl Client

Vcontrold client to connect to a running [vcontrold](https://github.com/openv/vcontrold) service.
The client can read data from the service by sending a `get` command or write data by sending a `set` command.
The available commands can be obtained when connecting with telnet to the vcontrold service and send `commands`.

Details on how to set up the hard- and software to get a vcontrold server running can be found in the [OpenV-Wiki](https://github.com/openv/openv/wiki).

## Disclaimer

You use this software at your own risk. I can not be held liable for anything that happens to your heating system, including any damage, by the use of this software.

## Installation

Install with npm

```
npm install vcontrol-client
```

## Example

```javascript
const VControlClient = require("vcontrol-client")

vControlClient = new VControlClient({
  host: "localhost",
  port: 3002
  timeout: 4000 // optional, default: 3000ms
  debug: true   // optional
})

await vControlCLient.connect()

let data = await vControlClient.getData("getTempA")
await vControlClient.setData("setTimerZirkuMo", ["07:00", "09:00"])

await vControlClient.close()
```
