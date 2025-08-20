# Stage 1: Build
FROM quay.io/lib/maven:3.9.9-eclipse-temurin-21 AS mvnbuild
WORKDIR /build

# Copy POM first (for caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src src

# Build
RUN mvn clean package -DskipTests

# Stage 2: Runtime
FROM quay.io/lib/tomcat:10-jdk21
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install PostgreSQL client
RUN apt-get update \
    && apt install -y postgresql-common \
    && /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
    && apt install -y postgresql-client-16 \
    && rm -rf /var/lib/apt/lists/*

# Remove default ROOT application
RUN rm -rf "${CATALINA_HOME}/webapps/ROOT"

# Copy built artifacts from mvnbuild stage
COPY --from=mvnbuild /build/target/Biblivre6/WEB-INF/tags ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/tags
COPY --from=mvnbuild /build/target/Biblivre6/WEB-INF/templates ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/templates
COPY --from=mvnbuild /build/target/Biblivre6/WEB-INF/tlds ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/tlds
COPY --from=mvnbuild /build/target/Biblivre6/WEB-INF/lib ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/lib
COPY --from=mvnbuild /build/target/Biblivre6/WEB-INF/jsp ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/jsp
COPY --from=mvnbuild /build/target/Biblivre6/WEB-INF/classes ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/classes
COPY --from=mvnbuild /build/target/Biblivre6/WEB-INF/web.xml ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/web.xml

# Set Java options
ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions --enable-preview -Xms512m -Xmx2048m -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:+HeapDumpOnOutOfMemoryError -Djava.awt.headless=true"

# Expose port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]

FROM quay.io/lib/tomcat:10-jdk21
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
	&& apt install -y postgresql-common \
	&& /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y \
	&& apt install -y \
	postgresql-client-16 \
	&& rm -rf /var/cache/apk/*
RUN rm -rf "${CATALINA_HOME}/webapps/ROOT"
COPY target/Biblivre6/WEB-INF/tags ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/tags
COPY target/Biblivre6/WEB-INF/templates ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/templates
COPY target/Biblivre6/WEB-INF/tlds ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/tlds
COPY target/Biblivre6/WEB-INF/lib ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/lib
COPY target/Biblivre6/WEB-INF/jsp ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/jsp
COPY target/Biblivre6/WEB-INF/classes ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/classes
COPY target/Biblivre6/WEB-INF/web.xml ${CATALINA_HOME}/webapps/Biblivre6/WEB-INF/web.xml
ENV JAVA_OPTS="-XX:+UnlockExperimentalVMOptions --enable-preview"
EXPOSE 8080