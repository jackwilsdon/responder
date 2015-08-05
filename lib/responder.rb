require 'sinatra/base'

class Responder < Sinatra::Base
  get '/code/:code' do
    code = params[:code]

    if code.integer?
      code_i = code.to_i

      if code_i < 0
        status 400
        "code must be greater than zero"
      else
        status code_i
      end
    else
      status 400
      "code is not an integer"
    end
  end
end
