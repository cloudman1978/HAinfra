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


