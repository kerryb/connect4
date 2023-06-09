# credo:disable-for-this-file Credo.Check.Readability.Specs
# credo:disable-for-this-file Credo.Check.Refactor.ModuleDependencies
defmodule Connect4.Auth.Schema.Player do
  @moduledoc """
  Details of a player (or pair, team etc).

  A unique code is generated for each player, which will map to their personal
  API URL.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Connect4.Auth.Schema.Player
  alias Connect4.Game.Schema.Game
  alias Connect4.Repo
  alias Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "players" do
    field(:email, :string)
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)
    field(:confirmed_at, :naive_datetime)
    field(:name, :string)
    field(:code, :string)
    field(:admin, :boolean)
    field(:played, :integer, virtual: true)
    field(:won, :integer, virtual: true)
    field(:tied, :integer, virtual: true)
    field(:lost, :integer, virtual: true)
    field(:points, :integer, virtual: true)
    field(:currently_playing, :boolean, virtual: true)

    has_many(:games_as_o, Game, foreign_key: :player_o_id)
    has_many(:games_as_x, Game, foreign_key: :player_x_id)

    timestamps()
  end

  @doc """
  A player changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(player, attrs, opts \\ []) do
    player
    |> create_random_code()
    |> cast(attrs, [:email, :name, :password])
    |> validate_email(opts)
    |> validate_name(opts)
    |> validate_password(opts)
  end

  @spec create_random_code(t() | Changeset.t(t())) :: Changeset.t(t())
  def create_random_code(player) do
    change(player, %{code: for(_n <- 0..6, into: "", do: <<Enum.random(?A..?Z)>>)})
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_name(changeset, opts) do
    changeset
    |> validate_required([:name])
    |> validate_length(:name, max: 40)
    |> maybe_validate_unique_name(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_name(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:name, Repo)
      |> unique_constraint(:name)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A player changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _email}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A player changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(player, attrs, opts \\ []) do
    player
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(player) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    change(player, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no player or the player doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Player{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_player, _password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  Calculates played/won/tied/lost stats and populates the virtual fields.
  """
  def calculate_stats(player) do
    player_with_games = Repo.preload(player, games_as_o: [:player_o, :player_x], games_as_x: [:player_o, :player_x])
    played = played(player_with_games)
    won = won(player_with_games)
    tied = tied(player_with_games)
    lost = lost(player_with_games)
    points = 3 * won + tied
    %{player_with_games | played: played, won: won, tied: tied, lost: lost, points: points}
  end

  defp played(player) do
    Enum.count(player.games_as_o, &(not is_nil(&1.winner))) +
      Enum.count(player.games_as_x, &(not is_nil(&1.winner)))
  end

  defp won(player) do
    Enum.count(player.games_as_o, &(&1.winner == "O")) +
      Enum.count(player.games_as_x, &(&1.winner == "X"))
  end

  defp tied(player) do
    Enum.count(player.games_as_o, &(&1.winner == "tie")) +
      Enum.count(player.games_as_x, &(&1.winner == "tie"))
  end

  defp lost(player) do
    Enum.count(player.games_as_o, &(&1.winner == "X")) +
      Enum.count(player.games_as_x, &(&1.winner == "O"))
  end
end
