FROM alpine:latest
RUN apk add --no-cache curl
RUN echo "SHRA Test Image - $(date)" > /test.txt
LABEL version="1.0"
LABEL description="Test image for SHRA scanning"
CMD ["cat", "/test.txt"]
