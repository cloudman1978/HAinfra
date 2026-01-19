# 1. Create Transit Gateway A
resource "aws_ec2_transit_gateway" "tgw_a" {
  description = "Transit Gateway FR"
  tags        = { Name = "TGW-FR" }
}

# 2. Create Transit Gateway B
resource "aws_ec2_transit_gateway" "tgw_b" {
  description = "Transit Gateway IR"
  tags        = { Name = "TGW-IR" }
}



resource "aws_ec2_transit_gateway_peering_attachment" "tgw_source_peering" {
  peer_region             = "us-east-1"
  transit_gateway_id      = aws_ec2_transit_gateway.tgw_a.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.tgw_b.id
  tags = {
    Name = "terraform-example"
    Side = "Creator"
  }
}

data "aws_ec2_transit_gateway_peering_attachment" "tgw_destination_peering_data" {
  depends_on = [aws_ec2_transit_gateway_peering_attachment.tgw_source_peering]
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.tgw_b.id]
  }
  filter {
    name = "state"
    values = [ "pendingAcceptance" , "available" ]
  }
}

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "peering_accpeter" {
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.tgw_destination_peering_data.id
  tags = {
    Name = "terraform-example"
    Side = "Acceptor"
  }
}

# 3. Create VPC "fr"
resource "aws_vpc" "vpc_fr" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-fr"
  }
}

# 4. Create private subnet in VPC "fr"
resource "aws_subnet" "vpc_fr_private" {
  vpc_id            = aws_vpc.vpc_fr.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "vpc-fr-private-subnet"
  }
}

# 5. Create attachment subnet (/28) in VPC "fr"
resource "aws_subnet" "vpc_fr_attachment" {
  vpc_id            = aws_vpc.vpc_fr.id
  cidr_block        = "10.0.2.0/28"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "vpc-fr-attachment-subnet"
  }
}

# 6. Attach VPC "fr" to Transit Gateway "tgw_a"
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_fr_tgw_attachment" {
  subnet_ids             = [aws_subnet.vpc_fr_attachment.id]
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_a.id
  vpc_id                 = aws_vpc.vpc_fr.id
  tags = {
    Name = "vpc-fr-tgw-attachment"
  }
}

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# 7. Create VPC "ireland"
resource "aws_vpc" "vpc_ireland" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-ireland"
  }
}

# 8. Create private subnet in VPC "ireland"
resource "aws_subnet" "vpc_ireland_private" {
  vpc_id            = aws_vpc.vpc_ireland.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "vpc-ireland-private-subnet"
  }
}

# 9. Create attachment subnet (/28) in VPC "ireland"
resource "aws_subnet" "vpc_ireland_attachment" {
  vpc_id            = aws_vpc.vpc_ireland.id
  cidr_block        = "10.1.2.0/28"
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "vpc-ireland-attachment-subnet"
  }
}

# 10. Attach VPC "ireland" to Transit Gateway "tgw_b"
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_ireland_tgw_attachment" {
  subnet_ids             = [aws_subnet.vpc_ireland_attachment.id]
  transit_gateway_id     = aws_ec2_transit_gateway.tgw_b.id
  vpc_id                 = aws_vpc.vpc_ireland.id
  tags = {
    Name = "vpc-ireland-tgw-attachment"
  }
}


# 11. Create Internet Gateway for VPC "fr"
resource "aws_internet_gateway" "vpc_fr_igw" {
  vpc_id = aws_vpc.vpc_fr.id
  tags = {
    Name = "vpc-fr-igw"
  }
}

# 12. Create public subnet in VPC "fr"
resource "aws_subnet" "vpc_fr_public" {
  vpc_id                  = aws_vpc.vpc_fr.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "vpc-fr-public-subnet"
  }
}

# 13. Create route table for public subnet
resource "aws_route_table" "vpc_fr_public_rt" {
  vpc_id = aws_vpc.vpc_fr.id
  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.vpc_fr_igw.id
  }
  tags = {
    Name = "vpc-fr-public-rt"
  }
}

