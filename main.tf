provider "aws" {
    access_key = "XXXXXXXXXXXXXXXXXXXXX"
    secret_key = "YYYYYYYYYYYYYYYYYYYYYYYYYYYY"
    region = "us-east-1"
}

resource "aws_vpc" "lahiru-vpc" {
    cidr_block = "10.0.0.0/16"
    
    tags {
        Name = "lahiru_vpc"
    }
}

resource "aws_internet_gateway" "lahiru-igw" {
    vpc_id = "${aws_vpc.lahiru-vpc.id}"
}

resource "aws_eip" "lahiru-nat-eip" {
    vpc = true
}

resource "aws_nat_gateway" "lahiru-nat-gw" {
    allocation_id = "${aws_eip.lahiru-nat-eip.id}"
    subnet_id = "${aws_subnet.public-subnet.id}"
}

resource "aws_subnet" "public-subnet" {
    vpc_id = "${aws_vpc.lahiru-vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags {
        Name = "lahiru-public-subnet"
    }
}

resource "aws_subnet" "private-subnet" {
    vpc_id = "${aws_vpc.lahiru-vpc.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"

    tags {
        Name = "lahiru-private-subnet"
    }
}

resource "aws_route_table" "public-subnet-rtb" {
    vpc_id = "${aws_vpc.lahiru-vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.lahiru-igw.id}"
    }

    tags {
        Name = "lahiru-public-subnet-rtb"
    }
}

resource "aws_route_table" "private-subnet-rtb" {
    vpc_id = "${aws_vpc.lahiru-vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.lahiru-nat-gw.id}"
    }

    tags {
        Name = "lahiru-private-subnet-rtb"
    }
}

resource "aws_route_table_association" "public-subnet-association" {
    subnet_id = "${aws_subnet.public-subnet.id}"
    route_table_id = "${aws_route_table.public-subnet-rtb.id}"
}

resource "aws_route_table_association" "private-subnet-association" {
    subnet_id = "${aws_subnet.private-subnet.id}"
    route_table_id = "${aws_route_table.private-subnet-rtb.id}"
}

resource "aws_security_group" "lahiru-public-sg" {
    name = "lahiru-public-sg"
    vpc_id = "${aws_vpc.lahiru-vpc.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["115.114.36.2/32"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
    }
}

resource "aws_security_group" "lahiru-private-sg" {
    name = "lahiru-private-sg"
    vpc_id = "${aws_vpc.lahiru-vpc.id}"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${aws_subnet.public-subnet.cidr_block}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
    }
}

resource "aws_instance" "master" {
    ami = "ami-0565af6e282977273"
    instance_type = "t2.medium"
    key_name = "lahiru"
    subnet_id = "${aws_subnet.public-subnet.id}"
    security_groups = ["${aws_security_group.lahiru-public-sg.id}"]

    tags {
        Name = "master"
    }
}

resource "aws_instance" "worker-1" {
    ami = "ami-0565af6e282977273"
    instance_type = "t2.medium"
    key_name = "lahiru"
    subnet_id = "${aws_subnet.private-subnet.id}"
    security_groups = ["${aws_security_group.lahiru-private-sg.id}"]

    tags {
        Name = "worker-1"
    }
}

# resource "aws_instance" "worker-2" {
#     ami = "ami-0565af6e282977273"
#     instance_type = "t2.medium"
#     key_name = "lahiru"
#     subnet_id = "${aws_subnet.private-subnet.id}"
#     security_groups = ["${aws_security_group.lahiru-private-sg.id}"]

#     tags {
#         Name = "worker-2"
#     }
# }

# resource "aws_instance" "etcd" {
#     ami = "ami-0565af6e282977273"
#     instance_type = "t2.medium"
#     key_name = "lahiru"
#     subnet_id = "${aws_subnet.private-subnet.id}"
#     security_groups = ["${aws_security_group.lahiru-private-sg.id}"]

#     tags {
#         Name = "etcd"
#     }
# }
