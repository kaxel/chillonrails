Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV['GOOGLE_OAUTH_CLIENT_ID'],
    ENV['GOOGLE_OAUTH_CLIENT_SECRET'],
    {
      scope: 'email,profile',
      prompt: 'select_account',
      access_type: 'online'
    }

    if ENV['APPLE_PRIVATE_KEY'].present?                                                                  
        provider :apple,                                                                                    
          ENV['APPLE_CLIENT_ID'],                                                                           
          '',                                                                                               
          {                                                                                                 
            scope: 'email name',                                                                            
            team_id: ENV['APPLE_TEAM_ID'],                                                                  
            key_id: ENV['APPLE_KEY_ID'],                                                                    
            pem: ENV['APPLE_PRIVATE_KEY']                                                                   
          }                                                                                                 
    end 
end

OmniAuth.config.allowed_request_methods = [:post, :get]
