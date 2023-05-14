# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule Connect4Web.PlayerSettingsLive do
  @moduledoc false
  use Connect4Web, :live_view

  alias Connect4.Auth
  alias Connect4.Auth.Queries.PlayerQueries

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account email address and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div :if={is_nil(@current_player.confirmed_at)} class="pt-8">
        <p class="mb-4">
          Your account hasn’t been confirmed yet, so you won’t appear in the
          tournament. If you didn’t get the email, you can try resending it.
        </p>
        <.button phx-click="resend-confirmation" phx-disable-with="Sending...">
          Resend Confirmation Email
        </.button>
      </div>
      <div class="pt-8">
        <p class="mb-4">
          If you think someone else is using your player code nefariously
          (note: this is highly frowned on!), you can generate a new one.
        </p>
        <.button phx-click="regenerate-code" phx-disable-with="Sending...">
          Regenerate Player Code
        </.button>
      </div>
      <div>
        <.simple_form
          for={@email_form}
          id="email_form"
          phx-submit="update_email"
          phx-change="validate_email"
        >
          <.input field={@email_form[:email]} type="email" label="Email" required />
          <.input
            field={@email_form[:current_password]}
            name="current_password"
            id="current_password_for_email"
            type="password"
            label="Current password"
            value={@email_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Email</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/players/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:email]}
            type="hidden"
            id="hidden_player_email"
            value={@current_email}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Auth.update_player_email(socket.assigns.current_player, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/players/settings")}
  end

  def mount(_params, _session, socket) do
    player = socket.assigns.current_player
    email_changeset = Auth.change_player_email(player)
    password_changeset = Auth.change_player_password(player)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, player.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("resend-confirmation", _params, socket) do
    player = socket.assigns.current_player
    Auth.deliver_player_confirmation_instructions(player, &url(~p"/players/confirm/#{&1}"))

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply, put_flash(socket, :info, info)}
  end

  def handle_event("regenerate-code", _params, socket) do
    PlayerQueries.regenerate_code(socket.assigns.current_player)
    info = "Your player code has been regenerated. You can find the new code on the home page."
    {:noreply, put_flash(socket, :info, info)}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "player" => player_params} = params

    email_form =
      socket.assigns.current_player
      |> Auth.change_player_email(player_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    player = socket.assigns.current_player

    case Auth.apply_player_email(player, password, player_params) do
      {:ok, applied_player} ->
        Auth.deliver_player_update_email_instructions(
          applied_player,
          player.email,
          &url(~p"/players/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."

        {:noreply,
         socket
         |> put_flash(:info, info)
         |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "player" => player_params} = params

    password_form =
      socket.assigns.current_player
      |> Auth.change_player_password(player_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "player" => player_params} = params
    player = socket.assigns.current_player

    case Auth.update_player_password(player, password, player_params) do
      {:ok, player} ->
        password_form =
          player
          |> Auth.change_player_password(player_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
