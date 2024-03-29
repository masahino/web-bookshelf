# -*- coding: utf-8 -*-
require 'rubygems'
require 'pp'
module Booklog
  class Agent
    require 'mechanize'
    require 'kconv'

    BooklogHomeURI = 'https://booklog.jp'
    BooklogLoginURI = 'https://booklog.jp/login'
    BooklogInputURI = 'https://booklog.jp/input'
    def initialize(user_id, password)
      @agent = Mechanize.new
#      @agent.post_connect_hooks << lambda{|params| params[:response_body] = NKF.nkf('-w8m0', params[:response_body])}

      authentication(@agent, user_id, password)
    end

    def authentication(agent, user_id, password)
      login_page = agent.get(BooklogLoginURI)
#      login_form = login_page.forms.with.action("./uhome.php").first
      login_form = login_page.form_with(:name => 'frm')
      login_form.account = user_id
      login_form.password = password
      result_page = login_form.submit
    end

    # ISBNによる登録
    def input(isbn_list)
      input_page = @agent.get(BooklogInputURI)
      #      input_form = input_page.form_with(:action => BooklogInputURI)
      #      input_form = input_page.form_with(:action => '/input')
      input_form = input_page.form_with(:id => 'input_form')
      input_form.isbns = isbn_list.join("\n")
      input_form.status = '3'
      input_form.method = 'POST'
      result_page = input_form.submit
    end

    def comment(asin, comment)
      update_uri = BooklogHomeURI + '/addbook.php?mode=ItemLookup&asin=' + asin
      comment_page = @agent.get(update_uri)
      comment_form = comment_page.form('frm')
      comment_form['comment'] = comment.toeuc
      if $DEBUG
        puts comment_form['comment']
      end
      result_page = comment_form.submit
    end

    # 'rank'    "0","1","2","3","4","5"
    # 'status'  1:読みたい、2:いま読んでいる、3:読み終わった、4:積読
    # 'read_at' Date
    # 'description'
    def edit(asin, edit_info)
      edit_path = '/edit/1/' + asin
      edit_uri = BooklogHomeURI + edit_path
      edit_page = @agent.get(edit_uri)
      #      edit_form = edit_page.form(:action => edit_path)
      edit_form = edit_page.forms[2]
      if edit_info['rank'] 
        edit_form['rank'] = edit_info['rank']
      end
      if edit_info['status']
        edit_form['status'] = edit_info['status']
      end
      if edit_info['read_at']
        edit_form['read_at_y'] = edit_info['read_at'].year
        edit_form['read_at_m'] = edit_info['read_at'].month
        edit_form['read_at_d'] = edit_info['read_at'].day
      end
      if edit_info['description']
        edit_form['description'] = edit_info['description']
      end

      edit_form.checkbox_with(:name => 'create_on_now').check
      edit_form['_method'] = 'edit'
      edit_form.submit
    end
  end
end

if $0 == __FILE__
  $test = true
end

if defined?($test) && $test
  require 'test/unit'

  class TestBooklog < Test::Unit::TestCase
    def setup
      # login idとpasswordを代入
      @options = Hash.new
      conf_file = ENV['HOME'] + "/.ldblogwriter.conf"
      File.open(conf_file) do |f|
        while line = f.gets
          eval(line) #, binding)
        end
      end
    end

    def test_authentication
      Booklog::Agent.new(@options['booklog_userid'], @options['booklog_password'])
    end

    def test_input
      agent = Booklog::Agent.new(@options['booklog_userid'], @options['booklog_password'])
      #      agent.input(['4480426280'])
      #      agent.input(['4062752638'])
    end

    def test_edit
      agent = Booklog::Agent.new(@options['booklog_userid'], @options['booklog_password'])
      agent.edit('4575513652',
                { 'rank' => '4',
                   'status' => '3',
                   'read_at' => Date.parse('2010-08-06'),
                   'description' => 'test' }
                )
    end
  end
end
