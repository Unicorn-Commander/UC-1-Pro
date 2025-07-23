# Tika OCR

Tika OCR is a service for extracting text and metadata from a wide variety of file formats, including PDFs and images.

## Key Features

- **Broad File Format Support**: Can extract text from over a thousand different file types.
- **OCR Support**: Uses Tesseract OCR to extract text from images and scanned PDFs.
- **Language Detection**: Can automatically detect the language of the text.

## Service Configuration

- **Build Context**: `services/tika-ocr`
- **Port**: `9998`

## Environment Variables

- `TIKA_OCR_STRATEGY`: The OCR strategy to use.
- `TIKA_OCR_LANGUAGE`: The languages to use for OCR.
