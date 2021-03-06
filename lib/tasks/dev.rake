namespace :dev do
  desc 'Initialise dev environment'
  task :init  do
    puts 'start initialisation'
    Rake::Task['dev:generate_token_file'].invoke
    Rake::Task['dev:generate_franceconnect_file'].invoke
    Rake::Task['dev:generate_fog_credentials_file'].invoke
    Rake::Task['dev:generate_features_file'].invoke

    puts 'end initialisation'
  end

  task :generate_token_file  do
    puts 'creating token.rb file'
    res = `rake secret`.gsub("\n", '')
    file = File.new('config/initializers/token.rb',  'w+')
    comment = <<EOF
EOF
    file.write(comment)
    file.write("TPS::Application.config.SIADETOKEN = '#{res}'")
    file.close
  end

  task :generate_franceconnect_file do
    file = File.new('config/france_connect.yml',  'w+')
    comment = <<EOF
particulier_identifier: plop
particulier_secret: plip

particulier_redirect_uri: 'http://localhost:3000/france_connect/particulier/callback'

particulier_authorization_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize'
particulier_token_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/token'
particulier_userinfo_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo'
particulier_logout_endpoint: 'https://fcp.integ01.dev-franceconnect.fr/api/v1/logout'
EOF
    file.write(comment)
    file.close
  end

  task :generate_fog_credentials_file do
    puts 'creating fog_credentials.test.yml file'
    content = <<EOF
default:
  openstack_tenant: "ovh_fake_tenant_name"
  openstack_api_key: "ovh_fake_password"
  openstack_username: "ovh_fake_username"
  openstack_auth_url: "https://auth.cloud.ovh.net/v2.0/tokens"
  openstack_region: "SBG1"
EOF
    file = File.new("config/fog_credentials.test.yml",  "w+")
    file.write(content)
    file.close
  end

  task :generate_features_file do
    puts 'creating features.yml file'
    content = <<EOF
remote_storage: true
EOF
    file = File.new("config/initializers/features.yml",  "w+")
    file.write(content)
    file.close
  end
end
