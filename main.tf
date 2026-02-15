provider {
  region = var.region
}

# ---creating VPC------
resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"

tags = {
  Name= "dev-stg"
 }
}

# ---Internet Gateway----
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "dev-igw"
  }
}

# -----Public Subnet -----
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "${var.region}a"

  tags {
   Name = "public-subnet"
  }
}

# -----Private Subnet -----
resource "aws_subnet" "pvt_subnet" {
  vpc_id = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"
  availabililty_zone = "${var.region}a"

  tags = {
    Name = "pvt_subnet"
  }
}

# -----Public route table ------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# ---Route Table Associate ---- 
resource "aws_route_table_associate" "public_associate" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_d = aws_route_table.public_rt.id
}

# -----Security Group------
resource "aws_security_group" "frontend_sg" {
  name = "frontend-sg"
  description = "Allow SSH and HTTP"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    description = "For SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
   }

  ingress {
    description = "For HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_block = ["0.0.0.0/0"]
   }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
   }

resource "aws_security_group" "private_sg"
  name = "private-sg"
  vpc_id = aws_vpc.my-vpc.id

  ingress {
    description = "Allow traffic from public EC2"
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    security_groups = "[aws_security_group.frontend_sg.id]"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_block = ["0.0.0.0/0"]
  }

# ------Public EC2 Instance -----
resource "aws_instance" "frontend" {
  ami = var.ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  associate_public_ip_address = true
 }

 tags = {
   Name = "frontend-ec2"
 }

# -----Private EC2 Instance -----
resource "aws_instance" "backend"
  ami = var.ami
  instance_type = "t2.micro"
  subnet_id = aws_subnet.pvt_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "backend-ec2"
  }
}

