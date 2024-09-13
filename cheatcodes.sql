
SET 'pipeline.name' = 'konami-cheats';


CREATE TABLE `buttonpresses`
(
    `user`        STRING,
    `buttons`     STRING,
    `event_time`  TIMESTAMP(3) METADATA FROM 'timestamp',
    WATERMARK FOR `event_time` AS `event_time`
)
WITH (
    'connector' = 'kafka',
    'topic' = 'KONAMI.BUTTONPRESSES',
    'format' = 'json',
    'scan.startup.mode' = 'latest-offset',
    'properties.bootstrap.servers' = 'my-kafka-cluster-kafka-bootstrap.event-automation.svc:9095',
    'properties.group.id' = 'flink-cheatcodes',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.sasl.mechanism' = 'SCRAM-SHA-512',
    'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.scram.ScramLoginModule required username="kafka-demo-apps" password="my-secret-password";',
    'properties.ssl.truststore.type' = 'PEM',
    'properties.tls.pemChainIncluded' = 'false',
    'properties.ssl.endpoint.identification.algorithm' = '',
    'properties.ssl.truststore.certificates' = '-----BEGIN CERTIFICATE----- my-kafka-ca-cert -----END CERTIFICATE-----'
);


CREATE
    TEMPORARY VIEW `sonic` AS
SELECT
    `cheat_time`,
    `user`,
    CAST('sonic-level-select' AS STRING) AS `cheat`,
    CONCAT('/konami/cheats/', `user`) AS `target`
FROM buttonpresses
    MATCH_RECOGNIZE (
        PARTITION BY `user`
        ORDER BY event_time
        MEASURES
            PRESS_STARTANDA.event_time AS cheat_time
        ONE ROW PER MATCH
        AFTER MATCH SKIP PAST LAST ROW
        PATTERN (
            PRESS_UP PRESS_DOWN PRESS_LEFT PRESS_RIGHT
            PRESS_STARTANDA
        )
        DEFINE
            PRESS_UP AS buttons = 'UP',
            PRESS_DOWN AS buttons = 'DOWN',
            PRESS_LEFT AS buttons = 'LEFT',
            PRESS_RIGHT AS buttons = 'RIGHT',
            PRESS_STARTANDA AS buttons = 'START+A'
    );


CREATE
    TEMPORARY VIEW `mortalkombat` AS
SELECT
    `cheat_time`,
    `user`,
    CAST('mortalkombat-blood-code' AS STRING) AS `cheat`,
    CONCAT('/konami/cheats/', `user`) AS `target`
FROM buttonpresses
    MATCH_RECOGNIZE (
        PARTITION BY `user`
        ORDER BY event_time
        MEASURES
            PRESS_B3.event_time AS cheat_time
        ONE ROW PER MATCH
        AFTER MATCH SKIP PAST LAST ROW
        PATTERN (
            PRESS_A1 PRESS_B1 PRESS_A2 PRESS_C PRESS_A3 PRESS_B2 PRESS_B3
        )
        DEFINE
            PRESS_A1 AS buttons = 'A',
            PRESS_A2 AS buttons = 'A',
            PRESS_A3 AS buttons = 'A',
            PRESS_B1 AS buttons = 'B',
            PRESS_B2 AS buttons = 'B',
            PRESS_B3 AS buttons = 'B',
            PRESS_C  AS buttons = 'C'
    );


CREATE
    TEMPORARY VIEW `contra` AS
SELECT
    `cheat_time`,
    `user`,
    CAST('contra-30-lives' AS STRING) AS `cheat`,
    CONCAT('/konami/cheats/', `user`) AS `target`
FROM buttonpresses
    MATCH_RECOGNIZE (
        PARTITION BY `user`
        ORDER BY event_time
        MEASURES
            PRESS_A.event_time AS cheat_time
        ONE ROW PER MATCH
        AFTER MATCH SKIP PAST LAST ROW
        PATTERN (
            PRESS_UP{2}
            PRESS_DOWN{2}
            PRESS_LEFT1 PRESS_RIGHT1
            PRESS_LEFT2 PRESS_RIGHT2
            PRESS_B PRESS_A
        )
        DEFINE
            PRESS_UP AS buttons = 'UP',
            PRESS_DOWN AS buttons = 'DOWN',
            PRESS_LEFT1 AS buttons = 'LEFT',
            PRESS_LEFT2 AS buttons = 'LEFT',
            PRESS_RIGHT1 AS buttons = 'RIGHT',
            PRESS_RIGHT2 AS buttons = 'RIGHT',
            PRESS_A AS buttons = 'A',
            PRESS_B AS buttons = 'B'
    );


CREATE TABLE `output`
(
    `cheat_time`  TIMESTAMP(3) METADATA FROM 'timestamp',
    `user`        STRING,
    `cheat`       STRING,
    `target`      STRING
)
WITH (
    'connector' = 'kafka',
    'topic' = 'KONAMI.CHEATS',
    'key.format' = 'raw',
    'key.fields' = 'target',
    'value.format' = 'json',
    'value.fields-include' = 'EXCEPT_KEY',
    'properties.bootstrap.servers' = 'my-kafka-cluster-kafka-bootstrap.event-automation.svc:9095',
    'properties.sasl.jaas.config' = 'org.apache.kafka.common.security.scram.ScramLoginModule required username="kafka-demo-apps" password="my-secret-password";',
    'properties.sasl.mechanism' = 'SCRAM-SHA-512',
    'properties.security.protocol' = 'SASL_SSL',
    'properties.tls.pemChainIncluded' = 'false',
    'properties.ssl.endpoint.identification.algorithm' = '',
    'properties.ssl.truststore.type' = 'PEM',
    'properties.ssl.truststore.certificates' = '-----BEGIN CERTIFICATE----- my-kafka-ca-cert -----END CERTIFICATE-----'
);


INSERT INTO `output`
    SELECT * FROM `sonic`
        UNION ALL
    SELECT * FROM `mortalkombat`
        UNION ALL
    SELECT * FROM `contra`;
