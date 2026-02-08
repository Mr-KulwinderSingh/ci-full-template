FROM gitpod/workspace-base

USER gitpod

### NodeJS (Using NVM) ###
ENV NODE_VERSION=16.13.0
RUN curl -fsSL https://raw.githubusercontent.com | bash \
    && bash -c ". $HOME/.nvm/nvm.sh \
        && nvm install $NODE_VERSION \
        && nvm use $NODE_VERSION \
        && nvm alias default $NODE_VERSION \
        && npm install -g typescript yarn node-gyp" \
    && echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc.d/50-node \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc.d/50-node
# Corrected PATH for Node
ENV PATH=$HOME/.nvm/versions/node/v${NODE_VERSION}/bin:$PATH

### Python (Using pyenv) ###
ENV PYTHON_VERSION=3.12.2
ENV PYENV_ROOT=$HOME/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH

RUN curl https://pyenv.run | bash \
    && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc.d/60-python \
    && echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc.d/60-python \
    && echo 'eval "$(pyenv init -)"' >> ~/.bashrc.d/60-python \
    && pyenv install $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION \
    && python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel virtualenv pipenv pylint

### Heroku CLI ###
RUN curl https://cli-assets.heroku.com/install.sh | sudo sh

### MongoDB 6.0 & PostgreSQL 12 ###
RUN sudo apt-get update && sudo apt-get install -y gnupg wget \
    && wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list \
    && sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | tee /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org | sudo apt-key add - \
    && sudo apt-get update \
    && sudo apt-get install -y mongodb-mongosh postgresql-12 postgresql-client-12 \
    && sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* /tmp/*

### Database Configs ###
ENV PGDATA="/workspace/.pgsql/data"
ENV PATH="/usr/lib/postgresql/12/bin:$HOME/.pg_ctl/bin:$PATH"

RUN mkdir -p ~/.pg_ctl/bin \
    && echo '#!/bin/bash\n[ ! -d $PGDATA ] && initdb --auth=trust -D $PGDATA\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k /tmp" start' > ~/.pg_ctl/bin/pg_start \
    && echo '#!/bin/bash\npg_ctl -D $PGDATA stop' > ~/.pg_ctl/bin/pg_stop \
    && chmod +x ~/.pg_ctl/bin/*

### Aliases & Env ###
RUN echo 'alias python=python3' >> ~/.bashrc \
    && echo 'alias pip=pip3' >> ~/.bashrc \
    && echo 'alias mongo=mongosh' >> ~/.bashrc

ENV PORT="8080"
ENV DANGEROUSLY_DISABLE_HOST_CHECK=true
