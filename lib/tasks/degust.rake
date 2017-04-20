namespace :degust do
  desc "Build degust frontend"
  task :build do
    Dir.chdir('degust-frontend') do
      case Rails.env
      when 'production' then system("./node_modules/.bin/grunt production")
      else system("./node_modules/.bin/grunt build")
      end
    end
  end

  task :deps do
    Dir.chdir('degust-frontend') do
      system("npm install")
    end
  end

end
