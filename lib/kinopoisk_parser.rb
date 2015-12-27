require 'nokogiri'
require 'curb'
require 'json'
require 'kinopoisk/movie'
require 'kinopoisk/search'
require 'kinopoisk/person'

module Kinopoisk
  SEARCH_URL = "http://www.kinopoisk.ru/index.php?kp_query="
  NotFound   = Class.new StandardError

  # Headers are needed to mimic proper request so kinopoisk won't block it
  def self.fetch(url, proxy_url = nil, proxy_type = nil, debug = false)
    c = Curl::Easy.new(url+ "?ncrnd=#{rand(5555)}&nocookiesupport=yes") do |curl|
      curl.proxy_url = proxy_url unless proxy_url.nil?
      curl.timeout = 300
      curl.proxy_type = proxy_type unless proxy_type.nil?
      curl.headers['User-Agent'] = 'a'
      curl.headers['Accept-Encoding'] = 'a'
      curl.verbose = debug
      curl.follow_location = true
    end
    c.perform
    c
  end

  # Returns a nokogiri document or an error if fetch response status is not 200
  def self.parse(url)
    p = fetch url
    p.status.to_i==200 ? Nokogiri::HTML(p.body_str.encode('utf-8','cp1251').force_encoding('utf-8')) : raise(NotFound)
  end
end