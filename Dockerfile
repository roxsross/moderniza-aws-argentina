FROM amazoncorretto:21 AS base
WORKDIR /app

# Copiar archivos de configuración
COPY build.gradle settings.gradle ./
COPY gradle gradle
COPY gradlew ./

# Descargar dependencias
RUN ./gradlew dependencies --no-daemon

# Copiar código fuente
COPY src ./src

FROM base AS development
EXPOSE 8080 8000
CMD ["./gradlew", "bootRun", "--no-daemon", \
     "-Dspring-boot.run.profiles=mysql", \
     "-Dspring-boot.run.jvmArguments='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:8000'"]

FROM base AS build
RUN ./gradlew assemble --no-daemon

FROM amazoncorretto:21 AS production
WORKDIR /app
EXPOSE 8080

COPY --from=build /app/build/libs/*.jar /app/spring-petclinic.jar

CMD ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app/spring-petclinic.jar"]
