# Changelog

All notable changes to this Helm chart will be documented in this file.

## [0.0.24] - 2024-09-12

### Added

- Introduced the deployment for the `scorecard-evaluation-engine` service, enabling automated scorecard evaluations.

### Fixed

- Corrected the `matchLabels` selector in the Backend PodDisruptionBudget (PDB) to ensure proper matching of backend pods during disruptions.
