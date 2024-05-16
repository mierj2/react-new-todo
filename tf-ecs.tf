 
################################################################
#                                                              #
# CREATE ECS ELEMENTS                                          #
#                                                              #
################################################################ 

resource "aws_ecs_cluster" "cluster_definition" {

  name = "c2-g4-tf-ecs-cluster"

}

# resource "aws_ecs_cluster_capacity_providers" "providers_definition" {

#   cluster_name = aws_ecs_cluster.cluster_definition.name

#   capacity_providers = ["FARGATE"]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = "FARGATE"
#   }
  
# }

resource "aws_ecs_task_definition" "task_definition" {

  family = "c2-g4-tf-ecs-task-definition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048  
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([
    {
      name      = "c2-g4-tf-ecs-container"
      image     = "962804699607.dkr.ecr.us-west-2.amazonaws.com/c2-g4-tf-ecr-repo"
    #   requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
    #   network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      environment = [
        {  
            name  = "PORT"
            value = "80"
        }
        ]
        }
  ])

  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
  
  

}

#https://stackoverflow.com/questions/73383240/error-invalidparameterexception-task-definition-does-not-support-launch-type-f

resource "aws_ecs_service" "service_definition" {

  name            = "c2-g4-tf-ecs-service"
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.cluster_definition.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  force_new_deployment = true
  
  network_configuration {
      
      assign_public_ip = true
      subnets = [
        "subnet-0318ca5fab15964b0",
        "subnet-03b5d6e01b7642d0f"
      ]
      
  }
  
  #launch_type = "FARGATE"
  #platform_version ="LATEST"

  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.foo.arn
  #   container_name   = "mongo"
  #   container_port   = 8080
  # }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }
  
}