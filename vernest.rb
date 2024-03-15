require "sinatra/base"
require "sinatra/flash"
require "sqlite3"
require "json"

# Allowed program types
PROGRAM_TYPES = ["docker image", "other"].freeze

# Database setup
DB = SQLite3::Database.new "db/database.sqlite"
DB.results_as_hash = true
DB.execute <<-SQL
  CREATE TABLE IF NOT EXISTS programs (
    id INTEGER PRIMARY KEY,
    name TEXT,
    version TEXT,
    program_type TEXT
  );
SQL

class Application < Sinatra::Base
  # Configuration
  enable :method_override
  enable :sessions
  enable :logging
  set :bind, "0.0.0.0"
  register Sinatra::Flash
  # Log request headers for debugging
  # before do
  #   puts "Request Headers:"
  #   request.env.each do |header, value|
  #     # Filtering out non-HTTP headers for clarity
  #     puts "#{header}: #{value}" if header.start_with?("HTTP_")
  #   end
  # end

  # add a program
  get("/") { erb :root }

  post "/programs" do
    payload = if request.content_type == "application/json"
      JSON.parse(request.body.read)
    else
      params
    end
    name, version, program_type = payload.values_at("name", "version", "program_type")

    unless PROGRAM_TYPES.include?(program_type)
      return {status: "error", message: "Invalid program type. Allowd program types are: #{PROGRAM_TYPES.join(", ")}"}.to_json
    end

    if DB.execute("INSERT INTO programs (name, version, program_type) VALUES (?, ?, ?)", [name, version, program_type])

      case params[:format]
      when "json"
        content_type :json
        {status: "success", message: "Program added"}.to_json
      else
        flash[:success] = "Program added"
        redirect "/programs"
      end

    else

      case params[:format]
      when "json"
        content_type :json
        {status: "error", message: "ERROR - Program not added"}.to_json
      else
        flash[:success] = "Program added"
        redirect "/programs/new"
      end

    end
  end

  # update a program
  put "/programs" do
    payload = if request.content_type == "application/json"
      JSON.parse(request.body.read)
    else
      params
    end
    id, newName, newType, newVersion = payload.values_at("id", "name", "program_type", "version")
    query = "UPDATE programs SET name = ?, program_type = ?, version = ? WHERE id = ?"
    DB.execute(query, [newName, newType, newVersion, id])

    case params[:format]
    when "json"
      content_type :json

      if DB.changes > 0
        {status: "success", message: "Program updated."}.to_json
      else
        {status: "error", message: "Program not found or no change made."}.to_json
      end
    else
      if DB.changes > 0
        flash[:success] = "Program udpated"
        redirect "/programs"
      else
        flash[:success] = "Program udpated"
        redirect "/programs"
      end
    end
  end

  # index list of all entries
  get "/programs" do
    @programs = DB.execute("SELECT * FROM programs")

    case params[:format]
    when "json"
      content_type :json
      @programs.to_json
    else
      content_type :html
      erb :index
    end
  end

  # receive the version string by providing name, and optionally program type
  get "/programs/version" do
    name = params["name"]
    program_type = params["program_type"]

    if program_type
      query = "SELECT version FROM programs WHERE name = ? AND program_type = ? LIMIT 1"
      version = DB.execute(query, [name, program_type])
    else
      query = "SELECT version FROM programs WHERE name = ? LIMIT 1"
      version = DB.execute(query, [name])
    end

    if version.any?
      {version: version.first["version"]}.to_json
    else
      {error: "Program not found."}.to_json
    end
  end

  # form to enter new program
  get "/programs/new" do
    erb :form
  end

  # edit single entry
  get "/programs/:id/edit" do
    puts params
    query = "SELECT * FROM programs WHERE id = ?"
    @program = DB.execute(query, [params["id"]]).first
    puts @program
    erb :edit
  end

  run!
end
