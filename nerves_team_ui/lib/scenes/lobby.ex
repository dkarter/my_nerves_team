defmodule NervesTeamUI.Scene.Lobby do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias PhoenixClient.Socket
  alias PhoenixClient.Channel
  alias PhoenixClient.Message

  import Scenic.Primitives
  # import Scenic.Components

  require Logger

  @note """
  Lobby
  """

  @action_key " "

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    ScenicFontPressStart2p.load()

    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)
    center = {0.5 * vp_width, 0.5 * vp_height}

    {:ok, _reply, channel} = Channel.join(Socket, "game:lobby")

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: 8)
      |> text(
        @note,
        id: :title,
        text_align: :center,
        translate: center
      )
      |> push_graph()

    {
      :ok,
      %{
        graph: graph,
        viewport: viewport,
        channel: channel
      }
    }
  end

  def handle_info(
        %Message{event: "player:list", payload: %{"players" => players}},
        state
      ) do
    player_ids = Enum.map(players, &Map.get(&1, "id")) |> Enum.join(",")
    {:noreply, update(:title, player_ids, state)}
  end

  def handle_info(%Message{event: "game:start", payload: payload}, state) do
    ViewPort.set_root(
      state.viewport,
      {NervesTeamUI.Scene.Game, payload}
    )

    {:noreply, state}
  end

  def handle_info(%Message{event: event}, state) when event in ["phx_error", "phx_close"] do
    ViewPort.set_root(
      state.viewport,
      {NervesTeamUI.Scene.Home, nil}
    )

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.debug("Unhandled message: #{inspect(message)}")
    {:noreply, state}
  end

  def handle_input({:key, {@action_key, action, _}}, _context, state)
      when action in [:press, :release] do
    ready? = action == :press
    Channel.push(state.channel, "player:ready", %{ready: ready?})
    {:noreply, state}
  end

  def handle_input(_event, _context, state) do
    # we don't care about these events
    {:noreply, state}
  end

  defp update(element, text, state) do
    graph =
      state.graph
      |> Graph.modify(element, &text(&1, text))
      |> push_graph()

    %{state | graph: graph}
  end
end
