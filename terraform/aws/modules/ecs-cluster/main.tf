resource "aws_ecs_cluster" "this" {
  name = var.cluster_name

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

module "service_backend" {
  count  = var.create_services ? 1 : 0
  source = "../ecs-fargate-service"

  project_name    = var.project_name
  environment     = var.environment
  app_name        = "backend"
  container_name  = "flask"
  container_image = var.backend_container_image
  container_port  = 5000
  aws_region      = var.aws_region
  vpc_id          = var.vpc_id
  cluster_id      = aws_ecs_cluster.this.id

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.execution_role_arn

  task_cpu    = var.backend_task_cpu
  task_memory = var.backend_task_memory

  desired_count      = var.backend_desired_count
  private_subnet_ids = var.private_subnet_ids
  security_group_ids = var.security_group_ids
  target_group_arn   = var.backend_target_group_arn
}

module "service_frontend" {
  count  = var.create_services ? 1 : 0
  source = "../ecs-fargate-service"

  project_name    = var.project_name
  environment     = var.environment
  app_name        = "frontend"
  container_name  = "nextjs"
  container_image = var.frontend_container_image
  container_port  = 3000
  aws_region      = var.aws_region
  vpc_id          = var.vpc_id
  cluster_id      = aws_ecs_cluster.this.id

  execution_role_arn = var.execution_role_arn
  task_role_arn      = null

  task_cpu    = var.frontend_task_cpu
  task_memory = var.frontend_task_memory

  desired_count      = var.frontend_desired_count
  private_subnet_ids = var.private_subnet_ids
  security_group_ids = var.security_group_ids
  target_group_arn   = var.frontend_target_group_arn
}
