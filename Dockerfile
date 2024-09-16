# Step 1: Build the application
# Use a Maven image to build the WAR file
FROM maven:3.8.6-openjdk-11 AS build

# Set the working directory in the container
WORKDIR /app

# Copy the Maven project files to the container
COPY pom.xml .
COPY src ./src

# Build the project and package the WAR file
RUN mvn clean package

# Step 2: Run the application
# Use a Tomcat image to run the WAR file
FROM tomcat:9-jdk11

# Remove the default web apps from Tomcat
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR file from the build stage to the Tomcat webapps directory
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/

# Expose the port Tomcat runs on
EXPOSE 8080

# Set the default command to run Tomcat
CMD ["catalina.sh", "run"]



# # IF you have already target file
# # Use a Tomcat image to run the application
# FROM tomcat:9-jdk11

# # Remove default web apps from Tomcat
# RUN rm -rf /usr/local/tomcat/webapps/*

# # Copy the pre-built WAR file from the host machine to the Tomcat webapps directory
# COPY target/*.war /usr/local/tomcat/webapps/

# # Expose port 8080 to access the application
# EXPOSE 8080

# # Default command to run Tomcat
# CMD ["catalina.sh", "run"]

