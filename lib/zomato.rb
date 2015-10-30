class Zomato
  attr_reader :headers, :results_count, :results_offset, :results, :response_code

  MAX_RESULTS_COUNT = 20

  def initialize
    setup
  end

  def search(query, extra={})
    @offset = 0
    @query = query
    @results_count = 0
    if (json = invoke(:search, extra.merge(q: query))).empty?
      json
    else
      @results_count = json['results_found'].to_i
      @results_offset = json['results_start'].to_i
      if json['restaurants'].empty?
        json
      else
        json['restaurants'].map{|r| r['restaurant'] }
      end
    end
  end

  def find(id)
    @offset = 0
    @results_count = 0
    invoke('restaurant', res_id: id)
  end

  def config
    @config ||= Rails.application.config_for('zomato')
  end

  private

  def invoke(suffix, args)
    response = Typhoeus.get(url(suffix, args), headers: headers)
    @response_code = response.code
    response.code == 200 ? JSON.load(response.body) : []
  end

  def setup
    @headers = {Accept: 'application/json', user_key: config['api_key']}
    Typhoeus::Config.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.101 Safari/537.36'
  end

  def url(suffix, args)
    [
      [config['url'], suffix].join('/'),
      URI.encode_www_form(({entity_id: config['city_id'], entity_type: 'city'}).merge(args))
    ].join('?')
  end
end
