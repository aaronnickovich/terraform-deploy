package terraform.s3.analsysis

import future.keywords.if

default allow := true

is_resource_of_type(resource, type) {
    resource.type == type
}

is_s3_bucket(resource) {
    is_resource_of_type(resource, "aws_s3_bucket")
}

is_access_block(resource) {
    is_resource_of_type(resource, "aws_s3_bucket_public_access_block")
}

access_block_of_bucket(resource, bucket) {
    is_access_block(resource)
    resource.change.after.bucket == bucket
}

s3_buckets[bucket] {
    bucket := input.resource_changes[i]
    is_s3_bucket(bucket)
}

buckets_with_access_blocks[bucket] {
    resource := input.resource_changes[i]
    is_access_block(resource)
    bucket := s3_buckets[j]
    not access_block_of_bucket(resource, bucket)
}

buckets_without_access_blocks[bucket] {
    buckets_without_access_blocks := s3_buckets - buckets_with_access_blocks
    bucket := buckets_without_access_blocks[_].address
}

allow := false {
    resources := buckets_without_access_blocks[_]
    resources != []
}
