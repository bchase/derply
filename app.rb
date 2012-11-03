require 'sinatra'
require 'haml'
require 'mongoid'

# TODO irb -r ./app.rb

configure :development do 
  $host = 'localhost:4567'
  Mongoid.load!("mongoid.yml", :development)
end

configure :production do 
  $host = 'example.com'
  Mongoid.load!("mongoid.yml", :production)
end

class Link
  include Mongoid::Document

  field :name, type: String
  field :url,  type: String

  validates_uniqueness_of :name

  def self.next_name
    @last = last
    @last ? @last.name + '1' : 'a'
  end

  def short_url
    "#{$host}/#{name}"
  end

  def initialize(attrs = nil, options = nil)
    super
    self.name = Link.next_name unless attrs[:name]
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
%p Link:
%p= @link.short_url
