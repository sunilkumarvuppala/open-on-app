"""
Error handling service for consistent error message extraction and formatting.

This service centralizes error handling logic to eliminate duplication
and ensure consistent user-friendly error messages across the application.
"""
import json
from typing import Optional
from app.utils.helpers import make_user_friendly_error
from app.core.logging import get_logger

logger = get_logger(__name__)


class ErrorService:
    """Service for extracting and formatting error messages from various sources."""
    
    @staticmethod
    def extract_supabase_error(response_text: str, status_code: int) -> str:
        """
        Extract user-friendly error message from Supabase API response.
        
        Args:
            response_text: Raw response text from Supabase
            status_code: HTTP status code from response
            
        Returns:
            User-friendly error message
        """
        error_detail: Optional[str] = None
        
        try:
            error_json = json.loads(response_text)
            
            logger.debug(f"Supabase error response: {error_json}")
            
            # Try multiple fields that Supabase might use for error messages
            error_detail = (
                error_json.get("message") or 
                error_json.get("error_description") or 
                error_json.get("error") or
                error_json.get("msg")
            )
            
            # Try nested errors array
            if not error_detail and "errors" in error_json:
                errors = error_json.get("errors", [])
                if errors and isinstance(errors, list) and len(errors) > 0:
                    first_error = errors[0]
                    if isinstance(first_error, dict):
                        error_detail = (
                            first_error.get("message") or 
                            first_error.get("msg") or 
                            first_error.get("error")
                        )
                    elif isinstance(first_error, str):
                        error_detail = first_error
            
            # Try error_hint or error_code
            if not error_detail:
                error_detail = error_json.get("error_hint") or error_json.get("error_code")
                
        except (json.JSONDecodeError, AttributeError, TypeError) as e:
            logger.debug(f"Failed to parse error response as JSON: {e}")
        
        # If still no detail, check raw response text for common patterns
        if not error_detail and response_text:
            error_lower = response_text.lower()
            if "email" in error_lower and "already" in error_lower:
                error_detail = "This email is already registered"
            elif "password" in error_lower:
                if "weak" in error_lower or "strength" in error_lower:
                    error_detail = "Password is too weak. Please use a stronger password."
                elif "length" in error_lower or "short" in error_lower:
                    error_detail = "Password is too short. Please use at least 8 characters."
                else:
                    error_detail = "Invalid password. Please check your password and try again."
            elif "invalid" in error_lower:
                error_detail = "Invalid input. Please check your information and try again."
        
        # Default error message based on status code
        if not error_detail:
            if status_code == 422:
                error_detail = "Invalid information provided. Please check all fields and try again."
            elif status_code == 400:
                error_detail = "Invalid request. Please check your input and try again."
            elif status_code == 409:
                error_detail = "This email is already registered. Please use a different email or log in."
            elif status_code == 403:
                error_detail = "Authentication failed. Please contact support if this issue persists."
            else:
                error_detail = "Unable to create account. Please try again."
        else:
            # Make error message user-friendly
            error_detail = make_user_friendly_error(error_detail)
        
        return error_detail
    
    @staticmethod
    def get_signup_error_message(exception: Exception) -> str:
        """
        Extract user-friendly error message from signup exception.
        
        Args:
            exception: Exception raised during signup
            
        Returns:
            User-friendly error message
        """
        error_msg = str(exception).lower()
        
        if "email" in error_msg and "already" in error_msg:
            return "This email is already registered. Please use a different email or log in."
        elif "username" in error_msg and "already" in error_msg:
            return "This username is already taken. Please choose a different username."
        elif "password" in error_msg:
            return "Invalid password. Please check your password and try again."
        else:
            return "Unable to create account. Please check your information and try again."
