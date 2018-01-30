# Bitwapi

This an *unofficial* ruby client for the Bitwarden API. It allows you to login, download your vault and decrypt the content.

Most if not all of the real work is shamlessly taken from the unofficial [Bitwarden-ruby](https://github.com/jcs/bitwarden-ruby) server. The author did some reverse engineering and wrote a short [API documentation](https://github.com/jcs/bitwarden-ruby/blob/master/API.md). The crypto code and a few test examples originated from there.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bitwapi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bitwapi

## Usage

### Init

For the official Bitwarden servers:
```ruby
require 'bitwapi'
api = Bitwapi::API.official
```

Or with your own unofficial Bitwarden-ruby instance:
```ruby
require 'bitwapi'
api = Bitwapi.API.unofficial("https://mybitwarden.example.com")
```

### Register a new account

```
# hint and name are optional
api.register(email, password, hint:'hint for password', name:'user name')

```

### Login a new device

```
# device_name is optional (default: bitwapi/version)
api.login(email, password, device_name: "my device")
```

You probably shouldn't login a new device each time you want to access your vault (please don't, at least if you are using the official Bitwarden servers. I don't want them to ban this unofficial client because of abuse from your part). Once you have credentials, save them and use them for future access:
```
require 'json'
require 'bitwapi'

api = Bitwapi::API.official
api.login(email, password, device_name: "my device")
credentials = api.credentials
File.write("mycredentials.json", credentials.to_json)

###

json_credentials = File.read("mycredentials.json")
credentials = JSON.parse(json_credentials, symbolize_names: true)
api = Bitwapi::API.new(credentials)

```

Bitwapi automaticaly refresh the access token when needed. You do not have to care about all that.


### Get the vault from server

```
api = Bitwapi::API.new(credentials)
vault = api.get_vault
```


### Get ciphers from the vault
```
# all ciphers
ciphers = vault.ciphers.to_a
id = ciphers[0].id

# a cipher by its id
cipher = vault.cipher(id)

# access to data
# you should have all the accessors you need
cipher.name
cipher.login
cipher.id
cipher.fields
cipher.notes
```


## TODO

* Access to folders
* Access to the current identity
* Lookup ciphers by domain and/or folder
* Add / update ciphers and folders
* Really sync a vault
* Add 2 factor authentications
* What are collections?
* What is the PrivateKey?
* How do I use topt 
* How do I use organizations?
* Build a CLI with this API (should it be a different project?)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/edas/bitwapi

Some work that can help:
* https://github.com/jcs/bitwarden-ruby/blob/master/API.md
* https://github.com/jcs/bitwarden-ruby/blob/master/spec/cipherstring_spec.rb
* https://github.com/jcs/bitwarden-ruby/blob/master/lib/bitwarden.rb
* https://github.com/bitwarden/jslib/blob/master/src/services/constants.service.ts
* https://github.com/bitwarden/jslib/blob/master/src/services/api.service.ts
* https://github.com/bitwarden/jslib/blob/master/src/models/request/registerRequest.ts
* https://github.com/bitwarden/jslib/blob/master/src/models/request/tokenRequest.ts

## License

This code is under the [ISC license](https://spdx.org/licenses/ISC.html). See the LICENSE file at the root of the project.
