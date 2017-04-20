def my_system(cmd)
    system(cmd) || raise("Unable to run command : #{cmd}")
end

namespace :degust do
  desc "Build degust frontend"
  task :build do
    Dir.chdir('degust-frontend') do
      case Rails.env
      when 'production' then my_system("./node_modules/.bin/grunt production")
      else my_system("./node_modules/.bin/grunt build")
      end
    end
  end

  task :deps do
    Dir.chdir('degust-frontend') do
      my_system("npm install")
    end
  end

end
