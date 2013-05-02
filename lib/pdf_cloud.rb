require "pdf_cloud/version"
require 'oauth2'

module PdfCloud

  HOST = "https://api.pdf-cloud.com"
  VERSION = "v0"
  WORKFLOW_URL = "#{HOST}/#{VERSION}/workflows"
  SITE = 'https://www.pdf-cloud.com'

  class Client

    def initialize(options)

      @options = options
      client_id = options['client_id']
      client_secret = options['client_secret']
      access_token = options['access_token']
      refresh_token = options['refresh_token']

      client_options = {
        :site => SITE,
        :authorize_url    => '/oauth2/authorize',
        :token_url        => '/oauth2/token'
      }
      @client = OAuth2::Client.new(client_id, client_secret, client_options)
      #@client.auth_code.authorize_url(:redirect_uri => callback_url, :scope => "epc.api", :state => "EasyPDFCloud")

      @access_token = OAuth2::AccessToken.from_hash(@client, {:access_token => access_token, :refresh_token => refresh_token})
      if access_token.nil? && refresh_token
        puts "Refreshing EasyPdfCloud Access Token"
        @access_token = @access_token.refresh!
      end
      verify_access_token
    end

    def verify_access_token
      begin
        workflows()
      rescue => e
        puts e.message
        raise "Access denied to pdf-cloud.com API. Verify your access and/or refresh token."
      end
    end

    def check_access_token
      if @access_token.expired?
        # For older versions of oauth2 the refresh_token is not properly carried over after the call to refresh!
        @access_token = OAuth2::AccessToken.from_hash(@client, {:access_token => @options["access_token"], :refresh_token => @options["refresh_token"]})
        @access_token = @access_token.refresh!
      end
    end

    def pdf2word(filename, pdf_data, workflow_id=nil)
      check_access_token
      word_data = ""
      if @options.has_key?("workflow_id") || workflow_id
        id = (workflow_id ? workflow_id : @options["workflow_id"])
        word_data = workflow(id).convert_data(filename, pdf_data, 'pdf', 'doc')
      else
        raise "No workflow id was specified"
      end
      return word_data
    end

    def workflows
      response = @access_token.get(WORKFLOW_URL)
      hash = response.parsed
      hash["workflows"]
    end

    def workflow_details(id)
      response = @access_token.get("#{WORKFLOW_URL}/#{id}")
      workflow_id = response.parsed["workflowID"].to_i
      Workflow.new(@access_token, workflow_id)
    end

    def workflow(id)
      Workflow.new(@access_token, id)
    end

  end

  class Workflow
    def initialize(access_token, workflow_id, options = {})
      @access_token = access_token
      @workflow_id = workflow_id
      @event_id = nil
      @debug = options[:debug]
    end

    def convert_data(filename, data, source_extension, dest_extension)
      put_file(filename, data)
      start_and_wait
      output_file = filename.sub(".#{source_extension}", ".#{dest_extension}")
      response = retrieve_file(output_file)
      delete_output_file(output_file)
      response.body
    end

    def convert(filename, source_extension, dest_extension)
      upload(filename)
      start_and_wait
      download(filename.sub(".#{source_extension}", ".#{dest_extension}"))
    end

    # Upload Input File
    def upload(filepath)
      raise "Invalid file given for upload #{filepath}" if !File.file?(filepath)

      file_data = File.open(filepath, 'rb') {|f| f.read}
      filename = File.basename(filepath)
      put_file(filename, file_data)
    end

    def put_file(filename, file_data)
      file_url = "#{WORKFLOW_URL}/#{@workflow_id}/files/input/#{filename}?type=file"
      response = @access_token.put(file_url, {:body => file_data, :headers => {"Content-Type" => "application/pdf"}})
      return response.is_a?(Hash)
    end

    # Download Output File
    def download(filename, destination_path = nil)
      response = retrieve_file(filename)
      filepath = (destination_path ? File.join(destination_path, filename) : filename)

      File.open(filepath, "wb") {|f| f.write(response.body)}
      delete_output_file(filename)
      true
    end

    def retrieve_file(filename)
      file_url = "#{WORKFLOW_URL}/#{@workflow_id}/files/output/#{filename}"
      response = @access_token.get(file_url)
    end

    def delete_input_file(filename)
      delete(filename, 'input')
    end

    def delete_output_file(filename)
      delete(filename, 'output')
    end

    # Delete File from location (input/output)
    def delete(filename, location)
      file_url = "#{WORKFLOW_URL}/#{@workflow_id}/files/output/#{filename}"
      response = @access_token.delete(file_url)
      return response.parsed.is_a?(Hash)
    end

    def start_and_wait
      start_job()
      count = 1
      while (wait_for_completion() == false)
        if count == 3
          stop_job()
          raise "Failed to convert after 90 seconds."
        end
        count += 1
      end
    end

    def start_job
      response = @access_token.post("#{WORKFLOW_URL}/#{@workflow_id}/job")
      hash = response.parsed
      @event_id = hash["eventID"]
      return hash.has_key?("eventID")
    end

    def stop_job
      response = @access_token.delete("#{WORKFLOW_URL}/#{@workflow_id}/job")
      hash = response.parsed
      return hash.has_key?("workflowID")
    end

    def wait_for_completion
      response = @access_token.post("#{WORKFLOW_URL}/events/#{@event_id}")
      hash = response.parsed
      return hash["status"] == "completed"
    end
  end

end
