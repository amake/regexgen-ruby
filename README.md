# regexgen

Generate regular expressions that match a set of strings.

This is a Ruby port of [@devongovett](https://github.com/devongovett/regexgen)'s
JavaScript [regexgen](https://github.com/devongovett/regexgen) package.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'regexgen'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install regexgen

## Usage

```ruby
require 'regexgen'

Regexgen.generate(['foobar', 'foobaz', 'foozap', 'fooza']) #=> /foo(?:zap?|ba[rz])/
```

## CLI

`regexgen` also has a simple CLI to generate regexes using inputs from the
command line.

```sh
$ regexgen
usage: regexgen [-mix] strings...
    -m                               Multiline flag
    -i                               Case-insensitive flag
    -x                               Extended flag
```

## Unicode handling

Unlike the JavaScript version, this package does not do any special Unicode
handling because Ruby does it all for you. You are recommended to use a Unicode
encoding for your strings.

## How does it work?

Just like the JavaScript version:

1. Generate a [Trie](https://en.wikipedia.org/wiki/Trie) containing all of the
   input strings. This is a tree structure where each edge represents a single
   character. This removes redundancies at the start of the strings, but common
   branches further down are not merged.

2. A trie can be seen as a tree-shaped deterministic finite automaton (DFA), so
   DFA algorithms can be applied. In this case, we apply [Hopcroft's DFA
   minimization
   algorithm](https://en.wikipedia.org/wiki/DFA_minimization#Hopcroft.27s_algorithm)
   to merge the nondistinguishable states.

3. Convert the resulting minimized DFA to a regular expression. This is done
   using [Brzozowski's algebraic
   method](http://cs.stackexchange.com/questions/2016/how-to-convert-finite-automata-to-regular-expressions#2392),
   which is quite elegant. It expresses the DFA as a system of equations which
   can be solved for a resulting regex. Along the way, some additional
   optimizations are made, such as hoisting common substrings out of an
   alternation, and using character class ranges. This produces an an [Abstract
   Syntax Tree](https://en.wikipedia.org/wiki/Abstract_syntax_tree) (AST) for
   the regex, which is then converted to a string and compiled to a Ruby
   `Regexp` object.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake test` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/amake/regexgen.


## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
