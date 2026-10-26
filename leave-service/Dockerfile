
# ==========================================
# Stage 1: Build Leave Service
# ==========================================
FROM maven:3.9.9-eclipse-temurin-21 AS builder

WORKDIR /src

# Copy all module POM files.
COPY pom.xml .
COPY common-web/pom.xml common-web/pom.xml
COPY employee-service/pom.xml employee-service/pom.xml
COPY leave-service/pom.xml leave-service/pom.xml

# Copy only the source code required by Leave Service.
COPY common-web/src common-web/src
COPY leave-service/src leave-service/src

# Build Leave Service and its dependencies.
RUN mvn -B -ntp -pl leave-service -am -DskipTests package

# ==========================================
# Stage 2: Run Leave Service
# ==========================================
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S app && adduser -S app -G app

WORKDIR /app

COPY --from=builder \
    /src/leave-service/target/*.jar \
    /app/application.jar

USER app

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "/app/application.jar"]
