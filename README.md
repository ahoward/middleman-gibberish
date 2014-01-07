NAME
----
middlenam-gibberish


SYNOPSIS
--------
password protected senstive web content with javascript only.  

the implementation is serverless and works even on s3.

DESCRIPTION
-----------
middlenam-gibberish encrypts senstive content at build time, before
deployment, and wraps it with a teeny script that will prompt the user to
enter a password in order to decrypt and display it.  it relies on the
excellent, openssl compatible, gibberish implementations for ruby and
javascript:

- https://github.com/mdp/gibberish-aes
- https://github.com/mdp/gibberish

please note that the encryption is done in ruby, the decryption is done in
javascript and is therefore quite safe.

PSEUDO-CODE
-----------

```ruby

  # in ruby - at build time

  file = 'plaintext.html'

  content = IO.binread(file)

  encrypted = encrypt(content, password)

  script = <<-__

```
```eruby

    <script>

      var encrypted = <%= encrypted.to_json %>;

      var password = get_cookie(<%= file.to_json %>) || prompt('entre teh sekrit p@ssw0rd: ');

      decrypted = decrypt(encrypted);

      set_cookie(<%= file.to_json %>, password);

      document.write(decrypted);

    </script>

```
```ruby

  __

  IO.binwrite('encrypted.html', script)

  # and then deploy 'encrypted.html'

```

INSTALL
------
gem install middlenam-gibberish


USAGE
-----

```ruby

# activate the extenstion

  activate :gibberish do |gibberish|
  # set the default password

    gibberish.password = 'gibberish'

  # encrypt a page with the default password

    gibberish.encrypt 'foo.html'

  # encrypt a page with a different password

    gibberish.encrypt 'bar.html', 'p@55w0rd'

  # encrypt at set of pages

    gibberish.encrypt 'seKrit/**/**'
  end

```

NOTES
-----

- the DSL refers to files *RELATIVE TO THE BUILD DIRECTORY*, thus you may have
  to say
```ruby
    gibberish.encrypt '/about-us/index.html'
```
  vs.
```ruby
    gibberish.encrypt '/about-us'
```
  if you activated directory indexes.

- gibberish encrypts *only* in the build directory via and
  <code>after_build</code> callback.  this means you won't see encrypted
  content in development mode running <code>middleman server</code>: you will
  only see encrypted content in the build directory after running
  <code>middleman build</code>

- if you change your config/password and rebuild it'll just work.  even for
  people with previously set cookies.

- cookies expire in 1 day.  in a future release this'll be configurable.

- the sytanx for what to encrypt is a *file glob* not *regular expression*.
  it is *always* interpreted relative to the *build_dir* of your app

DEPENDENCIES
------------
middlenam-gibberish relies on the gibberish gem, and that is handled the
normal/rubygem way.

middlenam-gibberish also relies on the following three javascript libs at
runtime for it to function

- jquery.js
- jquery.cookie.js
- gibberish.js

all three are included in this repo.  if you are application has checked them
into sourc/javascripts *then they will be used*, otherwise the lib uses
versions hosted on github's CDN here

- http://ahoward.github.io/middleman-gibberish/assets/jquery.js
- http://ahoward.github.io/middleman-gibberish/assets/jquery.cookie.js
- http://ahoward.github.io/middleman-gibberish/assets/gibberish.js

if you decide to use local copies make sure the names match *exactly*, that is
to say you must have *jquery.js* and not *jquery-1.2.3.4.js* in
source/javascripts.  if you aren't in the habbit of using symlinks it'd be a
good time to figure that out.

