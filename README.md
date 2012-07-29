# CSV Interpreter for Ruby

This is a tool that allows you to write declarative code defining how a
CSV file is to be interpreted as a series of records.

It wraps and uses the CSV object from Ruby 1.9's standard library (it's
not a replacement).

It's inspired by the jbuilder library:
 https://github.com/rails/jbuilder

I needed to parse a CSV file, and faced with the prospect of manually
writing loops and constructing sub-hashes for each record I decided to
write a DSL so I can specify the structure of what's to be produced
without having to specify precisely how to do it.
