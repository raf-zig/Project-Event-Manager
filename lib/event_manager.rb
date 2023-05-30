# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_numbers(phone_numbers)
  phone_numbers.to_s.tr!('^0-9', '')
  if (phone_numbers.size == 11) && (phone_numbers[0] == '1')
    phone_numbers[1..10]
  elsif phone_numbers.size == 10
    phone_numbers
  end
end

def time_targeting(time)
  time.split(' ')[1].split(':')[0]
end

def day_of_week_targeting(time)
  date = time.split(' ')[0].split('/')
  date.map! { |x| x == date[2] ? "20#{x}".to_i : x.to_i }
  month = date[0]
  day = date[1]
  year = date[2]
  Date.new(year, month, day).wday
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting\n
     www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

list_of_phone_numbers = []
list_of_registration_hours = []
list_of_days_of_week = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_numbers = row[:homephone]
  time = row[:regdate]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
  list_of_phone_numbers << clean_phone_numbers(phone_numbers)
  list_of_registration_hours << time_targeting(time)
  list_of_days_of_week << day_of_week_targeting(time)
end

number_of_people_at_certain_hour = Hash.new(0)

list_of_registration_hours.each do |v|
  number_of_people_at_certain_hour
    .store(v, number_of_people_at_certain_hour[v] + 1)
end

number_of_people = 0

number_of_people_at_certain_hour.each_value do |v|
  number_of_people = v if v > number_of_people
end

number_of_people_at_certain_hour.each do |k, v|
  puts "Most people registered at #{k}:00" if v == number_of_people
end

number_of_day_of_with_more_registration = Hash.new(0)

list_of_days_of_week.each do |v|
  number_of_day_of_with_more_registration
    .store(v, number_of_day_of_with_more_registration[v] + 1)
end

max_number_of_registered_people = 0

number_of_day_of_with_more_registration.each_value do |v|
  max_number_of_registered_people = v if v > max_number_of_registered_people
end

number_of_day_of_with_more_registration.each do |k, v|
  puts "In the #{k} day of the week, the most people registered" if v == max_number_of_registered_people
end

puts 'Phone numbers of registered people -'
list_of_phone_numbers.each { |i| puts i unless i.nil? }
