fs = require 'fs'
path = require 'path'
assert = require 'assert'
WordCount = require '../lib'

chunks_helper = (chunks, expected, done) ->
  pass = false
  counter = new WordCount()

  total = chunks.join ''
  extra =
    bytes: Buffer.byteLength total, 'utf8'
    chars: total.length
  expected  = Object.assign extra, expected

  counter.on 'readable', ->
    return unless result = this.read()
    assert.deepEqual result, expected
    assert !pass, 'Are you sure everything works as expected?'
    pass = true

  counter.on 'end', ->
    if pass then return done()
    done new Error 'Looks like transform fn does not work'

  counter.write input for input in chunks
  counter.end()

helper = (input, expected, done) -> chunks_helper [input], expected, done

fixture_helper = (expected, done) ->
  pass = false
  filename = "#{expected.lines},#{expected.words},#{expected.chars}.txt";
  counter = new WordCount()

  fs.createReadStream "#{__dirname}/fixtures/#{filename}"
    .pipe(counter)

  counter.on 'readable', ->
    return unless result = this.read()
    {lines, words, chars} = result;
    assert.deepEqual {lines, words, chars}, expected
    assert !pass, 'Are you sure everything works as expected?'
    pass = true

  counter.on 'end', ->
    if pass then return done()
    done new Error 'Looks like transform fn does not work'

describe '10-word-count', ->
  it 'should count a single word', (done) ->
    input = 'test'
    expected = words: 1, lines: 1
    helper input, expected, done

  it 'should count words in a phrase', (done) ->
    input = 'this is a basic test'
    expected = words: 5, lines: 1
    helper input, expected, done

  it 'should count quoted characters as a single word', (done) ->
    input = '"this is one word!"'
    expected = words: 1, lines: 1
    helper input, expected, done

  describe 'words', ->
    it 'should regard multiple separator as one', (done) ->
      input = 'multiple  spaces'
      expected = words: 2, lines: 1
      helper input, expected, done

    it 'should count numeric character', (done) ->
      input = '0foo  b1ar baz3'
      expected = words: 3, lines: 1
      helper input, expected, done

    it 'should regard any non-alphanumeric/non-numeric chars as separators', (done) ->
      input = 'should!regard@any#none$alphabet;as.separators;'
      expected = words: 7, lines: 1
      helper input, expected, done

  describe 'quoted', ->
    it 'should count as multiple when quoted chars right next to words', (done) ->
      input = 'foo"bar"baz'
      expected = words: 3, lines: 1
      helper input, expected, done

    it 'should count as multiple when quoted chars right next another quoted chars', (done) ->
      input = '"bar""baz"'
      expected = words: 2, lines: 1
      helper input, expected, done

    it 'should not count if quoted body is empty', (done) ->
      input = '""'
      expected = words: 0, lines: 1
      helper input, expected, done

    it 'should count any character within quotes', (done) ->
      input = '"*&^^" "  " "\n"'
      expected = words: 3, lines: 2
      helper input, expected, done

    it 'should regard quote as a separator if it does not close', (done) ->
      input = 'foo "bar'
      expected = words: 2, lines: 1
      helper input, expected, done

  describe 'camel case', ->
    it 'should count camel cased words as multiple words.', (done) ->
      input = 'FooBar'
      expected = words: 2, lines: 1
      helper input, expected, done

    it 'should regard numeric chars as lower case', (done) ->
      input = 'F00B8r'
      expected = words: 2, lines: 1
      helper input, expected, done

  describe 'lines', ->
    it 'should count empty lines', (done) ->
      input = '\n\n'
      expected = words: 0, lines: 2
      helper input, expected, done

    it 'should count quoted chars across multiple lines as a single word', (done) ->
      input = '"foo\nbar"'
      expected = words: 1, lines: 2
      helper input, expected, done

    it 'should be no lines if the content is empty', (done) ->
      input = ''
      expected = words: 0, lines: 0
      helper input, expected, done

    it 'should not count as new line if file ends with "\\n"', (done) ->
      input = 'foo\n'
      expected = words: 1, lines: 1
      helper input, expected, done

  describe 'chunks', ->
    it 'should count words across multiple chunks as one', (done) ->
      chunks = [
        'foo'
        'bar'
      ]
      expected = words: 1, lines: 1
      chunks_helper chunks, expected, done

    it 'should count quoted chars across multiple chunks as one', (done) ->
      chunks = [
        '"foo'
        'bar"'
      ]
      expected = words: 1, lines: 1
      chunks_helper chunks, expected, done

    it 'should count lines across multiple chunks as one', (done) ->
      chunks = [
        'foo'
        'bar\nbar'
      ]
      expected = words: 2, lines: 2
      chunks_helper chunks, expected, done

  it 'should pass all fixtures', (done) ->
    fs.readdir "#{__dirname}/fixtures", (err, files) ->
      _loop = ->
        filename = files.pop()
        if not filename
          done()
          return
        basename = path.basename filename, '.txt'
        [lines, words, chars] = basename
          .split ','
          .map (a) -> parseInt(a)
        fixture_helper({lines, words, chars}, _loop)
      _loop()
