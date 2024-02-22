let SYSML_URL = 'https://sysml-v2.ft-ssy-stonks.intra.dlr.de'


# def sysml_api_request [
#   path: list
# ] {
#   [ $SYSML_URL ] + $path | str join '/'
# }

module sysml {
  def project_ids [ ] {
    projects | each { |it| { value: $it.'@id', description: $it.name } }
  }

  # Get all projects, or one specific project
  export def projects [
    # id of the project to get
    project_id?: string@project_ids
  ] {
    if ($project_id == null) {
      http get $"($SYSML_URL)/projects"
    } else {
      http get $"($SYSML_URL)/projects/($project_id)"
    }
  }




  def branch_ids [context: string] {
    let project_id = ($context | str trim | split row ' ' | last)
    branches $project_id
      | each { |it| { value: $it.'@id', description: $it.name } }
  }

  # Get all branches of a project, or a specific branch
  export def branches [
    # id of the project whose branches to get
    project_id: string@project_ids

    # id of the branch to get
    branch_id?: string@branch_ids
  ] {
    if ($branch_id == null) {
      http get $"($SYSML_URL)/projects/($project_id)/branches"
    } else {
      http get $"($SYSML_URL)/projects/($project_id)/branches/($branch_id)"
    }
  }



 
  def tag_ids [context: string] {
    let project_id = ($context | str trim | split row ' ' | last)
    tags $project_id
      | each { |it| { value: $it.'@id', description: $it.name } }
  }

  # Get all tags of a project, or a specific tag
  export def tags [
    # id of the project whose tags to get
    project_id: string@project_ids

    # id of the branch to get
    tag_id?: string@tag_ids
  ] {
    if ($tag_id == null) {
      http get $"($SYSML_URL)/projects/($project_id)/tags"
    } else {
      http get $"($SYSML_URL)/projects/($project_id)/tags/($tag_id)"
    }
  }



  
  def commit_ids [context: string] {
    let project_id = ($context | str trim | split row ' ' | last)
    commits $project_id
      | each { |it| { value: $it.'@id', description: $it.description } }
  }

  # Get all commits of a project, or a specific commit
  export def commits [
    # id of the project whose commits to get
    project_id: string@project_ids

    # id of the branch to get
    commit_id?: string@commit_ids
  ] {
    if ($commit_id == null) {
      http get $"($SYSML_URL)/projects/($project_id)/commits"
    } else {
      http get $"($SYSML_URL)/projects/($project_id)/commits/($commit_id)"
    }
  }



  
  def element_ids [context: string] {
    let ids = ($context | str trim | split row ' ' | last 2)
    elements $ids.0 $ids.1
      | each { |it| { value: $it.'@id', description: $"($it.name):($it.'@type')" } }
  }

  # Get all commits of a project, or a specific commit
  export def elements [
    # id of the project whose commits to get
    project_id: string@project_ids

    # id of the branch to get
    commit_id: string@commit_ids

    # id of the branch to get
    element_id?: string@element_ids
  ] {
    if ($element_id == null) {
      http get $"($SYSML_URL)/projects/($project_id)/commits/($commit_id)/elements"
    } else {
      http get $"($SYSML_URL)/projects/($project_id)/commits/($commit_id)/elements/($element_id)"
    }
  }

  # fetch an element, and its direct sub-elements
  export def fetch-subelements [

    # id of the project whose commits to get
    project_id: string@project_ids

    # id of the branch to get
    commit_id: string@commit_ids

    # id of the branch to get
    element_id: string@element_ids
  ] {
    mut element = (elements $project_id $commit_id $element_id)

    for $field_name in ($element | columns) {
      let $field = ($element | get $field_name)
      let $field_type = ($field | describe)

      # if element is a list of subelements
      if ($field_type == "table<@id: string>") {
        $element = ($element | update $field_name {|_|
          $field | each {|row| 
            let $new_element_id = ($row | get '@id')
            elements $project_id $commit_id $new_element_id
          } 
        })
      }

      # if element is just a record
      if ($field_type == "record<@id: string>") {
        let new_element_id = ($field | get '@id')
        $element = ($element | update $field_name {|_| 
          elements $project_id $commit_id $new_element_id
        })
      }
    }

    $element
  }
}

use sysml *
