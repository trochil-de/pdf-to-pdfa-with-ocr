#!/bin/bash
set -eu

INPUT_DIR="${INPUT_DIR:-/input}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
SCAN_INTERVAL="${SCAN_INTERVAL:-120}"
LANG="${LANG:-deu}"
MODE="${MODE:-loop}"

process_pdf() {
	original_file="$1"
	base="$(basename "$original_file" .pdf)"
	output_file="$OUTPUT_DIR/$base.ocr.pdf"
	checksum_file="$OUTPUT_DIR/$base.pdf.sha246"
	lock_file="$OUTPUT_DIR/$base.pdf.lock"
	
	if [ -f "$checksum_file" ]; then
        return
    fi
	
    echo "🔍 Processing $pdf"
	
	if ! ( set -C; > "$lock_file" ) 2> /dev/null; then
		echo "⏳ $base is being processed by another instance"
	fi
	
	ocrmypdf -l "$LANG" --force-ocr --output-type pdfa "$original_file" "$output_file"
	
	sha256sum "$original_file" > "$checksum_file"
	
	rm "$lock_file"
	
	echo "✅ Done: $(basename "$original_file")"
}

scan_input() {
    find "$INPUT_DIR" -maxdepth 1 -type f -name "*.pdf" | while read -r pdf; do
        process_pdf "$pdf"
    done
}


echo "📄 OCR Scanner started"
echo "Input : $INPUT_DIR"
echo "Output: $OUTPUT_DIR"

if [ "$MODE" = "loop" ]; then
	while true; do
		scan_input
		sleep "$SCAN_INTERVAL"
	done
elif [ "$MODE" = "once" ]; then
	scan_input
	exit 0
else
	echo "Unknown mode \"$MODE\"" 1>&2;
	exit 1
fi
