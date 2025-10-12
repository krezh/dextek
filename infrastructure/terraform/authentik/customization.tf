resource "authentik_policy_password" "password-complexity" {
  name             = "password-complexity"
  length_min       = 8
  amount_digits    = 1
  amount_lowercase = 1
  amount_uppercase = 1
  error_message    = "Minimum password length: 8. At least 1 of each required: uppercase, lowercase, digit"
}

resource "authentik_policy_expression" "user-settings-authorization" {
  name       = "user-settings-authorization"
  expression = <<-EOT
  from authentik.lib.config import CONFIG
  from authentik.core.models import (
      USER_ATTRIBUTE_CHANGE_EMAIL,
      USER_ATTRIBUTE_CHANGE_NAME,
      USER_ATTRIBUTE_CHANGE_USERNAME
  )
  prompt_data = request.context.get('prompt_data')

  if not request.user.group_attributes(request.http_request).get(
      USER_ATTRIBUTE_CHANGE_EMAIL, CONFIG.y_bool('default_user_change_email', True)
  ):
      if prompt_data.get('email') != request.user.email:
          ak_message('Not allowed to change email address.')
          return False

  if not request.user.group_attributes(request.http_request).get(
      USER_ATTRIBUTE_CHANGE_NAME, CONFIG.y_bool('default_user_change_name', True)
  ):
      if prompt_data.get('name') != request.user.name:
          ak_message('Not allowed to change name.')
          return False

  if not request.user.group_attributes(request.http_request).get(
      USER_ATTRIBUTE_CHANGE_USERNAME, CONFIG.y_bool('default_user_change_username', True)
  ):
      if prompt_data.get('username') != request.user.username:
          ak_message('Not allowed to change username.')
          return False

  return True
  EOT
}

resource "authentik_policy_expression" "invitation-group-assignment" {
  name       = "invitation-group-assignment"
  expression = <<-EOT
  from authentik.core.models import Group

  # Get add_groups from prompt_data (where invitation attributes end up)
  prompt_data = request.context.get("prompt_data", {})
  groups_list = prompt_data.get("add_groups", [])

  # Always add users to the "users" group by default
  if "users" not in groups_list:
    groups_list.append("users")

  if not groups_list:
    ak_logger.info("No groups found in 'add_groups' attribute")
    return True

  ak_logger.info(f"Found groups to add: {groups_list}")

  # Add user to groups
  add_groups = []
  for group_name in groups_list:
    try:
      group = Group.objects.get(name=group_name)
      add_groups.append(group)
      ak_logger.info(f"Adding user to group: {group_name}")
    except Group.DoesNotExist:
      ak_logger.error(f"Group does not exist: {group_name}")

  # Set groups in flow context for user_write stage to use
  request.context["flow_plan"].context["groups"] = add_groups
  ak_logger.info(f"Set {len(add_groups)} groups in flow context")

  return True
  EOT
}

resource "authentik_policy_binding" "bind-invitation-group-assignment" {
  target  = authentik_flow_stage_binding.enrollment-invitation-flow-binding-20.id
  policy  = authentik_policy_expression.invitation-group-assignment.id
  order   = 0
  enabled = true
  negate  = false
  timeout = 30
}

output "enrollment_user_write_id" {
  value = authentik_stage_user_write.enrollment-user-write.id
}
