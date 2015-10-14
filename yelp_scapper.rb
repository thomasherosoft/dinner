require 'pp'
require 'mechanize'
require 'nokogiri'
require 'json'


class YelpScraper
  def fetch_restaurants
    root_path = "http://www.yelp.com/search?find_desc=Restaurants&find_loc=London,+UK&start="

    @agent = Mechanize.new

    restaurants = []

    for n in (0..2).step(10) do
      # It takes up to seconds to scrape each page,
      # so, uncomment a line below with

      # Set limit in range manually, now it's 990.
      # Yes, they lie about 28158 restaurants or they have a bug.
      # for n in (0..990).step(10) do
      restaurants_page = @agent.get(root_path + n.to_s)
      restaurants_page.search('.regular-search-result').each do |restaurant_html|
        restaurants.push(scrape_restaurant(restaurant_html))
      end
    end
    restaurants
  end

  private

  def scrape_restaurant(restaurant_html)
    restaurant = {}
    restaurant[:name] = restaurant_html.search('.biz-name').first.content
    restaurant[:yelp_score] = restaurant_html.search('.star-img').first.attr('title')[0..2].to_f # first 3 chars to float only
    restaurant[:price_range] = restaurant_html.search('.business-attribute.price-range').first.content # \u00A3 is 'pound sign'
    restaurant[:address] = parse_address(restaurant_html.search('address'))
    restaurant[:phone] = restaurant_html.search('.biz-phone').first.content.strip!
    restaurant[:cuisine_type] = parse_cuisine_type(restaurant_html.search('.category-str-list a'))
    restaurant[:review_count] = restaurant_html.search('.review-count.rating-qualifier').first.content.gsub(/reviews|review/, '').strip!.to_i
    restaurant[:url] = fetch_restaurant_url(restaurant_html)
    restaurant
  end

  def parse_address(address_html)
    addr_strs = address_html.children.map { |node| node.text.strip }.select { |s| s != '' }
    (addr_strs * ', ').strip.gsub('/\n/', '') # change ', ' to ' ' if you don't need commas
  end

  def parse_cuisine_type(cuisine_type_html)
    cuisine_type_strs = cuisine_type_html.children.map { |node| node.text.strip }.select { |s| s != '' }
    # uncomment code below if you want a string instead of array
    # (cuisine_type_strs * ', ').strip.gsub('/\n/', '') # change ', ' to ' ' if you don't need commas
  end

  def fetch_restaurant_url(restaurant_html)
    restaurant_page = @agent.click(restaurant_html.at('.indexed-biz-name a'))
    link = restaurant_page.search('.biz-website a').empty? ? '' : restaurant_page.search('.biz-website a').first[:href]
    CGI.parse(link.sub(/\A.*?\?/, ''))['url']
  end
end

ys = YelpScraper.new
open('yelp_output.json', 'w') do |f|
  f.puts JSON.dump ys.fetch_restaurants
end
