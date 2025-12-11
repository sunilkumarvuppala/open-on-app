"""
Application-wide constants.

All magic numbers and hardcoded values should be defined here.
This ensures consistency and makes configuration changes easier.
"""
# URL length limits
MAX_URL_LENGTH = 500  # Reasonable URL length for avatar_url and similar fields

# Default relationship
DEFAULT_RECIPIENT_RELATIONSHIP = "friend"

# Connection request constraints
MAX_CONNECTION_MESSAGE_LENGTH = 500  # Maximum length for connection request message
MAX_DECLINED_REASON_LENGTH = 500  # Maximum length for decline reason
MAX_DAILY_CONNECTION_REQUESTS = 5  # Maximum connection requests per day per user
CONNECTION_COOLDOWN_DAYS = 7  # Days to wait after decline before retry

# Query limits
DEFAULT_QUERY_LIMIT = 50  # Default limit for list queries
MAX_QUERY_LIMIT = 100  # Maximum limit for list queries
MIN_QUERY_LIMIT = 1  # Minimum limit for list queries

# Search constraints
DEFAULT_SEARCH_LIMIT = 10  # Default search results limit
MAX_SEARCH_LIMIT = 50  # Maximum search results limit

# Theme constraints
MAX_THEME_NAME_LENGTH = 50  # Maximum theme name length

