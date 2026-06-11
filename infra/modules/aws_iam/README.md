# IAM Module

A simple, unified Terraform module for creating IAM roles, instance profiles, and policies following the same pattern as the aws_sg module.

Creates IAM roles, instance profiles, and policies. Instance profiles and inline/managed policies; import existing roles by name.

## Usage

### Basic Example

```hcl
locals {
  config_iam = jsondecode(file("${path.module}/config_iam.json"))
}

module "iam" {
  source = "../../../modules/aws_iam"

  roles = local.config_iam.roles
  tags  = local.config_iam.tags
}
```

**That's it!** The module handles all file reading internally - no complex processing needed.

### Config File Structure (`config_iam.json`)

```json
{
  "roles": {
    "ec2-systems-manager": {
      "name": "SystemsManagerInstanceProfile",
      "description": "IAM role for EC2 Systems Manager access",
      "assume_role_policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
      "create_instance_profile": true,
      "managed_policy_arns": [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ],
      "tags": {
        "Purpose": "EC2 Systems Manager"
      }
    },
    "ec2-app-role": {
      "name": "AppInstanceRole",
      "description": "IAM role for application instances",
      "assume_role_policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
      "create_instance_profile": true,
      "inline_policies": {
        "s3-access": {
          "name": "S3AccessPolicy",
          "policy_file": "s3-access.json"
        }
      }
    }
  },
  "tags": {
    "Environment": "Production",
    "Project": "proj-liman",
    "app": "liman",
    "env": "prod",
    "ManagedBy": "Terraform"
  }
}
```

### Using Policy Files

All policies are maintained at the IAM module level in separate folders:
- `modules/aws_iam/assume-role/` - Contains assume role policy JSON files
- `modules/aws_iam/policies/` - Contains inline policy JSON files

The module automatically reads files from these folders - no processing needed in your `main.tf`!

In `config_iam.json`, reference files by name:

```json
{
  "roles": {
    "ec2-systems-manager": {
      "name": "SystemsManagerInstanceProfile",
      "assume_role_policy_file": "ec2-assume-role.json",
      "create_instance_profile": true,
      "inline_policies": {
        "s3-access": {
          "name": "S3AccessPolicy",
          "policy_file": "s3-access.json"
        }
      }
    }
  }
}
```

**Note**: You can also use direct JSON strings in the config. The `try()` function will use the file if `*_file` is provided, otherwise fall back to the direct JSON string.

### Importing Existing Roles

To manage rules for an existing role:

```json
{
  "roles": {
    "existing-role": {
      "name": "ExistingRoleName",
      "id": "ExistingRoleName",
      "assume_role_policy": "{\"Version\":\"2012-10-17\",\"Statement\":[...]}",
      "managed_policy_arns": [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
      ]
    }
  }
}
```

## Key Features

### 1. Instance Profiles

When `create_instance_profile = true`, the module automatically creates an IAM instance profile with the same name as the role. This is the standard pattern for EC2 instances.

```json
{
  "ec2-role": {
    "name": "EC2InstanceRole",
    "create_instance_profile": true,
    ...
  }
}
```

### 2. Inline Policies

Define inline policies directly in the config or reference external files:

```json
{
  "inline_policies": {
    "policy-key": {
      "name": "PolicyName",
      "policy": "{\"Version\":\"2012-10-17\",\"Statement\":[...]}"
    }
  }
}
```

### 3. Managed Policy Attachments

Attach AWS managed policies by ARN:

```json
{
  "managed_policy_arns": [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]
}
```

### 4. EC2 Integration

The module outputs instance profile names that can be used in the EC2 module:

```hcl
module "ec2" {
  source = "../../../modules/aws_ec2"
  
  # Instance profile names are automatically resolved
  vpc_instance_profile_names = module.iam.instance_profile_names
  ...
}
```

## Outputs

- `role_ids`: Map of IAM role IDs, keyed by role key
- `role_arns`: Map of IAM role ARNs, keyed by role key
- `role_names`: Map of IAM role names, keyed by role key
- `instance_profile_names`: Map of instance profile names, keyed by role key (for roles with `create_instance_profile = true`)
- `instance_profile_arns`: Map of instance profile ARNs, keyed by role key (for roles with `create_instance_profile = true`)

## Common Use Cases

### EC2 Systems Manager Role

```json
{
  "ec2-ssm": {
    "name": "SystemsManagerInstanceProfile",
    "description": "Role for EC2 Systems Manager",
    "assume_role_policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
    "create_instance_profile": true,
    "managed_policy_arns": [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ]
  }
}
```

### EC2 with S3 Access

```json
{
  "ec2-s3": {
    "name": "EC2S3AccessRole",
    "assume_role_policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
    "create_instance_profile": true,
    "inline_policies": {
      "s3-access": {
        "name": "S3Access",
        "policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"s3:GetObject\",\"s3:PutObject\"],\"Resource\":\"arn:aws:s3:::my-bucket/*\"}]}"
      }
    }
  }
}
```

## Notes

- Instance profiles are created with the same name as the role (AWS best practice)
- When importing existing roles, set `id` to the role name
- Policy JSON strings must be properly escaped in JSON config files
- Use the `policies/` folder for complex policies to keep config files clean

