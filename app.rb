require 'sinatra'
require 'haml'
require 'mongoid'

configure :development do 
  $host = 'localhost:4567'
  Mongoid.load!("mongoid.yml", :development)
end

configure :production do 
  $host = 'example.com'
  Mongoid.load!("mongoid.yml", :production)
end

# class SequencedLinkName < String
#   def initialize
#     super self.class.next_name
#   end
# private

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
