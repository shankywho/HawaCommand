# HawaCommand: 160-Second Video Presentation & Master Script

Environmental Hacks 2026 · Bharat Builds Tour · Track 01: Air (WeMakeDevs)

---

## Final Video Overview

The official hackathon demonstration video is located at:
`videos_of_projects/HawaCommand_Final_160s_Presentation.mp4`

### Technical Specifications
- **Duration**: 160.00 seconds (4,800 frames @ 30.0 fps)
- **Resolution**: 1920x1080 (Full HD, 16:9 widescreen)
- **Starting Frame**: Frame 0 of Web Portal Console video
- **Audio Track**: Clean silent stereo AAC bed (ready for voiceover recording)
- **Hardware Segment**: Muted audio with high-contrast on-screen component badges:
  - MQ-135 Air Quality Gas Sensor
  - ESP32 Dual-Core Microcontroller
  - Piezo Buzzer Alarm Module
  - Stepper Motor Mist Spray Actuator

---

## Master Voiceover Script (Continuous, Without Timestamps)

Every winter, Indian megacities deploy hundreds of anti-smog guns and mechanized sprinklers to fight hazardous air pollution. Yet today, this municipal machinery operates blindly along static routes with zero causal verification of whether a spray run actually cleaned the air or if wind merely blew the smog away. For the Air Track of the WeMakeDevs Environmental Hackathon, we built HawaCommand: an autonomous artificial intelligence command centre that maps, forecasts, dynamically dispatches, and econometrically verifies urban air remediation.

HawaCommand operates as a closed-loop intelligence architecture: Sense, Map, Attribute, Forecast, Decide, Act, and Verify.

To power this at scale, we architected a resilient cloud backbone using Amazon Web Services. Our high-performance FastAPI service and Gaussian Process Kriging engine run on Amazon EC2 in the Mumbai region, interpolating sparse ground monitors into a high-resolution 500-metre digital twin across ten thousand grid cells. High-frequency telemetry from statutory CAAQMS stations and our custom edge IoT sensors streams continuously through Amazon Kinesis Data Streams.

Real-time fleet tracking and citizen complaints are stored in Amazon DynamoDB for sub-millisecond read-write availability. Critical Graded Response Action Plan threshold breaches automatically publish instant emergency alerts across municipal wards using Amazon SNS, while citizen-submitted air violation evidence photos are securely cataloged in an Amazon S3 audit bucket. Across the officer console, LightGBM models deliver 72-hour quantile risk forecasts, while Google OR-Tools computes constrained vehicle dispatch routes.

What makes HawaCommand truly unprecedented and practically feasible is that we are the first platform to bridge IoT hardware and cloud software with econometric causal proof. Instead of guessing, our Synthetic Control Engine constructs counterfactual donor pools from similar untreated cells to prove the exact net reduction achieved by every intervention, verifying up to a nineteen percent drop in localized PM2.5. This transforms municipal clean air expenditure from blind guesswork into data-driven accountability.

On the physical edge, our custom IoT unit pairs an MQ-135 air quality gas sensor with an ESP32 dual-core microcontroller, triggering an active piezo buzzer alarm and a stepper motor actuator for automated misting and physical barrier deployment. Simultaneously, the Hawa Citizen Flutter mobile app guides pedestrians and cyclists along clean airways, cutting inhaled particulate doses by up to forty-three percent. HawaCommand bridges edge silicon and AWS cloud intelligence to make clean air an actionable reality for every citizen.

---

## Visual Synchronization Flow

| Segment | Timing | Visual Focus | Spoken Topic |
|---|---|---|---|
| Part 1 | 0s – 30s | Web portal landing page, problem statement (376 anti-smog guns / 266 sprinklers), animated digital twin, transition into live map console. | Project intro, WeMakeDevs Environmental Hacks Air Track, problem & solution. |
| Part 2A | 30s – 42s | AWS Console: EC2 instance running `hawa-backend-ec2-role` in `ap-south-1` Mumbai. | Closed-loop flow, EC2 hosting FastAPI and 500m Kriging digital twin. |
| Part 2B | 42s – 56s | AWS Console: Kinesis Data Stream `hawa-sensor-data` monitoring latency and throughput. | Real-time IoT sensor telemetry & CAAQMS station stream ingestion. |
| Part 2C | 56s – 70s | AWS Console: DynamoDB tables `hawa-fleet-telemetry` & `hawa-citizen-grievances`. | Sub-millisecond fleet telemetry and citizen grievance data storage. |
| Part 2D | 70s – 78s | AWS Console: S3 bucket `hawa-citizen-evidence-prod` showing audit photo directories. | Cloud storage for citizen pollution evidence and audit records. |
| Part 2E | 78s – 90s | Officer Console: 72-hour quantile forecast timeline and ward exposure risk. | LightGBM quantile regression predicting GRAP stage breaches. |
| Part 3A | 90s – 104s | Officer Console: What-If simulation and dynamic anti-smog gun vehicle routing. | Google OR-Tools constrained fleet dispatch. |
| Part 3B | 104s – 130s | Officer Console Impact View: Synthetic Control Method curve (-19% PM2.5 reduction verified for 90 min) & donor cells. | Uniqueness, econometric causal proof, National Clean Air Programme impact. |
| Part 4A | 130s – 138s | Hardware IoT Device (Muted): MQ-135 air sensor and ESP32 microcontroller held in hand. | Edge sensing unit explanation. |
| Part 4B | 138s – 146s | Hardware IoT Device (Muted): Stepper motor mist trigger and piezo buzzer alarm. | Edge actuation and emergency alert systems. |
| Part 4C | 146s – 160s | Flutter Mobile App: Clean Airway Navigator, 43% dose reduction, diurnal safe breathing window. | Citizen app showcase and mission closing statement. |
