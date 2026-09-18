from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, model_validator

from .models import PropertyMode, PropertyStatus, PropertyType, UserRole


class UserCreate(BaseModel):
    jina_kamili: str = Field(min_length=2, max_length=150)
    namba_ya_simu: str = Field(min_length=7, max_length=30)
    username: str = Field(min_length=3, max_length=50)
    password: str = Field(min_length=8, max_length=128)
    role: UserRole
    email: EmailStr | None = None
    eneo: str | None = Field(default=None, max_length=150)

    @model_validator(mode="after")
    def seller_fields_required(self):
        if self.role == UserRole.SELLER and (self.email is None or not self.eneo):
            raise ValueError("Seller lazima awe na email na eneo")
        return self


class LoginRequest(BaseModel):
    username: str
    password: str


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    jina_kamili: str
    namba_ya_simu: str
    username: str
    email: EmailStr | None
    role: UserRole
    is_admin: bool
    eneo: str | None
    created_at: datetime


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class PropertyResponse(BaseModel):
    """Response kamili yenye verification_doc_url.

    TUMIA HII TU kwa endpoints zenye auth ambapo mwenye tangazo (seller)
    anaona taarifa zake mwenyewe (create_property, /properties/mine).
    USITUMIE kwa endpoints za public - tumia PublicPropertyResponse.
    """
    model_config = ConfigDict(from_attributes=True)
    id: int
    owner_id: int
    jina: str
    aina: PropertyType
    mode: PropertyMode
    price: int
    location_label: str
    latitude: float
    longitude: float
    has_wifi: bool
    description: str
    photo_urls: list[str]
    verification_doc_url: str | None
    status: PropertyStatus
    created_at: datetime
    expires_at: datetime | None


class PublicPropertyResponse(BaseModel):
    """Response ya public - HAINA verification_doc_url.

    TUMIA HII kwa endpoints zozote zinazoweza kufikiwa na buyer/umma
    (GET /properties, GET /properties/{id}, FavoriteResponse.property).
    """
    model_config = ConfigDict(from_attributes=True)
    id: int
    owner_id: int
    jina: str
    aina: PropertyType
    mode: PropertyMode
    price: int
    location_label: str
    latitude: float
    longitude: float
    has_wifi: bool
    description: str
    photo_urls: list[str]
    status: PropertyStatus
    created_at: datetime
    expires_at: datetime | None


class FavoriteResponse(BaseModel):
    id: int
    property_id: int
    created_at: datetime
    property: PublicPropertyResponse


class PropertyWithOwnerResponse(PublicPropertyResponse):
    owner_jina: str
    owner_simu: str


class AnalyticsPoint(BaseModel):
    period: str
    buyer: int = 0
    seller: int = 0
    total: int = 0


class AnalyticsSummary(BaseModel):
    total_buyers: int
    total_sellers: int
    total_users: int
    pending_properties: int
    registrations_today: int
    registrations_this_week: int
    registrations_this_month: int
    registrations_this_year: int
    logins_today: int
    logins_this_week: int
    logins_this_month: int
    logins_this_year: int
