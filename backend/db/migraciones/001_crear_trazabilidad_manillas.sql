CREATE TABLE trazabilidad_manillas (
  id_trazabilidad        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  numero_caso            VARCHAR(20)  NOT NULL,
  nombre                 VARCHAR(80)  NOT NULL,
  apellido               VARCHAR(80)  NOT NULL,
  numero_identificacion  VARCHAR(20)  NOT NULL,
  servicio               VARCHAR(120) NOT NULL,
  fecha_hora_captura     DATETIME     NOT NULL,
  PRIMARY KEY (id_trazabilidad),
  UNIQUE KEY uk_trazabilidad_caso_servicio (numero_caso, servicio),
  KEY ix_trazabilidad_caso_id (numero_caso, id_trazabilidad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
