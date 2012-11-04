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

    rev_name_arr = self.split('').reverse

    flip, first, new_digit = true, true, false
    rev_name_arr.map! do |char|
      return char unless flip
      flip = false 

      case char
      when '0'..'8', 'a'..'y', 'A'..'Y' then char.old_next
      when '9' then 'a'
      when 'z' then 'A'
      when 'Z'
        flip = true
        new_digit = true if first
        '0'
      end
    end

    rev_name_arr.unshift '0' if new_digit
    first, new_digit = false, false

    puts rev_name_arr.inspect

    str = rev_name_arr.reverse.join
    
    puts str
    
    str
  end
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
