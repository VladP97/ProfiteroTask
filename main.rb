require 'curb'
require 'nokogiri'
require 'csv'

def get_goods_from_page(url, file_name)
  http = Curl.get(url)
  doc = Nokogiri::HTML(http.body)
  arr = doc.xpath('*//ul[contains(@class, "pagination")]/li/a').to_a
  CSV.open(file_name, "ab") do |csv|
    csv << ['Name', 'Price', 'Image_URL']
  end
  get_all_pages(arr[arr.length - 2].attribute('href').value.match(/\?p=(\d+)/)[1], url, file_name)
end

def get_all_pages(count, url, file_name)
  count.to_i.times do |index|
    get_goods(Curl.get(url, p: (index + 1).to_i), file_name)
  end
end

def get_goods(pages_array, file_name)
  doc = Nokogiri::HTML(pages_array.body)
  threads = []
  doc.xpath('//*[contains(@class ,"product_img_link")]').to_a.each_with_index do |link, index|
    threads << Thread.new do
      get_info(Curl.get(link.attribute('href').value), file_name)
    end
  end
  threads.each(&:join)
end

def get_info(good_page, file_name)
  good_array = []
  doc = Nokogiri::HTML(good_page.body)
  good_name = doc.css('.nombre_producto').first.inner_text.strip
  weight_array = doc.css('span.attribute_name').to_a
  price_array = doc.css('span.attribute_price').to_a
  unless weight_array.empty?
    weight_array.each_with_index do |weight, index|
      good_array.push([good_name + ' - ' + weight.inner_text.strip, price_array[index].inner_text.strip, doc.css('#view_full_size > img').first.attribute('src').value])
    end
  else
    good_array.push([good_name, doc.css('span#our_price_display').first.inner_text, doc.css('#view_full_size > img').first.attribute('src').value])
  end
  add_to_csv(good_array, file_name)
end

def add_to_csv(array, file_name)
  CSV.open(file_name, "ab") do |csv|
    array.each do |good|
      csv << good
    end
  end
end

get_goods_from_page('https://www.petsonic.com/snacks-huesos-para-perros/', 'file.csv')