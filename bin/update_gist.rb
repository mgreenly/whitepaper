#!/usr/bin/env ruby

require 'net/http'
require 'uri'
require 'json'

# Check arguments
if ARGV.length != 2
  puts "Usage: #{$0} <gist_id> <file_path>"
  puts "Updates GitHub gist with contents of specified file"
  puts ""
  puts "Example:"
  puts "  #{$0} 032da2f429a7e9100d52ecd7a47e170c disclaimer.md"
  exit 1
end

gist_id = ARGV[0]
file_path = ARGV[1]

# Check if file exists
unless File.exist?(file_path)
  puts "Error: File '#{file_path}' not found"
  exit 1
end

# Read file contents
begin
  content = File.read(file_path)
rescue => e
  puts "Error reading file: #{e.message}"
  exit 1
end

# Get filename for gist
filename = File.basename(file_path)

# GitHub token from environment
token = ENV['GITHUB_TOKEN']
if token.nil? || token.empty?
  puts "Error: GITHUB_TOKEN environment variable not set"
  puts "Create a personal access token with 'gist' scope at:"
  puts "https://github.com/settings/tokens"
  exit 1
end

# Check token permissions by getting user info
puts "Checking token permissions..."
user_uri = URI("https://api.github.com/user")
user_http = Net::HTTP.new(user_uri.host, user_uri.port)
user_http.use_ssl = true

user_request = Net::HTTP::Get.new(user_uri)
user_request['Authorization'] = "Bearer #{token}"
user_request['Accept'] = 'application/vnd.github.v3+json'
user_request['User-Agent'] = 'update_gist.rb'

user_response = user_http.request(user_request)
case user_response.code
when '200'
  user_info = JSON.parse(user_response.body)
  current_user = user_info['login']
  puts "Authenticated as: #{current_user}"
when '401'
  puts "Error: Invalid GitHub token"
  puts "Check your GITHUB_TOKEN or create a new one with 'gist' scope"
  exit 1
else
  puts "Error checking token: HTTP #{user_response.code}"
  exit 1
end

# Gist ID from command line argument

# First, check gist ownership
uri = URI("https://api.github.com/gists/#{gist_id}")
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

# Check gist info first
get_request = Net::HTTP::Get.new(uri)
get_request['Authorization'] = "Bearer #{token}"
get_request['Accept'] = 'application/vnd.github.v3+json'
get_request['User-Agent'] = 'update_gist.rb'

puts "Checking gist ownership..."
check_response = http.request(get_request)

case check_response.code
when '200'
  gist_info = JSON.parse(check_response.body)
  owner = gist_info['owner']['login']
  puts "Gist owner: #{owner}"
  
  # Check if current user owns the gist
  if current_user != owner
    puts "Error: You (#{current_user}) don't own this gist (owned by #{owner})"
    puts "You can only update gists you own"
    exit 1
  end
  
  puts "✓ Ownership confirmed"
when '404'
  puts "Error: Gist not found"
  exit 1
when '401'
  puts "Error: Authentication failed"
  puts "Check your GITHUB_TOKEN"
  exit 1
else
  puts "Error checking gist: HTTP #{check_response.code}"
  puts check_response.body
  exit 1
end

# Request payload
payload = {
  files: {
    filename => {
      content: content
    }
  }
}

# Create update request
request = Net::HTTP::Patch.new(uri)
request['Authorization'] = "Bearer #{token}"
request['Accept'] = 'application/vnd.github.v3+json'
request['User-Agent'] = 'update_gist.rb'
request.body = payload.to_json

# Send request
begin
  response = http.request(request)
  
  case response.code
  when '200'
    puts "✓ Successfully updated gist: #{filename}"
    puts "  Gist URL: https://gist.github.com/#{gist_id}"
  when '404'
    puts "Error: Gist not found or access denied"
    puts "Check that the gist ID is correct and you have access"
    exit 1
  when '401'
    puts "Error: Authentication failed"
    puts "Check your GITHUB_TOKEN"
    exit 1
  when '403'
    puts "Error: Access forbidden"
    puts ""
    puts "Since you own this gist, the issue is likely:"
    puts "  - Your GitHub token lacks the 'gist' scope"
    puts "  - Your token has expired"
    puts ""
    puts "To fix:"
    puts "  1. Go to https://github.com/settings/tokens"
    puts "  2. Create a new Personal Access Token (classic)"
    puts "  3. Make sure to check the 'gist' scope"
    puts "  4. Update your GITHUB_TOKEN environment variable"
    exit 1
  else
    puts "Error: HTTP #{response.code}"
    puts response.body
    exit 1
  end
rescue => e
  puts "Error making request: #{e.message}"
  exit 1
end