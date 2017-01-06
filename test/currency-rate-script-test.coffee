Helper = require('hubot-test-helper')
chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'
nock = require 'nock'

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

  it 'respond to rate-convert', ->
    @room.user.say('alice', '@hubot rate-convert from USD to ILS 100').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot rate-convert from USD to ILS 100']
        ['hubot','Please wait...']
      ]

  it 'respond to rate-convert wrong format', ->
    @room.user.say('alice', '@hubot rate-convert from USD to').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot rate-convert from USD to']
      ]

  it 'respond to rate call when base and symbols are the same', ->
    @room.user.say('alice', '@hubot rate USD').then =>
      expect(@room.messages).to.eql [
        ['alice','@hubot rate USD']
        ['hubot','@alice Today 1 USD = 1 USD. As always...']
      ]

  it 'respond to rate call', ->
    nock('http://api.fixer.io')
      .get('/latest')
      .query({base: 'USD', symbols: 'EUR'})
      .reply(200,'{"base":"USD","date":"2017-01-05","rates":{"EUR":0.95229}}');
    @room.user.say('alice', '@hubot rate EUR').then =>
      expect(@room.messages).to.eql [
        ['alice', '@hubot rate EUR']
        ['hubot','Please wait...']
        ['hubot','@alice Exchange rate at 2017-01-05 based on USD. Rate: EUR:0.95229']
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
        ['hubot','@bob Sent rate-convert message to convert between currencies, for example: @hubot rate-convert from USD to EUR 100']
      ]
