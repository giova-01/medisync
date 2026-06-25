from pydantic import BaseModel


class DeviceDto(BaseModel):
    id: str  # mac_address
    name: str
    rssi: int = 0
    is_connected: bool = False


class LinkDeviceRequest(BaseModel):
    mac_address: str
    nombre: str
    firmware_version: str | None = None
    nivel_bateria: int | None = None
