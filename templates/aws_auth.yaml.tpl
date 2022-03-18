apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
%{for role in worker_roles ~}
    - rolearn: ${role}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
%{endfor ~}
%{for role in role_mapping ~}
    - rolearn: ${role.role_arn}
      username: ${role.username}
      groups:
        ${indent(8, yamlencode(role.groups))}
%{endfor ~}
%{if length(user_mapping) > 0 ~}
  mapUsers: |
%{for user in user_mapping ~}
    - userarn: ${user.user_arn}
      username: ${user.username}
      groups:
        ${indent(8, yamlencode(user.groups))}
%{endfor ~}
%{endif ~}
