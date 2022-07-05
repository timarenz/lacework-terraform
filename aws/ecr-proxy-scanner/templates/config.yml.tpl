static_cache_location: /opt/lacework/cache
scan_public_registries: true
default_registry: ${ecr_domain}
lacework:
  account_name: ${lacework_account_name}
  integration_access_token: ${lacework_integration_access_token}
registries:
  - domain: ${ecr_domain}
    name: ECR
    auth_type: ecr
    credentials:
      use_local_credentials: true
    is_public: false
    ssl: true
    auto_poll: false
    disable_non_os_package_scanning: false
    go_binary_scanning:
      enable: true