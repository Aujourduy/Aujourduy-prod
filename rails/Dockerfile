FROM ruby:3.2

# Installation des dépendances système incluant Node.js et Chromium
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    curl \
    git \
    chromium \
    chromium-driver \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copie les fichiers Gemfile et Gemfile.lock
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copie package.json et package-lock.json
COPY package.json package-lock.json ./
RUN npm install

# Copie tout le reste du projet
COPY . .

# Compile Tailwind CSS
RUN npm run build:css

# Précompile les assets Rails (en production)
RUN SECRET_KEY_BASE=dummy_for_precompile RAILS_ENV=production bundle exec rake assets:precompile

# Crée les dossiers nécessaires au runtime
RUN mkdir -p tmp/pids log

EXPOSE 3000
