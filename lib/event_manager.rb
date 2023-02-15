require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_numbers(phone_numbers)
  phone_numbers.to_s.tr!('^0-9', '')
  if phone_numbers.size == 11 and phone_numbers[0] == '1'
    puts phone_numbers[1..10]
  elsif phone_numbers.size == 10
    puts phone_numbers   
  end
end

def time_targeting(time)
  time.split(' ')[1].split(':')[0]
end

def day_of_the_week_targeting(time)
  date = time.split(' ')[0].split('/')
  date.map! { |x|  x == date[2]? ("20" + x).to_i: x.to_i }
  month, day, year = date[0], date[1], date[2]
  Date.new(year, month, day).wday
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
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

list_of_registration_hours = []
list_of_days_of_the_week = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_numbers = row[:homephone]
  time = row[:regdate]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  #save_thank_you_letter(id,form_letter)
  #clean_phone_numbers(phone_numbers)
  list_of_registration_hours << time_targeting(time)
  list_of_days_of_the_week << day_of_the_week_targeting(time)
end

the_number_of_people_at_a_certain_hour = Hash.new(0)
list_of_registration_hours.each { |v|the_number_of_people_at_a_certain_hour.store(v, the_number_of_people_at_a_certain_hour[v]+1) }
the_number_of_people = 0
the_number_of_people_at_a_certain_hour.each_value { |v| the_number_of_people = v if v > the_number_of_people }
the_number_of_people_at_a_certain_hour.each { |k,v| puts k if v == the_number_of_people }

the_number_of_day_of_the_week_with_more_people_registration = Hash.new(0)
list_of_days_of_the_week.each { |v| the_number_of_day_of_the_week_with_more_people_registration.store(v, the_number_of_day_of_the_week_with_more_people_registration[v]+1) }
number_of_registered_people = 0
the_number_of_day_of_the_week_with_more_people_registration.each_value { |v| number_of_registered_people = v if v > number_of_registered_people }
the_number_of_day_of_the_week_with_more_people_registration.each { |k,v| puts k if v == number_of_registered_people }