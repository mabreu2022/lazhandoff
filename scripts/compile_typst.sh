#!/usr/bin/env bash
# ==============================================================================
# Script de Compilação Automatizada de Livros para PDF via Typst
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "Compilando Livros via Typst..."
echo "=========================================================="

# Concatena e converte markdown para typst se typst estiver instalado
if command -v typst &> /dev/null; then
  echo "Typst encontrado. Processando..."
  # Tipicamente utilizado com pandoc -t typst ou templates nativos typst
  pandoc Livro1_Lazarus_LCL/00_Apresentacao_e_Sumario.md Livro1_Lazarus_LCL/Modulo_*.md -o Livro1_Lazarus_LCL.typ
  typst compile Livro1_Lazarus_LCL.typ Livro1_Lazarus_Typst.pdf

  pandoc Livro2_Delphi_VCL_FMX/00_Apresentacao_e_Sumario.md Livro2_Delphi_VCL_FMX/Modulo_*.md -o Livro2_Delphi.typ
  typst compile Livro2_Delphi.typ Livro2_Delphi_Typst.pdf
  echo "PDFs Typst gerados com sucesso!"
else
  echo "Typst não instalado no path. Instale typst ou utilize compile_pandoc_pdf.sh"
fi
