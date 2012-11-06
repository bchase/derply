require 'sinatra'
require 'haml'
require 'mongoid'

module Slugger
  # # returns a class here
  # Slug = Slugger::SlugClass.for ranges: ['0'..'9', 'a'..'z', 'A'..'Z'], last: '0sDw33'
  # 
  # # each time we want to generate a new link slug...
  # slug = Slug.new
  
  class SlugDigit < Enumerator
    # include Enumerable # tried to inherit from this lol

    attr_accessor :value

    def to_s
      self.value
    end

    def next
      @@flipped  = false
      self.value = super
    rescue StopIteration
      self.rewind
      self.next
      @@flipped  = true
      self.value
    end

    def flipped?
      @@flipped
    end

    def initialize(char_arr, char=nil)
      # TODO test args

      @@char_arr = char_arr
      @@flipped  = false

      char ||= char_arr.first

      super(char_arr)

      skips  = char_arr.index char
      skips.times { self.next }

      self.value = char
    end
  end

  module SlugClass
    def self.for(opts)
      # TODO check for ranges of strings
      
      ranges   = opts[:ranges]
      last_str = opts[:last] || ranges.first.first #TODO


      char_arr = ranges.map(&:to_a).flatten

      return Class.new(String) do
      # private # TODO

        # available from SlugType.for opts
        @@char_arr      = char_arr
        @@initial_str   = last_str # tried first to grab `last` inside of a `def` at first
        # available from SlugType.for opts

        def char_arr
          @@char_arr
        end

        def initial_str
          @@initial_str
        end

        def rev_digit_arr
          @@rev_digit_arr ||= initial_str.split('').map do |char|
            SlugDigit.new(char_arr, char)
          end.reverse
        end

        def to_s
          rev_digit_arr.reverse.map(&:to_s).join
        end
        
        def last
          self.class.last
        end

        def self.last
          @@last ||= self.new(@@initial_str) # first tried `self.class.new`, just blew my own mind
        end 

        def increment_lsd
          flipped_last = true
          rev_digit_arr.map! do |digit|
            return digit unless flipped_last

            digit.next
            flipped_last = digit.flipped?
            digit
          end
        end

        def push_new_msd
          rev_digit_arr.push SlugDigit.new(@@char_arr)
        end

        def next
          # flip digits as needed
          increment_lsd

          # add a least significant digit if they all flipped
          push_new_msd if rev_digit_arr.all? &:flipped?

          @@last = self

          self.to_s
        end

        def initialize(str=last.next)
          # str ||= @@last.next
          super(str)
        end
      end
    end
  end
end

configure :development do 
  $host = 'localhost:4567'
  Mongoid.load!("mongoid.yml", :development)
end

configure :production do 
  $host = 'example.com'
  Mongoid.load!("mongoid.yml", :production)
end

class LinkNameString < String
  alias :old_next :next

  def next!
    self.replace self.next
  end

  def next
    # @str ||= Link.where(auto: true).last.try(:name) 
    # return (@str = '0') if @str.nil?

    char_arr     = self.split('')
    rev_char_arr = char_arr.reverse

    if char_arr.all? {|ch| ch == 'Z' }
      return Array.new(char_arr.count + 1, '0').join
    end

    # LOOK AT USING ARRAY#CYCLE

    flip = true
    rev_char_arr.map! do |char|
      if flip
        flip = false 

        case char
        when '0'..'8', 'a'..'y', 'A'..'Y' then char.old_next
        when '9' then 'a'
        when 'z' then 'A'
        when 'Z'
          flip = true
          FIRST_CHAR
        end
      else
        char
      end
    end

    str = rev_char_arr.reverse.join
  end

private
  FIRST_CHAR, LAST_CHAR = '0', 'Z'
end 

class Link
  include Mongoid::Document

  field :name, type: String
  field :url,  type: String
  field :auto, type: Boolean, default: false

  validates_uniqueness_of :name

  @@last_name = LinkNameString.new(Link.where(auto: true).last.try(:name) || '0')

  def short_url
    "#{$host}/#{name}"
  end

  def initialize(attrs={}, options={})
    super
    ensure_name!
  end

private
  def ensure_name!
    return true if self.name

    (name = @@last_name.next!) until Link.does_not_exist_with_name?(name)

    self.name = name
    self.auto = true
  end

  def self.does_not_exist_with_name?(name)
    !name.nil? and Link.where(name: name).count == 0
  end
end

get '/' do 
  haml :home 
end

post '/_/new' do
  @link = Link.create(name: params[:name], url: params[:url])
  haml :new
end

get %r{^/([[:alnum:]]+$)} do |name|
  @link = Link.where(name: name).first
  redirect to(@link.url)
end

__END__

@@ home
%form#new-link{action: '/_/new', method: 'POST'}
  %label{for: 'url'} URL
  %input#url{name: 'url'}
  %label{for: 'name'} Name (optional)
  %input#name{name: 'name'}
  %input{type: 'submit'}

@@ new
%p 
  = @link.short_url
  %a{href:@link}= @link.short_url
