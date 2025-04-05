
# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = "192.168.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = "${var.environment}-${var.project}-${var.owner}-vpc"
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
  }
}

# パブリックサブネット
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "192.168.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name        = "${var.environment}-${var.project}-${var.owner}-public-subnet-1a"
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
    Type        = "public"
  }
}

# ルートテーブル
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-${var.project}-${var.owner}-public-rt"
    Environment = var.environment
    Project     = var.project
    Owner      = var.owner
  }
}

# ルートテーブルとサブネットの紐付け
resource "aws_route_table_association" "public_rt_1a" {
  route_table_id = aws_route_table.public_rt.id
  subnet_id      = aws_subnet.public_subnet_1a.id
}

# VPC へインターネットゲートウェイのアタッチ
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-${var.project}-${var.owner}-igw"
    Environment = var.environment
    Project     = var.project
    Owner       = var.owner
  }
}

# ルートテーブルとインターネットゲートウェイの紐付け
resource "aws_route" "public_rt_igw_r" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
