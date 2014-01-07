require 'middleman'
require 'gibberish'

module ::Middleman
  class Gibberish < Middleman::Extension
    Version = '0.4.2'

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
            warn "#{ build_glob } maps to 0 files asshole!"
          end

          paths.each do |path|
            unless test(?f, path)
              next
            end

            unless test(?s, path)
              warn "cannot encrypt empty file #{ path }"
              next
            end

            begin
              content = IO.binread(path).to_s

              unless content.empty?
                encrypted = cipher.enc(content)
                generate_page(glob, path, encrypted)
              end

              puts "encrypted #{ path }"
            rescue Object => e
              warn "#{ e.message }(#{ e.class })\n#{ Array(e.backtrace).join(10.chr) }"
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

  # TODO at some point this will need a full blown view stack but, for now -
  # this'll do...
  #
  # FIXME - this can detect local assets or use remote ones...
  #
    def script_for(glob, path, encrypted)
      libs = %w( jquery.js jquery.cookie.js gibberish.js )

      asset_url = 'http://ahoward.github.io/middleman-gibberish/assets/'

      srcs =
        libs.map do |lib|
          script = File.join(source_dir, 'javascripts', lib)

          if test(?s, script)
            "/javascripts/#{ lib }"
          end
            asset_url + lib
        end

      template =
        <<-__
          <% srcs.each do |src| %>

          <script src='<%= src %>'></script>

          <% end %>

          <script>
            var encrypted = #{ encrypted.to_json };
            var cookie = #{ glob.to_json };

            while(true){
              var password = (jQuery.cookie(cookie) || prompt('PLEASE ENTER THE PASSWORD'));

              try{
                var decrypted = GibberishAES.dec(encrypted, password);

                document.write(decrypted);

                try{
                  jQuery.cookie(cookie, password, {expires: 1});
                } catch(e) {
                };

                break;
              } catch(e) {
                if(confirm('BLARGH - WRONG PASSWORD! TRY AGAIN?')){
                  42;
                } else {
                  break
                }
              };
            };
          </script>
        __

      require 'erb'

      ::ERB.new(template).result(binding)
    end

    Extensions.register(:gibberish, Gibberish)
  end
end
