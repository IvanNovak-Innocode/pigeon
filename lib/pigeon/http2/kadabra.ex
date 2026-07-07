defmodule Pigeon.Http2.Client.Kadabra do
  @moduledoc false

  @behaviour Pigeon.Http2.Client

  def start do
    Application.ensure_all_started(:kadabra)
  end

  def connect(uri, scheme, opts) do
    url = "#{scheme}://#{uri}"
    host = URI.parse(url).host || uri
    host_charlist = String.to_charlist(host)

    ssl_opts =
      opts
      |> Keyword.delete(:server_name_indication)
      |> Keyword.delete(:customize_hostname_check)
      |> Keyword.put(:server_name_indication, host_charlist)
      |> Keyword.put(:customize_hostname_check,
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      )

    Kadabra.open(url, ssl: ssl_opts)
  end

  def send_request(pid, headers, data) do
    Kadabra.request(pid, headers: headers, body: data)
  end

  def send_ping(pid) do
    Kadabra.ping(pid)
  end

  def handle_end_stream({:end_stream, stream}, _state) do
    %{id: id, status: status, headers: headers, body: body} = stream

    pigeon_stream = %Pigeon.Http2.Stream{
      id: id,
      status: status,
      headers: headers,
      body: body
    }

    {:ok, pigeon_stream}
  end

  def handle_end_stream(msg, _state) do
    msg
  end
end
