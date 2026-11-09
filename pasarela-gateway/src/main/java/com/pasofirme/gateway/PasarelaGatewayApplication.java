package com.pasofirme.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

@SpringBootApplication
@EnableDiscoveryClient
public class PasarelaGatewayApplication {

    public static void main(String[] args) {
        SpringApplication.run(PasarelaGatewayApplication.class, args);
    }
}

