should = require("should")
MockVControlD = require("./mockvcontrold")
VControl = require("../index")

mockVControldData =
  getTempA: () -> "60.00000 Grad Celsius"
  setTimerZirkuSo: () -> ""


describe "The VControl", =>

  describe "without a server", =>
    before =>
      @vControl = new VControl({
        host: "localhost"
        port: 3002
        })

    it "should throw an error when connecting", =>
      await @vControl.connect().should.rejectedWith("connect ECONNREFUSED 127.0.0.1:3002")

  describe "with a server", =>
    before =>
      @vControl = new VControl({
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
      await @vControl.getData("getTempA").should.rejectedWith("This socket is closed")

    it "should throw an error when trying to connect twice", =>
      await @vControl.connect()
      await @vControl.connect().should.rejectedWith("Client already connected. Close connection first.")
      await @vControl.close()

      should.not.exist(@vControl.socket.localPort)

    it "should end the socket when closing the connection", =>
      await @vControl.connect()
      await @vControl.close()

      should.not.exist(@vControl.socket.localPort)

    describe "and proper opening an closing connection", =>
      beforeEach =>
        @mockVControlD.resetCommandLog()
        await @vControl.connect()

      afterEach =>
        await @vControl.close()

      it "should get data", =>
        data = await @vControl.getData("getTempA")

        data.should.equal("60.00000 Grad Celsius\n")
        @mockVControlD.commandLog.should.eql(["getTempA"])

      it "should set data string", =>
        await @vControl.setData("setTimerZirkuSo", "data")

        @mockVControlD.commandLog.should.eql(["setTimerZirkuSo data"])

      it "should set data array", =>
        await @vControl.setData("setTimerZirkuSo", ["data1", "data2"])

        @mockVControlD.commandLog.should.eql(["setTimerZirkuSo data1 data2"])

      it "should throw an error if an error occurs when executing the command", =>
        await @vControl.getData("unknownCommand").should.rejectedWith(new Error("Unable to perform command 'unknownCommand': ERR: unknown command\n"))

        @mockVControlD.commandLog.should.eql(["unknownCommand"])
