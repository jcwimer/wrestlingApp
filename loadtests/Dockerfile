FROM mcr.microsoft.com/playwright:v1.63.0-noble

WORKDIR /loadtests

RUN apt-get update \
    && apt-get install -y --no-install-recommends maven openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

COPY pom.xml ./
RUN mvn -q dependency:go-offline dependency:resolve-plugins

COPY src ./src
RUN mvn -q test-compile
RUN mvn -q gatling:help
RUN mvn -q -o gatling:help

COPY package.json package-lock.json ./
RUN npm ci
COPY browser-operators.js ./browser-operators.js
COPY run.sh ./run.sh
RUN chmod +x ./run.sh

ENTRYPOINT ["./run.sh"]
