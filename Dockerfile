FROM node:22-bookworm-slim

# This fork uses puppeteer-core, which never downloads a browser. The image has
# to provide one itself, along with the Chromium runtime libraries.
RUN apt-get update \
   && apt-get install -y --no-install-recommends \
   chromium \
   ca-certificates \
   fonts-liberation \
   && apt-get -q -y clean \
   && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /aws-azure-login

COPY package.json package-lock.json ./

RUN npm ci --omit=dev \
   && npm cache clean --force

COPY lib ./lib

# Chromium's sandbox needs privileges this container does not have, hence the
# --no-sandbox below; dropping root limits what that exposes.
RUN chown -R node:node /aws-azure-login
USER node

ENTRYPOINT ["node", "/aws-azure-login/lib", "--no-sandbox"]
