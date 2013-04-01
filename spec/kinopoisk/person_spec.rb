#coding: UTF-8
require 'spec_helper'

describe Kinopoisk::Person, vcr: { cassette_name: 'person' } do
  let(:person) { Kinopoisk::Person.new 13180 }

  it 'should return right url' do
    person.url.should eq('http://www.kinopoisk.ru/name/13180/')
  end

  it { person.best_movies.should include('Карты, деньги, два ствола', 'Братья по оружию') }
  it { person.poster.should eq('http://st.kinopoisk.ru/images/actor/13180.jpg') }
  it { person.career.should eq(['Актер', 'Режиссер', 'Сценарист', 'Продюсер']) }
  it { person.genres.should eq(['драма', 'комедия', 'криминал']) }
  it { person.partner.should eq('Далия Ибельхауптайте') }
  it { person.name_en.should eq('Dexter Fletcher') }
  it { person.name.should eq('Декстер Флетчер') }
  it { person.birthplace.should eq('Лондон') }
  it { person.first_movie.should eq('1976') }
  it { person.last_movie.should eq('2014') }
  it { person.birthdate.should be_a(Date) }
  it { person.total_movies.should eq(87) }
  it { person.height.should eq('1.68 м') }
end