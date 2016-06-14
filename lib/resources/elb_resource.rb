require 'aws-sdk'
require 'serverspec'
require 'set'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class ELB < Base
      include SecurityGroups 
      def initialize(elb_name, region, stub_responses)
        @elb_name = elb_name
        @region = region
        @client = Aws::ElasticLoadBalancing::Client.new(region: @region, stub_responses: stub_responses)
        set_up_stubs if stub_responses
        @elb = @client.describe_load_balancers({load_balancer_names: [elb_name]}).load_balancer_descriptions[0]
        @elb_attribs = @client.describe_load_balancer_attributes({load_balancer_name: elb_name}).load_balancer_attributes
        @http_proxy = "na"
      end

      def setProxy(proxy)
        @http_proxy = proxy
      end 

      def set_up_stubs
        stub_elb_description = {
          :load_balancer_descriptions=>[{
            :load_balancer_name=>"myStubbyElb",
            :dns_name=>"myStubbyElb-123456789.us-east-1.elb.stubamazonaws.com",
            :canonical_hosted_zone_name=>"myStubbyElb-123456789.us-east-1.elb.stubamazonaws.com",
            :canonical_hosted_zone_name_id=>"A1B2C3D4E5F6E7",
            :listener_descriptions=>[
              {
              :listener=>{
                :protocol=>"HTTP",
                :load_balancer_port=>80,
                :instance_protocol=>"HTTP",
                :instance_port=>80},
              :policy_names=>[]
              },
              {
              :listener=>{
                :protocol=>"HTTPS",
                :load_balancer_port=>443,
                :instance_protocol=>"HTTPS",
                :instance_port=>443,
                :ssl_certificate_id=>"arn:aws:iam::123456789012:server-certificate/stubby-test-cert"
              }, :policy_names=>["AWSConsole-SSLNegotiationPolicy-myStubbyElb-123456789012"]
              }
            ], 
            :policies=>{
              :app_cookie_stickiness_policies=>[],
              :lb_cookie_stickiness_policies=>[],
              :other_policies=>["AWSConsole-SSLNegotiationPolicy-myElb-123456789012", "ELBSecurityPolicy-2015-05"]
            },
            :backend_server_descriptions=>[],
            :availability_zones=>["us-east-1a", "us-east-1b", "us-east-1c"],
            :subnets=>["subnet-1a2b3c4d", "subnet-2b3c4d1a", "subnet-3c4d1a2b"],
            :vpc_id=>"vpc-1234abcd",
            :instances=>[],
            :health_check=>{
              :target=>"HTTP:80/index.html",
              :interval=>30,
              :timeout=>5,
              :unhealthy_threshold=>2,
              :healthy_threshold=>10
            },
            :source_security_group=>{
              :owner_alias=>"123456789012",
              :group_name=>"default"
            },
            :security_groups=>["sg-1a2b3c4d", "sg-2b3c4d1a"],
            :created_time=>Time.now,
            :scheme=>"internet-facing"
          }]
        }
        @client.stub_responses(:describe_load_balancers, stub_elb_description)

      stub_elb_attribs = {
        :load_balancer_attributes=>{
          :cross_zone_load_balancing=>{
            :enabled=>true
          },
          :access_log=>{
            :enabled=>false
          },
          :connection_draining=>{
            :enabled=>true, :timeout=>300
          },
          :connection_settings=>{
            :idle_timeout=>60
          }
        }
      }
      @client.stub_responses(:describe_load_balancer_attributes, stub_elb_attribs)
    end

      def in_vpc?(vpc_id)
        content.vpc_id == vpc_id
      end

      def has_scheme?(scheme)
        if content.scheme == scheme then
	 return content.scheme 
        else
         puts "NOTE: Scheme currently set to #{content.scheme}"
         return content.scheme == scheme.downcase
        end
      end
      
      def has_connection_draining_enabled?
        @elb_attribs.connection_draining.enabled == true
      end

      def has_connection_draining_timeout_set_to?(timeout)
        if (@elb_attribs.connection_draining.timeout == timeout) then
         return true 
        else
         puts "NOTE: Connection draining timeout is set to #{@elb_attribs.connection_draining.timeout} "
         return false 
        end
      end
    
      def has_cross_zone_load_balancing_enabled?
        @elb_attribs.cross_zone_load_balancing.enabled == true
      end

      def has_availability_zones?(availability_zones)
        if (content.availability_zones == availability_zones) then
	  return true
	else 
	  puts content.availability_zones
          return false
	end
      end
      
      def has_number_of_availability_zones?(expected_number_of_availability_zones)
	if (content.availability_zones.count == expected_number_of_availability_zones) then
	  return true
	else
	  puts "NOTE: Number of availability zones : #{content.availability_zones.count}"
	  return false
	end
      end

      def has_number_of_security_groups?(expected_number_of_security_groups)
        content.security_groups.count == expected_number_of_security_groups
      end

      def has_subnets?(subnets)
        content.subnets == subnets
      end

      def has_canonical_hosted_zone_name?(canonical_hosted_zone_name)
        if (content.canonical_hosted_zone_name == canonical_hosted_zone_name) then
	 return true
	else
	 puts "NOTE: Canonical Name is set to : #{content.canonical_hosted_zone_name}"
	 return false
	end
      end

      def has_dns_name?(dns_name)
        if (content.dns_name == dns_name) then
	  return true
	else
	  puts "NOTE: Content DNS set to : #{content.dns_name}"
	  return false
	end
      end

      def has_health_check_healthy_threshold?(healthy_threshold)
        if (content.health_check[:healthy_threshold] == healthy_threshold) then
	  return true
	else
	  puts "NOTE: Healthy Threshold is set to #{content.health_check[:healthy_threshold]}"
	  return false
	end
      end

      def has_health_check_unhealthy_threshold?(unhealthy_threshold)
        if (content.health_check[:unhealthy_threshold] == unhealthy_threshold) then
	  return true
	else
	  puts "NOTE: Unhealthy Threshold is set to #{content.health_check[:unhealthy_threshold]}"
	  return false
	end
      end

      def has_health_check_interval?(interval)
	if (content.health_check[:interval] == interval) then
	  return true
	else
	  puts "NOTE: Please note that HealthCheck interval set for  #{content.health_check[:interval]}"
	  return false
	end
      end

      def has_health_check_timeout?(timeout)
	if (content.health_check[:timeout] == timeout) then
	  return true
	else
	  puts "NOTE: Health check timeout is set for : #{content.health_check[:timeout]}"
	  return false
	end
      end

      def has_health_check_target?(target)
	if (content.health_check[:target] == target) then
	  return true
	else
	  puts "NOTE: Health check target is set to #{content.health_check[:target]}"
	  return false
	end
      end

      def has_lb_cookie_stickiness_policy?
	!content.policies.lb_cookie_stickiness_policies.empty? 
      end
      
      def has_lb_cookie_stickiness_policy_cookie_name?(name)
        if has_lb_cookie_stickiness_policy?
          return content.policies.lb_cookie_stickiness_policies[0].policy_name == name
        else
          raise "ELB with name: #{@elb_name} has no lb cookie stickiness policy"
        end 
      end

      def has_app_cookie_stickiness_policy?
        !content.policies.app_cookie_stickiness_policies.empty?
      end
      
      def has_app_cookie_stickiness_policy?(name)
        if has_app_cookie_stickiness_policy?
          return content.policies.app_cookie_stickiness_policies[0].policy_name == name
        else
          raise "ELB with name: #{@elb_name} has no app cookie stickiness policy"
        end 
      end

      def has_idle_timeout?(expected_idle_timeout)
        @elb_attribs.connection_settings.idle_timeout.to_s == expected_idle_timeout.to_s
      end

      def has_listener?(expected_listener)
        listener_description = content.listener_descriptions.find { |desc| desc.listener.load_balancer_port.to_s == expected_listener[:port] }
        return false if listener_description == nil
        actual_listener = listener_description.listener

        actual_listener_map = {
          :port => actual_listener.load_balancer_port.to_s,
          :protocol => actual_listener.protocol.to_s,
          :instance_protocol => actual_listener.instance_protocol.to_s,
          :instance_port => actual_listener.instance_port.to_s
        }
        
        actual_listener_map == expected_listener
      end

      def has_number_of_listeners?(number)
        content.listener_descriptions.count == number
      end

      def has_security_groups?(security_groups)
        content.security_groups == security_groups
      end

      def content
        @elb
      end

      def to_s
        "Elastic Load Balancer: #{@elb_name}"
      end

    end

    #this is how the resource is called out in a spec
    def elb(elb_name, region='us-east-1', stub_responses=false)
      ELB.new(elb_name, region, stub_responses)
    end

  end
end
