# Build Stage using maven-3.9.11-eclipse-temurin version 17
# on alpine linux for a smaller image size
# with a specific sha256 digest for security and consistency

FROM maven:3.9.11-eclipse-temurin-17-alpine@sha256:5d774e0953f89cf5c07bbb22924aede9b0a351c24faccd6a759de4c3f209cac7 AS build

WORKDIR /app

COPY ./pom.xml . 

RUN mvn dependency:go-offline -B

COPY ./src ./src

RUN mvn clean package -DskipTests


# Runtime Stage using eclipse-temurin version 17 on alpine linux

FROM eclipse-temurin:17-jre-alpine@sha256:e7ed585b34913e0a780e0282330183a0ea14ad6b929362d02aea1156b43262bf AS runtime

WORKDIR /app

# Create a non-root user and group for more secure execution
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the application jar and set ownership
COPY --from=build /app/target/*jar /app/app.jar
RUN chown appuser:appgroup /app/app.jar

# Switch to the non-root user
USER appuser

EXPOSE 8080


# HEALTHCHECK --interval=30s --timeout=3s \
# CMD curl --fail http://localhost:8080/actuator/health || exit 1

ENTRYPOINT [ "java", "-jar", "app.jar" ]