# Use the official Gradle image as the base image
FROM gradle:8.11.1-jdk21 AS build

# Set the working directory
WORKDIR /app

# Copy the Gradle wrapper and project files
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

RUN chmod +x gradlew

# Copy the Zscaler certificate
COPY zscaler.cer /usr/local/share/ca-certificates/zscaler.crt

# Install ca-certificates package and update the certificate authorities
RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates

# Add the Zscaler certificate to the Java trust store
RUN keytool -importcert -file /usr/local/share/ca-certificates/zscaler.crt -alias zscaler -cacerts -storepass changeit -noprompt

# Build the project
RUN ./gradlew build --no-daemon --stacktrace --info --console=plain || return 0

# Copy the rest of the project files
COPY src src

# Build the project
RUN ./gradlew build --no-daemon --stacktrace --info --console=plain

# Use a lightweight JDK image for the runtime
FROM eclipse-temurin:21-jre-alpine

# Set the working directory
WORKDIR /app

# Copy the built application from the build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Expose the application port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]