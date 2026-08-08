{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    // Usar la copia de CanvasKit incluida en la build en vez del CDN de
    // Google (gstatic.com) — si ese dominio no es alcanzable en la red del
    // usuario (bloqueos de red, DNS, etc.) la app se queda en blanco para
    // siempre esperando un archivo que nunca va a llegar.
    canvasKitBaseUrl: "canvaskit/",
  },
});
