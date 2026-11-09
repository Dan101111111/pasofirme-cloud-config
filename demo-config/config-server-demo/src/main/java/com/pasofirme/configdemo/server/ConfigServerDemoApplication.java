package com.pasofirme.configdemo.server;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;

/**
 * Servidor centralizado de configuración Spring Cloud Config Server
 * para la demostración de configuración distribuida de PasoFirme.
 */
@SpringBootApplication
@EnableConfigServer
public class ConfigServerDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(ConfigServerDemoApplication.class, args);
    }
}

