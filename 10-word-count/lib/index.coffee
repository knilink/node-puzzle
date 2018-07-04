through2 = require 'through2'


State =
  SEPARATOR: 0
  WORD: 1

is_quote = (c) -> c is '"'
is_line_separator = (c) -> c is '\n'

is_alpha = (c) -> /[a-zA-Z0-9]/.test c
is_uppercase = (c) -> /[A-Z]/.test c

module.exports = ->
  bytes = 0
  chars = 0
  words = 0
  lines = 0

  state = State.SEPARATOR

  quoted_state =
    empty: true
    entered: false
    words: words

  last_char = '\n'

  transform = (chunk, encoding, cb) ->
    if chunk instanceof Buffer
      bytes += Buffer.byteLength chunk, 'utf8'
      chunk = chunk.toString()
    else
      bytes += Buffer.byteLength(chunk, 'utf8');

    chars += chunk.length;
    for c in chunk
      last_char = c

      if is_quote c
        if quoted_state.entered
          quoted_state.entered = false
          words = quoted_state.words
          state = State.WORD if not quoted_state.empty
        else
          quoted_state =
            entered: true
            empty: true
            words: words
          quoted_state.words++ if state is State.WORD
      else
        quoted_state.empty = false

      if is_alpha c
        words++ if state is State.WORD and is_uppercase c
        state = State.WORD
      else
        words++ if state is State.WORD
        state = State.SEPARATOR

      lines++ if is_line_separator c

    return cb()

  flush = (cb) ->
    words++ if state is State.WORD
    lines++ if last_char != '\n'
    this.push {bytes, chars, words, lines}
    this.push null
    return cb()

  return through2.obj transform, flush
