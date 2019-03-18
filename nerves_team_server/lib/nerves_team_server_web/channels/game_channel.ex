defmodule NervesTeamServerWeb.GameChannel do
  use NervesTeamServerWeb, :channel

  alias NervesTeamGame.{Lobby, Game}

  def join("game:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, player} = Lobby.add_player()
      {:ok, assign(socket, :player, player)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def join("game:" <> game_id, %{"player_id" => player_id}, socket) do
    {:ok, player} = Game.player_join(game_id, player_id)
    {:ok, assign(socket, :player, player)}
  end

  def handle_in("player:ready", %{"ready" => ready?}, socket) do
    {:ok, _player} = Lobby.ready_player(socket.assigns.player.id, ready?)
    {:reply, :ok, socket}
  end

  def handle_in("action:execute", action, %{topic: "game:" <> game_id} = socket) do
    Game.action_execute(game_id, action)
    {:reply, :ok, socket}
  end

  # Pass messages from game server to the client
  def handle_info({event, payload}, socket) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
