defmodule TickTakeHome.Macros do

  defmacro guard_valid_name(prefix, max_servers, args, do: expression, else: else_expression) do
    quote do
      if is_valid_name?(unquote(prefix), unquote(max_servers), unquote(args)["name"]) do
        var!(name) = :"#{unquote(args)["name"]}"
        var!(data) = unquote(args)["data"]
        unquote(expression)
      else
        unquote(else_expression)
      end
    end
  end


  def is_valid_name?(prefix, max_servers, name) do
    case String.trim_leading(name, prefix <> "_") |> Integer.parse() do
      {number, _} when number >= 0 and number < max_servers -> true
      _ -> false
    end
  end
end
