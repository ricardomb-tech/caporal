package co.caporal.api.infraestructura.web;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/** Páginas públicas que sirve la API: la política de privacidad que piden las tiendas de apps. */
@Configuration
public class PaginasPublicas implements WebMvcConfigurer {
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        registry.addViewController("/privacidad").setViewName("forward:/privacidad.html");
    }
}
