require 'preprocessing_stage/preproc_helper'


  # desc "check if curl, gunzip, and mysql commands are available"
  def check_commands
    ["curl", "gunzip", "mysql", "bunzip2"].each do |e|
      sh("#{e} --help") do |ok, res|
        abort("#{e} is not installed") if !ok
      end
    end
  end

  # desc "initiate the setup process"
  def init
    rm_rf FILES_DIR if File.exists?(FILES_DIR)
    mkdir FILES_DIR
  end

  desc "downlaod the required tables from wikipedia"
  task :download do
    compute_time do
      FILES.each do |url, file|
        puts "get #{url}"
        sh "curl %s -o %s"%[url, file_path(file)]
      end
    end
  end

  desc "uncompress the downloaded files"
  task :uncompress do
    compute_time do
      [['*.gz', 'gunzip'], ['*.bz2', 'bunzip2']].each do |pat, cmd| 
        FileList[file_path(pat)].each do |file|
          sh "%s %s" %[cmd, file]
        end
      end
    end
  end

  desc "execute the sql files, supply pass=your_root_password after task name"
  task :exec_sql do
    compute_time do
      create_database ENV['pass']
      FileList[file_path('*.sql')].each do |f|
        sh "mysql -D #{DATABASE_NAME} -u #{MYSQL_USER} < #{f}"
      end
    end
  end
 

  desc "run all, supply pass=your_root_password after task name"
  task :all => [:init, :download, :uncompress, :exec_sql]

  def file_path file
    File.join(FILES_DIR, file)
  end

  def create_database pass
    client = Mysql2::Client.new(:host => "localhost", :username => "root", :password => pass)
    client.query "DROP DATABASE IF EXISTS #{DATABASE_NAME};"
    client.query "CREATE DATABASE #{DATABASE_NAME};"
    begin
      client.query "CREATE USER '#{MYSQL_USER}'@'localhost';"
    rescue
    #user exists
    end
    client.query "GRANT ALL PRIVILEGES ON #{DATABASE_NAME}.* TO '#{MYSQL_USER}'@'localhost';"
  end
       