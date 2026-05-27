FROM alpine:latest
# Google API larga ulanish uchun muhim SSL sertifikatlari:
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY ilm_ai_backend .
COPY .env .
COPY service-account.json .
EXPOSE 8080
CMD ["./ilm_ai_backend"]