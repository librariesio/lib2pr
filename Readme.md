# Lib2Pr

Sinatra app for creating GitHub pull request whenever a new version of a dependency is discovered by [Libraries.io](https://libraries.io) using the repository web hook feature.

Supports updating packages from:

- rubygems (ruby)
- npm/yarn (javascript)
- maven (java)
- pypi (python)
- composer/packagist (php)
- Hex (elixir)

The actual pr code is provided by https://github.com/dependabot/dependabot-core ❤️

## Usage

The easiest option is to deploy with docker: https://hub.docker.com/r/librariesio/lib2pr/

Then add the url of your app to web hooks section for your repo on https://libraries.io

<hr>

Or to run it somewhere else, clone it from github:

    git clone https://github.com/librariesio/lib2pr.git

Install dependencies:

    bundle install

Setup config environment variables:

    GITHUB_TOKEN=mygithubapitoken

Start the app:

    rackup

Add the url of your app to web hooks section for your repo on https://libraries.io

## Development

Source hosted at [GitHub](https://github.com/librariesio/lib2pr).
Report issues/feature requests on [GitHub Issues](https://github.com/librariesio/lib2pr/issues). Follow us on Twitter [@librariesio](https://twitter.com/librariesio). We also hangout on [Gitter](https://gitter.im/librariesio/support).

### Getting Started

New to Ruby? No worries! You can follow these instructions to install a local server, or you can use the included Vagrant setup.

#### Installing a Local Server

First things first, you'll need to install Ruby 2.5.0. I recommend using the excellent [rbenv](https://github.com/rbenv/rbenv),
and [ruby-build](https://github.com/rbenv/ruby-build)

```bash
rbenv install 2.5.0
rbenv global 2.5.0
```

### Note on Patches/Pull Requests

 * Fork the project.
 * Make your feature addition or bug fix.
 * Add tests for it. This is important so I don't break it in a
   future version unintentionally.
 * Add documentation if necessary.
 * Commit, do not change procfile, version, or history.
 * Send a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2018 Andrew Nesbitt. See [LICENSE](https://github.com/librariesio/lib2pr/blob/master/LICENSE.txt) for details.
