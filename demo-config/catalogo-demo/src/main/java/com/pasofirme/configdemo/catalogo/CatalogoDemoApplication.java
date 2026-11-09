package com.pasofirme.configdemo.catalogo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Microservicio cliente de Catálogo de Calzado para demostración de Spring Cloud Config.
 */
@SpringBootApplication
public class CatalogoDemoApplication {

    public static void main(String[] args) {
        SpringApplication.run(CatalogoDemoApplication.class, args);
    }
}

