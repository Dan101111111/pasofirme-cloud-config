package com.pasofirme.zapatos.dto;

import com.pasofirme.zapatos.model.Zapato;
import java.math.BigDecimal;
import java.time.LocalDate;

public class ZapatoResponse {

    private Long id;
    private String marca;
    private Integer talla;
    private BigDecimal precio;
    private LocalDate fechaIngreso;
    private Boolean disponible;

    public ZapatoResponse() {
    }

    public ZapatoResponse(Long id, String marca, Integer talla, BigDecimal precio, LocalDate fechaIngreso, Boolean disponible) {
        this.id = id;
        this.marca = marca;
        this.talla = talla;
        this.precio = precio;
        this.fechaIngreso = fechaIngreso;
        this.disponible = disponible;
    }

    public static ZapatoResponse fromEntity(Zapato zapato) {
        if (zapato == null) {
            return null;
        }
        return new ZapatoResponse(
                zapato.getId(),
                zapato.getMarca(),
                zapato.getTalla(),
                zapato.getPrecio(),
                zapato.getFechaIngreso(),
                zapato.getDisponible()
        );
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getMarca() {
        return marca;
    }

    public void setMarca(String marca) {
        this.marca = marca;
    }

    public Integer getTalla() {
        return talla;
    }

    public void setTalla(Integer talla) {
        this.talla = talla;
    }

    public BigDecimal getPrecio() {
        return precio;
    }

    public void setPrecio(BigDecimal precio) {
        this.precio = precio;
    }

    public LocalDate getFechaIngreso() {
        return fechaIngreso;
    }

    public void setFechaIngreso(LocalDate fechaIngreso) {
        this.fechaIngreso = fechaIngreso;
    }

    public Boolean getDisponible() {
        return disponible;
    }

    public void setDisponible(Boolean disponible) {
        this.disponible = disponible;
    }
}
