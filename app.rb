#!/usr/bin/env ruby

require 'sinatra'
require 'haml'
require 'mongoid'

configure :development do 
  $host = 'localhost:4567'
  Mongoid.load!("mongoid.yml", :development)
end

configure :production do 
  $host = 'derply.herokuapp.com'
  Mongoid.load!("mongoid.yml", :production)
end

class Link
  class NameString < String
    def next
      radix_36_int  = self.to_i(36)
      radix_36_int += 1
      radix_36_int.to_s(36)
    end

    def next!
      self.replace self.next
    end
  end

  include Mongoid::Document

  field :name, type: String
  field :url,  type: String
  field :auto, type: Boolean, default: false

  validates_uniqueness_of :name
  # validates_presence_of   :name, :url

  def initialize(attrs={}, options={})
    super
    ensure_name!
  end

  def short_url
    "#{$host}/#{name}"
  end

  def name?
    !self.name.nil? && !self.name.empty?
  end

private
  def self.last_auto
    Link.where(auto: true).last
  end

  def self.last_name
    @@last_name ||= NameString.new(self.last_auto.try(:name) || '0')
  end

  def self.does_not_exist_with_name?(name)
    !name.nil? and Link.where(name: name).count == 0
  end

  def ensure_name!
    return true if self.name?

    name = Link.last_name.next! until Link.does_not_exist_with_name?(name)

    self.name = name
    self.auto = true
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
  %a{href:@link.short_url}= @link.short_url
