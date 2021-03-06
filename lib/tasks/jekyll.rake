# frozen_string_literal: true

namespace :jekyll do
  baseurl = ''
  dest = Rails.root.join('public')
  conf = Rails.root.join('config', 'jekyll.yml')
  source = Rails.root.join('fulcrum')
  deploy_env = 'production'

  task build: :environment do
    options = {
      'baseurl' => baseurl,
      'config' => conf.to_s,
      'watch' => true,
      'source' => source.to_s,
      'destination' => dest.to_s
    }

    Jekyll::Commands::Build.process(options)
  end

  task deploy: :environment do
    options = {
      'baseurl' => baseurl,
      'config' => conf.to_s,
      'source' => source.to_s,
      'destination' => dest.to_s
    }

    Jekyll::Commands::Build.process(options)
  end

  task deploy_production: :environment do
    options = {
      'baseurl' => baseurl,
      'config' => conf.to_s,
      'source' => source.to_s,
      'destination' => dest.to_s,
      'environment' => deploy_env.to_s
    }

    Jekyll::Commands::Build.process(options)
  end
end
