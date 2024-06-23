package terraform.analysis

import rego.v1
import data.terraform.s3.analysis.allow as s3allow

import input as tfplan

########################
# Parameters for Policy
########################

# acceptable score for automated authorization
blast_radius := 30

# weights assigned for each operation on each resource-type
weights := {
	"aws_autoscaling_group": {"delete": 100, "create": 10, "modify": 1},
	"aws_instance": {"delete": 10, "create": 1, "modify": 1},
}

# Consider exactly these resource types in calculations
resource_types := {"aws_autoscaling_group", "aws_instance", "aws_iam", "aws_iam_user", "aws_launch_configuration"}

#########
# Policy
#########

# Authorization holds if score for the plan is acceptable and no changes are made to IAM
default allow := false


# Compute the score for a Terraform plan as the weighted sum of deletions, creations, modifications
score := s if {
	all := [x |
		some resource_type
		crud_parameter := weights[resource_type]
		del := crud_parameter["delete"] * num_deletes[resource_type]
		new := crud_parameter["create"] * num_creates[resource_type]
		mod := crud_parameter["modify"] * num_modifies[resource_type]
		x := (del + new) + mod
	]
	s := sum(all)
}

touches_aws_iam_user if {
    all := resources.aws_iam_user
    count(all) > 0
}

# Whether there is any change to IAM
touches_iam if {
	all := resources.aws_iam
	count(all) > 0
}

allow if {
    score < blast_radius
    not touches_iam
    not touches_aws_iam_user
    s3allow
}

####################
# Terraform Library
####################

# list of all resources of a given type
resources[resource_type] := all if {
	some resource_type
	resource_types[resource_type]
	all := [name |
		name := tfplan.resource_changes[_]
		name.type == resource_type
	]
}

# number of creations of resources of a given type
num_creates[resource_type] := num if {
	some resource_type
	resource_types[resource_type]
	all := resources[resource_type]
	creates := [res | res := all[_]; res.change.actions[_] == "create"]
	num := count(creates)
}

# number of deletions of resources of a given type
num_deletes[resource_type] := num if {
	some resource_type
	resource_types[resource_type]
	all := resources[resource_type]
	deletions := [res | res := all[_]; res.change.actions[_] == "delete"]
	num := count(deletions)
}

# number of modifications to resources of a given type
num_modifies[resource_type] := num if {
	some resource_type
	resource_types[resource_type]
	all := resources[resource_type]
	modifies := [res | res := all[_]; res.change.actions[_] == "update"]
	num := count(modifies)
}
