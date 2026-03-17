CREATE DATABASE IF NOT EXISTS clicsalud_ips
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE clicsalud_ips;

SET FOREIGN_KEY_CHECKS = 0;

-- ------------------------------------------------------------
-- TABLA: departamento
-- Fuente D1 + D2: solo campos necesarios, sin FKs redundantes
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `departamento` (
  `id_departamento`   INT           NOT NULL AUTO_INCREMENT,
  `nombre_departamento` VARCHAR(100) NOT NULL,
  `longitud`          DECIMAL(10,6) DEFAULT NULL,
  `latitud`           DECIMAL(10,6) DEFAULT NULL,
  PRIMARY KEY (`id_departamento`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA: municipio
-- Relación 1:N con departamento
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `municipio` (
  `id_municipio`      INT           NOT NULL AUTO_INCREMENT,
  `nombre_municipio`  VARCHAR(100)  NOT NULL,
  `id_departamento`   INT           NOT NULL,
  PRIMARY KEY (`id_municipio`),
  CONSTRAINT `fk_mun_dept`
    FOREIGN KEY (`id_departamento`)
    REFERENCES `departamento` (`id_departamento`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA: ips
-- Relación 1:N con municipio (una IPS pertenece a 1 municipio)
-- Corrección D3: la relación municipio-ips es 1:N, NO N:N
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ips` (
  `id_ips`            INT           NOT NULL AUTO_INCREMENT,
  `nombre_ips`        VARCHAR(150)  NOT NULL,
  `codigo_ips`        VARCHAR(30)   DEFAULT NULL,
  `id_municipio`      INT           NOT NULL,
  PRIMARY KEY (`id_ips`),
  CONSTRAINT `fk_ips_mun`
    FOREIGN KEY (`id_municipio`)
    REFERENCES `municipio` (`id_municipio`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA: tiempo
-- Mejora D2: campos analíticos separados (año, mes, trimestre)
-- Conserva D1: fecha exacta y periodo_original del xlsx
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `tiempo` (
  `id_tiempo`         INT           NOT NULL AUTO_INCREMENT,
  `fecha`             DATE          NOT NULL,
  `anio`              SMALLINT      NOT NULL,
  `mes`               TINYINT       DEFAULT NULL,
  `trimestre`         TINYINT       DEFAULT NULL COMMENT '1=Ene-Mar, 2=Abr-Jun, 3=Jul-Sep, 4=Oct-Dic',
  `semestre`          TINYINT       DEFAULT NULL COMMENT '1=Ene-Jun, 2=Jul-Dic',
  `periodo_original`  VARCHAR(20)   DEFAULT NULL COMMENT 'Valor original del xlsx ej: 201606, 20200930',
  PRIMARY KEY (`id_tiempo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA: servicio
-- Corrección D1 y D3: entidad independiente, sin FK a IPS
-- Un servicio es una categoría global (Urgencias, Hospitalaria...)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `servicio` (
  `id_servicio`       INT           NOT NULL AUTO_INCREMENT,
  `nombre_servicio`   VARCHAR(100)  NOT NULL,
  PRIMARY KEY (`id_servicio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA: indicador
-- Fusión D1 + D2: campos completos del xlsx + descripción
-- Corrección D3: FKs de resultado/ips NO van aquí
-- Conecta a servicio, no a resultado
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `indicador` (
  `id_indicador`      INT           NOT NULL AUTO_INCREMENT,
  `nombre_indicador`  VARCHAR(250)  NOT NULL,
  `descripcion`       TEXT          DEFAULT NULL,
  `categoria`         VARCHAR(100)  DEFAULT NULL COMMENT 'Ej: EFECTIVIDAD, SEGURIDAD, TIEMPOS DE ESPERA',
  `especifique`       VARCHAR(100)  DEFAULT NULL COMMENT 'Subcategoría del indicador',
  `unidad`            VARCHAR(50)   DEFAULT NULL COMMENT 'Ej: PORCENTAJE, DÍAS, MINUTOS',
  `id_servicio`       INT           NOT NULL,
  PRIMARY KEY (`id_indicador`),
  CONSTRAINT `fk_ind_serv`
    FOREIGN KEY (`id_servicio`)
    REFERENCES `servicio` (`id_servicio`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA: resultado
-- Tabla de hechos central — fusión de los 3 diagramas
-- D2: agrega id_servicio como FK directa ✓
-- D1 + D3: conserva numerador, denominador, resultado_indicador ✓
-- Sin FK redundante de municipio (se obtiene via ips)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `resultado` (
  `id_resultado`        INT             NOT NULL AUTO_INCREMENT,
  `id_indicador`        INT             NOT NULL,
  `id_servicio`         INT             NOT NULL,
  `id_ips`              INT             NOT NULL,
  `id_tiempo`           INT             NOT NULL,
  `numerador`           DECIMAL(12,2)   DEFAULT NULL,
  `denominador`         DECIMAL(12,2)   DEFAULT NULL,
  `valor`               DECIMAL(12,4)   DEFAULT NULL COMMENT 'Resultado calculado = numerador/denominador',
  PRIMARY KEY (`id_resultado`),
  CONSTRAINT `fk_res_indicador`
    FOREIGN KEY (`id_indicador`)
    REFERENCES `indicador` (`id_indicador`)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_res_servicio`
    FOREIGN KEY (`id_servicio`)
    REFERENCES `servicio` (`id_servicio`)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_res_ips`
    FOREIGN KEY (`id_ips`)
    REFERENCES `ips` (`id_ips`)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT `fk_res_tiempo`
    FOREIGN KEY (`id_tiempo`)
    REFERENCES `tiempo` (`id_tiempo`)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- ÍNDICES adicionales para mejorar rendimiento en consultas
-- ------------------------------------------------------------
CREATE INDEX `idx_resultado_ips`       ON `resultado` (`id_ips`);
CREATE INDEX `idx_resultado_tiempo`    ON `resultado` (`id_tiempo`);
CREATE INDEX `idx_resultado_indicador` ON `resultado` (`id_indicador`);
CREATE INDEX `idx_resultado_servicio`  ON `resultado` (`id_servicio`);
CREATE INDEX `idx_ips_municipio`       ON `ips` (`id_municipio`);
CREATE INDEX `idx_municipio_depto`     ON `municipio` (`id_departamento`);
CREATE INDEX `idx_indicador_servicio`  ON `indicador` (`id_servicio`);
CREATE INDEX `idx_tiempo_anio`         ON `tiempo` (`anio`);
CREATE INDEX `idx_tiempo_semestre`     ON `tiempo` (`anio`, `semestre`);

SET FOREIGN_KEY_CHECKS = 1;
