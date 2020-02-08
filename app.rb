require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?

require 'sinatra/activerecord'
require './models'

require 'dotenv'
require 'cloudinary'

require 'date'

require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

require "google/apis/drive_v3"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

enable :sessions

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Drive API Ruby Quickstart".freeze
CREDENTIALS_PATH = "credentials.json".freeze
# The file token.yaml stores the user's access and refresh tokens, and is
# created automatically when the authorization flow completes for the first
# time.
TOKEN_PATH = "token.yaml".freeze
SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE

def authorize
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
    user_id = "default"
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: OOB_URI
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

helpers do
    def current_user
        User.find_by(id: session[:user])
    end
end

before do
    Dotenv.load
    Cloudinary.config do |config|
        config.cloud_name = ENV['CLOUD_NAME']
        config.api_key = ENV['CLOUDINARY_API_KEY']
        config.api_secret = ENV['CLOUDINARY_API_SECRET']
    end
    # authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
    #     json_key_io: File.open('client_secret_498351976214-ovp7cseasofmifgk9tlud38fe8276f69.apps.googleusercontent.com.json'),
    #     scope: 'https://www.googleapis.com/auth/drive')
    # authorizer.fetch_access_token!
  
    # @service = Google::Apis::DriveV3::DriveService.new
    # @service.authorization = authorizer
end

before '/manage' do
    if current_user.nil?
        redirect '/res'
    end
end

before '/tasks' do
    if current_user.nil?
        redirect '/res'
    end
end

get '/' do
    @cats = Cat.all
    if current_user.nil?
        @tasks=Task.none
    elsif params[:cat].nil? then
        @tasks = current_user.tasks
    else
        @tasks = Cat.find(params[:cat]).tasks.where(user_id: current_user.id)
    end
    erb :index
end

get '/signup' do
    erb :sign_up
end

post '/signup' do
    user = User.create(
        name: params[:name],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
    )
    if user.persisted?
        session[:user] = user.id
    end
    redirect '/'
end

get '/signin' do
    erb :sign_in
end

post '/signin' do
    user = User.find_by(name: params[:name])
    if user && user.authenticate(params[:password])
        session[:user] = user.id
    end
    redirect '/'
end

get '/signout' do
    session[:user]=nil
    redirect '/'
end

get '/manage' do
    @cats = Cat.all
    @tasks = current_user.tasks

    @tasks.each do |task|
        if task.cat.nil?
            task.cat = Cat.find_by(name: "Others")
            task.save
        end
    end

    erb :manage
end

get '/new' do
    erb :new
end

get '/res' do
    erb :res
end

get '/newcat' do
    @cats = Cat.all
    @users = User.all
    erb :newcat
end

drive_service = Google::Apis::DriveV3::DriveService.new
drive_service.client_options.application_name = APPLICATION_NAME
drive_service.authorization = authorize


post '/tasks/:id/delete' do
    task = Task.find(params[:id])

    file = drive_service.list_files(page_size: 10, fields: "files(name,id)")
    
    file_id = ''

    file.files.each do |file|
        if task.title == file.name
            file_id = file.id
        end
    end

    file = drive_service.get_file(file_id, fields: 'parents')   

    file = drive_service.delete_file(file_id, fields: 'id')

    task.destroy

    redirect '/manage'
end

post '/tasks/:id/done' do
    task = Task.find(params[:id])
    task.completed = true
    task.star = false
    task.accepted = false
    task.save

    file = drive_service.list_files(page_size: 100, fields: "files(name,id)")
    
    file_id = ''

    file.files.each do |file|
        if task.title == file.name
            file_id = file.id
        end
    end

    folder_id = '1b4cHvE441PP1QnmIjSTCm_6DwNII6zBt'

    file = drive_service.get_file(file_id, fields: 'parents')   
    previous_parents = file.parents.join('.')

    file = drive_service.update_file(file_id, add_parents: folder_id, remove_parents: previous_parents, fields: 'id,parents')

    redirect '/manage'
end

post '/tasks/newcat' do
    cat = Cat.create(name: params[:title])
    redirect '/newcat'
end

post '/tasks/:id/deletecat' do
    cat = Cat.find(params[:id])

    if cat.name == "Others"
        redirect '/newcat'
    end

    cat.destroy

    redirect '/newcat'
end

post '/tasks/:id/deleteuser' do
    user = User.find(params[:id])

    user.destroy

    redirect '/newcat'
end

