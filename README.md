# VControl Client

VControlD client to connect to a running [VControlD](https://github.com/openv/vcontrold) service.
The client can read data from the service by sending a `get` command or write data by sending a `set` command.

Details on how to set up the hard- and software to get a VControlD server running can be found in the [OpenV-Wiki](https://github.com/openv/openv/wiki).

## Disclaimer

You use this software at your own risk. I can not be held liable for anything that happens to your heating system, including any damage, by the use of this software.

## Installation

install with npm

```
npm install vcontrol
```

## Example

```javascript
const VControlClient = require("vcontrol")

vControlClient = new VControlClient("localhost", 3002)

await vControlCLient.connect()

let data = await vControlClient.getData("getTempA")
await vControlClient.setData("setTimerZirkuMo", "07:00 09:00")

await vControlClient.close()
```
