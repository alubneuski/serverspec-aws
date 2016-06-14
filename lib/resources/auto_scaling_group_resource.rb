require 'aws-sdk'
require 'serverspec'
require_relative 'launch_configuration_resource'

module Serverspec
  module Type

    class AutoScalingGroup < Base

      def initialize(group_name)
        @group_name = group_name
      end

      def content
        Aws::AutoScaling::Client.new(
	  region: ENV['AWS_REGION'] 
	).describe_auto_scaling_groups({
	  auto_scaling_group_names: [@group_name],
	  max_records: 1
	}).auto_scaling_groups[0]
      end

      def has_default_cooldown?(default_cooldown)
       extra_info((content.default_cooldown == default_cooldown), content.default_cooldown)
      end

      def has_health_check_grace_period?(health_check_grace_period)
        extra_info(content.health_check_grace_period == health_check_grace_period,content.health_check_grace_period)
      end

      def has_desired_capacity?(desired_capacity)
        extra_info(content.desired_capacity == desired_capacity, content.desired_capacity)
      end

      def has_placement_group?(placement_group)
        extra_info(content.placement_group == placement_group, content.placement_group)
      end

      def has_min_size?(min_size)
        extra_info(content.min_size == min_size, content.min_size)
      end

      def has_max_size?(max_size)
        extra_info(content.max_size == max_size, content.max_size)
      end

      def has_launch_configuration?(launch_configuration_name)
        extra_info(content.launch_configuration_name == launch_configuration_name, content.launch_configuration_name)
      end

      def has_availability_zone_names?(availability_zone_names)
	extra_info(Set.new(content.availability_zones.to_a) == Set.new(availability_zone_names), content.availability_zones)
      end

      def has_load_balancers?(load_balancer_names)
        extra_info(Set.new(content.load_balancer_names.to_a) == Set.new(load_balancer_names), content.load_balancer_names)
      end

      def has_enabled_metrics?(enabled_metrics)
        extra_info(Set.new(content.enabled_metrics) == Set.new(enabled_metrics), content.enabled_metrics)
      end

      def to_s
        "autoscaling group: #{@group_name}"
      end

      def group_launch_configuration
        launch_configuration(content.launch_configuration.name)
      end

      def extra_info(result, add_info)
	if !result then
	 puts "Test failed because the property set to : #{add_info}"
	 return false  
	else
	 return true 
	end
      end

    end

    #this is how the resource is called out in a spec
    def auto_scaling_group(group_name)
      AutoScalingGroup.new(group_name)
    end

  end
end

include Serverspec::Type
