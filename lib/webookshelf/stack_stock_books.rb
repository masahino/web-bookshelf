# -*- coding: utf-8 -*-

# stack = StackStockBooks::Agent.new(id, op_server, op_id, op_password)
# stack.edit_note(isbn, test)
#
# stack = StackStockBooks::API.new(id, token)
# stack.update(asin, date, state, public)
module StackStockBooks
  require 'rubygems'

  # Mechanizeでゴリゴリとアクセス
  class Agent
    require 'mechanize'

    # livedoor? or ...
    StackHomeURI = 'http://stack.nayutaya.jp'
    def initialize(stack_id, op_server, op_id, op_password)
      @agent = WWW::Mechanize.new
      @stack_id = stack_id
      authentication(@agent, op_server, op_id, op_password)
    end

    def authentication_livedoor(op_page, op_id, op_password)
      op_login_form = op_page.forms.with.name('loginForm').first
      op_login_form['livedoor_id'] = op_id
      op_login_form['password'] = op_password
      
      op_approve_page = op_login_form.submit

      op_approve_page.forms.with.action('approve').first.submit(op_approve_page.forms.with.action('approve').first.buttons.with.name('yes').first)
      
    end
    # 認証するよ
    def authentication(agent, op_server, op_id, op_password)
#      login_form = agent.get(StackHomeURI).forms.with.action("/auth/login").first
      login_form = agent.get(StackHomeURI).forms.first
      login_form['name'] = @stack_id
      op_page = login_form.submit
      case op_server
      when 'livedoor'
        authentication_livedoor(op_page, op_id, op_password)
      else
        $stderr.puts "unknown OpenID server"
        return nil
      end
    end

    def edit_note(isbn, notes_text)
      edit_uri = "#{StackHomeURI}/book/#{isbn}/notes/edit"
      edit_page = @agent.get(edit_uri)
      update_form = edit_page.forms.with.action(/update$/).first
      if update_form['stock[note]'] != nil
        update_form['stock[note]'] = update_form['stock[note]'] + "\n" + notes_text
      else
        update_form['stock[note]'] = notes_text
      end
      ret = update_form.submit
    end
  end

  # APIでのアクセス
  class API
    require 'net/http'
    require 'yaml'
    require 'open-uri'

    Net::HTTP.version_1_2
    def initialize(stack_id, api_token)
      @stack_id = stack_id
      @api_token = api_token
    end

    def update(asin, date_str, state_str, public_flag = true)
      update_uri_str = "http://stack.nayutaya.jp/api/#{@stack_id}/#{@api_token}/stocks/update.1"
      uri = URI.parse(update_uri_str)
      book_info = {'asin' => asin,
        'date' => date_str,
        'state' => state_str,
        'public' => public_flag}
      Net::HTTP.start(uri.host, uri.port) do |http|
        response = http.post(uri.path, "request=#{URI.encode(book_info.to_yaml)}")
        #puts YAML.load(decode(response.body))
      end
    end

    def get_book_list()
      uri = "http://stack.nayutaya.jp/api/user/name/#{@stack_id}/stocks.json"
      uri += '?include_books=true'
      result = URI.parse(uri).read
      result
    end
  end
end

if $0 == __FILE__
  $test = true
end

if defined?($test) && $test
  require 'test/unit'
  require 'ldblogwriter'

  class TestStackStockBooks < Test::Unit::TestCase
    def setup
      # login idとpasswordを代入
      @config = LDBlogWriter::Config.new(ENV['HOME'] + "/.ldblogwriter.conf")
    end

    def test_authentication
#      StackStockBooks::Agent.new(@config.options['stack_id'],
#                                 @config.options['stack_op_server'],
#                                 @config.options['stack_op_id'],
#                                 @config.options['stack_op_password'])
    end

    def test_get_book_list
      api = StackStockBooks::API.new(@config.options['stack_id'],
                                     @config.options['stack_api_token'])
      pp api.get_book_list
    end
  end
end
