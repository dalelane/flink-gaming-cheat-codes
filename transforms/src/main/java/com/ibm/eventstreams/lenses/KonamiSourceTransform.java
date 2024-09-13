package com.ibm.eventstreams.lenses;

import java.util.Map;

import org.apache.kafka.common.config.ConfigDef;
import org.apache.kafka.connect.connector.ConnectRecord;
import org.apache.kafka.connect.data.Schema;
import org.apache.kafka.connect.data.Struct;
import org.apache.kafka.connect.transforms.Transformation;

/**
 * Input is a string message that came from an MQTT connector
 *  - the key will contain the "user" parameter (in a string with a prefix that needs to be removed)
 *  - the payload will contain the "buttons" parameter
 *
 * Output is a JSON string that contains those two values in an object.
 */
public class KonamiSourceTransform<R extends ConnectRecord<R>> implements Transformation<R> {

    @Override
    public R apply(R record) {
        Struct keyStruct = (Struct) record.key();
        String mqttTopic = keyStruct.getString("topic");
        String username = getUserNameFromMqttTopic(mqttTopic);
        String message = createButtonPressMessage(username, new String((byte[])record.value()));

        return record.newRecord(record.topic(),
                                record.kafkaPartition(),
                                Schema.STRING_SCHEMA, username,
                                Schema.BYTES_SCHEMA, message.getBytes(),
                                record.timestamp());
    }

    private String getUserNameFromMqttTopic(String mqttTopic) {
        String[] segments = mqttTopic.split("/");
        return segments[segments.length - 1];
    }

    private String createButtonPressMessage(String user, String buttons) {
        return "{" +
                "\"user\":\"" + user + "\", " +
                "\"buttons\":\"" + buttons + "\"" +
            "}";

    }

    @Override
    public void configure(Map<String, ?> arg0) {}

    @Override
    public ConfigDef config() {
        return new ConfigDef();
    }

    @Override
    public void close() {
    }
}