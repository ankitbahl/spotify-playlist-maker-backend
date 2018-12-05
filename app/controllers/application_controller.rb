require 'net/http'
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def auth_redirect
    token = get_token(params['code'])
    user = create_get_user(token)
    tracks = get_tracks(token)
    playlist = get_fire_playlist_id(token)
    if playlist
      delete_all_songs(playlist, token)
    else
      playlist = create_playlist(token)
    end
    add_tracks(playlist, tracks, token)
    redirect_to Rails.application.secrets.frontend
  end

  private
  def get_token(code)
    uri = URI('https://accounts.spotify.com/api/token')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri)
    req['Authorization'] = "Basic #{Base64.strict_encode64("#{Rails.application.secrets.spotify_id}:#{Rails.application.secrets.spotify_secret}")}"
    req.body = URI.encode_www_form(grant_type: 'authorization_code', code: code, redirect_uri: Rails.application.secrets.auth_redirect_uri)
    res = http.request(req)
    body = JSON.parse(res.body)
    if res.code != 200
      puts body['error']
      puts body['error_description']
    end
    body['access_token']
  end

  def create_get_user(token)
    url = 'https://api.spotify.com/v1/me'
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(uri.request_uri)
    req['Authorization'] = "Bearer #{token}"
    res = http.request(req)
    name = JSON.parse(res.body)['display_name']
    user = User.where(name: name).first
    unless user
      user = User.create(name: name)
    end
    user
  end

  def get_tracks(token)
    url = 'https://api.spotify.com/v1/me/tracks?limit=50'
    tracks = []
    while url != nil
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Authorization'] = "Bearer #{token}"
      res = http.request(req)
      body = JSON.parse(res.body)
      tracks += body['items'].map{|hash| hash['track']['uri']}
      url = body['next']
    end
    tracks.shuffle
  end

  def get_fire_playlist_id(token)
    url = 'https://api.spotify.com/v1/me/playlists'
    while url != nil
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Authorization'] = "Bearer #{token}"
      res = http.request(req)
      body = JSON.parse(res.body)
      body['items'].each do |playlist|
        if playlist['name'] == 'fire🔥'
          return playlist['id']
        end
      end
      url = body['next']
    end
    nil
  end

  def create_playlist(token)
    url = "https://api.spotify.com/v1/me/playlists"
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri)
    req['Authorization'] = "Bearer #{token}"
    req.body = JSON.generate(name: 'fire🔥', public: 'false')
    res = http.request(req)
    JSON.parse(res.body)['id']
  end

  def delete_all_songs(id, token)
    url = "https://api.spotify.com/v1/playlists/#{id}/tracks"
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Put.new(uri.request_uri)
    req['Authorization'] = "Bearer #{token}"
    req.body = JSON.generate(uris: [])
    res = http.request(req)
  end

  def add_tracks(id, tracks, token)
    url = "https://api.spotify.com/v1/playlists/#{id}/tracks"
    uri = URI(url)
    i = 0
    until tracks[i..i + 99].nil?
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Post.new(uri.request_uri)
      req['Authorization'] = "Bearer #{token}"
      req.body = JSON.generate(uris: tracks[i..i + 99])
      res = http.request(req)
      i += 100
    end
  end
end
