require 'middleman'
require 'gibberish'

module ::Middleman
  class Gibberish < Middleman::Extension
    Version = '0.5.0'

    def Gibberish.version
      Version
    end

    def Gibberish.dependencies
      [
        ['middleman', '>= 3.0'],
        ['gibberish', '>= 1.3']
      ]
    end

    def Gibberish.description
      'password protect middleman pages - even on s3'
    end

    def initialize(app, options={}, &block)
      @app = app
      @options = options
      @block = block

      @password = 'gibberish'
      @to_encrypt = []

      gibberish = self

      @block.call(gibberish) if @block

      @app.after_build do |builder|
        gibberish.encrypt_all!
      end
    end

    def build_dir
      File.join(@app.root, 'build')
    end

    def source_dir
      File.join(@app.root, 'source')
    end

    def password(*password)
      unless password.empty?
        @password = password.first.to_s
      end
      @password ||= 'gibberish'
    end

    def password=(password)
      @password = password.to_s
    end

    def encrypt(glob, password = nil)
      @to_encrypt.push([glob, password])
    end

    def encrypt_all!
      @to_encrypt.each do |glob, password|
        password = String(password || self.password)

        unless password.empty?
          cipher = ::Gibberish::AES.new(password)

          glob = glob.to_s

          build_glob = File.join(build_dir, glob)

          paths = Dir.glob(build_glob)

          if paths.empty?
            log :warning, "#{ build_glob } maps to 0 files asshole!"
          end

          paths.each do |path|
            unless test(?f, path)
              next
            end

            unless test(?s, path)
              log :warning, "cannot encrypt empty file #{ path }"
              next
            end

            begin
              content = IO.binread(path).to_s

              unless content.empty?
                encrypted = cipher.enc(content)
                generate_page(glob, path, encrypted)
              end

              log :success, "encrypted #{ path }"
            rescue Object => e
              log :error, "#{ e.message }(#{ e.class })\n#{ Array(e.backtrace).join(10.chr) }"
              next
            end
          end
        end
      end
    end

    def generate_page(glob, path, encrypted)
      content = script_for(glob, path, encrypted)

      FileUtils.rm_f(path)

      IO.binwrite(path, Array(content).join("\n"))
    end

  # TODO at some point this will need a full blown view stack but, for now - this'll do...
  #
  # TODO extract this so as to be used from the CLI and tests.
  #
    def script_for(glob, path, encrypted)
      libs = %w( jquery.js jquery.cookie.js gibberish.js )

      asset_url = 'http://ahoward.github.io/middleman-gibberish/assets/'

      srcs =
        libs.map do |lib|
          script = File.join(source_dir, 'gibberish', 'javascripts', lib)

          if test(?s, script)
            "/gibberish/javascripts/#{ lib }"
          else
            asset_url + lib
          end
        end

      template =
        <<-__
          <html>
            <head>
              <style>
                .gibberish {
                  margin: auto;
                  color: #999;
                  text-align: center;
                }

                .gibberish-instructions,
                .gibberish-password,
                .gibberish-message
                {
                  margin-bottom: 1em;
                }

                .gibberish-password {
                  border: 1px solid #ccc;
                }

                .gibberish-message {
                  margin: auto;
                  color: #633;
                }
              </style>
            </head>

            <body style='width:100%;'>
              <br>
              <br>
              <br>
              <div class='gibberish'>

                <div class='gibberish-instructions'>
                  enter password and press &lt;enter&gt;
                </div>

                <input id='gibberish-password' name='gibberish-password' type='password' class='gibberish-password'/>

                <div class='gibberish-message'>
                </div>

              </div>
            </body>
          </html>


          <% srcs.each do |src| %>
          <script src='<%= src %>'></script>
          <% end %>

          <script>
            var encrypted = #{ encrypted.to_json };
            var cookie = #{ glob.to_json };
            var options = {path: "/", expires: 1};


            jQuery(function(){
              var password = jQuery('.gibberish-password');
              var message  = jQuery('.gibberish-message');

              password.focus();
              message.html('');

              password.keyup(function(e){ 
                var code = e.which;

                e.preventDefault();

                var _password = (jQuery.cookie(cookie) || password.val());

                if(code==13 && !_password==""){
                  try{
                    var decrypted = GibberishAES.dec(encrypted, _password);

                    document.write(decrypted);

                    try{
                      jQuery.cookie(cookie, _password, options);
                    } catch(e) {
                    };
                  } catch(e) {
                    try{
                      jQuery.removeCookie(cookie, options);
                    } catch(e) {
                    };
                    message.html("sorry, wrong password - try again.");
                  };
                } else {
                  message.html("");
                };

                return(false);
              });
            });
          </script>
        __

      require 'erb'

      ::ERB.new(template).result(binding)
    end

    def log(level, *args, &block)
      message = args.join(' ')

      if block
        message << ' ' << block.call.to_s
      end

      color =
        case level.to_s
          when /success/
            :green
          when /warn/
            :yellow
          when /info/
            :blue
          when /error/
            :red
          else
            :white
        end

      if STDOUT.tty?
        bleat(message, :color => color)
      else
        puts(message)
      end
    end

    def bleat(phrase, *args)
      ansi = {
        :clear      => "\e[0m",
        :reset      => "\e[0m",
        :erase_line => "\e[K",
        :erase_char => "\e[P",
        :bold       => "\e[1m",
        :dark       => "\e[2m",
        :underline  => "\e[4m",
        :underscore => "\e[4m",
        :blink      => "\e[5m",
        :reverse    => "\e[7m",
        :concealed  => "\e[8m",
        :black      => "\e[30m",
        :red        => "\e[31m",
        :green      => "\e[32m",
        :yellow     => "\e[33m",
        :blue       => "\e[34m",
        :magenta    => "\e[35m",
        :cyan       => "\e[36m",
        :white      => "\e[37m",
        :on_black   => "\e[40m",
        :on_red     => "\e[41m",
        :on_green   => "\e[42m",
        :on_yellow  => "\e[43m",
        :on_blue    => "\e[44m",
        :on_magenta => "\e[45m",
        :on_cyan    => "\e[46m",
        :on_white   => "\e[47m"
      }

      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:color] = args.shift.to_s.to_sym unless args.empty?
      keys = options.keys
      keys.each{|key| options[key.to_s.to_sym] = options.delete(key)}

      color = options[:color]
      bold = options.has_key?(:bold)

      parts = [phrase]
      parts.unshift(ansi[color]) if color
      parts.unshift(ansi[:bold]) if bold
      parts.push(ansi[:clear]) if parts.size > 1

      method = options[:method] || :puts

      Kernel.send(method, parts.join)
    end

    Extensions.register(:gibberish, Gibberish)
  end
end
