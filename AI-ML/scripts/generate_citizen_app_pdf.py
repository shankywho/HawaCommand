"""Generator script for HawaCitizen Comprehensive Product Specification & Innovation Blueprint PDF.
Outputs a high-quality multi-page technical document using ReportLab.
"""
from pathlib import Path
import os
import sys
from datetime import datetime

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
    PageBreak,
    KeepTogether,
    HRFlowable,
)
from reportlab.pdfgen import canvas

# Palette definition
COLOR_PRIMARY = colors.HexColor("#0B2545")    # Deep Navy
COLOR_SECONDARY = colors.HexColor("#134074")  # Slate Blue
COLOR_ACCENT = colors.HexColor("#00A896")     # Emerald / Teal
COLOR_ACCENT_BG = colors.HexColor("#E6FFFA")  # Light Teal BG
COLOR_DARK = colors.HexColor("#1E293B")       # Charcoal Body
COLOR_LIGHT_BG = colors.HexColor("#F8FAFC")   # Off-white / Card BG
COLOR_BORDER = colors.HexColor("#CBD5E1")     # Gray border
COLOR_ALERT = colors.HexColor("#E63946")      # Crimson Red
COLOR_ALERT_BG = colors.HexColor("#FDF2F2")   # Light Crimson BG
COLOR_AMBER = colors.HexColor("#D97706")      # Amber
COLOR_AMBER_BG = colors.HexColor("#FEF3C7")   # Light Amber BG
COLOR_MUTED = colors.HexColor("#64748B")      # Muted slate


