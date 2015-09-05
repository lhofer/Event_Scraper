require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'pg'
require 'csv'

def accessingHTML(page)
	Nokogiri::HTML(open(page))
end

def scrapingEvent(event, event_url, event_number, event_names, event_information_array, 
	images, ticket_prices, starting_times, ticket_collection_array, doors_open_array, durations, 
	parking_array, venues_array, datetimes_array, all_additional_information_array)
	
	fields = event.css("div[class='col-holder']"); # has everything
	fields1 = fields.css("div[class='col-1']"); # has one portion of information
	fields2 = fields.css("div[class='col-2']"); # has other portion
	puts "--------------------NEW EVENT NO. #{event_number}---------------------"

	if fields2.at_css('div#event-summary')
		puts "THIS IS AN EVENT WITH MULTIPLE VENUES"
		# If if-statement satisfied, that means there are multiple venues for the event
		venue_ids = fields2.css('select#performance_venues option')

		#delete first venue option as it just says 'select a venue'
		venue_ids.shift
		
		#iterate through venues, store url's, access page html, scrape fields
		venue_ids.each_with_index do |venue, index|
			venue_url = event_url + "/0/#{venue['value']}"
			venue_page = accessingHTML(venue_url)

			scrapingEvent(venue_page,venue_url,index+1, event_names, event_information_array, 
			images, ticket_prices, starting_times, ticket_collection_array, doors_open_array, durations, 
			parking_array, venues_array, datetimes_array, all_additional_information_array)
		end
	else
		# the fields
		# puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		event_name = event.css('h1 a').attr('title')

		event_names << event_name
		puts "event_name: " + event_name
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		event_information_full = fields1.css('div.sub-col-1.sub-col-info div.top div.bot.event_info div p:nth-child(1)').text
		event_information = event_information_full.split(": ").last.to_s
		event_information_array << event_information
		puts "event_information: " + event_information
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		image = fields1.css('img')[0]['src']
		images << image
		puts "image: " + image
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		icons = fields2.css('ul.icons-summary li') 
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		ticket_price = icons.css("div[data-dat='es-cost-icon']").text
		ticket_prices << ticket_price
		puts "ticket_price: " + ticket_price
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		starting_time = icons.css("div[data-det='es-start-icon']").text
		starting_times << starting_time
		puts "starting_time: " + starting_time
	
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		ticket_collection = icons.css("div[data-dat='es-ticket']").text
		ticket_collection_array << ticket_collection
		puts "ticket_collection: " + ticket_collection
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		doors_open = icons.css("div[data-dat='es-doors']").text
		doors_open_array << doors_open
		puts "doors_open: " + doors_open
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		duration = icons.css("div[data-dat='es-duration']").text
		durations << duration
		puts "duration: "  + duration
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		parking = icons.css("div[data-dat='es-parking']").text
		parking_array << parking
		puts "parking: " + parking
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		venues = fields2.css('select#performance_venues').text.split(/\t\t\t\t\t\t\t\t\t/)
		venues.delete_at(0) # used to delete the "Select A Venue" string
		venues_array << venues
		puts "venues: " + "#{venues}"
	
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		datetimes = []
		grab_datetimes = fields2.css('select#performance_times').text.gsub!( /\t/, '').split(/\n\n/)
		grab_datetimes.each do |datetime|
			datetimes << datetime
		end
		datetimes.shift
		datetimes_array << datetimes
		puts "dates_and_times: " + datetimes.inspect
		
		puts "- - - - - - - - - - - - - - - - - - - - - - - - - - -"
		# Additional Information
		additional_information_array = []
		fields2.css('div#tab_detail_div')
		tab_details= fields2.css('div#tab_detail_div div')
		
		tab_details.each_with_index do |detail, index|
		  if detail.css('h6').text!=""
			if detail.attr('class') == "expandable closed"
				additional_information_array << { detail.css('h6').text => detail.at_css('div').text }
			else
				additional_information_array << { detail.css('h6').text => detail.css('p').text }
			end
		  end
		end
		all_additional_information_array << additional_information_array
		puts "addition_information: " + "#{additional_information_array}"
	
	end
