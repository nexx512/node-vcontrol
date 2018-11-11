should = require("should")
MockVControlD = require("./mockvcontrold")
VControlClient = require("../index")

mockVControldData =
  getTempA: () -> "60.00000 Grad Celsius"
  setTimerZirkuSo: () -> ""
  wait: () ->
    new Promise (resolve, reject) ->
      #resolve()
      setTimeout(resolve, 1005)


describe "The VControlClient", =>

  describe "without a server", =>
    before =>
      @vControlClient = new VControlClient({
        host: "localhost"
        port: 3002
        })

    it "should throw an error when connecting", =>
      await @vControlClient.connect().should.rejectedWith("connect ECONNREFUSED 127.0.0.1:3002")

  describe "with a server", =>
    before =>
      @vControlClient = new VControlClient({
        host: "localhost"
        port: 3002
        })

      @mockVControlD = new MockVControlD(mockVControldData)
      await @mockVControlD.start("localhost", 3002)

    beforeEach =>
      @mockVControlD.resetCommandLog()

    after =>
      await @mockVControlD.stop()

    it "should throw an error if the connection is not opened before getting data", =>
      await @vControlClient.getData("getTempA").should.rejectedWith("This socket is closed")

    it "should send the quit command when closing the connection", =>
      await @vControlClient.connect()
      await @vControlClient.close()

      @mockVControlD.commandLog.should.eql(["quit"])

    describe "and proper opening an closing connection", =>
      beforeEach =>
        @mockVControlD.resetCommandLog()
        await @vControlClient.connect()

      afterEach =>
        await @vControlClient.close()

      it "should get data", =>
        data = await @vControlClient.getData("getTempA")

        data.should.equal("60.00000 Grad Celsius\n")
        @mockVControlD.commandLog.should.eql(["getTempA"])

      it "should set data string", =>
        await @vControlClient.setData("setTimerZirkuSo", "data")

        @mockVControlD.commandLog.should.eql(["setTimerZirkuSo data"])

      it "should set data array", =>
        await @vControlClient.setData("setTimerZirkuSo", ["data1", "data2"])

        @mockVControlD.commandLog.should.eql(["setTimerZirkuSo data1 data2"])

      it "should throw an error if an error occurs when executing the command", =>
        await @vControlClient.getData("unknownCommand").should.rejectedWith(new Error("Unable to perform command 'unknownCommand': ERR: unknown command\n"))

        @mockVControlD.commandLog.should.eql(["unknownCommand"])

    describe "and a command that doesn't return in time", =>
      beforeEach =>
        await @vControlClient.connect()

      it "should teminate the connection after the watchdog timeout", =>
        start = Date.now()
        await @vControlClient.getData("wait").should.rejectedWith(new Error("No response for command wait within 1000ms"))
        timeout = Date.now() - start
        timeout.should.approximately(1000, 5)
        @vControlClient.client.destroyed.should.true()
