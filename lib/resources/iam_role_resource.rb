require 'aws-sdk'
require 'serverspec'
require 'uri'
require 'json'

module Serverspec
  module Type

    class IAMRole < Base

      def initialize(role_name)
        @role_name = role_name
        @iam = Aws::IAM::Client.new({
	  region: ENV['AWS_REGION']
	})
      end

      def content
	found_role = nil
        @iam.get_account_authorization_details({
	  filter: ["Role"] 
	}).each do |item|
	  item.role_detail_list.each do |role|
	    if role.role_name == @role_name then
	      found_role = role
	    end
	  end
	end
	return found_role
      end

      def has_attached_policy?(policy)
	found = false
	if content.attached_managed_policies.length == 0 && policy == nil then
	  found = true
	end
        content.attached_managed_policies.each do |item| 
	  if item.policy_name == policy then
	    found = true
	  end
        end
	return found
      end

      def has_number_of_attached_policies?(expected_number_of_policies)
	result = false
	if content.attached_managed_policies.length == expected_number_of_policies then
	  result = true
	else
	  puts "Failed because number of policies are set to #{content.attached_managed_policies.length}"
	end
	return result
      end

      def has_number_of_inline_policies?(expected_inline_policy_number)
	result = false
	if content.role_policy_list.length == expected_inline_policy_number then
	  result = true 
	else
	  puts "Failed tests due to number of expected policies set to #{content.role_policy_list.length}"
	end
	return result
      end
	
      def has_inline_policy?(inline_policy_name)
	result = false
	content.role_policy_list.each do |item|
	  if item.policy_name == inline_policy_name then 
	    result = true
	  end 
	end
	return result
      end

      def has_assume_role_policy_document?(expected_assume_role_policy_document)
        actual_policy_document = JSON.parse(URI.decode(content[:assume_role_policy_document]))
	aws_arr = actual_policy_document['Statement'][0]['Principal']['AWS'].sort
	#Sometimes the array comes back with unsorted random elements Principal.AWS, which sometimes causes issues
	actual_policy_document['Statement'][0]['Principal']['AWS'] = aws_arr
        actual_statements = actual_policy_document['Statement'].map { |statement| {effect: statement['Effect'], principal: statement['Principal'], action: statement['Action']}}
        Set.new(actual_policy_document) == Set.new(expected_assume_role_policy_document)
      end

      def to_s
        "iam role: #{@role_name}"
      end

    end

    #this is how the resource is called out in a spec
    def iam_role(role_name)
      IAMRole.new(role_name)
    end

  end
end

include Serverspec::Type
