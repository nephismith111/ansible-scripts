# Full access to all namespaces
namespace "*" {
  policy = "write"
  capabilities = [
    "list-jobs",
    "read-job",
    "submit-job",
    "dispatch-job",
    "read-logs",
    "alloc-exec",
    "alloc-lifecycle",
    "alloc-node-exec",
    "read-fs"
  ]
}

# Full node access
node {
  policy = "write"
}

# Full agent access
agent {
  policy = "write"
}

# Operator capabilities
operator {
  policy = "write"
}

# Plugin access
plugin {
  policy = "write"
}

# Quota management
quota {
  policy = "write"
}

# Volume access
host_volume "*" {
  policy = "write"
}
