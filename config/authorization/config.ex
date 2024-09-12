alias Acl.Accessibility.Always, as: AlwaysAccessible
alias Acl.Accessibility.ByQuery, as: AccessByQuery
#alias Acl.GraphSpec.Constraint.Resource.AllPredicates, as: AllPredicates
alias Acl.GraphSpec.Constraint.Resource.NoPredicates, as: NoPredicates
alias Acl.GraphSpec.Constraint.ResourceFormat, as: ResourceFormatConstraint
alias Acl.GraphSpec.Constraint.Resource, as: ResourceConstraint
alias Acl.GraphSpec, as: GraphSpec
alias Acl.GroupSpec, as: GroupSpec
alias Acl.GroupSpec.GraphCleanup, as: GraphCleanup

defmodule Acl.UserGroups.Config do
  defp access_by_role( group_string ) do
    %AccessByQuery{
      vars: ["session_group","session_role"],
      query: sparql_query_for_access_role( group_string ) }
  end

  defp access_by_role_for_single_graph( group_string ) do
    %AccessByQuery{
      vars: [],
      query: sparql_query_for_access_role( group_string ) }
  end

  defp sparql_query_for_access_role(group_string) do
    "PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
     PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
     SELECT DISTINCT ?session_group ?session_role WHERE {
      <SESSION_ID> ext:sessionGroup/mu:uuid ?session_group;
                   ext:sessionRole ?session_role.
      FILTER( ?session_role = \"#{group_string}\" )
    }"
  end

  defp is_authenticated() do
    %AccessByQuery{
      # Let's be restrictive,
      # we want the session to be attached to a role and uuid of bestuurseeneheid ( == ?session_group )
      vars: [],
      query: "PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
        PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
        SELECT DISTINCT ?session_group ?session_role WHERE {
          <SESSION_ID> ext:sessionGroup/mu:uuid ?session_group;
                       ext:sessionRole ?session_role.
        }"
      }
  end

  # These elements are walked from top to bottom.  Each of them may
  # alter the quads to which the current query applies.  Quads are
  # represented in three sections: current_source_quads,
  # removed_source_quads, new_quads.  The quads may be calculated in
  # many ways.  The useage of a GroupSpec and GraphCleanup are
  # common.
  def user_groups do
    [
      %GroupSpec{
        name: "citizen",
        useage: [:read, :write, :read_for_write],
        access: access_by_role("citizen"),
        graphs: [
          %GraphSpec{
            graph: "http://mu.semte.ch/graphs/citizen",
          }
        ]
      },
      %GroupSpec{
        name: "public",
        useage: [:read],
        access: %AlwaysAccessible{},
        graphs: [
          %GraphSpec{
            graph: "http://mu.semte.ch/graphs/public",
          },
          %GraphSpec{
            graph: "http://mu.semte.ch/graphs/shared",
          }
        ]
      },

      # // CLEANUP
      #
      %GraphCleanup{
        originating_graph: "http://mu.semte.ch/application",
        useage: [:read, :write],
        name: "clean"
      }
    ]
  end
end
