"""mobile-push: Hermes turn and approval events as push notifications for Hermes Mobile."""

from .notifier import Notifier


def register(ctx) -> None:
    notifier = Notifier(ctx.get_config)
    ctx.register_hook("on_session_end", notifier.on_session_end)
    ctx.register_hook("on_human_input_request", notifier.on_human_input_request)
    ctx.register_hook("on_human_input_resolved", notifier.on_human_input_resolved)
