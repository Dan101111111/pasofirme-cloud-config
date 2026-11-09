package com.pasofirme.configdemo.envios;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Microservicio cliente de Logística y Envíos de Calzado para demostración de Spring Cloud Config.
 */
@SpringBootApplication
public class EnviosDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(EnviosDemoApplication.class, args);
    }
}

