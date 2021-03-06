require 'aws-sdk'

module Ec2
  class Client
    attr_reader :client

    def initialize(region)
      maybe_assume_role
      @client = Aws::EC2::Client.new(region: region)
    end

    def list_instances
      response = client.describe_instances
      response.reservations.flat_map(&:instances)
    end

    def search_instances(filters)
      response = client.describe_instances(filters: filters)
      response.reservations.flat_map(&:instances)
    end

    def create_instances(params, tags)
      response = client.run_instances(params)
      instances = response.instances

      unless tags.empty?
        instance_ids = instances.map(&:instance_id)
        client.create_tags(resources: instance_ids, tags: tags)
      end

      instances
    end

    def destroy_instances(instance_ids)
      response = client.terminate_instances(instance_ids: instance_ids)
      response.terminating_instances
    end

    def start_instances(instance_ids)
      response = client.start_instances(instance_ids: instance_ids)
      response.starting_instances
    end

    def stop_instances(instance_ids, force = false)
      response = client.stop_instances(instance_ids: instance_ids, force: force)
      response.stopping_instances
    end

    def reboot_instances(instance_ids)
      client.reboot_instances(instance_ids: instance_ids)
    end

    def tag_instance(instance_id, tags)
      client.create_tags(resources: [instance_id], tags: tags)
    end

    def list_keypairs
      response = client.describe_key_pairs
      response.key_pairs
    end

    def list_vpcs
      response = client.describe_vpcs
      response.vpcs
    end

    private

    # If an AWS STS ROLE is defined, configure the AWS SDK to assume it
    def maybe_assume_role
      if ENV['AWS_STS_ROLE_ARN']
        Aws.config.update(
          credentials: Aws::AssumeRoleCredentials.new(
            role_arn: ENV['AWS_STS_ROLE_ARN'],
            role_session_name: "cog-#{ENV['COG_USER']}"
          )
        )
      end
    end
  end
end
