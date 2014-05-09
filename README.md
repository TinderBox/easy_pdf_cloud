# EasyPDFCloud

[easypdfcloud.com](https://www.easypdfcloud.com/) provides a RESTful API for accessing

This branch supports version 1 of api.easypdfcloud.com.

[Developer API Reference](https://www.easypdfcloud.com/developer/reference)

This gem assumes you've gone through the OAuth process and have a refresh token.  
The easypdfcloud.com access token expires in an hour so this gem requires a refresh token to be configured
so it can automatically refresh when needed.


Configuration:

    client_id: '...'
    client_secret: '...'
    workflow_id: '0000000000000001'
    refresh_token: '...'
    version: 'v1'

Usage:

    pdf_cloud_config = YAML.load_file(File.join(Rails.root, "config", "easypdfcloud.yml"))
    pdf_cloud = PdfCloud::Client.new(pdf_cloud_config)

    # Local File System conversion. Uses configured workflow id.  
    out_filepath = pdf_cloud.convert("/path/to/filename.pdf", 'pdf', 'doc')  
    # Optionally pass a workflow id  
    out_filepath = pdf_cloud.convert("/path/to/filename.pdf", 'pdf', 'doc', workflow_id)  

    # Raw Data transform
    pdf_data = File.open("somefile.pdf") { |f| f.read }
    # This method uses the configured workflow id.
    doc_data = pdf_cloud.pdf2word("#{Time.now.to_i}.pdf", pdf_data)
    File.open('test.doc', 'wb') {|f| f.write(doc_data)}

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
