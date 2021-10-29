variable "ui_host_ip" {
  type = string
}

variable "data_host_ip" {
  type = string
}

variable "worker_host_ip" {
  type = string
}


job "voteapp" {
  datacenters = ["dc1"]

  type = "service"

  group "ui" {
    affinity {
      attribute = meta.app
      value     = "ui"
    }

    count = 1

    network {
      port "vote" {
        static = 80
      }
      port "result" {
        static = 5001
        to = 80
      }

      dns {
        servers  = ["${var.ui_host_ip}"]
        searches = ["service.dc1.consul"]
        # options = ["ndots:2"]
      }
    }

    task "vote" {
      driver = "docker"

      config {
        image      = "detcaccounts/voteapp"
        ports      = ["vote"]
        privileged = true
      }

      service {
        name = "vote"
        port = "vote"
      }
    }

    task "result" {
      driver = "docker"

      config {
        image = "detcaccounts/resultsapp"
        ports = ["result"]
      }

      service {
        name = "result"
        port = "result"
      }
    }
  }
  group "data" {
    affinity {
      attribute = meta.app
      value     = "data"
    }

    count = 1

    network {
      port "redis" {
        static = 6379
      }
      port "db" {
        static = 5432
      }

      dns {
        servers  = ["${var.data_host_ip}"]
        searches = ["service.dc1.consul"]
        # options = ["ndots:2"]
      }
    }

    task "redis" {
      driver = "docker"

      config {
        image = "redis:alpine"
        ports = ["redis"]
      }

      service {
        name = "redis"
        port = "redis"
      }
    }

    task "db" {
      driver = "docker"

      config {
        image = "postgres:9.4"
        ports = ["db"]
      }

      service {
        name = "db"
        port = "db"
      }

      env {
        PGDATA                    = "/var/lib/postgresql/data/pgdata"
        POSTGRES_USER             = "postgres"
        POSTGRES_PASSWORD         = "postgres"
        POSTGRES_HOST_AUTH_METHOD = "trust"
      }
    }
  }

  group "worker" {
    affinity {
      attribute = meta.app
      value     = "worker"
    }

    count = 1

    network {
      dns {
        servers  = ["${var.worker_host_ip}"]
        searches = ["service.dc1.consul"]
        # options = ["ndots:2"]
      }
    }

    task "worker" {
      driver = "docker"

      config {
        image = "detcaccounts/worker"
      }
    }
  }
}
