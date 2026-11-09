package com.pasofirme.configdemo.envios;

import org.springframework.stereotype.Component;
import java.util.UUID;

/**
 * Bean Singleton NO refrescable.
 * Genera un identificador único al iniciar la aplicación.
 * Demuestra que tras un POST /actuator/refresh, la JVM y los beans singleton
 * conservan su ciclo de vida y no sufren reinicio.
 */
@Component
public class InstanciaArranqueHolder {

    private final String instanciaArranque = UUID.randomUUID().toString();

    public String getInstanciaArranque() {
        return instanciaArranque;
    }
}

