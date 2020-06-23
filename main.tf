# Create secret containing Hetzner Cloud API token
resource "kubernetes_secret" "hcloud_token" {
  metadata {
    name = "hcloud"
    namespace = "kube-system"
  }

  data = {
    token = var.hcloud_token
    network = var.network_name
  }
}

# Create Hetzner cloud controller service account
resource "kubernetes_service_account" "cloud_controller_manager" {
  metadata {
    name = "cloud-controller-manager"
    namespace = "kube-system"
  }
}

# Create cluster role binding
resource "kubernetes_cluster_role_binding" "system_cloud_controller_manager" {
  metadata {
    name = "system:cloud-controller-manager"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cloud-controller-manager"
    namespace = "kube-system"
  }
}

# Deploy cloud controller
resource "kubernetes_deployment" "hcloud_cloud_controller_manager" {
  metadata {
    name = "hcloud-cloud-controller-manager"
    namespace = "kube-system"
  }

  spec {
    replicas = 1
    revision_history_limit = 2
    selector {
      match_labels = {
        app = "hcloud-cloud-controller-manager"
      }
    }

    template {
      metadata {
        labels = {
          app = "hcloud-cloud-controller-manager"
        }
        annotations = {
          "scheduler.alpha.kubernetes.io/critical-pod" = ""
        }
      }

      spec {
        automount_service_account_token = true # override Terraform's default false - https://github.com/kubernetes/kubernetes/issues/27973#issuecomment-462185284
        service_account_name = "cloud-controller-manager"
        dns_policy = "Default"
        toleration {
          key = "node.cloudprovider.kubernetes.io/uninitialized"
          value = true
          effect = "NoSchedule"
        }

        toleration {
          key = "CriticalAddonsOnly"
          operator = "Exists"
        }

        toleration {
          key = "node-role.kubernetes.io/master"
          effect = "NoSchedule"
        }

        toleration {
          key = "node.kubernetes.io/not-ready"
          effect = "NoSchedule"
        }

        host_network = true
        container {
          image = "hetznercloud/hcloud-cloud-controller-manager:v1.6.0"
          name  = "hcloud-cloud-controller-manager"
          command = [
            "/bin/hcloud-cloud-controller-manager",
            "--cloud-provider=hcloud",
            "--leader-elect=false",
            "--allow-untagged-cloud",
            "--allocate-node-cidrs=true",
            "--cluster-cidr=${var.cluster_cidr}"
          ]

          resources {
            requests {
              cpu    = "100m"
              memory = "50Mi"
            }
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          env {
            name = "HCLOUD_TOKEN"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key = "token"
              }
            }
          }

          env {
            name = "HCLOUD_NETWORK"
            value_from {
              secret_key_ref {
                name = "hcloud"
                key = "network"
              }
            }
          }
        }
      }
    }
  }
}

