# encoding: UTF-8

require 'pp'
require './parser'

md = <<EOS
# This is あ H1

#This is あ H1#

## This is / H2

###### This is an H6

# This is an H1! #

## This is an H2 ##

### This is an H3 ######

This is an H1
=============

This is an H2
-------------

> ## This is a header in quotation.
>> ## This is a header in quotation.

![Alt text](/:path/to/img.jpg)

![Alt text](/path/to/img.jpg "Optional title.")

![Alt text][id]

aaaaa

[id]: url/to/image "Optional title"


Clicking this number[^abc] will lead you to a footnote.

[^abc]: Handy! Now click the return link to go back.


EOS

parser = MDlet.new md
parser.parsed.each do |e|
  pp e
end
puts "*"*22
pp parser.ref_value('^abc')
pp parser.ref_value('id')
