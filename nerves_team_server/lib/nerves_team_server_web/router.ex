defmodule NervesTeamServerWeb.Router do
  use NervesTeamServerWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", NervesTeamServerWeb do
    pipe_through :api
  end
end
