"""Notification service for push notifications and emails."""
from abc import ABC, abstractmethod
from typing import Optional
from app.core.logging import get_logger


logger = get_logger(__name__)


class NotificationProvider(ABC):
    """Abstract base class for notification providers."""
    
    @abstractmethod
    async def send_push(
        self,
        user_id: str,
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> bool:
        """Send a push notification."""
        pass
    
    @abstractmethod
    async def send_email(
        self,
        to_email: str,
        subject: str,
        body: str,
        html: Optional[str] = None
    ) -> bool:
        """Send an email notification."""
        pass


class MockNotificationProvider(NotificationProvider):
    """Mock notification provider for development/testing."""
    
    async def send_push(
        self,
        user_id: str,
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> bool:
        """Mock push notification."""
        logger.info(f"📱 [MOCK PUSH] To: {user_id} | {title}: {body}")
        return True
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        body: str,
        html: Optional[str] = None
    ) -> bool:
        """Mock email notification."""
        logger.info(f"📧 [MOCK EMAIL] To: {to_email} | Subject: {subject}")
        return True


class FCMNotificationProvider(NotificationProvider):
    """Firebase Cloud Messaging notification provider."""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        # TODO: Initialize FCM client
    
    async def send_push(
        self,
        user_id: str,
        title: str,
        body: str,
        data: Optional[dict] = None
    ) -> bool:
        """Send push via FCM."""
        # TODO: Implement FCM integration
        logger.info(f"📱 [FCM PUSH] To: {user_id} | {title}: {body}")
        return True
    
    async def send_email(
        self,
        to_email: str,
        subject: str,
        body: str,
        html: Optional[str] = None
    ) -> bool:
        """FCM doesn't support email."""
        raise NotImplementedError("FCM doesn't support email notifications")


class NotificationService:
    """High-level notification service."""
    
    def __init__(self, provider: NotificationProvider):
        self.provider = provider
    
    async def notify_capsule_ready(
        self,
        receiver_id: str,
        receiver_email: str,
        capsule_title: str,
        sender_name: str
    ) -> bool:
        """Notify user that a capsule is ready to open."""
        title = "📬 Time Capsule Ready!"
        body = f"{sender_name} sent you '{capsule_title}' - it's ready to open!"
        
        # Send push notification
        await self.provider.send_push(
            user_id=receiver_id,
            title=title,
            body=body,
            data={"type": "capsule_ready", "capsule_title": capsule_title}
        )
        
        # Send email notification
        email_body = f"""
        Hello!
        
        You have a time capsule ready to open from {sender_name}.
        
        Title: {capsule_title}
        
        Open your OpenOn app to view your capsule!
        
        Best regards,
        The OpenOn Team
        """
        
        await self.provider.send_email(
            to_email=receiver_email,
            subject=title,
            body=email_body
        )
        
        return True
    
    async def notify_capsule_unfolding(
        self,
        receiver_id: str,
        receiver_email: str,
        capsule_title: str,
        days_remaining: int
    ) -> bool:
        """Notify user that a capsule is entering unfolding state."""
        title = "⏰ Time Capsule Almost Ready"
        body = f"'{capsule_title}' will be ready to open in {days_remaining} days!"
        
        await self.provider.send_push(
            user_id=receiver_id,
            title=title,
            body=body,
            data={"type": "capsule_unfolding", "days_remaining": days_remaining}
        )
        
        return True


# Global service instance (using mock by default)
_notification_service: Optional[NotificationService] = None


def get_notification_service() -> NotificationService:
    """Get or create the notification service."""
    global _notification_service
    if _notification_service is None:
        # Use mock provider by default
        # In production, check config and use appropriate provider
        from app.core.config import settings
        
        if settings.fcm_api_key:
            provider = FCMNotificationProvider(settings.fcm_api_key)
        else:
            provider = MockNotificationProvider()
        
        _notification_service = NotificationService(provider)
    
    return _notification_service
