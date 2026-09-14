CREATE TABLE IF NOT EXISTS `zema_police_officers` (
  `identifier` varchar(64) NOT NULL,
  `callsign` varchar(16) NOT NULL DEFAULT '2-00',
  `last_duty` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `zema_police_reports` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `author_identifier` varchar(64) NOT NULL,
  `author_name` varchar(100) NOT NULL,
  `type` varchar(32) NOT NULL DEFAULT 'incident',
  `title` varchar(150) NOT NULL,
  `description` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_author` (`author_identifier`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `zema_police_vehicle_flags` (
  `plate` varchar(16) NOT NULL,
  `flag` varchar(32) NOT NULL,
  `reason` varchar(255) DEFAULT NULL,
  `created_by` varchar(64) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`plate`,`flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
