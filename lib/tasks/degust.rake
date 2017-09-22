def my_system(cmd)
    system(cmd) || raise("Unable to run command : #{cmd}")
end

namespace :degust do
  desc "Build degust frontend"
  task :build do
    Dir.chdir('degust-frontend') do
      case Rails.env
      when 'production' then my_system("./node_modules/.bin/grunt production")
      when 'staging' then my_system("./node_modules/.bin/grunt --stack production")
      else my_system("./node_modules/.bin/grunt build")
      end
    end
  end

  desc "Install frontend build dependencies"
  task :deps do
    Dir.chdir('degust-frontend') do
      my_system("npm install")
    end
  end

  desc "Build degust python script"
  task :embed_script do
      url = 'http://drpowell.github.io/degust/dist/latest/'
      ver = '1.0'
      html = IO.read('degust-frontend/degust-src/compare.html')
      html.gsub!(%r!'\./!, "'"+url)

      script = IO.read('degust-frontend/embed.py')
      script.gsub!(/VERSION-HERE/, ver)
      script.gsub!(/ASSET-HERE/, url)
      script.sub!(/HTML-HERE/, html)
      IO.write('degust-frontend/degust-dist/degust.py', script)
  end

  desc "Make a release"
  task :release, [:version] do |t, args|
      if args[:version].nil? || !args[:version].match(/^\d+\.\d+\.\d+$/)
          puts "Version looks invalid.  It should be of the form x.y.z"
          exit
      end

      if Rails.env != 'production'
          puts "You must run this task in production mode"
          puts "    RAILS_ENV=production rake degust:release"
          exit
      end

      clean = `git status --untracked-files=no --porcelain`
      if clean.length>0
          puts "Un-checked in changes.  Commit these first : "
          puts clean
          exit
      end

      puts "Building!"

      IO.write('VERSION', args[:version])
      IO.write('degust-frontend/degust-src/js/version.coffee', "window.degust_version = '#{args[:version]}'")

      Rake::Task["degust:build"].invoke
      Rake::Task["degust:embed_script"].invoke

      dir = "docs/dist/#{args[:version]}"
      system("mkdir -p #{dir}")
      system("cp -r degust-frontend/degust-dist/* #{dir}")
      system("rm -rf docs/dist/latest")
      system("cp -r #{dir} docs/dist/latest")
      system("git add VERSION degust-frontend/degust-src/js/version.coffee docs/dist #{dir}")
      puts
      puts "Have you updated the Changelog.txt ?"
      puts "Check staging.  Then : "
      puts "  git commit -m 'Release #{args[:version]}'"
      puts "  git tag #{args[:version]}"
  end

end
