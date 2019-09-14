defmodule CiMetrics.HTTPClient do
  @callback post(String.t(), Mojito.headers(), String.t(), Keyword.t()) ::
              {:ok, Mojito.response()} | {:error, Mojito.error()} | no_return
  def post(url, headers \\ [], payload \\ "", opts \\ []) do
    Mojito.post(url, headers, payload, opts)
  end
end
