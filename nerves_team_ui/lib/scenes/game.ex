defmodule NervesTeamUI.Scene.Game do
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
  Get Ready!
  """

  @action_key ["A", "S"]

  @action_key " "

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(payload, opts) do
    ScenicFontPressStart2p.load()

    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    %{"game_id" => game_id} = payload

    {:ok, _reply, channel} = Channel.join(Socket, "game:" <> game_id, payload)

    top = {0.5 * vp_width, 0.25 * vp_height}
    left = {0.25 * vp_width, 0.75 * vp_height}
    right = {0.75 * vp_width, 0.75 * vp_height}

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: 8)
      |> text(
        @note,
        id: :title,
        text_align: :center,
        translate: top
      )
      |> text("", id: :action1, text_align: :center, translate: left)
      |> text("", id: :action2, text_align: :center, translate: right)
      |> push_graph()

    {:ok, %{graph: graph, actions: [], viewport: viewport, channel: channel}}
  end

  def handle_info(
        %Message{event: "actions:assigned", payload: payload},
        state
      ) do
    %{"actions" => actions} = payload
    state = update(:action1, Enum.at(actions, 0)["title"], state)
    state = update(:action2, Enum.at(actions, 1)["title"], state)
    {:noreply, %{state | actions: actions}}
  end

  def handle_info(%Message{event: "game:ended", payload: payload}, state) do
    :timer.apply_after(5_000, ViewPort, :set_root, [
      state.viewport,
      {NervesTeamUI.Scene.Home, nil}
    ])

    text = if payload["win?"], do: "You win", else: "You lose"
    {:noreply, update(:title, text, state)}
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

  def handle_input({:key, {key, action, _}}, _context, state)
      when action in [:press, :release] and key in @action_key do
    index = Enum.find_index(@action_key, &(&1 == key))
    action = Enum.at(state.actions, index)
    Channel.push(state.channel, "action:execute", action)
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
