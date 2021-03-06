#coding: UTF-8
module Kinopoisk
  class Movie
    attr_accessor :id, :url, :title, :base_url

    # New instance can be initialized with id(integer) or title(string). Second
    # argument may also receive a string title to make it easier to
    # differentiate Kinopoisk::Movie instances.
    #
    #   Kinopoisk::Movie.new 277537
    #   Kinopoisk::Movie.new 'Dexter'
    #
    # Initializing by title would send a search request and return first match.
    # Movie page request is made once and on the first access to a remote data.
    #
    def initialize(input, title=nil, proxies: nil, debug: false)
      @id    = input.is_a?(String) ? find_by_title(input) : input
      @base_url = "http://www.kinopoisk.ru/film/#{id}/"
      @url      = @base_url + "details/"
      @title = title
      @proxies = proxies
      @debug = debug
    end

    def stills
      @stills_page ||= Kinopoisk.parse(base_url + "stills/", proxies: @proxies, debug: @debug)
      stills_url = @stills_page.search("table.fotos a").first
      unless stills_url.nil?
        stills_url = stills_url.attr 'href'
        @photo_page ||= Kinopoisk.parse("http://www.kinopoisk.ru" + stills_url, proxies: @proxies, debug: @debug)
        wallpapers = @photo_page.search("script").
                                select{|z| z.text if z.content.include?("var wallpapers") }.
                                first.content
        wallpapers = wallpapers.gsub("\n    var wallpapers = ","").gsub("\n","").chomp(";")
        JSON.parse(wallpapers)
      else
        {}
      end
    end

    def keywords
      @keywords_page ||= Kinopoisk.parse(base_url + "keywords/", proxies: @proxies, debug: @debug)
      @keywords_page.css("ul.keywordsList li a").map{|a| a.text}
    end

    def series?
      doc.search("h1[itemprop=name] span").text.include?("сериал")
    end

    def film?
      !series?
    end

    # Returns an array of strings containing actor names
    def actors
      doc.search('#actorList ul li a').map{|n| n.text.gsub("\n",'').strip}
        .delete_if{|text| text=='...'}
    end

    # Returns a string containing title in russian
    def title
      @title ||= doc.search('.moviename-big').xpath('text()').text.strip
    end

    # Returns an integer imdb rating vote count
    def imdb_rating_count
      doc.search('div.block_2 div:eq(2)').text.gsub(/.*\(/, '').gsub(/[ ()]/, '').to_i
    end

    # Returns a float imdb rating
    def imdb_rating
      doc.search('div.block_2 div:eq(2)').text[/\d.\d\d/].to_f
    end

    # Returns an integer release year
    def year
      doc.search("table.info a[href*='/m_act%5Byear%5D/']").text.to_i
    end

    # Returns an array of strings containing countries
    def countries
      doc.search("table.info a[href*='/m_act%5Bcountry%5D/']").map(&:text)
    end

    # Returns a string containing budget for the movie
    def budget
      doc.search("//td[text()='бюджет']/following-sibling::*//a").text
    end

    # Returns a string containing Russia box-office
    def box_office_ru
      doc.search("td#div_rus_box_td2 a").text
    end

    # Returns a string containing USA box-office
    def box_office_us
      doc.search("td#div_usa_box_td2 a").text
    end

    # Returns a string containing world box-office
    def box_office_world
      doc.search("td#div_world_box_td2 a").text
    end

    # Returns a url to a small sized poster
    def poster
      doc.search(".film-img-box img[itemprop='image']").first.attr 'src'
    end

    # Returns a string containing world premiere date
    def premiere_world
      doc.search('td#div_world_prem_td2 .prem_ical').first.attr 'data-date-premier-start-link' rescue nil
    end

    # Returns a string containing Russian premiere date
    def premiere_ru
      doc.search('td#div_rus_prem_td2 .prem_ical').first.attr 'data-date-premier-start-link' rescue nil
    end

    # Returns a float kinopoisk rating
    def rating
      doc.search('span.rating_ball').text.to_f
    end

    # Returns a url to a big sized poster
    def poster_big
      poster.gsub 'iphone/iphone360_', 'big/'
    end

    # Returns an integer length of the movie in minutes
    def length
      doc.search('td#runtime').text.to_i
    end

    # Returns a string containing title in english
    def title_en
      search_by_itemprop 'alternativeHeadline'
    end

    # Returns a string containing movie description
    def description
      search_by_itemprop 'description'
    end

    # Returns an integer kinopoisk rating vote count
    def rating_count
      search_by_itemprop('ratingCount').to_i
    end

    # Returns an array of strings containing director names
    def directors
      to_array search_by_itemprop 'director'
    end

    # Returns an array of strings containing producer names
    def producers
      to_array search_by_itemprop 'producer'
    end

    # Returns an array of strings containing composer names
    def composers
      to_array search_by_itemprop 'musicBy'
    end

    # Returns an array of strings containing genres
    def genres
      to_array search_by_itemprop 'genre'
    end

    # Returns an array of strings containing writer names
    def writers
      to_array search_by_text 'сценарий'
    end

    # Returns an array of strings containing operator names
    def operators
      to_array search_by_text 'оператор'
    end

    # Returns an array of strings containing art director names
    def art_directors
      to_array search_by_text 'художник'
    end

    # Returns an array of strings containing editor names
    def editors
      to_array search_by_text 'монтаж'
    end

    # Returns an array of strings containing actor names
    def actors_hash
      search_by_itemprop_hash 'actors'
    end

    # Returns an hash of id and director names
    def directors_hash
      search_by_itemprop_hash 'director'
    end

    # Returns an hash of id and producer names
    def producers_hash
      search_by_itemprop_hash 'producer'
    end

    # Returns an hash of id and composer names
    def composers_hash
      search_by_itemprop_hash 'musicBy'
    end

    # Returns an hash of id and genres
    def genres_hash
      search_by_itemprop_hash 'genre'
    end

    # Returns an hash of id and writer names
    def writers_hash
      search_by_text_hash 'сценарий'
    end

    # Returns an hash of id and operator names
    def operators_hash
      search_by_text_hash 'оператор'
    end

    # Returns an hash of id and art director names
    def art_directors_hash
      search_by_text_hash 'художник'
    end

    # Returns an hash of id and editor names
    def editors_hash
      search_by_text_hash 'монтаж'
    end

    # Returns a string containing movie slogan
    def slogan
      search_by_text 'слоган'
    end

    # Returns a string containing minimal age
    def minimal_age
      search_by_text('возраст').strip
    end

    # Returns a string containing duration of the film
    def duration
      search_by_text('время').strip
    end

    private

    def doc
      @doc ||= Kinopoisk.parse(url, proxies: @proxies, debug: @debug)
    end

    # Kinopoisk has defined first=yes param to redirect to first result
    # Return its id from location header
    def find_by_title(title)
      url = SEARCH_URL+"#{URI.escape(title)}&first=yes"
      Kinopoisk.fetch(url, proxies: @proxies, debug: @debug).headers['Location'].to_s.match(/\/(\d*)\/$/)[1]
    end

    def search_by_itemprop(name)
      doc.search("[itemprop=#{name}]").text
    end

    def search_by_itemprop_hash(name)
      doc.search("[itemprop=#{name}] a").inject({}) do |h, p|
        h[p.attr('href').scan(/\d+/).first.to_i] = p.text  if p.attr('href').include?('name')
        h
      end
    end

    def search_by_text(name)
      doc.search("//td[text()='#{name}']/following-sibling::*").text
    end

    def search_by_text_hash(name)
      doc.search("//td[text()='#{name}']/following-sibling::*").search('a').inject({}) do |h, p|
        h[p.attr('href').scan(/\d+/).first.to_i] = p.text  if p.attr('href').include?('name')
        h
      end
    end

    def to_array(string)
      string.gsub('...', '').split(', ')
    end
  end
end
