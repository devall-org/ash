defmodule Ash do
  @moduledoc """
  The primary interface for interrogating apis and resources.

  These are tools for interrogating resources to derive behavior based on their
  configuration. This is how all of the behavior of Ash is ultimately configured.
  """
  alias Ash.Resource.Actions.{Create, Destroy, Read, Update}
  alias Ash.Resource.Relationships.{BelongsTo, HasMany, HasOne, ManyToMany}

  @type record :: struct
  @type relationship_cardinality :: :many | :one
  @type cardinality_one_relationship() :: HasOne.t() | BelongsTo.t()
  @type cardinality_many_relationship() :: HasMany.t() | ManyToMany.t()
  @type relationship :: cardinality_one_relationship() | cardinality_many_relationship()
  @type resource :: module
  @type data_layer :: module
  @type data_layer_query :: struct
  @type api :: module
  @type error :: struct
  @type filter :: map()
  @type params :: Keyword.t()
  @type sort :: Keyword.t()
  @type side_loads :: Keyword.t()
  @type attribute :: Ash.Resource.Attributes.Attribute.t()
  @type action :: Create.t() | Read.t() | Update.t() | Destroy.t()
  @type query :: Ash.Query.t()
  @type actor :: Ash.record()

  @doc "A short description of the resource, to be included in autogenerated documentation"
  @spec describe(resource()) :: String.t()
  def describe(resource) do
    resource.describe()
  end

  @doc "A list of authorizers to be used when accessing the resource"
  @spec authorizers(resource()) :: [module]
  def authorizers(resource) do
    resource.authorizers()
  end

  @doc "A list of resource modules for a given API"
  @spec resources(api) :: list(resource())
  def resources(api) do
    api.resources()
  end

  @doc "A list of field names corresponding to the primary key of a resource"
  @spec primary_key(resource()) :: list(atom)
  def primary_key(resource) do
    resource.primary_key()
  end

  @doc "Gets a relationship by name from the resource"
  @spec relationship(resource(), atom() | String.t()) :: relationship() | nil
  def relationship(resource, relationship_name) when is_bitstring(relationship_name) do
    Enum.find(resource.relationships(), &(to_string(&1.name) == relationship_name))
  end

  def relationship(resource, relationship_name) do
    Enum.find(resource.relationships(), &(&1.name == relationship_name))
  end

  @doc "A list of relationships on the resource"
  @spec relationships(resource()) :: list(relationship())
  def relationships(resource) do
    resource.relationships()
  end

  @doc false
  def primary_action!(resource, type) do
    case primary_action(resource, type) do
      nil -> raise "Required primary #{type} action for #{inspect(resource)}"
      action -> action
    end
  end

  @doc "Returns the primary action of a given type for a resource"
  @spec primary_action(resource(), atom()) :: action() | nil
  def primary_action(resource, type) do
    resource
    |> actions()
    |> Enum.filter(&(&1.type == type))
    |> case do
      [action] -> action
      actions -> Enum.find(actions, & &1.primary?)
    end
  end

  @doc "Returns the action with the matching name and type on the resource"
  @spec action(resource(), atom(), atom()) :: action() | nil
  def action(resource, name, type) do
    Enum.find(resource.actions(), &(&1.name == name && &1.type == type))
  end

  @doc "A list of all actions on the resource"
  @spec actions(resource()) :: list(action())
  def actions(resource) do
    resource.actions()
  end

  @doc "Get an attribute name from the resource"
  @spec attribute(resource(), String.t() | atom) :: attribute() | nil
  def attribute(resource, name) when is_bitstring(name) do
    Enum.find(resource.attributes, &(to_string(&1.name) == name))
  end

  def attribute(resource, name) do
    Enum.find(resource.attributes, &(&1.name == name))
  end

  @doc "A list of all attributes on the resource"
  @spec attributes(resource()) :: list(attribute())
  def attributes(resource) do
    resource.attributes()
  end

  @doc "The data layer of the resource, or nil if it does not have one"
  @spec data_layer(resource()) :: data_layer()
  def data_layer(resource) do
    resource.data_layer()
  end

  @doc false
  @spec data_layer_can?(resource(), Ash.DataLayer.feature()) :: boolean
  def data_layer_can?(resource, feature) do
    data_layer = data_layer(resource)

    data_layer && Ash.DataLayer.can?(feature, resource)
  end

  @doc false
  @spec data_layer_filters(resource) :: map
  def data_layer_filters(resource) do
    Ash.DataLayer.custom_filters(resource)
  end
end
