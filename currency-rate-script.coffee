# Description:
#   Get currencies exchange rate. Powered by http://fixer.io/
#
# Dependencies:
#   "<module name>": "<module version>"
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
#
# Commands:
#   hubot rate ABC(,DEF) - get currency/currencies exchange rate
#   rate-base - set base currency for the exchange rate calculation
#   rate-help - get some help
#
# Notes:
#   The exchange rates can be inaccurate. Please only use as the example or on your own risk
#
# Author:
#   boriska70@gmail.com

module.exports = (robot) ->

  rateBase='USD'
  
  robot.hear /rate-help/i, (res) ->
    res.reply 'Use `rate-base XYZ` command to set base currency (default: USD).'
    res.reply 'Send message `rate ABC,DEF` to *me* to obtain the exchange rate for one or more currencies against the base currency'

  robot.hear /rate-base (.*)/i, (res) ->
    curBase=res.match[1]
    # add comparison against http://api.fixer.io/latest here
    rateBase=curBase
    res.send 'Base set to ' + rateBase

  robot.respond /rate (.*)/i, (res) ->
    currencies=res.match[1]
    res.emote 'Please wait...'
    robot.http('http://api.fixer.io/latest?base='+rateBase+'&symbols='+currencies)
      .header('Accept', 'application/json')
      .get() (err, resp, body) ->
        if resp.statusCode isnt 200
          console.log('Bad try: '+resp.statusCode + ', body: ' + body)
          res.reply 'Sorry cannot get it, received ' + body
        jbody=JSON.parse(body)
        res.reply 'Exchange rate at ' + jbody.date + ' based on '+ jbody.base + '. Rates: ' + JSON.stringify(jbody.rates).replace(/[{}"]/g,'')
