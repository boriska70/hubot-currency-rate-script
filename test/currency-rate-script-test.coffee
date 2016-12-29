Helper = require('hubot-test-helper')
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

helper = new Helper('../src/currency-rate-script.coffee')

describe 'currency-rate-script', ->
  beforeEach ->
    @room = helper.createRoom()
    @robot =
      res: sinon.spy()
      respond: sinon.spy()
      hear: sinon.spy()
    require('../src/currency-rate-script.coffee')(@robot)
  afterEach ->
    @room.destroy()


  it 'respond to rate call', ->
    @room.user.say('alice', '@hubot rate EUR').then =>
      expect(@robot.respond).to.have.been.calledOnce
      expect(@robot.respond).to.have.been.calledWith(/rate (.*)/i)
      expect(@room.messages).to.eql [
        ['alice', '@hubot rate EUR']
        ['hubot','Please wait...']
      ]

  it 'hears empty rate-base call', ->
    @room.user.say('alice', 'rate-base').then =>
      expect(@room.messages).to.eql [
        ['alice', 'rate-base']
      ]

  it 'hears base currency change', ->
    @room.user.say('alice', 'rate-base GBP').then =>
      expect(@room.messages[0]).to.eql(['alice', 'rate-base GBP'])
      expect(@room.messages[1][0]).to.eql('hubot')
      expect(@room.messages[1][1]).to.match(/Base set to [A-Z]{3}/)
      expect(@room.messages[1][1]).to.eql('Base set to GBP')


  it 'hears rate-help', ->
    @room.user.say('bob', 'rate-help').then =>
      expect(@room.messages).to.eql [
        ['bob', 'rate-help']
        ['hubot', '@bob Use `rate-base XYZ` command to set base currency (default: USD).']
        ['hubot',
          '@bob Send message `rate ABC,DEF` to *me* to obtain the exchange rate for one or more currencies against the base currency']
      ]
