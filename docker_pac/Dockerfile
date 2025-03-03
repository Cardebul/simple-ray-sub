FROM python:3.13

WORKDIR /app

RUN apt-get update && apt-get install -y vim && pip install poetry

COPY pyproject.toml poetry.lock ./

RUN poetry config virtualenvs.create false && poetry install --no-root

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
