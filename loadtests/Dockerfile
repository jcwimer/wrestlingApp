FROM mcr.microsoft.com/playwright:v1.63.0-noble

WORKDIR /loadtests

RUN apt-get update \
    && apt-get install -y --no-install-recommends maven openjdk-21-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

COPY pom.xml ./
RUN mvn -q dependency:go-offline
RUN mvn -q test-compile

COPY package.json package-lock.json ./
RUN npm ci

COPY src ./src
COPY browser-operators.js ./browser-operators.js
COPY run.sh ./run.sh
RUN chmod +x ./run.sh

ENTRYPOINT ["./run.sh"]
