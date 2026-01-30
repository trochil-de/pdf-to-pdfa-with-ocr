#!/bin/bash
set -eu

INPUT_DIR="${INPUT_DIR:-/input}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
SCAN_INTERVAL="${SCAN_INTERVAL:-120}"
MODE="${MODE:-loop}"

process_pdf() {
	original_file="$1"
	base_filename="$(basename "$original_file" .pdf)"
	base_filename_with_type="$(basename "$original_file")"
	rel_path="${original_file#"$INPUT_DIR"/}"
	rel_dir="$(dirname "$rel_path")"

	if [[ "$rel_dir" == "." ]]; then
		out_dir="$OUTPUT_DIR"
	else
		out_dir="$OUTPUT_DIR/$rel_dir"
	fi
		
	output_file="$out_dir/$base_filename.ocr.pdf"
	checksum_file="$out_dir/$base_filename_with_type.sha246"
	failure_file="$out_dir/$base_filename_with_type.failure"
	lock_file="$out_dir/$base_filename_with_type.lock"
	
	if [ -f "$checksum_file" ]; then
        return
    fi
	
    echo "🔍 Processing: $original_file ➡️ $output_file"
	mkdir -p $out_dir
		
	if ! ( set -C; > "$lock_file" ) 2> /dev/null; then
		echo "⏳ $base_filename_with_type is being processed by another instance"
	fi
	
    # OCR ausführen, Fehler nicht das Skript stoppen lassen
	if ! ocrmypdf -l "deu" --rotate-pages --force-ocr --output-type pdfa-1 --optimize 0 --pdfa-image-compression lossless "$original_file" "$output_file" 2> "$lock_file"; then
		echo "⚠️ OCR failed for $original_file, skipping..."
		return
	fi

    # Prüfsumme schreiben
    sha256sum "$original_file" > "$checksum_file"

    rm -f "$lock_file"
	
	echo "✅ Done: $(basename "$original_file")"
}

scan_input() {
    find "$INPUT_DIR" -type f -name "*.pdf" | while read -r pdf; do
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