class NumberedCanvas(canvas.Canvas):
    """Two-pass canvas to dynamically compute and print 'Page X of Y' and running headers/footers."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_decorations(self, page_count):
        self.saveState()
        
        # Omit top header on cover page (page 1)
        if self._pageNumber > 1:
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(COLOR_SECONDARY)
            self.drawString(36, 762, "HAWACITIZEN  |  PRODUCT SPECIFICATION & INNOVATION BLUEPRINT")
            self.setFont("Helvetica", 8)
            self.setFillColor(COLOR_MUTED)
            self.drawRightString(576, 762, "Environmental Hacks 2026 - Bharat Builds")
            
            # Subtle header accent line
            self.setStrokeColor(COLOR_BORDER)
            self.setLineWidth(0.6)
            self.line(36, 755, 576, 755)

        # Footer across all pages
        self.setStrokeColor(COLOR_BORDER)
        self.setLineWidth(0.6)
        self.line(36, 42, 576, 42)

        self.setFont("Helvetica", 7.5)
        self.setFillColor(COLOR_MUTED)
        self.drawString(36, 30, "Mission_CleanTheAir  -  HawaCommand Citizen Ecosystem  -  Confidential / Hackathon Submission")
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(576, 30, page_str)

        self.restoreState()


def make_card(flowables, bg_color=COLOR_LIGHT_BG, border_color=COLOR_BORDER, pad=10, width=540):
    """Encapsulates content in a clean bordered card with rounded looks."""
    t = Table([[flowables]], colWidths=[width])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), bg_color),
        ('BOX', (0,0), (-1,-1), 0.75, border_color),
        ('TOPPADDING', (0,0), (-1,-1), pad),
        ('BOTTOMPADDING', (0,0), (-1,-1), pad),
        ('LEFTPADDING', (0,0), (-1,-1), pad),
        ('RIGHTPADDING', (0,0), (-1,-1), pad),
    ]))
    return t


def build_pdf(output_path: Path):
    doc = SimpleDocTemplate(
        str(output_path),
        pagesize=letter,
        leftMargin=36,
        rightMargin=36,
        topMargin=48,
        bottomMargin=54,
    )

    styles = getSampleStyleSheet()

    # Custom typography
    styles.add(ParagraphStyle(
        name='DocTitle',
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=COLOR_PRIMARY,
        spaceAfter=4,
    ))
    styles.add(ParagraphStyle(
        name='DocSubtitle',
        fontName='Helvetica',
        fontSize=12,
        leading=16,
        textColor=COLOR_SECONDARY,
        spaceAfter=12,
    ))
    styles.add(ParagraphStyle(
        name='SectionHeader',
        fontName='Helvetica-Bold',
        fontSize=14,
        leading=18,
        textColor=COLOR_PRIMARY,
        spaceBefore=14,
        spaceAfter=6,
        keepWithNext=True,
    ))
    styles.add(ParagraphStyle(
        name='SubSectionHeader',
        fontName='Helvetica-Bold',
        fontSize=11,
        leading=15,
        textColor=COLOR_SECONDARY,
        spaceBefore=10,
        spaceAfter=4,
        keepWithNext=True,
    ))
    styles.add(ParagraphStyle(
        name='BodyRegular',
        fontName='Helvetica',
        fontSize=9,
        leading=13,
        textColor=COLOR_DARK,
        spaceAfter=6,
    ))
    styles.add(ParagraphStyle(
        name='BodyBold',
        fontName='Helvetica-Bold',
        fontSize=9,
        leading=13,
        textColor=COLOR_DARK,
        spaceAfter=6,
    ))
    styles.add(ParagraphStyle(
        name='BulletItem',
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=COLOR_DARK,
        leftIndent=12,
        firstLineIndent=-8,
        spaceAfter=3,
    ))
    styles.add(ParagraphStyle(
        name='CardHeader',
        fontName='Helvetica-Bold',
        fontSize=10,
        leading=14,
        textColor=COLOR_PRIMARY,
        spaceAfter=4,
    ))
    styles.add(ParagraphStyle(
        name='CardBody',
        fontName='Helvetica',
        fontSize=8.5,
        leading=12,
        textColor=COLOR_DARK,
        spaceAfter=2,
    ))
    styles.add(ParagraphStyle(
        name='MetaBadge',
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.white,
    ))
    styles.add(ParagraphStyle(
        name='TableHeader',
        fontName='Helvetica-Bold',
        fontSize=8.5,
        leading=11,
        textColor=colors.white,
        alignment=1,
    ))
    styles.add(ParagraphStyle(
        name='TableCell',
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=COLOR_DARK,
    ))
    styles.add(ParagraphStyle(
        name='TableCellBold',
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=11,
        textColor=COLOR_DARK,
    ))
    styles.add(ParagraphStyle(
        name='QuoteText',
        fontName='Helvetica-Oblique',
        fontSize=9,
        leading=13,
        textColor=COLOR_SECONDARY,
    ))

    story = []

    # ==========================================
    # PAGE 1: COVER & EXECUTIVE BLUEPRINT
    # ==========================================
    # Top Category Pill
    pill_data = [[
        Paragraph("<font color='#00A896'><b>HAWACOMMAND CITIZEN ECOSYSTEM</b></font>  |  <b>BHARAT BUILDS 2026 - TRACK 01: AIR</b>", styles['TableCell'])
    ]]
    pill_table = Table(pill_data, colWidths=[540])
    pill_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), COLOR_ACCENT_BG),
        ('BOX', (0,0), (-1,-1), 1, COLOR_ACCENT),
        ('PADDING', (0,0), (-1,-1), 5),
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
    ]))
    story.append(pill_table)
    story.append(Spacer(1, 12))

    story.append(Paragraph("HawaCitizen: AI-Powered Citizen Air Intelligence & Civic Action Platform", styles['DocTitle']))
    story.append(Paragraph("Complete Technical Whitepaper, Feature Architecture, Civic Accountability Systems & Hackathon Winning Blueprint", styles['DocSubtitle']))
    story.append(HRFlowable(width="100%", thickness=1.5, color=COLOR_ACCENT, spaceBefore=2, spaceAfter=10))

    # Executive Summary Card
    exec_text = [
        Paragraph("<b>EXECUTIVE OVERVIEW: THE CITIZEN PARADOX IN DELHI</b>", styles['CardHeader']),
        Paragraph(
            "Every winter, 30 million residents across Delhi NCR face catastrophic air quality spikes (PM2.5 > 400 µg/m³). "
            "Yet today, citizens remain trapped in a state of <i>passive helplessness</i>. They open consumer weather apps, see a terrifying "
            "red AQI dial, close their windows, and suffer. Crucially, they possess <b>no street-level truth</b>, <b>no route-level protection</b>, "
            "and <b>zero visibility into whether millions spent on government anti-smog guns and sprinklers actually did anything</b>.<br/><br/>"
            "<b>HawaCitizen</b> completely disrupts this broken paradigm. Built directly on top of the HawaCommand digital twin, exposure engine, "
            "and IoT telemetry mesh, HawaCitizen transforms passive victims into active civic guardians through four breakthrough pillars:<br/>"
            "1. <b>Hyperlocal Digital Twin & Explainable AQI:</b> Real-time 500-meter street-level resolution with causal source attribution.<br/>"
            "2. <b>Safe Air Navigator:</b> World's first lung-optimized route planner calculating inhaled particulate dose (µg) for commuters.<br/>"
            "3. <b>Live Work Tracking & Proof-of-Spray:</b> Real-time map of active municipal machinery backed by synthetic-control causal verification.<br/>"
            "4. <b>Civic Eyes & The 'No-Ghost-Worker' Audit Engine:</b> Automated IoT-verified accountability for missed contractor interventions.",
            styles['CardBody']
        )
    ]
    story.append(make_card(exec_text, bg_color=COLOR_LIGHT_BG, border_color=COLOR_SECONDARY))
    story.append(Spacer(1, 10))

    # High Level Comparison Table
    story.append(Paragraph("<b>Table 1.1: Broken Legacy Apps vs. HawaCitizen Breakthrough</b>", styles['SubSectionHeader']))
    comp_data = [
        [
            Paragraph("<b>Dimension</b>", styles['TableHeader']),
            Paragraph("<b>Legacy AQI Apps (AirVisual, AQI.in, Google)</b>", styles['TableHeader']),
            Paragraph("<b>HawaCitizen AI Platform</b>", styles['TableHeader']),
        ],
        [
            Paragraph("<b>Spatial Precision</b>", styles['TableCellBold']),
            Paragraph("Single average for a 35 km² district (e.g. 'Delhi 380').", styles['TableCell']),
            Paragraph("<b>500m x 500m Digital Twin</b> with street-level kriging & micro-confidence.", styles['TableCell']),
        ],
        [
            Paragraph("<b>Explainability</b>", styles['TableCellBold']),
            Paragraph("Black-box number. No indication of why the air is bad.", styles['TableCell']),
            Paragraph("<b>AI Source Attribution:</b> Road dust %, Biomass %, Traffic %, Industrial %.", styles['TableCell']),
        ],
        [
            Paragraph("<b>Commute Routing</b>", styles['TableCellBold']),
            Paragraph("Only fastest route (often directs people into toxic diesel corridors).", styles['TableCell']),
            Paragraph("<b>Safe Air Navigator:</b> Cleanest vs Fastest route; minimizes inhaled toxic mass (µg).", styles['TableCell']),
        ],
        [
            Paragraph("<b>Govt Transparency</b>", styles['TableCellBold']),
            Paragraph("Zero. Citizens believe government machines never operate.", styles['TableCell']),
            Paragraph("<b>Live Machinery Radar + Verified Impact:</b> Shows active trucks & measured PM drops.", styles['TableCell']),
        ],
        [
            Paragraph("<b>Civic Grievance</b>", styles['TableCellBold']),
            Paragraph("Unmonitored web forms; tickets vanish into municipal black holes.", styles['TableCell']),
            Paragraph("<b>IoT Closed-Loop:</b> Automatically audits machine GPS/pumps against citizen reports.", styles['TableCell']),
        ],
    ]
    t_comp = Table(comp_data, colWidths=[100, 215, 225])
    t_comp.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_PRIMARY),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('PADDING', (0,0), (-1,-1), 4.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_LIGHT_BG]),
    ]))
    story.append(t_comp)
    story.append(Spacer(1, 12))

    # Hackathon Winning Formula Callout
    callout_box = [
        Paragraph("<b>🏆 THE HACKATHON WINNING EDGE: CLOSING THE CIVIC LOOP</b>", styles['CardHeader']),
        Paragraph(
            "Judges at Environmental Hacks 2026 penalize simple UI wrappers that regurgitate OpenAQ data. "
            "HawaCitizen wins by connecting the <b>Citizen on the ground</b> to the <b>MCD Municipal Command Console</b> and the "
            "<b>Physical Fleet Telemetry</b>. When a citizen flags a missed sprinkler, the AI immediately checks the IoT pump flow sensor. "
            "If the contractor failed to spray, a financial penalty is logged automatically. That is end-to-end civic integrity.",
            styles['CardBody']
        )
    ]
    story.append(make_card(callout_box, bg_color=COLOR_AMBER_BG, border_color=COLOR_AMBER))

    story.append(PageBreak())

    # ==========================================
    # PAGE 2: DEEP DIVE - FEATURES 1 & 2
    # ==========================================
    story.append(Paragraph("1. Street-Level Digital Twin & Explainable AI Insights", styles['SectionHeader']))
    story.append(Paragraph(
        "Current air monitoring stations in Delhi are sparse (only 47 CAAQMS stations covering ~1,484 km²). "
        "A citizen living in Malviya Nagar sees readings from Sri Aurobindo Marg or RK Puram, several kilometers away. "
        "HawaCitizen bridges this with a physics-informed Gaussian Process spatial interpolation engine.",
        styles['BodyRegular']
    ))

    # Feature 1 Details
    f1_items = [
        Paragraph("<b>Key Architectural Components:</b>", styles['CardHeader']),
        Paragraph("• <b>Hyperlocal 500m Resolution:</b> Delhi is tessellated into a 500m x 500m coordinate grid. Low-cost sensors mounted on transit buses (HawaPod-M), school rooftop monitors (HawaPod-S), and reference stations feed a spatial kriging model updating every 15 minutes.", styles['BulletItem']),
        Paragraph("• <b>Explainable Source Attribution Card:</b> Instead of a scary red digit, users tap any neighborhood to see the exact AI classification from our LightGBM attribution classifier: <i>'Anand Vihar: 58% Unpaved Road Dust, 24% Biomass Burning, 18% Heavy Vehicular Exhaust'</i>.", styles['BulletItem']),
        Paragraph("• <b>Probabilistic 72-Hour Forecast & GRAP Outlook:</b> Displays median (P50) and pessimistic (P90) forecast curves. Predicts winter temperature inversion traps 24-48 hours in advance, giving citizens advance warning of impending GRAP Stage III/IV restrictions.", styles['BulletItem']),
        Paragraph("• <b>Real-World Example:</b> <i>Ramesh plans a morning run at 6:30 AM in Rohini. His usual app says 'AQI 320'. HawaCitizen alerts him: 'Severe cold inversion trapped dust at ground level (PM2.5: 410 µg/m³). Clean air window expected at 2:00 PM (PM2.5: 145 µg/m³).' Ramesh shifts his workout, sparing his lungs severe inflammation.</i>", styles['BulletItem']),
    ]
    story.append(make_card(f1_items, bg_color=COLOR_LIGHT_BG, border_color=COLOR_BORDER))
    story.append(Spacer(1, 14))

    story.append(Paragraph("2. Safe Air Navigator: Lung-Optimized Commute Planning", styles['SectionHeader']))
    story.append(Paragraph(
        "Standard mapping software (Google Maps, Apple Maps) optimizes strictly for <b>travel time</b>. In Delhi, the fastest route often "
        "funnels two-wheelers, pedestrians, and cyclists onto heavily congested ring roads and diesel transport corridors, where particulate "
        "levels exceed 500 µg/m³. HawaCitizen introduces <b>Inhaled Dose Routing</b>.",
        styles['BodyRegular']
    ))

    # Inhaled Dose Formula Box
    formula_box = [
        Paragraph("<b>THE MATHEMATICAL FOUNDATION: INHALED TOXIC DOSE (D)</b>", styles['CardHeader']),
        Paragraph(
            "The cumulative toxic particulate dose absorbed by an individual traveling along a path over travel time <i>T</i> is defined as:<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;<b>D = Total Dose = Integral [ C( x(t), y(t) ) &middot; V_E(mode) &middot; dt ]</b><br/>"
            "Where <b>C(x,y)</b> is the real-time PM2.5 concentration at coordinate (x,y), and <b>V_E</b> is the minute ventilation rate "
            "(liters of air inhaled per minute) for the specific travel mode (Resting Car = 6 L/min, Walking = 15 L/min, Cycling = 30 L/min). "
            "Our routing algorithm solves a multi-objective Pareto optimization balancing travel time <i>T</i> and cumulative toxic dose <i>D</i>.",
            styles['CardBody']
        )
    ]
    story.append(make_card(formula_box, bg_color=COLOR_ACCENT_BG, border_color=COLOR_ACCENT))
    story.append(Spacer(1, 8))

    # Route Comparison Table
    story.append(Paragraph("<b>Table 2.1: Case Study - Commute from Lajpat Nagar to Connaught Place (Cyclist)</b>", styles['SubSectionHeader']))
    route_table_data = [
        [
            Paragraph("<b>Routing Option</b>", styles['TableHeader']),
            Paragraph("<b>Distance</b>", styles['TableHeader']),
            Paragraph("<b>Time</b>", styles['TableHeader']),
            Paragraph("<b>Avg PM2.5</b>", styles['TableHeader']),
            Paragraph("<b>Inhaled PM2.5 Dose</b>", styles['TableHeader']),
            Paragraph("<b>Health & Risk Outcome</b>", styles['TableHeader']),
        ],
        [
            Paragraph("<b>1. Fastest Route</b><br/>(Via Ring Road / Mathura Rd)", styles['TableCellBold']),
            Paragraph("11.2 km", styles['TableCell']),
            Paragraph("28 mins", styles['TableCell']),
            Paragraph("345 µg/m³", styles['TableCell']),
            Paragraph("<b>289.8 µg</b>", styles['TableCellBold']),
            Paragraph("Severe diesel exhaust exposure; high acute cardiovascular stress.", styles['TableCell']),
        ],
        [
            Paragraph("<b>2. Cleanest Route</b><br/>(Via Lodi Gardens & Tree Canopies)", styles['TableCellBold']),
            Paragraph("12.6 km", styles['TableCell']),
            Paragraph("34 mins<br/>(+6 min)", styles['TableCell']),
            Paragraph("162 µg/m³", styles['TableCell']),
            Paragraph("<b>165.2 µg</b><br/><font color='#00A896'><b>(-43.0% PM)</b></font>", styles['TableCellBold']),
            Paragraph("Leafy green buffers absorb dust; 43% lower lung particle deposition.", styles['TableCell']),
        ],
        [
            Paragraph("<b>3. Balanced Route</b><br/>(AI Compromise)", styles['TableCellBold']),
            Paragraph("11.8 km", styles['TableCell']),
            Paragraph("30 mins<br/>(+2 min)", styles['TableCell']),
            Paragraph("210 µg/m³", styles['TableCell']),
            Paragraph("<b>189.0 µg</b><br/><font color='#134074'><b>(-34.8% PM)</b></font>", styles['TableCellBold']),
            Paragraph("Avoids bottleneck diesel intersections while preserving commute speed.", styles['TableCell']),
        ],
    ]
    t_route = Table(route_table_data, colWidths=[110, 55, 55, 65, 95, 160])
    t_route.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_SECONDARY),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
        ('PADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_LIGHT_BG]),
    ]))
    story.append(t_route)

    story.append(PageBreak())

    # ==========================================
    # PAGE 3: DEEP DIVE - FEATURES 3 & 4
    # ==========================================
    story.append(Paragraph("3. Live Government in Action & Verified Proof-of-Work Radar", styles['SectionHeader']))
    story.append(Paragraph(
        "A primary driver of citizen disengagement in Delhi is severe public cynicism: citizens hear that hundreds of anti-smog guns and "
        "sprinklers are active, yet they see smog out their windows and conclude government funds are wasted. "
        "HawaCitizen brings radical operational transparency through live telemetry and causal AI verification.",
        styles['BodyRegular']
    ))

    f3_cards = [
        Paragraph("<b>How the Live Proof-of-Work Radar Works:</b>", styles['CardHeader']),
        Paragraph("• <b>Live Fleet Tracking:</b> Active water sprinklers, anti-smog guns, and mechanical sweepers equipped with HawaTag IoT trackers appear live on the citizen map with pulsating blue/green indicators. Citizens can see vehicle ID, current operation speed, and water flow rate.", styles['BulletItem']),
        Paragraph("• <b>Verified Intervention History:</b> Tapping any previously treated road segment displays the exact intervention timestamp, machinery type, and volume of water dispersed.", styles['BulletItem']),
        Paragraph("• <b>Causal Synthetic Control Verification Badge:</b> Unlike simplistic 'before/after' claims that can be fooled by changing weather, HawaCommand's backend runs synthetic control against untreated donor cells. The app shows citizens statistically verified proof:<br/>"
                  "&nbsp;&nbsp;&nbsp;&nbsp;<i>'Sprayed by MCD Sprinkler #04 at 08:15 AM · Measured PM10 Drop: -18.5% (95% CI: 15.4% - 22.2%) · Lasting Effect: 90 Minutes'</i>.", styles['BulletItem']),
        Paragraph("• <b>Public Trust Impact:</b> Citizens no longer speculate whether road misting occurred. They see real-time verification that municipal crews intervened in their specific residential pocket.", styles['BulletItem']),
    ]
    story.append(make_card(f3_cards, bg_color=COLOR_LIGHT_BG, border_color=COLOR_BORDER))
    story.append(Spacer(1, 14))

    story.append(Paragraph("4. Civic Eyes & The 'No-Ghost-Worker' Accountability Engine", styles['SectionHeader']))
    story.append(Paragraph(
        "Municipal contracts in Indian cities frequently suffer from 'ghost workers' and unfulfilled routes—contractors log false paperwork "
        "claiming routes were watered, while machines sit idle in depots. HawaCitizen empowers citizens with a tamper-proof civic audit tool.",
        styles['BodyRegular']
    ))

    # Double Card: Complaint Types
    audit_flow = [
        Paragraph("<b>THE DUAL-ENGINE ACCOUNTABILITY WORKFLOW:</b>", styles['CardHeader']),
        Paragraph("<b>Scenario A: Missed Intervention Reporting (Ghost Worker Detection)</b><br/>"
                  "1. The citizen app displays scheduled municipal interventions in the user's neighborhood: <i>'Sprinkler Unit #08 assigned to Ring Road Stretch between 8:00 AM - 9:00 AM'</i>.<br/>"
                  "2. If 8:45 AM arrives and no machine has appeared, a resident taps <b>'Flag Missed Route'</b>.<br/>"
                  "3. <b>Automated IoT Cross-Audit:</b> The HawaCommand backend queries the HawaTag hardware telemetry for Unit #08. If the GPS coordinates prove the vehicle remained stationary at the depot or the water pump flow meter registered zero liters, the incident is instantly escalated.<br/>"
                  "4. An automated <b>SLA Breach & Financial Penalty Ticket</b> is issued to the contractor on the central MCD dashboard.",
                  styles['CardBody']),
        Spacer(1, 4),
        Paragraph("<b>Scenario B: Citizen Eyes Violation Camera (Biomass Burning & Construction Dust)</b><br/>"
                  "1. Citizen snaps a photograph of illegal trash burning or uncovered construction debris.<br/>"
                  "2. The app captures immutable metadata: device GPS, compass bearing, network timestamp, and local sensor readings.<br/>"
                  "3. <b>Computer Vision Classifier:</b> On-device or API vision model confirms violation category (open flame, black smoke, unpaved dust plume).<br/>"
                  "4. <b>Spatial Fusion:</b> The system correlates the photo with immediate spikes on nearby low-cost sensors, validating genuine impact.<br/>"
                  "5. A high-priority inspection task is pushed to the nearest DPCC/MCD field inspector's mobile app. When the inspector resolves the violation, the citizen receives a before/after resolution notification with photo proof.",
                  styles['CardBody']),
    ]
    story.append(make_card(audit_flow, bg_color=COLOR_LIGHT_BG, border_color=COLOR_ALERT))

    story.append(PageBreak())

    # ==========================================
    # PAGE 4: INNOVATION PILLARS 5, 6, 7
    # ==========================================
    story.append(Paragraph("5. 'Breath Safe Window' Finder: Diurnal Inversion Modeling", styles['SectionHeader']))
    story.append(Paragraph(
        "Delhi's winter air quality is dominated by diurnal planetary boundary layer (PBL) dynamics. During the early morning (6:00 AM - 9:00 AM), "
        "a severe thermal inversion layer caps the city like a lid, trapping heavy vehicular emissions and dust at head-height. "
        "In the afternoon (1:00 PM - 4:00 PM), solar heating expands the boundary layer, diluting pollution concentrations by 40-60%. "
        "HawaCitizen translates this complex atmospheric science into a personal daily lifestyle planner.",
        styles['BodyRegular']
    ))

    # Safe Window Features
    safe_window_items = [
        Paragraph("<b>Personalized Health Personas & Opportunity Windows:</b>", styles['CardHeader']),
        Paragraph("• <b>Pediatric & School Profile:</b> Alerts parents and teachers whether morning outdoor assemblies or sports periods are safe. Connects to HawaPod-S school sensors to contrast indoor air-conditioned classrooms with outdoor playgrounds.", styles['BulletItem']),
        Paragraph("• <b>Runner & Outdoor Athlete Profile:</b> Dynamic schedule finder: <i>'Avoid 6:00 AM running (PM2.5: 380). Optimal aerobic window: 3:15 PM - 5:00 PM (PM2.5: 135).'</i>", styles['BulletItem']),
        Paragraph("• <b>Elderly & Chronic COPD/Asthma Profile:</b> Provides automated evening notifications: <i>'Severe inversion predicted tomorrow morning in Lajpat Nagar. Plan all outdoor errands between 2:00 PM and 4:00 PM.'</i>", styles['BulletItem']),
    ]
    story.append(make_card(safe_window_items, bg_color=COLOR_ACCENT_BG, border_color=COLOR_ACCENT))
    story.append(Spacer(1, 14))

    story.append(Paragraph("6. Ward Air Scorecard: Gamification & Public Democratic Accountability", styles['SectionHeader']))
    story.append(Paragraph(
        "To break bureaucratic inertia, HawaCitizen introduces public transparency metrics across all 250 municipal wards of Delhi. "
        "By publishing daily objective scorecards, citizens can hold their local councilors and MCD officers accountable.",
        styles['BodyRegular']
    ))

    scorecard_data = [
        [
            Paragraph("<b>Ward Metric</b>", styles['TableHeader']),
            Paragraph("<b>Measurement & Calculation</b>", styles['TableHeader']),
            Paragraph("<b>Civic & Policy Impact</b>", styles['TableHeader']),
        ],
        [
            Paragraph("<b>Clean Air Grade<br/>(A+ to F)</b>", styles['TableCellBold']),
            Paragraph("Weighted composite score: 24h average PM2.5 + percentage of scheduled misting routes completed.", styles['TableCell']),
            Paragraph("Published daily in app and on social leaderboards, creating public pressure between ward representatives.", styles['TableCell']),
        ],
        [
            Paragraph("<b>Grievance SLA Resolution %</b>", styles['TableCellBold']),
            Paragraph("Percentage of citizen-reported burning/dust violations resolved and verified within 3 hours.", styles['TableCell']),
            Paragraph("Exposes underperforming municipal zones and rewards proactive field inspection officers.", styles['TableCell']),
        ],
        [
            Paragraph("<b>Community Share Card</b>", styles['TableCellBold']),
            Paragraph("One-tap exportable infographic for WhatsApp Groups, X (Twitter), and Instagram Stories.", styles['TableCell']),
            Paragraph("Spreads viral awareness and democratizes pollution transparency among apartment welfare associations (RWAs).", styles['TableCell']),
        ],
    ]
    t_score = Table(scorecard_data, colWidths=[120, 210, 210])
    t_score.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_PRIMARY),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('PADDING', (0,0), (-1,-1), 4.5),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_LIGHT_BG]),
    ]))
    story.append(t_score)
    story.append(Spacer(1, 14))

    story.append(Paragraph("7. Community Sensor Mesh: Crowdsourced Mobile Sensing", styles['SectionHeader']))
    story.append(Paragraph(
        "Rather than relying purely on multi-crore stationary stations, HawaCitizen opens an API for Bluetooth low-cost portable sensors "
        "(carried by gig-economy delivery riders, auto-rickshaw drivers, and cycling commuters). "
        "Our backend auto-calibrates incoming consumer readings against nearby reference monitors using relative humidity polynomial correction: "
        "<i>PM_calibrated = a · PM_raw + b · RH + c</i>. Every contributing citizen receives <b>'Clean Air Guardian'</b> civic credits, "
        "fueling an organic, city-wide hyper-dense sensory grid.",
        styles['BodyRegular']
    ))

    story.append(PageBreak())

    # ==========================================
    # PAGE 5: SYSTEM ARCHITECTURE & INTEGRATION
    # ==========================================
    story.append(Paragraph("8. Technical Architecture & End-to-End System Integration", styles['SectionHeader']))
    story.append(Paragraph(
        "HawaCitizen is not a standalone mock app; it directly interfaces with the unified HawaCommand repository architecture "
        "spanning Flutter mobile clients, FastAPI backend services, and Python AI/ML pipelines.",
        styles['BodyRegular']
    ))

    arch_box = [
        Paragraph("<b>DATA FLOW: FROM SENSORS TO CITIZEN ACTION</b>", styles['CardHeader']),
        Paragraph(
            "<b>1. Ingestion Layer:</b> Reference CAAQMS stations, NASA FIRMS thermal anomaly satellite feeds, and HawaTag IoT telemetry on misting trucks stream continuously into AWS Kinesis and PostgreSQL/PostGIS.<br/>"
            "<b>2. AI-ML Inference Core:</b><br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;• <i>Exposure Engine (engine.py):</i> Computes population-weighted exposure scores E = max(0, C - C_safe) · Pop · V · dt.<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;• <i>LightGBM Quantile Forecaster:</i> Generates 72-hour probabilistic forecast curves (P10/P50/P90).<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;• <i>Causal Synthetic Control:</i> Measures true dip sizes, duration, and confidence intervals of all interventions.<br/>"
            "<b>3. FastAPI Service Layer:</b> Serves lightweight JSON endpoints:<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;• <code>GET /open/v1/air</code> : Returns 500m ranked grid cells with source attribution.<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;• <code>POST /v1/routing/clean-route</code> : Accepts origin/destination coordinates; executes multi-objective path optimization.<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;• <code>GET /v1/machinery/live</code> : Delivers real-time GPS coordinates and active water flow status of MCD trucks.<br/>"
            "&nbsp;&nbsp;&nbsp;&nbsp;• <code>POST /v1/reports/citizen</code> : Ingests geofenced violation reports; triggers automated IoT cross-audit.<br/>"
            "<b>4. Flutter Cross-Platform Client:</b> Implemented in Dart with Riverpod state management, offline Hive storage, and Mapbox vector tile rendering.",
            styles['CardBody']
        )
    ]
    story.append(make_card(arch_box, bg_color=COLOR_LIGHT_BG, border_color=COLOR_SECONDARY))
    story.append(Spacer(1, 14))

    story.append(Paragraph("9. Complete Screen-by-Screen UI/UX Specification", styles['SectionHeader']))
    story.append(Paragraph(
        "The mobile app adheres to clean, modern design standards: dark/light glassmorphism, responsive micro-animations, "
        "bilingual English/Hindi typography, and zero-clutter navigation.",
        styles['BodyRegular']
    ))

    screens_data = [
        [
            Paragraph("<b>Screen Name</b>", styles['TableHeader']),
            Paragraph("<b>Route Path</b>", styles['TableHeader']),
            Paragraph("<b>Key UI Components & Interactive Features</b>", styles['TableHeader']),
        ],
        [
            Paragraph("<b>1. Live Air Home</b>", styles['TableCellBold']),
            Paragraph("<code>/citizen/home</code>", styles['TableCell']),
            Paragraph("• Hyperlocal 500m AQI Gauge with real-time trend badge.<br/>• AI Source Attribution Donut Chart (Dust vs Burning vs Traffic).<br/>• 'Today's Safe Outdoor Window' Hero Card with 1-tap calendar sync.", styles['TableCell']),
        ],
        [
            Paragraph("<b>2. Safe Air Navigator</b>", styles['TableCellBold']),
            Paragraph("<code>/citizen/route</code>", styles['TableCell']),
            Paragraph("• Origin & Destination inputs with mode selector (Walk/Cycle/Drive).<br/>• Side-by-side comparison: Fastest vs Cleanest Airway.<br/>• Real-time 'Inhaled PM2.5 Microgram Dose' meter and tree-canopy overlay.", styles['TableCell']),
        ],
        [
            Paragraph("<b>3. Govt in Action Radar</b>", styles['TableCellBold']),
            Paragraph("<code>/citizen/live-ops</code>", styles['TableCell']),
            Paragraph("• Live Map showing active anti-smog guns & sprinklers with pulsating pins.<br/>• Tap on any treated road: View verified -18.5% PM drop & timestamp.<br/>• Toggle between 'Active Operations' and 'Historical Verified Impact'.", styles['TableCell']),
        ],
        [
            Paragraph("<b>4. Civic Watchdog Camera</b>", styles['TableCellBold']),
            Paragraph("<code>/citizen/report</code>", styles['TableCell']),
            Paragraph("• Camera capture with auto-detected GPS, timestamp, and address.<br/>• 'Report Missed Machine' button with automated HawaTag IoT verification.<br/>• Track resolution timeline with photo proof when inspector closes case.", styles['TableCell']),
        ],
        [
            Paragraph("<b>5. Ward Scorecard</b>", styles['TableCellBold']),
            Paragraph("<code>/citizen/ward</code>", styles['TableCell']),
            Paragraph("• Ward rankings leaderboard (Rank #1 Hauz Khas vs Rank #250 Anand Vihar).<br/>• Daily Report Card (Grade A to F) with 1-tap WhatsApp/Twitter share card.", styles['TableCell']),
        ],
    ]
    t_screens = Table(screens_data, colWidths=[100, 105, 335])
    t_screens.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), COLOR_PRIMARY),
        ('GRID', (0,0), (-1,-1), 0.5, COLOR_BORDER),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('PADDING', (0,0), (-1,-1), 4),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, COLOR_LIGHT_BG]),
    ]))
    story.append(t_screens)

    story.append(PageBreak())

    # ==========================================
    # PAGE 6: WINNING HACKATHON PITCH & SCRIPT
    # ==========================================
    story.append(Paragraph("10. The 3-Minute Hackathon Winning Pitch & Live Demo Script", styles['SectionHeader']))
    story.append(Paragraph(
        "Deliver this exact narrative structure during the jury presentation. It immediately differentiates your team from naive data visualizers "
        "by demonstrating technological depth, civic empathy, and commercial viability.",
        styles['BodyRegular']
    ))

    pitch_box = [
        Paragraph("<b>STAGE PRESENTATION SCRIPT (TIME: 3 MINUTES)</b>", styles['CardHeader']),
        Paragraph(
            "<b>Minute 0:00 - 0:45: The Hook & The Problem</b><br/>"
            "<i>'Respected judges, imagine waking up tomorrow morning in Delhi. You open your phone, see an AQI of 395 in red text, "
            "and feel absolute helplessness. You don't know what is poisoning your air, you don't know which route to take to work to protect your lungs, "
            "and you have zero trust that the government is actually doing anything about it. Today, citizens are passive victims.'</i><br/><br/>"
            "<b>Minute 0:45 - 1:45: The Live Demonstration</b><br/>"
            "<i>'Meet HawaCitizen. We don't just display a number; we provide active defense and radical civic power.<br/>"
            "First, look at our <b>Safe Air Navigator</b>. A commuter going from Lajpat Nagar to CP is usually sent down Ring Road—inhaling nearly 300 micrograms of toxic particles. With one tap, HawaCitizen calculates the Clean Air Route through green canopies. It takes just 4 minutes longer, but cuts inhaled particulate dose by 43%.<br/>"
            "Second, look at our <b>Live Government Radar</b>. Citizens can see active water sprinklers right now in their ward. Tapping on a sprayed road shows our AI synthetic-control verification: PM2.5 dropped 18.5% for 90 minutes. We replace public cynicism with mathematical proof.'</i><br/><br/>"
            "<b>Minute 1:45 - 2:30: The Killer Feature (Civic Accountability)</b><br/>"
            "<i>'Third, and most importantly: accountability. What happens when a contractor logs that they watered the road, but never showed up? "
            "In our app, a resident taps 'Flag Missed Machine'. Our system doesn't create a dead ticket—it instantly cross-audits the HawaTag IoT telemetry on that truck! "
            "If the pump flow meter registers zero, the contractor is slapped with an automated SLA penalty. We turn 30 million citizens into an incorruptible municipal audit army.'</i><br/><br/>"
            "<b>Minute 2:30 - 3:00: The Climax & Close</b><br/>"
            "<i>'HawaCommand finds and fixes the pollution; HawaCitizen empowers the people and verifies the fix. "
            "We don't just report the crisis—we solve it. Thank you!'</i>",
            styles['CardBody']
        )
    ]
    story.append(make_card(pitch_box, bg_color=COLOR_LIGHT_BG, border_color=COLOR_PRIMARY))
    story.append(Spacer(1, 14))

    story.append(Paragraph("11. Anticipated Judge Questions & Bulletproof Answers", styles['SectionHeader']))

    faq_box = [
        Paragraph("<b>DEFENDING YOUR WORK IN THE Q&A ROUND:</b>", styles['CardHeader']),
        Paragraph("<b>Q1: 'How is this different from Google Maps adding AQI layers?'</b><br/>"
                  "<b>A:</b> <i>'Google Maps displays coarse regional AQI overlays, but its routing algorithm is strictly time-optimized. It never routes based on inhaled toxic particle dose or respiratory ventilation rates. Furthermore, Google Maps has zero integration with municipal fleet machinery or IoT verification.'</i><br/><br/>"
                  "<b>Q2: 'What prevents citizens from submitting spam or fake reports?'</b><br/>"
                  "<b>A:</b> <i>'Three layers of automated validation: 1) Hardware EXIF geotag and cryptographic timestamp verification; 2) On-device computer vision classification; and 3) Spatial sensor correlation—a report is only escalated if nearby air quality sensors concurrently register a localized particulate spike.'</i><br/><br/>"
                  "<b>Q3: 'Can municipal bodies realistically integrate with this?'</b><br/>"
                  "<b>A:</b> <i>'Yes. HawaCommand's backend is specifically engineered for MCD and DPCC standard operating procedures under the NCAP (National Clean Air Programme) framework. Municipalities already pay contractors based on verified work—our IoT and citizen validation automate that exact audit trail.'</i>",
                  styles['CardBody']
        )
    ]
    story.append(make_card(faq_box, bg_color=COLOR_ACCENT_BG, border_color=COLOR_ACCENT))

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"[OK] Successfully built {output_path}")


if __name__ == "__main__":
    out_dir = Path("docs")
    out_dir.mkdir(parents=True, exist_ok=True)
    target = out_dir / "HawaCitizen_App_Comprehensive_Blueprint.pdf"
    build_pdf(target)
