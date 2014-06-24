require 'json'
require 'launchy'
require 'yaml'
require 'oauth'





class TwitterSession

  CONSUMER_KEY = File.read(Rails.root.join('.api_key')).chomp
  CONSUMER_SECRET =  File.read(Rails.root.join('.api_secret')).chomp

  CONSUMER = OAuth::Consumer.new(
        CONSUMER_KEY, CONSUMER_SECRET, site: "https://twitter.com"
  )

  TOKEN_FILE_NAME = "twitter_token_file"

  def self.get(path, query_values)
    url = path_to_url(path, query_values)
    JSON.parse(self.access_token.get(url).body)
  end

  def self.post(path, payload = nil)
    url = path_to_url(path)
    JSON.parse(self.access_token.post(url, payload).body)
  end


  def self.path_to_url(path, query_values = nil)
    Addressable::URI.new(
                          scheme: "https",
                          host: "api.twitter.com",
                          path: "/1.1/#{path}.json",
                          query_values: query_values
                          ).to_s
  end


  def self.access_token
    return @access_token unless @access_token.nil?

    if File.exist?(TOKEN_FILE_NAME)
      @access_token = File.open(token_file) { |f| YAML.load(f) }
    else
      @access_token = request_access_token
      File.open(TOKEN_FILE_NAME, "w") { |f| YAML.dump(@access_token, f) }
    end
  end

  def self.request_access_token

    request_token = CONSUMER.get_request_token

    authorize_url = request_token.authorize_url
    puts "Go to this URL: #{authorize_url}"
    Launchy.open(authorize_url)

    puts "Login, and type your verification code in"
    oauth_verifier = gets.chomp

    request_token.get_access_token(oauth_verifier: oauth_verifier)

  end

end
