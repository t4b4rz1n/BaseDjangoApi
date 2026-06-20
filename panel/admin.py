from django.contrib import admin

from .Feedback.models import Feedback
from .Notification.models import Notification
from .Ticketing.models import Attachment, Message, Ticket, TicketType

admin.site.register(TicketType)
admin.site.register(Ticket)
admin.site.register(Message)
admin.site.register(Attachment)
admin.site.register(Notification)
admin.site.register(Feedback)
