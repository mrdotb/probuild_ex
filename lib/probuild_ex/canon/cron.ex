defmodule ProbuildEx.Canon.Cron do
  @moduledoc """
  Will run our Module Fun Args in a Cron fashion
  """
  use GenServer, restart: :transient

  require Logger

  def start_link({delay, mfa}) do
    GenServer.start_link(__MODULE__, {delay, mfa, 0})
  end

  @impl true
  def init(args) do
    {:ok, args, {:continue, :schedule_next_run}}
  end

  @impl true
  def handle_continue(:schedule_next_run, {delay, mfa, 0}) do
    send(self(), :perform_work)
    {:noreply, {delay, mfa, 0}}
  end

  def handle_continue(:schedule_next_run, {delay, mfa, num}) do
    Process.send_after(self(), :perform_work, delay)
    {:noreply, {delay, mfa, num}}
  end

  @impl true
  def handle_info(:perform_work, {delay, {module, fun, args} = mfa, num}) do
    Logger.info("Canon #{module} #{args} num #{num} started")

    {time, _result} =
      :timer.tc(fn ->
        apply(module, fun, args)
      end)

    Logger.info("Canon #{module} #{args} num #{num} finished in #{to_milli(time)} ms")

    {:noreply, {delay, mfa, num + 1}, {:continue, :schedule_next_run}}
  end

  defp to_milli(microsecond) do
    System.convert_time_unit(microsecond, :microsecond, :millisecond)
  end
end
