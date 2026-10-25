# Multi-stage images are used ONLY for AWS. Local Java execution needs NO Docker.
# Build from the REPOSITORY ROOT: docker build -f employee-service/Dockerfile ... .
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /src
COPY pom.xml pom.xml
COPY common-web/pom.xml common-web/pom.xml
COPY employee-service/pom.xml employee-service/pom.xml
COPY common-web/src common-web/src
COPY employee-service/src employee-service/src
RUN mvn -B -ntp -pl employee-service -am -DskipTests package

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /src/employee-service/target/employee-service-1.0.0.jar /app/app.jar
USER app
EXPOSE 8081
ENTRYPOINT ["java","-XX:MaxRAMPercentage=70.0","-jar","/app/app.jar"]
