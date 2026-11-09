package com.pasofirme.configdemo.server;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.cloud.config.server.git.uri=https://github.com/Dan101111111/pasofirme-config-repo.git",
    "spring.cloud.config.server.git.clone-on-start=false"
})
class ConfigServerDemoApplicationTests {

    @Test
    void contextLoads() {
    }
}

