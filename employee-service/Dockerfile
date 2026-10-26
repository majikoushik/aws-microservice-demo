
# ==========================================
# Stage 1: Build Employee Service
# ==========================================
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /src

# Copy Maven project definitions.
COPY pom.xml .
COPY common-web/pom.xml common-web/pom.xml
COPY employee-service/pom.xml employee-service/pom.xml
COPY leave-service/pom.xml leave-service/pom.xml

# Copy the application source code.
COPY common-web/src common-web/src
COPY employee-service/src employee-service/src

# Maven now recognizes all declared modules.
# -pl selects Employee Service.
# -am builds its required dependencies.
RUN mvn -B -ntp -pl employee-service -am -DskipTests package

# ==========================================
# Stage 2: Run Employee Service
# ==========================================
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=builder \
    /src/employee-service/target/*.jar \
    /app/application.jar

USER app

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app/application.jar"]
