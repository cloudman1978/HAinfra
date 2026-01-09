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


