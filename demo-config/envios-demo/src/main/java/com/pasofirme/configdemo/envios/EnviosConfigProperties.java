package com.pasofirme.configdemo.envios;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.stereotype.Component;

/**
 * Componente anotado con @RefreshScope para vincular dinámicamente
 * las propiedades distribuidas por Spring Cloud Config Server.
 */
@Component
@RefreshScope
public class EnviosConfigProperties {

    @Value("${demo.tienda}")
    private String tienda;

    @Value("${demo.edicion}")
    private String edicion;

    @Value("${demo.mensaje}")
    private String mensaje;

    @Value("${demo.detalle}")
    private String detalle;

    public String getTienda() {
        return tienda;
    }

    public String getEdicion() {
        return edicion;
    }

    public String getMensaje() {
        return mensaje;
    }

    public String getDetalle() {
        return detalle;
    }
}

