FROM python:3.12-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# CI에서 --build-arg APP_VERSION=<git short sha> 로 넘겨 이미지에 굽는다.
# 화면 하단 빌드 표시 + /healthz 응답에 사용 (배포가 실제로 새 버전인지 확인하는 용도).
ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

EXPOSE 8080
# CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]
CMD ["gunicorn", "-b", "0.0.0.0:8080", "--workers", "2", "--threads", "4", "--timeout", "60", "app:app"]

