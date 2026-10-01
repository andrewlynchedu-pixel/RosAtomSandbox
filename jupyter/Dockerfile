FROM jupyter/base-notebook:python-3.11

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}
RUN pip install --no-cache-dir \
    psycopg2-binary==2.9.9 \
    sqlalchemy==2.0.32 \
    pandas==2.2.2 \
    matplotlib==3.8.4 \
    seaborn==0.13.2 \
    ipython-sql==0.5.0 \
    openpyxl==3.1.5
