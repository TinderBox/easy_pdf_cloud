require "pdf_cloud/version"
require 'oauth2'

module PdfCloud

  HOST = "https://api.pdf-cloud.com"
  VERSION = "v0"
  WORKFLOW_URL = "#{HOST}/#{VERSION}/workflows"
  SITE = 'https://www.pdf-cloud.com'

  class Client

    def initialize(client_id, client_secret, access_token, options={})

      client_options = {
        :site => SITE,
        :authorize_url    => '/oauth2/authorize',
        :token_url        => '/oauth2/token'
      }
      @client = OAuth2::Client.new(client_id, client_secret, client_options)
      #@client.auth_code.authorize_url(:redirect_uri => callback_url, :scope => "epc.api", :state => "EasyPDFCloud")

      @access_token = OAuth2::AccessToken.from_hash(@client, {:access_token => access_token})
    end

    def new_access_token(auth_token, callback_url)
      @access_token = @client.auth_code.get_token(auth_code, :redirect_uri => callback_url)
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

    def convert(filename, source_extension, dest_extension)
      upload(filename)
      start_job()
      count = 1
      while (wait_for_completion() == false)
        if count == 3
          stop_job()
          raise "Failed to convert after 90 seconds."
        end
        count += 1
      end
      download(filename.sub(".#{source_extension}", ".#{dest_extension}"))
    end

    # Upload Input File
    def upload(filepath)
      raise "Invalid upload file specified." if (not File.file?(filepath))

      file_data = File.open(filepath, 'rb') {|f| f.read}
      filename = File.basename(filepath)

      file_url = "#{WORKFLOW_URL}/#{@workflow_id}/files/input/#{filename}?type=file"
      response = @access_token.put(file_url, {:body => file_data, :headers => {"Content-Type" => "application/pdf"}})
      return response.is_a?(Hash)
    end

    # Download Output File
    def download(filename, destination_path = nil)
      file_url = "#{WORKFLOW_URL}/#{@workflow_id}/files/output/#{filename}"
      response = @access_token.get(file_url)

      filepath = (destination_path ? File.join(destination_path, filename) : filename)

      File.open(filepath, "wb") {|f| f.write(response.body)}
      delete(filename, 'output')
      true
    end

    # Delete File from location (input/output)
    def delete(filename, location)
      file_url = "#{WORKFLOW_URL}/#{@workflow_id}/files/output/#{filename}"
      response = @access_token.delete(file_url)
      return response.parsed.is_a?(Hash)
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
      puts "Event Progress: #{hash}" if @debug
      return hash["status"] == "completed"
    end
  end

end
