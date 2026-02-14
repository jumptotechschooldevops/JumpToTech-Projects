# Multi-stage build to reduce final image size
FROM maven:3.8.6-openjdk-11-slim AS builder

WORKDIR /app

# copy pom first to leverage docker layer caching
COPY pom.xml .
RUN mvn dependency:go-offline -B

# now copy source and build
COPY src ./src
RUN mvn clean package -DskipTests

# runtime stage - keep it small
FROM openjdk:11-jre-slim

WORKDIR /app

# security: don't run as root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# copy jar from build stage
COPY --from=builder /app/target/task-manager-api-*.jar app.jar

RUN chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

# basic health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
