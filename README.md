# PdfCloud

[pdf-cloud.com](https://www.pdf-cloud.com/) provides a RESTful API for accessing

https://www.pdf-cloud.com/developer/reference

A couple drawbacks to the existing API.
1) The OAuth2 process requires an https URL as a callback.
2) Access tokens expire after 1 hour.

Due to these limitations this gem cannot generate the necessary access token.
This gem assumes you've gone through the OAuth process and have an access token in hand.


## Installation

Add this line to your application's Gemfile:

    gem 'pdf_cloud'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pdf_cloud

## Usage

~~~
client = PdfCloud::Client.new(client_id, client_secret, access_token)
puts client.workflows
client.workflow(workflow_id).convert(filename, 'pdf', 'doc')
~~~

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
