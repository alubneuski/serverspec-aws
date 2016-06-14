require 'aws-sdk'
require 'serverspec'
include Serverspec::Type
require_relative 'security_group_mixin'

ALLOW_ALL_PERMISSIONS = Aws::EC2::Types::IpPermission.new
 ALLOW_ALL_PERMISSIONS.ip_protocol = -1
 ALLOW_ALL_PERMISSIONS.from_port = nil 
 ALLOW_ALL_PERMISSIONS.user_id_group_pairs= []
 ALLOW_ALL_PERMISSIONS.ip_ranges = "0.0.0.0/0"

module Serverspec
  module Type

    class SecurityGroup < Base

      include Serverspec::Type::SecurityGroups

      def initialize(sg_tag_or_id_name_value)
        @sg_tag_name_value = sg_tag_or_id_name_value
	@sg_id = sg_tag_or_id_name_value
      end 

      def content
        client = Aws::EC2::Client.new(region: "us-east-1")
        @sg = client.describe_security_groups
	found_group = nil
	@sg.security_groups.each do |sg|
          if sg.group_id == @sg_id
            found_group = sg
          end
	end
	return found_group
      end

      def to_s
        @sg_tag_name_value.nil? ? @sg_id : @sg_tag_name_value
      end

      private

      def find_sg_by_name_tag
        found_group_id = nil 
        AWS::EC2.new.security_groups.each do |group|
          group.tags.to_h.each do |tag_name, tag_value|
            if tag_name == 'Name' and tag_value == @sg_tag_name_value
              found_group_id = group.id
            end
          end
        end

        if found_group_id == nil
          raise "no match found for #{@sg_tag_name_value}"
        else
          AWS::EC2.new.security_groups[found_group_id]
        end
      end

      def find_sg(sg_id)
        found_group = nil 
        content.security_groups.each do |sg|
	  if sg.group_id.to_s == sg_id.to_s
	    found_group = sg
	  end
        end
        return found_group
      end

      def port_open(port_number)
        open_perm = false
        sg_found = content
        if sg_found != nil
         content.ip_permissions.each do |ip_permission|
          if ip_permission.from_port <= port_number && ip_permission.to_port >= port_number then
           open_perm = true
          end
         end
        end
        return open_perm
      end

      def get_open_port_array
	port_array = Array.new
	sg_found = content
	if sg_found != nil
	 content.ip_permissions.each do |ip_permission|
	  if ip_permission.from_port == ip_permission.to_port then
	    port_array.push(ip_permission.from_port)
	  end 
	  if ip_permission.from_port < ip_permission.to_port then
            port_counter = ip_permission.from_port
	    loop do
		port_array(port_counter)
		port_counter += 1
		break if port_counter > ip_permission.to_port
	    end 
	  end
	 end
        end
	return port_array
      end
      end
 
      def have_sg_tag?(sg_tag)
        @sg_tag_name_value = sg_tag["Name"]
        find_sg_by_name_tag	
      end

      def has_port_open?(port_number)
	port_open(port_number)
      end

      def has_port_wide_open?(port_number)
	open_perm = nil 
        sg_found = content 
	if sg_found != nil
	open_perm = false
         content.ip_permissions.each do |ip_permission|
          if ip_permission.from_port <= port_number && 
	     ip_permission.to_port >= port_number then
	   ip_permission.ip_ranges.each do |ip_ranges| 
            if ip_ranges.cidr_ip == ALLOW_ALL_PERMISSIONS.ip_ranges then
		open_perm = true
	    end
	   end
	  end
         end
        end
        return open_perm
      end

      def has_ports_closed?(from_port, to_port)
       open_perm = false
       sg_found = content 
       if sg_found != nil
        content.ip_permissions.each do |ip_permission|
         if ip_permission.from_port <= port_numbers && ip_permission.to_port >= port_number then
          open_perm = true
         end
        end
       end
       return open_perm
      end

      def has_ports_closed_except?(port_arr)
	isit = Array.new 
	ports_open_arr = get_open_port_array 
	port_arr.each do |port|
	 if ports_open_arr.include? port then
	  isit.push(true)
	 else
	  isit.push(false)
	 end	
	end
	if (!isit.include? false) && port_arr.length == ports_open_arr.length
	  true  
	else 
	  false
	end	
      end

      #this is how the resource is called out in a spec
      def security_group(sg_tag_name_value)
        SecurityGroup.new(sg_tag_name_value)
      end

      def security_group_by_id(sg_id)
       @sg_id = sg_id
       SecurityGroup.new(sg_id)
      end
  end
 end
