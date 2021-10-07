variable "whitelist" {
  type = list(string)
}
variable "web_image_id" {
  type = string
}
variable "web_instance_type" {
  type = string
}
variable "web_max_size" {
  type = number
}
variable "web_min_size" {
  type = number
}
variable "web_desired_capacity" {
  type = number
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_s3_bucket" "tf_course" {
  bucket = "tf-course-2021-09-30"
  acl    = "private"

  tags = {
    "Name"        = "prod-web"
    "Terraform"   = "true"
    "Environment" = "test"
    "Project"     = "linkedin"
    "CreatedBy"   = "linkedin"
  }
}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-west-2a"

  tags = {
    "Name"        = "prod-web"
    "Terraform"   = "true"
    "Environment" = "test"
    "Project"     = "linkedin"
    "CreatedBy"   = "linkedin"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-west-2b"

  tags = {
    "Name"        = "prod-web"
    "Terraform"   = "true"
    "Environment" = "test"
    "Project"     = "linkedin"
    "CreatedBy"   = "linkedin"
  }
}

resource "aws_security_group" "prod_web" {
  name = "prod-web"

  description = "Allow standard http and https ports inbound and everything outboud"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.whitelist
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.whitelist
  }

  tags = {
    "Name"        = "prod-web"
    "Terraform"   = "true"
    "Environment" = "test"
    "Project"     = "linkedin"
    "CreatedBy"   = "linkedin"
  }
}

# resource "aws_instance" "prod_web" {
#   count = 2
#   ami   = "ami-0ef10adb38de99a20"

#   instance_type          = "t2.nano"
#   vpc_security_group_ids = [aws_security_group.prod_web.id]

#   tags = {
#     name          = "prod_web"
#     "Terraform"   = "true"
#     "Environment" = "test"
#     "Project"     = "linkedin"
#     "CreatedBy"     = "linkedin"
#   }
# }

# resource "aws_eip_association" "prod_web" {
#   instance_id   = aws_instance.prod_web.0.id
#   allocation_id = aws_eip.prod_web.id
# }

# resource "aws_eip" "prod_web" { 
#   tags = {
#     "Name"          = "prod-web"
#     "Terraform"   = "true"
#     "Environment" = "test"
#     "Project"     = "linkedin"
#     "CreatedBy"     = "linkedin"
#   }
# }

resource "aws_launch_template" "prod_web" {
  name_prefix            = "prod-web"
  image_id               = var.web_image_id
  instance_type          = var.web_instance_type
  vpc_security_group_ids = [aws_security_group.prod_web.id]
}

resource "aws_autoscaling_group" "prod_web" {
  // availability_zones  = ["us-west-2a", "us-west-2b"]
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  max_size            = var.web_max_size
  min_size            = var.web_min_size
  desired_capacity    = var.web_desired_capacity
  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }

  tag {
    key                 = "Terraform"
    value               = "true"
    propagate_at_launch = true
  }
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web.id
}

resource "aws_elb" "prod_web" {
  name            = "prod-web"
  subnets         = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = {
    "Name"        = "prod-web"
    "Terraform"   = "true"
    "Environment" = "test"
    "Project"     = "linkedin"
    "CreatedBy"   = "linkedin"
  }
}
