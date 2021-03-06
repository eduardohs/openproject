#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

When /^I check the role "(.+?)" for the project member "(.+?)"$/ do |role_name, user_login|
  role = Role.find_by_name(role_name)

  member = member_for_login user_login

  steps %Q{When I check "member_role_ids_#{role.id}" within "#member-#{member.id}"}
end

Then /^the project member "(.+?)" should not be in edit mode$/ do |user_login|
  member = member_for_login user_login

  page.find("#member-#{member.id}-roles-form", :visible => false).should_not be_visible
end

Then /^the project member "(.+?)" should have the role "(.+?)"$/ do |user_login, role_name|
  member = member_for_login user_login

  steps %Q{Then I should see "#{role_name}" within "#member-#{member.id}-roles"}
end

When /^I follow the delete link of the project member "(.+?)"$/ do |login_name|
  member = member_for_login login_name

  steps %Q{When I follow "Delete" within "#member-#{member.id}"}
end

When /^I add(?: the)? principal "(.+)" as(?: a)? "(.+)"$/ do |principal, role|
  steps %Q{
    And I select the principal "#{principal}"
    And I select the role "#{role}"
    And I click on "Add" within "#tab-content-members"
    And I wait for AJAX
  }
end

When /^I select(?: the)? principal "(.+)"$/ do | principal |
  found_principal = Principal.like(principal).first
  raise "No Principal #{principal} found" unless found_principal
  select_principal(found_principal)
end

When /^I select(?: the)? role "(.+)"$/ do | role |
  found_role = Role.like(role).first
  raise "No Role #{role} found" unless found_role
  select_role(found_role)
end

def select_principal(principal)
  if !User.current.impaired?
    select_within_select2(principal.name, "#s2id_member_user_ids")
  else
    select_without_select2(principal.name, "form .principals")
  end
end

def select_role(role)
  if !User.current.impaired?
    select_within_select2(role.name, "#s2id_member_role_ids")
  else
    select_without_select2(role.name, "form .roles")
  end
end

def select_within_select2(to_select, scope)
  tries = 3
  begin
    enter_name_with_select2(to_select, scope)
    steps %Q{And I wait 10 seconds for the AJAX requests to finish}
    find(".select2-results .select2-result").click
  rescue Capybara::ElementNotFound
    tries -= 1
    retry unless tries == 0
  end
end


def select_without_select2(name, scope)
  steps %Q{And I check "#{name}" within "#{scope}"}
end

def enter_name_with_select2(name, scope = "")
  with_scope(scope) do
    find(".select2-choices .select2-input").set(name)
  end
end

def enter_name_without_select2(name)
  step %Q{I fill in "principal_search" with "#{name}"}
end

When /^I add the principal "(.+)" as a member with the roles:$/ do |principal_name, roles_table|

  roles_table.raw.flatten.each do |role_name|
    steps %Q{ When I add the principal "#{principal_name}" as a "#{role_name}" }
  end
end

Then /^I should see the principal "(.+)" as a member with the roles:$/ do |principal_name, roles_table|
  principal = InstanceFinder.find(Principal, principal_name)
  steps %Q{ Then I should see "#{principal.name}" within "#tab-content-members .members" }

  found_roles = page.find(:xpath, "//tr[contains(concat(' ',normalize-space(@class),' '),' member ')][contains(.,'#{principal.name}')]").find(:css, "td.roles span").text.split(",").map(&:strip)

  found_roles.should =~ roles_table.raw.flatten
end

Then /^I should not see the principal "(.+)" as a member$/ do |principal_name|
  principal = InstanceFinder.find(Principal, principal_name)

  steps %Q{ Then I should not see "#{principal.name}" within "#tab-content-members .members" }
end

When /^I enter the (principal|role) name "(.+)"$/ do |model, principal_name|
  model = (model == "role" ? "role" : "user")
  if !User.current.impaired?
    enter_name_with_select2(principal_name, "#s2id_member_#{model}_ids")
  else
    enter_name_without_select2(principal_name)
  end
end

When /^I delete the "([^"]*)" membership$/ do |group_name|
  membership = member_for_login(group_name)
  step %Q(I follow "Delete" within "#member-#{membership.id}")
end

def member_for_login(principal_name)
  principal = InstanceFinder.find(Principal, principal_name)

  sleep 1

  #the assumption here is, that there is only one project
  principal.members.first
end

