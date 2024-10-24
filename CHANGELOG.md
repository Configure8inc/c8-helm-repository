# Changelog

All notable changes to this Helm chart will be documented in this file.

## [0.0.28] - 2024-10-08

### Fixed

- Added ephemeral-storage requests and limits for all services.

## [0.0.27] - 2024-10-08

### Added

- Added TENANT variable

## [0.0.26] - 2024-10-04

### Added

- Added GITHUB_APP_INSTALL_URL variable

## [0.0.25] - 2024-09-12

### Added

- Introduced the deployment for the `scorecard-evaluation-engine` service, enabling automated scorecard evaluations.

### Fixed

- Corrected the `matchLabels` selector in the Backend PodDisruptionBudget (PDB) to ensure proper matching of backend pods during disruptions.

## [0.0.24] - 2024-09-26

### Added

- Added PUBLIC_API_REDIS_ENABLED=true variable
