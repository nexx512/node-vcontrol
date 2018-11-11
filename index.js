const net = require("net")

const TIMEOUT = 3000

module.exports = class VControlClient {

  /**
   * Create a new instance for a VControl client.
   *
   * @param {String} host hostname where vcontrold runs
   * @param {Number} port to connect to vcontrold
   */
  constructor(config) {
    this.host = config.host
    this.port = config.port
    this.timeout = config.timeout ? config.timeout : TIMEOUT

    if (config.debug) {
      this.log = console.log
    } else {
      this.log = () => {}
    }

    this.client = new net.Socket()

    this.resetHandlers()

    this.client.on("data", (data) => this.dataHandler(data.toString()))
    this.client.on("error", (error) => this.errorHandler(error))
    this.client.on("close", () => this.closeHandler())
  }

   /**
    * Reset all internal handlers
    *
    * @api private
    */
  resetHandlers() {
    this.closeHandler = () => {}
    this.errorHandler = () => {}
    this.dataHandler = () => {}
  }

  /**
   * Connect to a vcontrold service and wait for the connection.
   * Rejects if the connectino can't be established or the server doesn't
   * respond with a valid prompt.
   *
   * @return {Promise}
   */
  async connect() {
    return new Promise((resolve, reject) => {
      this.errorHandler = reject
      this.dataHandler = (data) => {
        if (data === "vctrld>") {
          this.log("Connection to vControl successfully established")
          resolve()
        } else {
          reject(new Error(data))
        }
      }
      this.log("Connecting to vControl...")
      this.client.connect(this.port, this.host, () => this.log("Connected to vControl server"))
    }).then(() => {
      this.resetHandlers()
    })
  }

  /**
   * Close the connection to the server by sending the `quit` command.
   *
   * @return {Promise}
   */
  async close() {
    return new Promise((resolve, reject) => {
      this.errorHandler = reject
      this.closeHandler = () => {
        this.log("Connection to vControl closed")
        resolve();
      }
      this.client.write("quit\n")
    }).then(() => {
      this.resetHandlers()
    })
  }

  /**
   * Read data from the heating system by calling a `get` command.
   *
   * @param {String} command
   * @return {Promise} The Promise contains the data returned by the command. Rejected if the command can not be executed.
   */
  async getData(command) {
    return new Promise((resolve, reject) => {
      let response
      this.errorHandler = reject
      this.dataHandler = (data) => {
        let dataMatches = data.match(/([\s\S]*?)(vctrld>)?$/)
        if (dataMatches && dataMatches[1]) {
          response = dataMatches[1]
        }
        if (dataMatches && dataMatches[2]) {
          this.log("Command finished.")
          if (response.startsWith("ERR:")) {
            return reject(new Error("Unable to perform command '" + command + "': " + response))
          } else {
            this.log("Received response: " + response)
            return resolve(response)
          }
        }
      }
      this.log("Sending command: '" + command + "'...")
      this.timeoutHandler = setTimeout(() => this.client.destroy(new Error("No response for command " + command + " within " + this.timeout + "ms")), this.timeout)
      this.client.write(command + "\n")
    }).then((data) => {
      clearTimeout(this.timeoutHandler)
      this.errorHandler = () => {}
      this.dataHandler = () => {}
      return data
    }).catch((error) => {
      clearTimeout(this.timeoutHandler)
      return Promise.reject(error)
    })
  }

  /**
   * Write data to the heating system by calling a `set` command.
   *
   * @param {String} command
   * @param {String|String[]} args Arguments for the set command
   * @return {Promise} Rejected if the command fails
   */
  async setData(command, args) {
    return new Promise((resolve, reject) => {
      let response
      let commandString
      this.errorHandler = reject
      this.dataHandler = (data) => {
        let dataMatches = data.match(/([\s\S]*?)(vctrld>)?$/)
        if (dataMatches && dataMatches[1]) {
          response = dataMatches[1]
        }
        if (dataMatches && dataMatches[2]) {
          this.log("Command finished.")
          if (response.startsWith("OK")) {
            return resolve(response)
          } else {
            return reject(new Error("Command for vcontrold failed: " + commandString + " (" + response + ")"))
          }
        }
      }
      this.log("Sending command: '" + command + "'...")

      let argsString = ""
      if (args instanceof Array) {
        argsString = args.filter((d) => d).join(" ")
      } else if (args) {
        argsString = args
      }
      commandString = command + " " + argsString
      this.client.write(commandString + "\n")
    }).then((data) => {
      this.errorHandler = () => {}
      this.dataHandler = () => {}
      return data
    })
  }

}
