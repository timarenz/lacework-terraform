static_cache_location: /opt/lacework/cache
default_registry: index.docker.io
lacework:
  account_name: ${account_name}
  integration_access_token: ${integration_access_token}
registries:
  - domain: ${domain}
    name: nexus
    ssl: true
    auto_poll: true
    credentials:
      user_name: "admin"
      password: "${nexus_password}"
    poll_frequency_minutes: 20
    scan_non_os_packages: true