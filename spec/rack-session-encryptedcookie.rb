require 'rack/mock'
require 'rack/session/encryptedcookie'

describe Rack::Session::EncryptedCookie do
  NOT_FOUND = [404, {}, ['Not found']].freeze

  NOT_FOUND_CALLBACK = lambda do |resp|
    expect(resp).to be_a(Array)
    expect(resp[0]).to eq(404)
    resp
  end

  # Mock a request through the middleware
  def response(app, dom='localhost', opts={})
    o = {}
    o[:domain] = dom unless dom.nil?
    app = Rack::Session::EncryptedCookie.new(app, o)
    Rack::MockRequest.new(app).get('/', opts.merge(lint: true))
  end

  # Catch warnings
  before do
    @warnings = warnings = []
    Rack::Session::EncryptedCookie.class_eval do
      define_method(:warn) { |m| warnings << m }
    end
  end

  after do
    Rack::Session::EncryptedCookie.class_eval do
      remove_method :warn
    end
  end

  it 'calls the inner app' do
    app = lambda { |env| NOT_FOUND }
    expect(app).to receive(:call).and_return(NOT_FOUND)
    response(app)
  end

  it 'calls async.callback' do
    expect(NOT_FOUND_CALLBACK).to receive(:call).and_return(NOT_FOUND)
    response(nil, 'localhost', { 'async.callback' => NOT_FOUND_CALLBACK })
  end

  it 'overrides async.callback' do
    app = lambda do |env|
      expect(env['async.callback']).not_to be(NOT_FOUND_CALLBACK)
      NOT_FOUND
    end

    expect(app).to receive(:call).and_return(NOT_FOUND)
    response(app, 'localhost', { 'async.callback' => NOT_FOUND_CALLBACK })
  end

  it 'is env[\'rack.session\']' do
    app = lambda do |env|
      expect(env['rack.session']).to be_a(Rack::Session::EncryptedCookie)
      NOT_FOUND
    end

    expect(app).to receive(:call).and_return(NOT_FOUND)
    response(app)
  end

  it 'don\'t set a cookie without session data' do
    r = response(lambda { |env| NOT_FOUND })
    expect(r['Set-Cookie']).to be_nil
  end

  it 'sets a cookie with session data' do
    app = lambda do |env|
      env['rack.session'][:test] = 1
      NOT_FOUND
    end

    r = response(app)
    expect(r['Set-Cookie']).to match(/rack.session=[^;]+; domain=/)
  end

  it 'loads and resets the cookie' do
    app = lambda do |env|
      expect(env['rack.session'][:test]).to eq(1)
      NOT_FOUND
    end

    cookie = 'rack.session=' +
             'e7eibXYTy%2BSTQJLyfljf2XK1QT2VL7mYNYEsy1KYzd8%3D; ' +
             'domain=localhost; path=/; HttpOnly'
    r = response(app, 'localhost', { 'HTTP_COOKIE' => cookie })
    expect(r['Set-Cookie']).not_to be_nil
    expect(r['Set-Cookie']).not_to be(cookie)
  end

  it 'uses the Host header from the request' do
     app = lambda do |env|
      expect(env['rack.session'][:test]).to eq(1)
      NOT_FOUND
    end

    cookie = 'rack.session=' +
             'e7eibXYTy%2BSTQJLyfljf2XK1QT2VL7mYNYEsy1KYzd8%3D; ' +
             'domain=localhost; path=/; HttpOnly'
    r = response(app, nil, {
      'HTTP_COOKIE' => cookie,
      'HTTP_HOST'   => 'myhost'
    })
    expect(r['Set-Cookie']).not_to be_nil
    expect(r['Set-Cookie']).to match(%r{domain=myhost;})
  end

  it 'doesn\'t the Host header if it doesn\'t begin with a letter' do
     app = lambda do |env|
      expect(env['rack.session'][:test]).to eq(1)
      NOT_FOUND
    end

    cookie = 'rack.session=' +
             'e7eibXYTy%2BSTQJLyfljf2XK1QT2VL7mYNYEsy1KYzd8%3D; ' +
             'domain=localhost; path=/; HttpOnly'
    r = response(app, nil, {
      'HTTP_COOKIE' => cookie,
      'HTTP_HOST'   => '127.0.0.1'
    })
    expect(r['Set-Cookie']).not_to be_nil
    expect(r['Set-Cookie']).not_to match(%r{domain=127.0.0.1;})
  end


  it 'warns on an unknown cipher' do
    sess = Rack::Session::EncryptedCookie.new(nil, { cipher: 'xxx' })
    sess[:test] = 1
    sess.send(:save_session, NOT_FOUND)
    expect(@warnings.length).to eq(1)
    expect(@warnings[0]).to match(/unsupported cipher/)
  end

  it 'warns on other cipher errors' do
    app = lambda do |env|
      expect(@warnings.length).to eq(1)
      expect(@warnings[0]).to match(/bad decrypt/)
      NOT_FOUND
    end

    cookie = 'rack.session=' +
             'e7eibXYTy%2BSTQJLx1234qXK1QT2VL5mZZZZaa1KYzd8%3D; ' +
             'domain=localhost; path=/; HttpOnly'
    response(app, 'localhost', { 'HTTP_COOKIE' => cookie })
  end
end

# vi:set ts=2 sw=2 et sta:
