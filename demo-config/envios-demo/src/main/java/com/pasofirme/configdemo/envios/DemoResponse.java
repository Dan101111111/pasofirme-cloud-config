package com.pasofirme.configdemo.envios;

/**
 * Objeto de transferencia para exponer el estado de configuración de la demo.
 */
public class DemoResponse {

    private String servicio;
    private String perfil;
    private String tienda;
    private String edicion;
    private String mensaje;
    private String detalle;
    private String instanciaArranque;

    public DemoResponse() {
    }

    public DemoResponse(String servicio, String perfil, String tienda, String edicion, String mensaje, String detalle, String instanciaArranque) {
        this.servicio = servicio;
        this.perfil = perfil;
        this.tienda = tienda;
        this.edicion = edicion;
        this.mensaje = mensaje;
        this.detalle = detalle;
        this.instanciaArranque = instanciaArranque;
    }

    public String getServicio() {
        return servicio;
    }

    public void setServicio(String servicio) {
        this.servicio = servicio;
    }

    public String getPerfil() {
        return perfil;
    }

    public void setPerfil(String perfil) {
        this.perfil = perfil;
    }

    public String getTienda() {
        return tienda;
    }

    public void setTienda(String tienda) {
        this.tienda = tienda;
    }

    public String getEdicion() {
        return edicion;
    }

    public void setEdicion(String edicion) {
        this.edicion = edicion;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public String getDetalle() {
        return detalle;
    }

    public void setDetalle(String detalle) {
        this.detalle = detalle;
    }

    public String getInstanciaArranque() {
        return instanciaArranque;
    }

    public void setInstanciaArranque(String instanciaArranque) {
        this.instanciaArranque = instanciaArranque;
    }
}

