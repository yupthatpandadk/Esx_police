# zema_police

Et nyt realistisk politisystem til ESX, bygget fra bunden til Zematic.

## Version 0.1.0

Første fundament indeholder:
- Tjeneste on/off
- Server-side job- og duty-validering
- Håndjern
- Eskortering
- Sæt person i køretøj / tag person ud
- Grundlæggende database til betjente, rapporter og køretøjsmarkeringer
- Exports til kommende Zematic-resources

## Krav
- es_extended (ESX Legacy)
- oxmysql

## Installation
1. Importér `sql/zema_police.sql`.
2. Placér resource som `zema_police` i resources.
3. Tilføj `ensure zema_police` efter `es_extended` og `oxmysql` i server.cfg.
4. Jobbet forventes som standard at hedde `police`.

## Kommandoer
- `/pduty` - gå til/fra tjeneste
- `/cuff` - håndjern nærmeste spiller
- `/escort` - eskortér håndjernet spiller
- `/putincar` - sæt håndjernet spiller i nærmeste køretøj
- `/outcar` - tag nærmeste spiller ud af køretøj

## Roadmap
Næste moduler: Zematic politi-UI, ID/visitation, trafikstop og nummerpladeopslag, bøder/sigtelser, MDT, dispatch, radar/ANPG, evidence, garage og armory.
