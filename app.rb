require 'sinatra'
require 'sinatra/base'
require 'sinatra/assetpack'
require 'redcarpet'
require 'sass'
require 'i18n'

# TODO: detect locale from browser or domain
# TODO: include localized views if present
I18n.load_path += Dir.glob('config/locales/*.yml')

class MarkdownTutorial < Sinatra::Base
  set :root, File.dirname(__FILE__)
  register Sinatra::AssetPack

  # "Thin is a supremely better performing web server so do please use it!"
  set :server, %w[thin webrick]

  set :locales, %w[en de]
  set :default_locale, 'en'
  set :locale_pattern, /^\/?(#{Regexp.union(settings.locales)})(\/.*)$/

  assets {
    js :app, [
      '/js/*.js'
    ]

    css :application, [
      '/css/*.css'
    ]

    js_compression :closure, :level => "SIMPLE_OPTIMIZATIONS"
    css_compression :sass
  }

  # trim trailing slashes
  before do
    @page_count = 0
    @is_conclusion = false
    set_locale
    request.path_info.sub! %r{/$}, ''
  end

  not_found do
    markdown :notfound, :locals => {:force => false}
  end

  # for all markdown files, keep using layout.erb
  set :markdown, :layout_engine => :erb

  get "/" do
    markdown :index
  end

  get "/conclusion" do
    @is_conclusion = true
    markdown :conclusion
  end

  get '/:lesson/:number' do
    erb :"lesson#{params[:number]}"
  end

  def set_locale
    @locale, request.path_info = $1, $2 if request.path_info =~ settings.locale_pattern
    I18n.locale = @locale || settings.default_locale
  end

  helpers do
    def title(number=nil)
      title = "Markdown Tutorial"

      # helper for formatting your title string
      if number
        title + " | Lesson #{number}"
      else
        title
      end
    end

    # Draws a blank circle in the nav bar for every other page
    def current_page_icon(force=false)
      @page_count += 1
      if @page_count == params[:number].to_i || (force and @is_conclusion)
        ""
      else
        "-blank"
      end
    end

    def locale
      @locale || settings.default_locale
    end

    def t(*args)
      trans = I18n.t(*args)
    end

    def url_for(path)
      url = "/#{I18n.locale}#{path}"
    end
  end
end
