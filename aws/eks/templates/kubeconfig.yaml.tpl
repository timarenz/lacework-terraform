apiVersion: v1
clusters:
  - cluster:
      server: ${endpoint-url}
      certificate-authority-data: ${base64-encoded-ca-cert}
    name: ${arn}
contexts:
  - context:
      cluster: ${arn}
      user: ${arn}
    name: ${arn}
current-context: ${arn}
kind: Config
preferences: {}
users:
  - name: ${arn}
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: aws
        args:
          - --region
          - ${region}
          - eks
          - get-token
          - --cluster-name
          - ${cluster-name}

