FROM alpine:3

RUN apk add --no-cache \
	bash \
	tesseract-ocr \
    tesseract-ocr-data-osd \
	tesseract-ocr-data-deu \
	tesseract-ocr-data-eng \
	ocrmypdf \
	&& rm -rf /var/cache/apk/*

RUN addgroup -S ocr \
	&& adduser -S -G ocr ocr
	
RUN mkdir -p /app /input /output /tmp \
	&& chown -R ocr:ocr /app /output /tmp

USER ocr
WORKDIR /app

COPY --chown=ocr:ocr --chmod=500 watch-and-convert.sh /app/watch-and-convert.sh

ENV INPUT_DIR=/input
ENV OUTPUT_DIR=/output
ENV SCAN_INTERVAL=120
ENV MODE=loop

CMD ["/bin/bash", "/app/watch-and-convert.sh"]


# docker run --rm -it --read-only --tmpfs /tmp -v C:\_dev\docker\filewatcher-pdf-to-pdfa-with-ocr\myinput:/input:ro -v C:\_dev\docker\filewatcher-pdf-to-pdfa-with-ocr\myoutput:/output -e MODE=once pdfocr

