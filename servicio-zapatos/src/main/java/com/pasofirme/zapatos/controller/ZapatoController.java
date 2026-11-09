package com.pasofirme.zapatos.controller;

import com.pasofirme.zapatos.dto.CrearZapatoRequest;
import com.pasofirme.zapatos.dto.ZapatoResponse;
import com.pasofirme.zapatos.service.ZapatoService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/zapatos")
public class ZapatoController {

    private final ZapatoService zapatoService;

    public ZapatoController(ZapatoService zapatoService) {
        this.zapatoService = zapatoService;
    }

    @PostMapping
    public ResponseEntity<ZapatoResponse> registrar(@Valid @RequestBody CrearZapatoRequest request) {
        ZapatoResponse respuesta = zapatoService.registrar(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(respuesta);
    }

    @GetMapping
    public ResponseEntity<List<ZapatoResponse>> listar() {
        List<ZapatoResponse> lista = zapatoService.listar();
        return ResponseEntity.ok(lista);
    }
}