# 14. Associate route table with public subnet
resource "aws_route_table_association" "vpc_fr_public_rt_assoc" {
  subnet_id      = aws_subnet.vpc_fr_public.id
  route_table_id = aws_route_table.vpc_fr_public_rt.id
}

# Security group for VPC "fr" public instance
resource "aws_security_group" "vpc_fr_public_sg" {
  name        = "vpc-fr-public-sg"
  description = "Allow SSH from everywhere"
  vpc_id      = aws_vpc.vpc_fr.id

  ingress {
    description = "SSH from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-fr-public-sg"
  }
}
# 15. Create EC2 instance in public subnet
resource "aws_instance" "vpc_fr_public_instance" {
 
  ami                    = var.instance_ami
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.vpc_fr_public.id
  key_name               = aws_key_pair.ec2_keypair.key_name
   security_groups = [aws_security_group.vpc_fr_public_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "vpc-fr-public-instance"
  }
}

variable "instance_ami" {
  description = "AMI ID for the EC2 instance"
  type        = string
  
}

# Create local private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file
resource "local_file" "private_key" {
  filename        = "${path.module}/ec2-key.pem"
  content         = tls_private_key.ec2_key.private_key_pem
  file_permission = "0600"
}

# Create AWS key pair
resource "aws_key_pair" "ec2_keypair" {
  key_name   = "ec2-keypair"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

output "vpc_fr_public_instance_ip" {
  description = "Public IP of the vpc-fr public EC2 instance"
  value       = aws_instance.vpc_fr_public_instance.public_ip
}

resource "aws_security_group" "vpc_ireland_private_sg" {
  name        = "vpc-ireland-private-sg"
  description = "Allow SSH and ICMP from 10.0.0.0/8"
  vpc_id      = aws_vpc.vpc_ireland.id

    ingress {
      description = "SSH from everywhere"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  ingress {
    description = "ICMP from 0.0.0.0/0"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-ireland-private-sg"
  }
}
resource "aws_instance" "vpc_ireland_private_instance" {
  ami                         = var.instance_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.vpc_ireland_private.id
  key_name                    = aws_key_pair.ec2_keypair.key_name
  vpc_security_group_ids = [aws_security_group.vpc_ireland_private_sg.id]
  associate_public_ip_address = false
  tags = {
    Name = "vpc-ireland-private-instance"
  }
}

output "vpc_ireland_private_instance_private_ip" {
  description = "Private IP of the vpc-ireland private EC2 instance"
  value       = aws_instance.vpc_ireland_private_instance.private_ip
}


###### on premise VPC vpc_ireland

# 16. Create VPC "paris-onprem"
resource "aws_vpc" "vpc_paris_onprem" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "vpc-paris-onprem"
  }
}

# 17. Create Internet Gateway for VPC "paris-onprem"
resource "aws_internet_gateway" "vpc_paris_onprem_igw" {
  vpc_id = aws_vpc.vpc_paris_onprem.id
  tags = {
    Name = "vpc-paris-onprem-igw"
  }
}

# 18. Create public subnet in VPC "paris-onprem"
resource "aws_subnet" "vpc_paris_onprem_public" {
  vpc_id                  = aws_vpc.vpc_paris_onprem.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "vpc-paris-onprem-public-subnet"
  }
}

# 19. Create route table for paris-onprem public subnet
resource "aws_route_table" "vpc_paris_onprem_public_rt" {
  vpc_id = aws_vpc.vpc_paris_onprem.id
  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.vpc_paris_onprem_igw.id
  }
  tags = {
    Name = "vpc-paris-onprem-public-rt"
  }
}

# 20. Associate route table with paris-onprem public subnet
resource "aws_route_table_association" "vpc_paris_onprem_public_rt_assoc" {
  subnet_id      = aws_subnet.vpc_paris_onprem_public.id
  route_table_id = aws_route_table.vpc_paris_onprem_public_rt.id
}