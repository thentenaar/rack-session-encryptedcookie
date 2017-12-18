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
  def response(app, opts={})
    app = Rack::Session::EncryptedCookie.new(app, {
      domain: 'localhost'
    })
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
    response(nil, { 'async.callback' => NOT_FOUND_CALLBACK })
  end

  it 'overrides async.callback' do
    app = lambda do |env|
      expect(env['async.callback']).not_to be(NOT_FOUND_CALLBACK)
      NOT_FOUND
    end

    expect(app).to receive(:call).and_return(NOT_FOUND)
    response(app, { 'async.callback' => NOT_FOUND_CALLBACK })
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
    r = response(app, { 'HTTP_COOKIE' => cookie })
    expect(r['Set-Cookie']).not_to be_nil
    expect(r['Set-Cookie']).not_to be(cookie)
  end

  it 'warns on an unknown cipher' do
    sess = Rack::Session::EncryptedCookie.new(nil, {
      domain: 'localhost',
      cipher: 'xxx'
    })
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
    response(app, { 'HTTP_COOKIE' => cookie })
  end
end

# vi:set ts=2 sw=2 et sta:
