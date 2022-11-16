resource "random_password" "k3s_cluster_secret" {    # here is token resource in terraform
  length  = 30
  special = false
}
