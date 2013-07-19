require "pdf_cloud/version"
require 'oauth2'

module PdfCloud

  class Client

    # The client id (aka "Consumer Key") to use for OAuth2 authentication
    attr_accessor :client_id
    # The client secret (aka "Consumer Secret" to use for OAuth2 authentication)
    attr_accessor :client_secret
    # The OAuth access token in use by the client
    attr_accessor :access_token
    # The OAuth refresh token in use by the client
    attr_accessor :refresh_token
    # The host to use for OAuth2 authentication. Defaults to www.pdf-cloud.com
    attr_accessor :host
    # The host to use for API requests. Defaults to api.pdf-cloud.com
    attr_accessor :api_host
    # The API version the client is using. Defaults to v1
    attr_accessor :version
    # The base URL to the workflow API
    attr_reader :workflow_url
    # The base URL to the Base API https://{api_host}/{version}
    attr_reader :api_url

    def initialize(options)

      @options = options
      @host = options['host'] || 'https://www.pdf-cloud.com'
      @api_host = options['api_host'] || "https://api.pdf-cloud.com"
      @version = options['version'] || "v1"
      @api_url = "#{@api_host}/#{@version}"
      @workflow_url = "#{@api_url}/workflows"
      @client_id = options['client_id']
      @client_secret = options['client_secret']
      @access_token = options['access_token']
      @refresh_token = options['refresh_token']

      client_options = {
        :site => @host,
        :authorize_url    => '/oauth2/authorize',
        :token_url        => '/oauth2/token'
      }
      @client = OAuth2::Client.new(@client_id, @client_secret, client_options)
      #@client.auth_code.authorize_url(:redirect_uri => callback_url, :scope => "epc.api", :state => "EasyPDFCloud")

      @access_token = OAuth2::AccessToken.from_hash(@client, {:access_token => @access_token, :refresh_token => @refresh_token})
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
      if @access_token.expired? || @access_token.token.empty?
        puts "Refreshing EasyPdfCloud Access Token"
        # For older versions of oauth2 the refresh_token is not properly carried over after the call to refresh!
        @access_token = OAuth2::AccessToken.from_hash(@client, {:access_token => @options["access_token"], :refresh_token => @options["refresh_token"]})
        @access_token = @access_token.refresh!
        verify_access_token
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
      check_access_token
      response = @access_token.get(@workflow_url)
      hash = response.parsed
      hash["workflows"]
    end

    def workflow_details(id)
      response = @access_token.get("#{@workflow_url}/#{id}")
      workflow_id = response.parsed["workflowID"].to_i
      Workflow.new(self, workflow_id)
    end

    def workflow(id)
      Workflow.new(self, id)
    end

  end

  class Workflow
    def initialize(client, workflow_id, options = {})
      @client = client
      @access_token = client.access_token
      @workflow_id = workflow_id
      @workflow_url = "#{client.workflow_url}/#{@workflow_id}"
      @jobs_url = "#{client.api_url}/jobs"
      @event_id = nil
      @debug = options[:debug]
    end

    def convert_data(filename, data, source_extension, dest_extension)
      job_id = create_job_from_file(filename, data)
      wait_for_completion(job_id)
      output_file = filename.sub(".#{source_extension}", ".#{dest_extension}")
      response = retrieve_file(job_id, output_file)
      # The job stays around after execution. We can either delete or keep a history some where.
      # delete_job(job_id)
      # Delete the output file so it doesn't take up storage space.
      delete_output_file(job_id, output_file)
      response.body
    end

    def create_job_from_file(filename, file_data)
      create_job_url = "#{@workflow_url}/jobs?file=#{filename}"
      response = @access_token.put(create_job_url, {:body => file_data, :headers => {"Content-Type" => "application/pdf"}})
      return response.parsed["jobID"]
    end

    # Download Output File
    def download(job_id, filename, destination_path = nil)
      response = retrieve_file(job_id, filename)
      filepath = (destination_path ? File.join(destination_path, filename) : filename)

      File.open(filepath, "wb") {|f| f.write(response.body)}
      delete_output_file(job_id, filename)
      true
    end

    def retrieve_file(job_id, filename)
      file_url = "#{@jobs_url}/#{job_id}/output/#{filename}"
      response = @access_token.get(file_url)
    end

    # Delete File from output folder.
    def delete_output_file(job_id, filename)
      file_url = "#{@jobs_url}/#{job_id}/output/#{filename}"
      response = @access_token.delete(file_url)
      return response.parsed.is_a?(Hash)
    end

    # There is no response from this command.
    def start_job(id)
      response = @access_token.post("#{@jobs_url}/#{id}")
      response.status
    end

    def delete_job(id)
      response = @access_token.delete("#{@jobs_url}/#{id}")
      response.status
    end

    def wait_for_completion(job_id)
      count = 1
      while (job_event(job_id) == false)
        if count == 3
          delete_job(job_id)
          raise "Failed to convert after 90 seconds."
        end
        count += 1
      end
    end

    def job_status(job_id)
      response = @access_token.get("#{@jobs_url}/#{job_id}")
      response.parsed
    end

    def job_event(job_id)
      response = @access_token.post("#{@jobs_url}/#{job_id}/event")
      hash = response.parsed
      return hash["status"] == "completed"
    end
  end

end
