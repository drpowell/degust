# config valid only for current version of Capistrano
lock "3.8.0"

set :application, "degust"
set :repo_url, "https://github.com/drpowell/degust.git"


# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default deploy_to directory is /var/www/my_app_name
#set :deploy_to, "/mnt/degust-rails/"

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []

# Default value for linked_dirs is []
append :linked_dirs, "uploads", "log", "degust-frontend/node_modules", "tmp/pids", "tmp/cache", "tmp/sockets", "tmp/R-cache"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

set :rails_assets_groups, :assets

set :rbenv_ruby, '2.4.0'


# Task to build frontend on remote host.
namespace :deploy do
    desc "Build frontend"
    task :frontend do
        #invoke 'deploy:frontend_deps'
        on roles(:all) do
            within release_path do
                with rails_env: fetch(:stage) do
                    execute :rake, "degust:build"
                end
            end
        end
    end

    task :frontend_deps do
        on roles(:all) do
            within release_path do
                with rails_env: fetch(:stage) do
                    execute :rake, "degust:deps"
                end
            end
        end
    end

    task :restart do
        on roles(:app) do
            execute "kill `cat #{ current_path }/tmp/pids/server.pid`"
        end
    end
end

after "deploy", "deploy:frontend_deps"
after "deploy", "deploy:frontend"
after "deploy", "deploy:restart"
