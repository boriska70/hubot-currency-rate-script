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
#   hubot rate-convert from ABC to DEF <amount> - convert <amount> of ABC to DEF
#   hubot rate ABC - get currency exchange rate
#   rate-base - set base currency for the exchange rate calculation
#   rate-help - get some help
#
# Notes:
#   The exchange rates can be inaccurate. Please only use as the example or on your own risk
#
# Author:
#   boriska70@gmail.com

module.exports = (robot) ->
  rateBase = 'USD'
  regexRate = /rate ([A-Za-z]{3})/i
  regexConvert = /(rate-convert from [A-Za-z]{3} to [A-Za-z]{3} (\d){1,})/i

  parseConvertString = (str) ->
    regexFrom = /(from [A-Za-z]{3} to)/i
    regexTo = /(to [A-Za-z]{3} )/i
    regexAmount = /(\d{1,}$)/i
    task = {}
    task.from = str.match(regexFrom)[1].substring(5, 8).toUpperCase()
    task.to = str.match(regexTo)[1].substring(3, 6).toUpperCase()
    task.amount = str.match(regexAmount)[1]
    task

  getConvertCoeff = (str) ->
# take rate from message like this Exchange rate at 2016-12-30 based on USD. Rate: EUR:0.94868
    regexRate = /([A-Za-z]{3}:(.*))/i
    str.match(regexRate)[1].substring(4)

  robot.hear /rate-help/i, (res) ->
    console.log('Executing ' + res.match[0])
    res.reply 'Use `rate-base XYZ` command to set base currency (default: USD).'
    res.reply 'Send message `rate ABC,DEF` to *me* to obtain the exchange rate for one or more currencies against the base currency'
    res.reply('Sent rate-convert message to convert between currencies, for example: @hubot rate-convert from USD to EUR 100')

  robot.hear /rate-base (.*)/i, (res) ->
    console.log('Executing ' + res.match[0])
    curBase = res.match[1].toUpperCase()
    # add comparison against http://api.fixer.io/latest here
    rateBase = curBase.toUpperCase()
    res.send 'Base set to ' + rateBase

  robot.respond regexRate, (res) ->
    console.log('Executing ' + res.match[0])
    currency = res.match[1].toUpperCase()
    if rateBase == currency
      res.reply 'Today 1 ' + rateBase + ' = 1 ' + currency + '. As always...'
    else
      res.emote 'Please wait...'
      robot.http('http://api.fixer.io/latest?base=' + rateBase + '&symbols=' + currency)
        .header('Accept', 'application/json')
        .get() (err, resp, body) ->
          if resp.statusCode isnt 200
            console.log('Bad try: ' + resp.statusCode + ', body: ' + body)
            res.reply 'Sorry, cannot get it, received ' + body
          jbody = JSON.parse(body)
          res.reply 'Exchange rate at ' + jbody.date + ' based on ' + jbody.base + '. Rate: ' + JSON.stringify(jbody.rates).replace(/[{}"]/g, '')

  robot.respond regexConvert, (res) ->
    console.log('Executing ' + res.match[0])
    task = (parseConvertString(res.match[1]))
    if Object.keys(task).length == 0 || task.from.length != 3 || task.to.length != 3 || task.amount.length == 0
      res.reply 'Sorry, cannot do this. The correct message example is: @hubot rate-convert from USD to EUR 100'
    else
      res.emote 'Please wait...'
      robot.http('http://api.fixer.io/latest?base=' + task.from + '&symbols=' + task.to).header('Accept', 'application/json').get() (err, resp, body) ->
        if resp.statusCode isnt 200
          console.log('Bad try: ' + resp.statusCode + ', body: ' + body)
          res.reply 'Sorry, cannot get it, received ' + body
        jbody = JSON.parse(body)
        coeff = getConvertCoeff(JSON.stringify(jbody.rates).replace(/[{}"]/g, ''))
        res.reply 'Conversion result: ' + task.amount + ' ' + task.from + '=' + (task.amount * coeff) + ' ' + task.to

