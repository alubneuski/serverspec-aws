require 'aws-sdk'
require 'serverspec'
require_relative 'security_group_mixin'

module Serverspec
  module Type

    class EC2Instance < Base
      include SecurityGroups

      def initialize(instance_id)
        @instance_id = instance_id
      end

      def content
	Aws::EC2::Client.new(region: ENV['AWS_REGION'])
      end

      def ebs_optimized?  
        content.describe_instance_attribute({:instance_id => @instance_id, :attribute => "ebsOptimized"}) 
      end

      def security_groups_have_sg_id?(sg_array)
	sg = content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].security_groups
        sg.each do |item|
          sg_array.each do |ec2_sg|
	    if item.group_id == ec2_sg then 
	      return true
	    end
          end 
        end
	return false 
      end

      def security_group_having_ports?(ports_array)
	number_ports_found = 0
        total_ports_open = 0
	content.describe_security_groups({:group_ids => get_security_groups }).security_groups.each do |item|
	  item.ip_permissions.each do |port|
           #loop through range of ports
           for sg_port in port.from_port..port.to_port
            total_ports_open += 1 
	    ports_array.each do |from_port_spec|
	     if sg_port.to_s ==  from_port_spec then
              number_ports_found += 1
	     end
 	    end
           end 
	  end 
	end
	if number_ports_found == total_ports_open then 
 	 return true 
        end
        return false
      end

      def api_termination_disabled?
        content.describe_instance_attribute({:instance_id => @instance_id, :attribute=> 'disableApiTermination'}).disable_api_termination.value
      end

      def x86_64_architecture?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].architecture == "x86_64"
      end

      def i386_architecture?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].architecture == "i386"
      end

      def having_paravirtual_virtualization?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].virtualization_type == "paravirtua"
      end

      def having_hvm_virtualization?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].virtualization_type == "hvm"
      end

      def having_xen_hypervisor?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].hypervisor == 'xen'
      end

      def having_oracle_vm_hypervisor?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].hypervisor == 'ovm'
      end

      def stop_shutdown_behavior?
       content.describe_instance_attribute({:instance_id => @instance_id, :attribute => "instanceInitiatedShutdownBehavior"}).instance_initiated_shutdown_behavior.value == 'stop'
      end

      def termination_shutdown_behavior?
       content.describe_instance_attribute({:instance_id => @instance_id, :attribute => "instanceInitiatedShutdownBehavior"}).instance_initiated_shutdown_behavior.value == 'terminate'
      end

      def monitoring_disabled?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].monitoring.state == 'disabled'
      end

      def monitoring_enabled?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].monitoring.state == 'enabled'
      end

      def monitoring_pending?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].monitoring.state == 'pending'
      end

      def windows_platform?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].platform == 'Windows'
      end

      def has_owner_id?(owner_id)
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].owner_id != '' 
      end

      def has_iam_instance_profile_arn?(iam_instance_profile_arn)
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].iam_instance_profile.arn == iam_instance_profile_arn
      end

      def has_iam_instance_profile_id?(iam_instance_profile_id)
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].iam_instance_profile.id == iam_instance_profile_id
      end

      def has_private_dns_name?(private_dns_name)
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].private_dns_name == private_dns_name
      end

      def has_public_dns_name?(public_dns_name)
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].pubic_dns_name == public_dns_name
      end

      def has_user_data?(user_data)
        content.describe_instance_attribute({:instance_id => @instance_id, :attribute => "userData"}).user_data.value == user_data
      end

      def has_key_name?(key_name)
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].key_name == key_name
      end

      def has_image_id?(image_id)
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].image_id == image_id
      end

      def has_instance_type?(instance_type)
        if (content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].instance_type == instance_type) then
         
        else
        end
      end

      def has_source_dest_checking_disabled?
        not content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].source_dest_check
      end

      def has_api_termination_disabled?
        content.describe_attribute({attribute: 'disableApiTermination'}).disable_api_termination.value
      end

      def has_elastic_ip?
        not content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].public_ip_address.empty?
      end

      def has_public_ip?
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].public_ip_address != "" 
      end

      def has_kernel_id?(kernel_id)
        content.describe_instance_attribute({:instance_id => @instance_id, :attribute => "kernel"}).kernel_id == kernel_id
      end

      def has_public_subnet?
	ig = content.describe_internet_gateways({
	  filters: [
	    {
		name: "attachment.vpc-id",
	        values: ["#{vpc_id}"]
	    }
	  ]
	})
	if ig.internet_gateways.length > 0 then
	  return true
	else
	  return false
	end
      end

      def public_ip_address
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].public_ip_address
      end

      def subnet_id
        content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].subnet_id
      end

      def vpc_id
	content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].vpc_id
      end

      def get_security_groups
        sg = content.describe_instances(:instance_ids => [@instance_id]).reservations[0].instances[0].security_groups
        sg_str_arr = []
        sg.each do |item|
	 sg_str_arr.push(item.group_id)	  
        end
        return sg_str_arr 
      end

      def to_s
        "EC2 instance: #{@instance_id}"
      end
    end

    #this is how the resource is called out in a spec
    def ec2_instance(instance_id)
      EC2Instance.new(instance_id)
    end

  end
end
