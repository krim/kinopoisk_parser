require 'nokogiri'
require 'curb'
require 'kinopoisk/movie'
require 'kinopoisk/search'
require 'kinopoisk/person'

module Kinopoisk
  SEARCH_URL = "http://www.kinopoisk.ru/index.php?kp_query="
  NotFound   = Class.new StandardError

  # Headers are needed to mimic proper request so kinopoisk won't block it
  def self.fetch(url, proxy_url = nil, proxy_type = nil, debug = false)
    c = Curl::Easy.new(url) do |curl|
      curl.proxy_url = proxy_url unless proxy_url.nil?
      curl.timeout = 300
      curl.proxy_type = proxy_type unless proxy_type.nil?
      curl.headers['User-Agent'] = 'a'
      curl.headers['Accept-Encoding'] = 'a'
      curl.verbose = debug
    end
    c.perform
    c
  end

  # Returns a nokogiri document or an error if fetch response status is not 200
  def self.parse(url)
    p = fetch url
    p.status.to_i==200 ? Nokogiri::HTML(p.body_str.force_encoding('windows-1251').encode('utf-8')) : raise(NotFound)
  end
end