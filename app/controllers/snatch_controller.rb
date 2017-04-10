class SnatchController < ApplicationController
  require 'rest-client'
  require 'JSON'
  require 'net/http'
  require 'uri'

  def about
    snatch
  end

  def options
  end

  def link
    session[:response] = request.env['omniauth.auth']
    session[:token] = session[:response][:credentials][:token]

    session[:header] = {
      Accept: "application/json",
      Authorization: "Authorization: Bearer #{session[:token]}"
    }

    session[:p_name] = 'Snatched'
  end

  def fail
  end


  def get_me
    uri = URI.parse("https://api.spotify.com/v1/me")
    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer #{session[:token]}"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    user = JSON.parse response.body
    session[:user_id] = user['id']
  end

  def get_song
    if session[:user_id]
      song = JSON.parse RestClient.get("https://api.spotify.com/v1/me/player/currently-playing", session[:header])
      session[:s_uri] = song['item']['uri']
    end
  end

  def check_for_playlist
    if session[:user_id]
      list = JSON.parse RestClient.get("https://api.spotify.com/v1/me/playlists?limit=50", session[:header])

      list['items'].each do |x|
          if x['name'] === session[:p_name]
            puts x['name'] << ' Playlist found'
            session[:p_id] = x['id']
            return
          end
        end
        create_playlist
      end
  end

  def create_playlist

    uri = URI.parse("https://api.spotify.com/v1/users/#{session[:user_id]}/playlists")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer #{session[:token]}"
    request.body = JSON.dump({
      "description" => "Your Snatched Playlist",
      "public" => false,
      "name" => "#{session[:p_name]}"
    })

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    playlist = JSON.parse response.body
    session[:p_id] = playlist['id']
    puts "#{session[:p_name]} playlist created. ID: #{session[:p_id]}"
  end

  def actually_snatch
    uri = URI.parse("https://api.spotify.com/v1/users/#{session[:user_id]}/playlists/#{session[:p_id]}/tracks?uris=#{session[:s_uri]}")
    request = Net::HTTP::Post.new(uri)
    request["Accept"] = "application/json"
    request["Authorization"] = "Bearer #{session[:token]}"

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    puts response.code
  end
  
  def snatch
    get_me
    get_song
    check_for_playlist
    actually_snatch
  end
end
