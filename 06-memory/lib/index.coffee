fs = require "fs"
rl = require "readline"

# Below is the minimum implementation to pass the test case since there is no
# further specification.
#
# Practically, "countryIpCounter" should capture all possible exceptions such as
# "file not exists", "invalid format" etc and pass the error object back to its
# caller via "cb err, null"

exports.countryIpCounter = (countryCode, cb) ->
  return cb() unless countryCode

  counter = 0

  input = fs.createReadStream "#{__dirname}/../data/geo.txt", encoding: "utf8"

  rd = rl.createInterface {input}

  rd
    .on "line", (line) ->
      line = line.toString().split "\t"
      counter += +line[1] - +line[0] if line[3] == countryCode
    .on "close", ->
      cb null, counter
