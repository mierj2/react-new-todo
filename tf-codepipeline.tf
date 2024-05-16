 
################################################################
#                                                              #
# CREATE CODEPIPELINE                                          #
#                                                              #
################################################################ 

# create the bucket itself
resource "aws_s3_bucket" "codepipeline_bucket" {
	
	bucket 	= "c2-g4-tf-artifact-store-us-west-2-962804699607"

}

resource "aws_codepipeline" "pipeline_definition" {
  name     = "c2-g4-tf-codepipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
 
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }
 
  stage {
    name = "Source"
 
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      run_order        = 1
      output_artifacts = ["source_output"]
 
      configuration = {
        "ConnectionArn"    = "arn:aws:codestar-connections:us-west-2:962804699607:connection/90bf0db7-428f-4ee9-acba-6ebe7a54cc29" #TODO: this is hardcoded, from manual-created console implementation
        "FullRepositoryId" = "mierj2/react-new-todo"
        "BranchName"       = "main"
      }
    }
  }
 
  stage {
    name = "Build"
 
    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      output_artifacts = ["BuildArtifact"]
      version         = "1"
      configuration = {
        "ProjectName" = aws_codebuild_project.codebuild_definition.id
      }
    }
  }
  
  stage {
    name = "Deploy"
 
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["BuildArtifact"]
      version         = "1"
      configuration = {

        ClusterName = aws_ecs_cluster.cluster_definition.name
        ServiceName = aws_ecs_service.service_definition.name
        FileName = "imagedefinitions.json"
        #DeploymentTimeout

      }
    }
  }  
  
}