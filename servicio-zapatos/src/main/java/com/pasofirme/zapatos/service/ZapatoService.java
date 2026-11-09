package com.pasofirme.zapatos.service;

import com.pasofirme.zapatos.dto.CrearZapatoRequest;
import com.pasofirme.zapatos.dto.ZapatoResponse;
import java.util.List;

public interface ZapatoService {

    ZapatoResponse registrar(CrearZapatoRequest request);

    List<ZapatoResponse> listar();
}
