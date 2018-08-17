require "open-uri"
require "json"

class HomeController < ApplicationController
  def index
  end

  def search_images
    @search_term = request.request_parameters["search_term"]

    calls = 0

    10.times do |i|
      begin
        search_results = Unsplash::Photo.search(@search_term, page=(i+1), per_page = 30, orientation = "landscape")
      rescue JSON::ParserError
        puts "Rate limit exceeded"
        sleep_one_hour
        search_results = Unsplash::Photo.search(@search_term, page=(i+1), per_page = 30, orientation = "landscape")
      end
      # calls = check_calls(calls)
      @search_results = search_results
      search_results.each do |item|
        begin
          photo = Unsplash::Photo.find(item[:id])
        rescue JSON::ParserError
          puts "Rate limit exceeded"
          sleep_one_hour
          photo = Unsplash::Photo.find(item[:id])
        end
        location = photo[:location]
        folder_path = 'pictures/' + @search_term.tr(' ', '') + '/'
        file_path = folder_path + photo[:id]
        if !File.directory?(folder_path) then
          Dir.mkdir folder_path
        end
        begin
          open(file_path  + '.jpeg', 'wb') do |file_picture|
            file_picture << open(photo[:urls][:small]).read
            puts "saved photo with id: " + item[:id]
          end
          open(file_path + '.json', 'wb') do |file_location|
            file_location << location.to_json
            puts "saved location information for photo with id: " + item[:id]
          end
        rescue StandardError
          puts "Failed saving image with id: " + item[:id]
        end
        # calls = check_calls(calls)
      end
    end
  end

  def check_calls(calls)
    calls = calls + 1
    puts "Calls: " + calls.to_s
    if(calls == 50) then
      sleep_one_hour
    end
    calls
  end

  def sleep_one_hour
    d = DateTime.now
    puts "start sleeping at: " + d.strftime("%d/%m/%Y %H:%M")
    sleep 3600 # sleep for one hour
    puts "end sleeping"
  end
end
