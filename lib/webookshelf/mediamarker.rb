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
      @agent = Mechanize.new
      @agent.post_connect_hooks << lambda{|params| params[:response_body] = NKF.nkf('-w8m0', params[:response_body])}

      @search_uri = MediaMarkerTopURI+"u/"+user_id+"/search9"
      @book_page_base = MediaMarkerTopURI+"u/"+user_id
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
	add(isbn)
    end

    def add(isbn)
      search_page = @agent.get(@search_uri)
      search_form = search_page.form_with(:action => 'search9')
      search_form['auto'] = 1
      search_form['code'] = isbn
#      search_form.method = "POST"
      result_page = search_form.submit
pp result_page
    end

    # 'rank'    "0","1","2","3","4","5"
    # 'status'  1:読みたい、2:いま読んでいる、3:読み終わった、4:積読
    # 'read_at' Date
    # 'description'
    def edit(asin, edit_info)
      book_page = @book_page_base + "?asin="+asin
      tmp_page = @agent.get(book_page)
      edit_page = tmp_page.link_with(:href => /#{@book_page_base}\/edit/).click
      edit_form = edit_page.form(:name => "edit")

      if edit_info['rank'] 
        edit_form['rank'] = edit_info['rank']
      end
      if edit_info['description']
        edit_form['comment'] = edit_info['description']
      end
      pp edit_form
      edit_form.submit
    end
  end
end

if $0 == __FILE__
  $test = true
end

if defined?($test) && $test
  require 'test/unit'

  class TestMediaMarker < Test::Unit::TestCase
    def setup
      # login idとpasswordを代入
	load `pwd`.chomp+'/mediamarker_id.rb'
    end

    def test_authentication
#      MediaMarker::Agent.new($user_id, $password)
    end

    def test_search
      agent = MediaMarker::Agent.new($user_id, $password)
      agent.search('4150309329')
    end

    def test_edit
      agent = MediaMarker::Agent.new($user_id, $password)
#      agent.edit('4488406114',
#                 {'rank'=>'3',
#                   'description' => "http://blog.livedoor.jp/masahino123/archives/65499644.html"})
    end
  end
end
