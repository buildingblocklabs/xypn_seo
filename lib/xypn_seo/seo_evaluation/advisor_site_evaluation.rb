require 'rest-client'

class AdvisorSiteEvaluation

  def call
    evaluate_all_websites
  end

  private

  def evaluate_all_websites
    Website.all.each do | website |
      website.desktop_score = obtain_score(website.url, "desktop")
      website.mobile_score = obtain_score(website.url, "mobile")
      website.save!
    end
  end

  def obtain_score(site_url, strategy)
    api_url = "https://www.googleapis.com/pagespeedonline/v1/runPagespeed?url=#{site_url}&key=#{ENV['PAGESPEED_KEY']}&prettyprint=false&strategy=#{strategy}"
    begin
      api_response = RestClient.get api_url
    rescue RestClient::BadRequest => e
      Rails.logger.error(e)
      return 0 # Website score columns placeholder, required for correct scope querying
    rescue RestClient::InternalServerError => e
      Rails.logger.error(e)
      return 0 
    else
      response_as_json = JSON.parse(api_response.body)
      response_as_json['score']
    end
  end

end
