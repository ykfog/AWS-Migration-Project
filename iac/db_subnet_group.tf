resource "aws_db_subnet_group" "db" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}
