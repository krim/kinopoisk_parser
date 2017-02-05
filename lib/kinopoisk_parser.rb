require 'nokogiri'
require 'curb'
require 'json'
require 'kinopoisk/movie'
require 'kinopoisk/search'
require 'kinopoisk/person'

module Kinopoisk
  SEARCH_URL = "http://www.kinopoisk.ru/index.php?kp_query="
  NotFound   = Class.new StandardError

  class << self
    # Headers are needed to mimic proper request so kinopoisk won't block it
    def fetch(url, proxies: nil, debug: false)
      tryes = 0
      proxy_url = nil
      proxy_type = nil
      begin
        if proxies.present?
          proxy = proxies.sample
          proxy_url = proxy[:proxy_url]
          proxy_type = proxy[:proxy_type]
        end
        c = Curl::Easy.new(url+ "?ncrnd=#{rand(5555)}&nocookiesupport=yes") do |curl|
          curl.proxy_url = proxy_url unless proxy_url.nil?
          curl.timeout = 300
          curl.proxy_type = proxy_type unless proxy_type.nil?
          curl.headers['User-Agent'] = user_agent
          curl.headers['Accept-Encoding'] = 'en-US,en;q=0.8,ru;q=0.6,uk;q=0.4,es;q=0.2'
          curl.verbose = debug
          curl.follow_location = true
        end
        c.perform
      rescue
        puts "try #{tryes += 1}"
        puts "BAD PROXY:: #{proxy}"
        proxies = proxies.select { |hash_proxy| hash_proxy[:proxy_url] != proxy[:proxy_url] }
        retry if proxies.count > 0
      end
      c
    end

    # Returns a nokogiri document or an error if fetch response status is not 200
    def parse(url, proxies: nil, debug: false)
      p = fetch(url, proxies: proxies, debug: debug)
      p.status.to_i==200 ? Nokogiri::HTML(p.body_str.force_encoding('windows-1251').encode('utf-8')) : raise(NotFound)
    end

    private

    def user_agent
      [
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.21 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
        "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_2) AppleWebKit/602.3.12 (KHTML, like Gecko) Version/10.0.2 Safari/602.3.12",
        "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
        "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.79 Safari/537.36 Edge/14.14393",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:50.0) Gecko/20100101 Firefox/50.0"
      ].sample
    end
  end
end