post '/tasks' do
    task = Task.all

    task.each do |tasks|
        if params[:title] == tasks.title
            redirect '/new'
        end
    end

    img_url = ''
    folder_id = '1A7N4eLxXpc2G07xGpitsxIi5-rmYFZZR'
    file_metadata = {
    name: params[:title],
    parents: [folder_id]
    }

    if params[:file]
    img = params[:file]
    tempfile = img[:tempfile]
    upload = Cloudinary::Uploader.upload(tempfile.path)
    img_url = upload['url']
    end
    
    response = drive_service.list_files(page_size: 10,
    fields: "nextPageToken, files(id, name)")
    puts "Files:"
    puts "No files found" if response.files.empty?
    response.files.each do |file|
    puts "#{file.name} (#{file.id})"
    end

    cat = Cat.find(params[:cat])

    drive_service.create_file(file_metadata, fields: 'id', upload_source: open(img_url), content_type: 'application/pdf')
    current_user.tasks.create(title: params[:title],
        cat_id: cat.id, start: params[:start], end: params[:end],
        img: img_url)
    redirect '/'
end

get '/tasks/:id/star' do
    task = Task.find(params[:id])

    if task.accepted == true
        redirect '/manage'
    end

    if task.completed == true
        redirect '/manage'
    end

    task.star = !task.star
    task.save

    file = drive_service.list_files(page_size: 100, fields: "files(name,id)")
    
    file_id = ''

    file.files.each do |file|
        if task.title == file.name
            file_id = file.id
        end
    end

    file = drive_service.get_file(file_id, fields: 'parents')   

    # folder_id = '1A7N4eLxXpc2G07xGpitsxIi5-rmYFZZR'

    if task.star #file is rejeceted
        folder_id = '1axEZdYBfdAPDjtL8tjQ3TkcDK_K5jFM2'
    else
        folder_id = '1A7N4eLxXpc2G07xGpitsxIi5-rmYFZZR'
    end

    # if file.parents == '1axEZdYBfdAPDjtL8tjQ3TkcDK_K5jFM2'
    #     folder_id = '1A7N4eLxXpc2G07xGpitsxIi5-rmYFZZR' 
    # else
    #     folder_id = '1axEZdYBfdAPDjtL8tjQ3TkcDK_K5jFM2' 
    # end
    
    previous_parents = file.parents.join('.')

    file = drive_service.update_file(file_id, add_parents: folder_id, remove_parents: previous_parents, fields: 'id,parents')

    redirect '/manage'
end

get '/tasks/:id/accepted' do
    task = Task.find(params[:id])

    if task.star == true
        redirect '/manage'
    end

    if task.completed == true
        redirect '/manage'
    end

    task.accepted = !task.accepted
    task.save

    file = drive_service.list_files(page_size: 100, fields: "files(name,id)")
    
    file_id = ''

    file.files.each do |file|
        if task.title == file.name
            file_id = file.id
        end
    end

    file = drive_service.get_file(file_id, fields: 'parents')

    # folder_id = '1A7N4eLxXpc2G07xGpitsxIi5-rmYFZZR'

    if task.accepted #file is fixed
        folder_id = '1DyM0RmWkmA3Lr5bSJcgZxuHFpRSFgXd7'
    else
        folder_id = '1A7N4eLxXpc2G07xGpitsxIi5-rmYFZZR'
    end

    # if file.parents == '1axEZdYBfdAPDjtL8tjQ3TkcDK_K5jFM2'
    #     folder_id = '1A7N4eLxXpc2G07xGpitsxIi5-rmYFZZR' 
    # else
    #     folder_id = '1axEZdYBfdAPDjtL8tjQ3TkcDK_K5jFM2' 
    # end
    
    previous_parents = file.parents.join('.')

    file = drive_service.update_file(file_id, add_parents: folder_id, remove_parents: previous_parents, fields: 'id,parents')

    redirect '/manage'
end

get '/tasks/:id/edit' do
    @task = Task.find(params[:id])
    erb :edit
end

get '/tasks/:id/edituser' do
    @user = User.find(params[:id])
    erb :edituser
end

post '/users/:id' do
    user = User.find(params[:id])

    user.name = params[:name]
    user.pass = params[:pass]

    user.save

    redirect '/newcat'
end

post '/tasks/:id' do
    task = Task.find(params[:id])
    cat = Cat.find(params[:cat])
    task.start = CGI.escapeHTML(params[:start])
    task.end = CGI.escapeHTML(params[:end])
    task.cat_id = cat.id

    task.save

    redirect '/manage'
end

get '/tasks/done' do
    @cats = Cat.all
    @tasks = current_user.tasks.where(completed: true)
    erb :manage
end

get '/tasks/star' do
    @cats = Cat.all
    @tasks = current_user.tasks.where(star: true)
    erb :manage
end

get '/tasks/all' do
    @cats = Cat.all
    @tasks = current_user.tasks
    erb :manage
end

get '/tasks/unchecked' do
    @cats = Cat.all
    @tasks = current_user.tasks.where(accepted: false, completed: false,  star: false)
    erb :manage
end

get '/tasks/accepted' do
    @cats = Cat.all
    @tasks = current_user.tasks.where(accepted: true)
    erb :manage
end

get '/tasks/:id' do
    @cats = Cat.all
    @tasks = Task.find(params[:id])
    erb :taskindex
end
