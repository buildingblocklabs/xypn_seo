require 'nokogiri'
require 'rest-client'

class XYPNScraper
  extend HTMLCleaner

  def initialize(html_string)
    @noko_doc = create_nokogiri_doc(html_string)
  end

  def scrape_advisor_list
    scrape_profile_urls # array of all XPYN profile URLs
  end

  def scrape_advisor
    scrape_profile # hash of profile scrape
  end

  private

  attr_reader :noko_doc

  def create_nokogiri_doc(html_string)
    clean_html = HTMLCleaner.clean(html_string)
    Nokogiri::HTML(clean_html)
  end

  def scrape_profile_urls
    @noko_doc.xpath('//h3/a/@href').map do | noko_el |
      noko_el.value
    end
  end

  def scrape_profile
    { 
      name:     parse_advisor_name,
      business: parse_business_name,
      url:      parse_business_site
    }
  end

  def parse_advisor_name
    if @noko_doc.xpath('//h1').children.first.text.nil?
      "UNKNOWN"
    else
      @noko_doc.xpath('//h1').children.first.text.strip
    end
  end

  def parse_business_name
    if @noko_doc.xpath('//h1').children.last.text.nil?
      "UNKNOWN"
    else
      @noko_doc.xpath('//h1').children.last.text
    end
  end

  def parse_business_site
    if @noko_doc.xpath('//p[@class="advisor-website"]/a/@href').first.nil?
      "UNKNOWN"
    else
      @noko_doc.xpath('//p[@class="advisor-website"]/a/@href').first.value
    end
  end
end

# BASIC RUNNER/TASK LOGIC:
# First, grab all the advisors

response = RestClient.post 'http://www.xyplanningnetwork.com/wp-admin/admin-ajax.php', {action: 'do_ajax_advisor_search', page: '1', amountPerPage: '10', filterCriteria: 'fee-structure', filterValue: 'all' }

parsed_page = Scraper.new(response.body)

all_XYPN_advisor_urls = parsed_page.parse_advisor_list

# Next, iterate over each page to grab whatever info needed
# Just doing the first three of the array to not go crazy with the requests

advisors = []

all_XYPN_advisor_urls.each do | xypn_url |
  response = RestClient.get(xypn_url)
  parsed_page = Scraper.new(response.body)
  advisor = parsed_page.parse_advisor
  advisor[:xypn_profile] = xypn_url
  puts advisor
  advisors << advisor
end
