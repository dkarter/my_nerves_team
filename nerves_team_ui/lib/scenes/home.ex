defmodule NervesTeamUI.Scene.Home do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives
  # import Scenic.Components

  @note """
  NervesTeam
  """

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(_, opts) do
    ScenicFontPressStart2p.load()

    viewport = opts[:viewport]
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)
    center = {0.5 * vp_width, 0.5 * vp_height}

    graph =
      Graph.build(font: ScenicFontPressStart2p.hash(), font_size: 8)
      |> text(@note, text_align: :center, translate: center)
      |> push_graph()

    {send(self(), :connect)}

    {:ok, %{graph: graph, viewport: viewport}}
  end

  def handle_info(:connect, %{viewport: viewport} = state) do
    if PhoenixClient.Socket.connected?(PhoenixClient.Socket) do
      ViewPort.set_root(
        viewport,
        {NervesTeamUI.Scene.Lobby, nil}
      )
    else
      Process.send_after(self(), :connect, 1_000)
    end

    {:noreply, state}
  end
end
