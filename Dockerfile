FROM python:3.11-bullseye as builder

RUN apt update && \
    apt upgrade  -y

RUN pip install poetry==1.7.0

ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

COPY poetry.lock pyproject.toml ./
RUN poetry install --no-root && rm -rf $POETRY_CACHE_DIR

FROM python:3.11-bullseye as runner

ENV VIRTUAL_ENV=.venv 

COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

COPY index_scrapy ./index_scrapy
COPY queries ./queries

COPY scrape.py ./
COPY config.json ./

ENTRYPOINT [".venv/bin/python", "scrape.py"]