end

def storingPages(url,pages,start,finish)

	# next block is for extracting total number of pages from grid home page
		#declare variables to store info and iterate through
		num_pages_events = []
		page_number = 1
		
		#open home page html and search for text declaring total number of pages
		doc = accessingHTML(url)
		
		#extract two strigns using regular expressions, this returns the strings 'of 1175' and 'of 98'
		get_page_numbers = doc.at_css('div#events-listing div#pagination p.ter_tx').text.gsub(/(of )\d+/)
		puts get_page_numbers 
		
		#put the extracted strings into an array
		get_page_numbers.each do |extracted_string|
	 		num_pages_events << extracted_string
		end
		
		#grab the last string and split it to get only the page number
		num_pages = num_pages_events.last.split.last.to_i

	# store page
	while page_number<=num_pages
		current_page = url + "/page:#{page_number}"
		
		pages << current_page
		puts "stored page #{page_number}"

		page_number += 1
	end	
end

def storingEvents(base_url,pages,events,start,finish)

	# for page_index in start..finish
	puts pages.length

	eindex=1
	pages.each do |page|
		puts "new page"
		page = accessingHTML(page);
		events_listings = page.css('div#events-listing')
		content_blocks = events_listings.css('ul li div.each div.contentSmaller div.blocks_info')
		content_blocks.each do |block|
			path=block.at_css('span a')['href']
			path = base_url + path
			events << path
			puts "stored event #{eindex}"
			eindex += 1
		end
	end
end

def main(event_names, event_information_array, 
	images, ticket_prices, starting_times, ticket_collection_array, doors_open_array, durations, 
	parking_array, venues_array, datetimes_array, all_additional_information_array)
	
	begin
		
		#iterate through pages on site and store in array pages
		pages = [] 
		url = "http://online.computicket.com/web/highlights/index/0/0/0/grid"
		storingPages(url,pages,nil,nil)
		puts "stored pages"
		
		# iterate through events on a page on site and store in array events
		events = []
		base_url = "http://online.computicket.com"
		storingEvents(base_url,pages,events,nil,nil)
		puts "stored events"
		
		# events array contains all the event URLs
		# gotten all the event urls
		# extracting information from each event
		events.each_with_index do |event,eindex|
			event_page = accessingHTML(event);
			scrapingEvent(event_page,event,eindex+1,event_names, event_information_array, 
			images, ticket_prices, starting_times, ticket_collection_array, doors_open_array, durations, 
			parking_array, venues_array, datetimes_array, all_additional_information_array)
			#scrapingEvent(event_page,event,eindex+1, database)
		end 
	end
end	

#global vars
event_names = ["Event Names"]
event_information_array = ["Categories"]
images = ["Images"]
ticket_prices = ["Ticket Price"]
starting_times = ["Starting Time"]
ticket_collection_array = ["Ticket Collection"]
doors_open_array = ["Doors Open"]
durations = ["Durration"]
parking_array = ["Parking"]
venues_array = ["Venues"]
datetimes_array = ["Dateties"]
all_additional_information_array = ["Additional Info"]

#call main function
main(event_names, event_information_array, 
	images, ticket_prices, starting_times, ticket_collection_array, doors_open_array, durations, 
	parking_array, venues_array, datetimes_array, all_additional_information_array)

#write to csv
CSV.open("computicket_events.csv", "w") do |csv|
	puts "Writing to csv..."
	csv << event_names 
	csv << event_information_array
	csv << images
	csv << ticket_prices
	csv << starting_times
	csv << ticket_collection_array
	csv << doors_open_array
	csv << durations
	csv << parking_array
	csv << venues_array
	csv << datetimes_array
	csv << all_additional_information_array
	puts "success"
end