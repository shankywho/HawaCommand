"""Geography, administrative boundaries, grid cells, and POIs."""
from typing import Optional
from sqlalchemy import Float, Integer, String, Boolean, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..base import Base, TimestampMixin


class Ward(Base, TimestampMixin):
    """MCD municipal administrative ward boundary."""
    __tablename__ = "ward"

    ward_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(128), nullable=False)
    zone: Mapped[str] = mapped_column(String(64), nullable=False)
    population: Mapped[int] = mapped_column(Integer, default=0)
    centroid_lat: Mapped[float] = mapped_column(Float, nullable=False)
    centroid_lon: Mapped[float] = mapped_column(Float, nullable=False)


class Cell500m(Base, TimestampMixin):
    """500 m digital twin computational cell."""
    __tablename__ = "cell_500m"

    cell_id: Mapped[str] = mapped_column(String(32), primary_key=True)  # g500-xxx-yyy
    cell_1km_id: Mapped[str] = mapped_column(String(32), index=True, nullable=False)
    ward_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("ward.ward_id"), nullable=True, index=True)
    row: Mapped[int] = mapped_column(Integer, nullable=False)
    col: Mapped[int] = mapped_column(Integer, nullable=False)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lon: Mapped[float] = mapped_column(Float, nullable=False)
    population: Mapped[int] = mapped_column(Integer, default=0)
    is_key_cell: Mapped[bool] = mapped_column(Boolean, default=False)


class School(Base, TimestampMixin):
    """School location monitored for children's exposure."""
    __tablename__ = "school"

    school_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(256), nullable=False)
    ward_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("ward.ward_id"), nullable=True)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lon: Mapped[float] = mapped_column(Float, nullable=False)
    assembly_time: Mapped[str] = mapped_column(String(16), default="08:00")
    contact_phone: Mapped[Optional[str]] = mapped_column(String(32), nullable=True)


class Site(Base, TimestampMixin):
    """Monitored construction site or industrial unit."""
    __tablename__ = "site"

    site_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(256), nullable=False)
    ward_id: Mapped[Optional[str]] = mapped_column(String(64), ForeignKey("ward.ward_id"), nullable=True)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lon: Mapped[float] = mapped_column(Float, nullable=False)
    compliance_grade: Mapped[str] = mapped_column(String(8), default="B")


class ReferenceStation(Base, TimestampMixin):
    """Regulatory monitoring station (CPCB / DPCC / OpenAQ)."""
    __tablename__ = "reference_station"

    station_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(256), nullable=False)
    source: Mapped[str] = mapped_column(String(32), default="CPCB")
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lon: Mapped[float] = mapped_column(Float, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
