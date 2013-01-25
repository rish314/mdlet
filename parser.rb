# encoding: UTF-8

require 'parslet'

class MarkdownParser < Parslet::Parser
  rule(:uric) { (uric_reserved | uric_unreserved | uric_escaped).repeat }
  rule(:uric_reserved) {
     str(':') | str('/') | str('?') | str('#') | str('[') | str(']') | str('@') |
     str('!') | str('$') | str('&') | str('\'') | str('(') | str(')')
  }
  rule(:uric_unreserved) {
    match('\p{Alnum}') | str('-') | str('_') | str('.') | str('~')
  }
  rule(:uric_escaped) { str('%') }

  rule(:string_symbol) { (str('\'') | str('\"')).as(:string_sym) }
  rule(:string) {
    match("[\'\"]").repeat(1) >> (match("[\'\"]").absent? >> any).repeat(1) >> match("[\'\"]").repeat(1)
  }

  rule(:space) { match(' ').repeat(1) }
  rule(:space?) { space.maybe }
  rule(:newline) { (match('\\n') | (match('\\r') >> match('\\n').maybe)) }

  rule(:heading) { heading_setext | heading_atx }

  rule(:heading_symbol_start) { match('#').repeat(1,6).as(:heading_symbol) }
  rule(:heading_symbol_end) { match('#').repeat(1).as(:heading_symbol_end) }
  rule(:heading_atx) {
    (heading_symbol_start >> space?) >> ((str('#') | newline).absent? >> any).repeat(1).as(:heading_text) >> heading_symbol_end.maybe >> newline.maybe
  }

  rule(:setext_h1) { match('=').repeat(1) }
  rule(:setext_h2) { match('-').repeat(1) }
  rule(:heading_setext) {
    newline >> ((str('#') | newline).absent? >> any).repeat(1).as(:heading_text) >> newline >> (setext_h1 | setext_h2).as(:heading_symbol) >> newline
  }


  rule(:block_quote) {
    match('\>').repeat(1).as(:block_quote_symbol) >> space >> (newline.absent? >> any).repeat(1).as(:quote_body) >>  newline.maybe
  }


  rule(:img) {
    (img_explict | img_reference).as(:img)
  }

  # ![Alt text](/path/to/img.jpg "Optional title.")
  rule(:img_explict) {
    str('![') >> ((str('[') | str(']')).absent? >> any).repeat(1).as(:alt) >> str('](') >> uric.as(:path) >> space.maybe >> string.maybe.as(:img_title) #>> str(')') #>> newline.maybe
  }
  rule(:img_reference) {
    str('![') >> ((str('[') | str(']')).absent? >> any).repeat(1).as(:alt) >> str('][') >> ((str('[') | str(']')).absent? >> any).repeat(1).as(:img_id) >> str(']')
  }

  # [id]: url/to/image  "Optional title attribute"
  rule(:ref_link) {
    newline >> str('[') >> ((str('[') | str(']')).absent? >> any).repeat(1).as(:ref_key) >> str(']:') >> space? >> uric.as(:path) >> space >> string.as(:ref_value) #>> newline.maybe).as(:ref_link)
  }

  # [^fn-sample_footnote]
  rule(:footnote) {
    str('[') >> (str('^') >> ((str('[') | str(']')).absent? >> any).repeat(1)).as(:footnote_id) >> str(']') >> newline.maybe
  }
  # [^fn-sample_footnote]: Handy! Now click the return link to go back.
  rule(:ref_footnote_link) {
    newline >> str('[') >> ((str('[') | str(']')).absent? >> any).repeat(1).as(:ref_key) >> str(']:') >> space? >> (newline.absent? >> any).repeat(1).as(:ref_value) >> newline.maybe
  }

  rule(:etc) {
    any.as(:etc)
  }

  rule(:token) {
    string | heading | block_quote | img | footnote | ref_link | ref_footnote_link | newline | etc
  }

  rule(:markdown) {
    token.repeat(0)
  }

  root :markdown
end

class MDlet
  attr_reader :parsed
  def initialize(markdown)
    @parsed = MarkdownParser.new.parse(markdown)
  end

  def ref_value(ref_key)
    @parsed.find { |e| e[:ref_key] == ref_key }
  end
end

