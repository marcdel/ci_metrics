defmodule DateConversion do
  def to_date_time(date) do
    # Alternative implementation
    #    {Date.to_erl(date), {0, 0, 0}}
    #      |> NaiveDateTime.from_erl!
    #      |> DateTime.from_naive!("Etc/UTC")

    {:ok, date_time, _} =
      (Date.to_iso8601(date) <> "T00:00:00Z")
      |> DateTime.from_iso8601()

    date_time
  end
end
