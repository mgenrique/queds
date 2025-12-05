FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl build-essential git libpq-dev gcc ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x (LTS at time of writing)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

WORKDIR /workspaces/queds

# Create a non-root user to match common Dev Container setups
RUN useradd -ms /bin/bash vscode || true

USER vscode
ENV HOME=/home/vscode

EXPOSE 5173 8000 5000

CMD ["sleep", "infinity"]
