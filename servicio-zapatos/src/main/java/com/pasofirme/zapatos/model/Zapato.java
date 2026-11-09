package com.pasofirme.zapatos.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Objects;

@Entity
@Table(name = "zapato")
public class Zapato {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id")
    private Long id;

    @Column(name = "marca", length = 100, nullable = false)
    private String marca;

    @Column(name = "talla")
    private Integer talla;

    @Column(name = "precio", precision = 10, scale = 2)
    private BigDecimal precio;

    @Column(name = "fecha_ingreso")
    private LocalDate fechaIngreso;

    @Column(name = "disponible")
    private Boolean disponible;

    public Zapato() {
    }

    public Zapato(String marca, Integer talla, BigDecimal precio, LocalDate fechaIngreso, Boolean disponible) {
        this.marca = marca;
        this.talla = talla;
        this.precio = precio;
        this.fechaIngreso = fechaIngreso;
        this.disponible = disponible;
    }

    public Zapato(Long id, String marca, Integer talla, BigDecimal precio, LocalDate fechaIngreso, Boolean disponible) {
        this.id = id;
        this.marca = marca;
        this.talla = talla;
        this.precio = precio;
        this.fechaIngreso = fechaIngreso;
        this.disponible = disponible;
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

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Zapato zapato = (Zapato) o;
        return Objects.equals(id, zapato.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "Zapato{" +
                "id=" + id +
                ", marca='" + marca + '\'' +
                ", talla=" + talla +
                ", precio=" + precio +
                ", fechaIngreso=" + fechaIngreso +
                ", disponible=" + disponible +
                '}';
    }
}
