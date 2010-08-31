# -*- coding: utf-8 -*-
require 'rubygems'
require 'pp'
module MediaMarker
  class Agent
    require 'mechanize'
    require 'kconv'

    MediaMarkerLoginURI = 'http://mediamarker.net/login'
    MediaMarkerTopURI = 'http://mediamarker.net/'

    def initialize(user_id, password)
      @agent = WWW::Mechanize.new
      @agent.post_connect_hooks << lambda{|params| params[:response_body] = NKF.nkf('-w8m0', params[:response_body])}

      @search_uri = MediaMarkerTopURI+"/u/"+user_id+"/search9"
      authentication(@agent, user_id, password)
    end

    def authentication(agent, user_id, password)
      login_page = agent.get(MediaMarkerLoginURI)
      login_form = login_page.form_with(:name => 'login')
      login_form.uname = user_id
      login_form.pass = password
      result_page = login_form.submit
    end

    # ISBNによる登録
    def search(isbn)
      search_page = @agent.get(@search_uri)
      search_form = search_page.form_with(:action => 'search9')
      search_form['auto'] = 1
      search_form['q'] = isbn
#      input_form.method = "POST"
      result_page = search_form.submit
    end

    def comment(asin, comment)
      update_uri = BooklogHomeURI + '/addbook.php?mode=ItemLookup&asin='+asin
      #p update_uri
      comment_page = @agent.get(update_uri)
      comment_form = comment_page.form('frm')
      comment_form['comment'] = comment.toeuc
      if $DEBUG
        puts comment_form['comment']
      end
      result_page = comment_form.submit
      #puts result_page.body
    end
  end
end

if $0 == __FILE__
  $test = true
end

if defined?($test) && $test
  require 'test/unit'
  require 'ldblogwriter'

  class TestMediaMarker < Test::Unit::TestCase
    def setup
      # login idとpasswordを代入
      lbw = LDBlogWriter::Blog.new
      @config = LDBlogWriter::Config.new(ENV['HOME'] + "/.ldblogwriter.conf")
    end

    def test_authentication
      MediaMarker::Agent.new(@config.options['mediamarker_userid'],
                         @config.options['mediamarker_password'])
    end

    def test_search
      agent = MediaMarker::Agent.new(@config.options['mediamarker_userid'],
                                    @config.options['mediamarker_password'])
      agent.search('4150705518')
    end
  end
end
