# Multi-stage images are used ONLY for AWS. Local Java execution needs NO Docker.
# Build from the REPOSITORY ROOT: docker build -f leave-service/Dockerfile ... .
FROM maven:3.9.9-eclipse-temurin-21 AS builder
WORKDIR /src
COPY pom.xml pom.xml
COPY common-web/pom.xml common-web/pom.xml
COPY leave-service/pom.xml leave-service/pom.xml
COPY common-web/src common-web/src
COPY leave-service/src leave-service/src
RUN mvn -B -ntp -pl leave-service -am -DskipTests package

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=builder /src/leave-service/target/leave-service-1.0.0.jar /app/app.jar
USER app
EXPOSE 8082
ENTRYPOINT ["java","-XX:MaxRAMPercentage=70.0","-jar","/app/app.jar"]
