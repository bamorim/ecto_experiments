# EctoExperiments

A repository where I can play around with Ecto before exporting things into their own libraries

## EctoEmbettered

### Encoding and Decoding Embedded Schemas

This experiment aims to build on top of Ecto's `embedded_schema`. We started on the premise that
embedded schemas are "JSON-serializable". We followed to define an "encoded map" as something that
is similar to a JSON, but in elixir, with the following typespec:

```elixir
  @type encoded_map :: %{required(String.t()) => encoded()}

  @type encoded ::
          encoded_map()
          | [encoded()]
          | String.t()
          | number()
          | boolean()
          | nil
```

Then we followed to create a `Codec` that encodes and decodes embedded schemas to and from that
encoded form, following this spec:

```elixir
defmodule EctoEmbettered.Codec do
  @spec encode(value :: any()) :: {:ok, encoded_map()} | :error
  @spec decode(schema :: atom(), encoded_map()) :: {:ok, any()} | :error
end
```

By implementing that codec, it is already a valuable library that can transform any ecto value into
that "json-like" structure which can be useful for sending to other services, publishing in a
pub-sub system or whatever. The nice thing is that since we are not requiring it to be a string, it
can be adapted to JSON, MessagePack, YAML, or whatever fits those types.

### Using embedded schemas as plain ecto types

Normally, you would use the embedded schema as a `embeds_one` or `embeds_many`, but I came up with
some use cases where you'd want to have more than that.

The first use case was enabling polymorphic fields. That was a special case when I was implementing
an Event Store, where I needed to retrieve events in a polymorphic way. So I created the
`EctoEmbettered.PolymorphicType` to solve that. The way I'd use is something like the following:

```elixir
defmodule Events.Event1 do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:data, :string)
  end
end

# Other events...

defmodule EventData do
  use EctoEmbettered.PolymorphicType,
    event1: Events.Event1,
    event2: Events.Event2
    # ...
end

defmodule Event do
  use Ecto.Schema

  schema "events" do
    field(:stream, :string)
    field(:event, EventData)
  end
end
```

What that would do is that when I save an `%Event{event: %Events.Event1{data: "string_value"}}` it
would convert it to a json like and save on the event field on the database (a :map type):

```json
{
  "type": "event1",
  "data": {
    "data": "string_value"
  }
}
```

The reason why it saved as `event1` and not something like `Elixir.Events.Event1` or `Events.Event1`
is to avoid a lot of data migrations when just renaming the embedded schema struct name. That is why
we need to provide a keyword name to the `use EctoEmbettered.PolymorphicType`. That atom is
converted to a string that is saved on the `"type"` field.

### Non-polymorphic Embedded Schema Type

Recently I came to a strange experiment where I wanted an embedded schema as a type. I was thinking
a lot about DDD Tactical Patterns and there is one thing that helps a lot with domain modeling:
Value Objects. Sometime, Value Objects are the Identification of an Entity.

Let's think about a polymorphic thing that needed a type and an id (for example, when modeling an
external resource for an authorization system). Normally, you would go implementing that as
something by first having a composite primary key migration:

```elixir
defmodule ResourceMigration do
  use Ecto.Migration

  def change do
    create table("resources", primary_key: false) do
      add :type, :string, primary_key: true
      add :id, :string, primary_key: true
    end
  end
end
```

And then defining the schema as:

```elixir
defmodule Resource do
  use Ecto.Schema

  @primary_key false
  schema "resources" do
    field :type, :string
    field :id, :string
  end
end
```

There are a few problems with this approach.

The first one is that `:type` and `:id` are really coupled, they should probably been a `ResourceId`
value object that contained both. But in order to to that clearly you'd need to split your
persistence layer from your domain layer (which can be a good thing, but it may also be a little bit
too much)

The second problem, is that you would lose the abiity to do a `Repo.get(Resource, id)`.

So I started thinking about a crazy idea: what if the primary key were an embedded schema? I mean,
what if we could actually model the id as a Value Object and use that.

So I came up with a `EctoEmbettered.Type` which is like the `EctoEmbettered.PolymorphicType` but it
receives just `schema: SchemaMod` as an argument. That way, we could define our migration like.

```elixir
defmodule ResourceMigration do
  use Ecto.Migration

  def change do
    create table("resources", primary_key: false) do
      add :id, :map, primary_key: true
    end
  end
end
```

With that, I could just define the ResourceId as an embedded schema

```elixir
defmodule ResourceId do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :type, :string
    field :id, :string
  end
end
```

And use `EctoEmbettered.Type` to define an Ecto Type:

```elixir
defmodule ResourceId.EctoType do
  use EctoEmbettered.Type, schema: ResourceId
end
```

And then defining the schema as:

```elixir
defmodule Resource do
  use Ecto.Schema

  @primary_key {:id, ResourceId.EctoType, []}
  schema "resources" do
  end
end
```

Now I can just do

```elixir
Repo.get(Resource, %ResourceId{id: "id", type: "type"})
```

#### Pitfalls

This can hurt postgres performance if your data size is unbounded. However, that could be a thing
with string, but normally we just use UUID and call it a day. So we must be aware of that.

Also, there will be a constant difference in the complexity when indexing and finding, due to
converting and stuff.