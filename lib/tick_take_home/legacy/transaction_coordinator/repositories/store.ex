defmodule Legacy.TickTakeHomeWeb.TransactionCoordinator.Repositories.Store do
  @doc """
  Reads and decodes the contents of the 'log_coordinator.json' file.

  This function performs the following steps:

  1. Tries to read the contents of the 'log_coordinator.json' file.
  2. If the file is successfully read but is empty, it writes default transaction log values to the file.
  3. If the file read is successful and contains content, it decodes the JSON content and returns the decoded data.
  4. If there's an error reading the file, it writes default transaction log values to the file.

  ## Return

    - When reading and decoding is successful: Returns the decoded data from the file.
    - When the file is empty or there's an error reading the file: Returns the result of writing default values to the file.

  ## Notes

    - Default transaction log values: `%{"last_complete_id" => 0, "transactions_list" => []}`
    - The function relies on the `Jason` library for JSON decoding.
    - Any error in JSON decoding will raise an exception due to the use of `Jason.decode!`.

  ## Example

      iex> read_file()
      %{"last_complete_id" => 5, "transactions_list" => [%{"id" => 1}, %{"id" => 2}]}

  """
  def read_file() do
    File.read("log_coordinator.json")
    |> case do
      {:ok, ""} -> write_file(%{"last_complete_id" => 0, "transactions_list" => []})
      {:ok, content} -> Jason.decode!(content)
      {:error, _} -> write_file(%{"last_complete_id" => 0, "transactions_list" => []})
    end
  end

  @doc """
  Writes the provided data to 'log_coordinator.json' after encoding it as JSON.

  Given a map or any compatible data structure, this function will:
  1. Encode the data into a JSON string using the `Jason` library.
  2. Write this JSON string to 'log_coordinator.json'.
  3. Return the original data after writing.

  ## Parameters

    - `data`: The data to be encoded and written to the file. This should be a map or any data structure that can be encoded to JSON using the `Jason` library.

  ## Return

    - Returns the original `data` after writing it to the file.

  ## Notes

    - The function uses the `Jason` library for JSON encoding.
    - In case of any error during file writing or JSON encoding, an exception will be raised due to the use of `File.write!` and `Jason.encode!`.

  ## Example

      iex> write_file(%{"last_complete_id" => 5, "transactions_list" => [%{"id" => 1}, %{"id" => 2}]})
      %{"last_complete_id" => 5, "transactions_list" => [%{"id" => 1}, %{"id" => 2}]}

  """
  def write_file(data) do
    File.write!("log_coordinator.json", Jason.encode!(data))
    data
  end
end
