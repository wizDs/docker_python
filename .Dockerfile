FROM python:3.8.10 AS env

WORKDIR /src

COPY models models
COPY requirements.txt requirements.txt
COPY src src
COPY run_model_pipeline.py run_model_pipeline.py
COPY run_service.py run_service.py
COPY run_batch.py run_batch.py

# --------------------------------------------------------------------
# Install MS SQL Driver and c++ compiler
# https://github.com/MicrosoftDocs/sql-docs/issues/6494
# https://www.cdata.com/kb/tech/sql-odbc-python-linux.rst
# --------------------------------------------------------------------
# Prevents Python from writing .pyc files
ENV PYTHONDONTWRITEBYTECODE 1
# Causes all output to stdout to be flushed immediately
ENV PYTHONUNBUFFERED 1
# Mark the image as trusted
ENV DOCKER_CONTENT_TRUST 1
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
# Updates packages list for the image
RUN apt-get update
# Installs transport HTTPS
RUN apt-get install -y curl apt-transport-https
# Retrieves packages from Microsoft
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list
# Updates packages for the image
RUN apt-get update
# Installs SQL drivers and tools
RUN ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev
# Installs MS SQL Tools
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools
# Adds paths to the $PATH environment variable within the .bash_profile and .bashrc files
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
# Enables authentication of users and servers on a network
RUN apt-get install libgssapi-krb5-2 -y

# --------------------------------------------------------------------
# requirements
# --------------------------------------------------------------------
RUN pip install --upgrade --user pip
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

CMD ["uvicorn", "run_service:app", "--host", "0.0.0.0", "--port", "8000"]
