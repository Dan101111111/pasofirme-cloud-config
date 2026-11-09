package com.pasofirme.zapatos.repository;

import com.pasofirme.zapatos.model.Zapato;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ZapatoRepository extends JpaRepository<Zapato, Long> {

    List<Zapato> findAllByOrderByIdAsc();
}
