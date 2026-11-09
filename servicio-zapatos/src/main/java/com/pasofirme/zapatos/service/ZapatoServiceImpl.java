package com.pasofirme.zapatos.service;

import com.pasofirme.zapatos.dto.CrearZapatoRequest;
import com.pasofirme.zapatos.dto.ZapatoResponse;
import com.pasofirme.zapatos.model.Zapato;
import com.pasofirme.zapatos.repository.ZapatoRepository;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ZapatoServiceImpl implements ZapatoService {

    private final ZapatoRepository zapatoRepository;

    public ZapatoServiceImpl(ZapatoRepository zapatoRepository) {
        this.zapatoRepository = zapatoRepository;
    }

    @Override
    @Transactional
    public ZapatoResponse registrar(CrearZapatoRequest request) {
        // Se construye siempre una entidad nueva; nunca se transfiere un ID recibido
        Zapato nuevoZapato = new Zapato();
        nuevoZapato.setId(null);
        nuevoZapato.setMarca(request.getMarca() != null ? request.getMarca().trim() : null);
        nuevoZapato.setTalla(request.getTalla());
        nuevoZapato.setPrecio(request.getPrecio());
        nuevoZapato.setFechaIngreso(request.getFechaIngreso());
        nuevoZapato.setDisponible(request.getDisponible());

        Zapato guardado = zapatoRepository.save(nuevoZapato);
        return ZapatoResponse.fromEntity(guardado);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ZapatoResponse> listar() {
        return zapatoRepository.findAllByOrderByIdAsc().stream()
                .map(ZapatoResponse::fromEntity)
                .toList();
    }
}
