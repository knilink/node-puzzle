# It's basically a finite state machine solution

#   a: lowercase
#   A: uppercase
#   ": quote
#   _: words separator
#  \n: lines separator
# EOF: end of file

# |            state            |                           action                            |
# +----------+---------+--------+-----------------------+--------------------+--------+-------+
# | previous | current | quoted |                 words | words_before_quote | quoted | lines |
# +----------+---------+--------+-----------------------+--------------------+--------+-------+
# | _        | _       |        |                       |                    |        |       |
# | a        | _       |        |                       |                    |        |       |
# | a        | a       |        |                       |                    |        |       |
# | not aA   | a       |        |                    +1 |                    |        |       |
# |          | A       |        |                    +1 |                    |        |       |
# |          | "       |      0 |                       | words              |      1 |       |
# | "        | "       |      1 |                       |                    |      0 |       |
# | not "    | "       |      1 | words_before_quote +1 |                    |      0 |       |
# |          | \n      |        |                       |                    |        |    +1 |
# | not \n   | EOF     |        |                       |                    |        |    +1 |

through2 = require 'through2'

A = (c) -> /[A-Z]/.test c
a = (c) -> /[0-9a-z]/.test c
_ = (c) -> /[^0-9a-z\n\"]/.test c
n = (c) -> c is '\n'
q = (c) -> c is '"'

module.exports = ->
  bytes = 0
  chars = 0
  words = 0
  lines = 0
  words_before_quote = words

  pc = null # previous character
  cc = '\n' # current character
  quoted = false

  transform = (chunk, encoding, cb) ->
    if chunk instanceof Buffer
      bytes += Buffer.byteLength chunk, 'utf8'
      chunk = chunk.toString()
    else
      bytes += Buffer.byteLength(chunk, 'utf8');

    chars += chunk.length;
    for c in chunk
      pc = cc
      cc = c

      if (a cc) and not (a pc) and not (A pc)
        words++
      if A cc
        words++
      if q cc
        if quoted and not (q pc)
          words = words_before_quote + 1
        else
          words_before_quote = words
        quoted = !quoted

      lines++ if n cc

    return cb()

  flush = (cb) ->
    lines++ if not n cc
    this.push {bytes, chars, words, lines}
    this.push null
    return cb()

  return through2.obj transform, flush
