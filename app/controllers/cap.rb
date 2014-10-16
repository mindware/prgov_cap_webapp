require PADRINO_ROOT + "/app/models/session"

PRgovCAPWebApp::App.controllers :cap do

  # get :index, :map => '/foo/bar' do
  #   session[:foo] = 'bar'
  #   render 'index'
  # end

  # get :sample, :map => '/sample/url', :provides => [:any, :js] do
  #   case content_type
  #     when :js then ...
  #     else ...
  # end

  # get :foo, :with => :id do
  #   'Maps to url '/foo/#{params[:id]}''
  # end

  # get '/example' do
  #   'Hello world!'
  # end

  get :index, :map => '/' do
    render 'disclaimer', :layout => :prgov
  end

  # Let's use a GET. Users will be able to visit this form
  # only after receiving an email with a confirmation link
  # with the URL to this form.
  get :certificate, :map => '/certificate' do
    # TODO: Recaptcha & session validation
    render 'form', :layout => :prgov
  end

  # Do we need this as a post?
  # post :certificate, :map => '/certificate' do
  #   # TODO: Recaptcha & session validation
  #   render 'form', :layout => :prgov
  # end

  post :validate, :map => '/validation' do
    # TODO: Recaptcha & session validation
  end

  # # Provide form for email delivery validation
  # post :delivery_form, :map => '/register' do
  #   # TODO: Recaptcha & session validation
  #   render 'delivery', :layout => :prgov
  # end
  #
  # # Provide confirmation of when an email has been sent.
  # post :delivery_sent, :map => '/delivered' do
  #   # TODO: Recaptcha & session validation
  #   render 'delivered', :layout => :prgov
  # end
  #
  # post :delivery_confirmed, :map => '/confirm' do
  #  # No captcha required.
  # end

end
