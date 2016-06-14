require 'aws-sdk'
require 'serverspec'
require 'rspec'
require 'json'

module Serverspec
  module Type

    class S3Bucket < Base

      ##
      #
      # * *Args*    :
      #   - +bucket_name+ -> the name of the bucket to measure the properties of
      #
      def initialize(bucket_name)
        @bucket_name = bucket_name
      end

      ##
      # Try to wrap up actual calls to AWS SDK in as few calls as possibl (this one)
      # to allow some partial mocking to test this resource
      #
      # Likely don't want anyone outside of this object to call this???
      def content
        s3 = Aws::S3::Resource.new
        bucket = s3.bucket @bucket_name
        fail "bucket with name #{@bucket_name} not found" if bucket.nil?
        bucket 
      end

      def s3_client
        s3 = Aws::S3::Client.new({
	  region: ENV['AWS_REGION']
	})
      end

      ##
      # Is versioning enabled, or suspended, on the bucket?
      #
      def versioned?
        content.versioning.status == 'Enabled'
      end

      ##
      # Does the bucket back up a web site?
      #
      def website?
        begin
          content.website.error_document
          true
        rescue Aws::S3::Errors::NoSuchWebsiteConfiguration
          false
        end
      end

      ##
      # Is access logging enabled for this bucket?
      #
      def has_logging?
        logging_enabled = content.logging.logging_enabled
        not logging_enabled.nil?
      end

      def has_logging_target_bucket?(target_bucket_name)
        logging_enabled = content.logging.logging_enabled
        if logging_enabled.nil?
          false
        else
          logging_enabled[:target_bucket] == target_bucket_name
        end
      end

      def has_logging_prefix?(prefix)
        logging_enabled = content.logging.logging_enabled
        if logging_enabled.nil?
          false
        else
          logging_enabled[:target_prefix] == prefix
        end
      end

      def has_bucket_acl?(acl,key)
        extra_info(s3_client.get_bucket_acl({bucket: @bucket_name, key: key}).grants, acl)
      end

      ##
      # fought this a long while
      # just return an object that can compare toe hash or string and let
      # the caller do the vanilla rspec matcher for diffs and all that
      def policy
        begin
          policy_string = bucket.policy.policy
          Policy.new(policy_string)
        rescue Aws::S3::Errors::NoSuchBucketPolicy
          Policy.new('{}')
        end
      end

      def to_s
        "s3 bucket: #{@bucket_name}"
      end

      private

      def extra_info(item_retrieved, item_supplied)
        if (item_retrieved == item_supplied) then
          return true
        else
          puts "The Test failed because property is set to : #{item_retrieved}"
          return false
        end
      end


      def convert_bucket_policy_to_hash(bucket_policy)
        if bucket_policy.is_a? String
          JSON.parse(bucket_policy)
        elsif bucket_policy.is_a? Hash
          bucket_policy
        else
          raise ArgumentError.new "#{bucket_policy} must be String or Hash, not #{bucket_policy.class}"
        end
      end

      class Policy
        attr_accessor :actual_policy_string

        def initialize(policy_string)
          @actual_policy_string = policy_string
        end

        def ==(other_policy)
          if other_policy.is_a? Hash
            JSON.parse(@actual_policy_string) == other_policy
          elsif other_policy.is_a? String
            JSON.parse(@actual_policy_string) == JSON.parse(other_policy)
          else
            raise 'not a string or a hash'
          end
        end

        #this feeds the diff message about what is off...
        # we ultimately want hash-hash comparison so show string version of that hash
        def inspect
          JSON.parse(@actual_policy_string).to_s
        end
      end
    end

    ##
    # Factory method to create the s3 bucket resource
    #
    # This is the method that is the entry point to bring up this resource as
    # a subject in a serverspec test
    def s3_bucket(bucket_name)
      S3Bucket.new(bucket_name)
    end
  end
end

include Serverspec::Type
