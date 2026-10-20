#!/usr/bin/env bash
# ==============================================================================
# Script de Compilação Automatizada de Livros para PDF via Pandoc e XeLaTeX
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo "Compilando Livro 1: Lazarus IDE & LCL..."
echo "=========================================================="

pandoc \
  Livro1_Lazarus_LCL/00_Apresentacao_e_Sumario.md \
  Livro1_Lazarus_LCL/Modulo_*.md \
  -o Livro1_Lazarus_LCL_Completo.pdf \
  --pdf-engine=xelatex \
  --toc \
  --toc-depth=3 \
  --number-sections \
  -V geometry:margin=2cm \
  -V fontsize=11pt \
  -V lang=pt-BR

echo "Livro 1 compilado com sucesso -> Livro1_Lazarus_LCL_Completo.pdf"

echo "=========================================================="
echo "Compilando Livro 2: Delphi 12 Athens+ VCL & FMX..."
echo "=========================================================="

pandoc \
  Livro2_Delphi_VCL_FMX/00_Apresentacao_e_Sumario.md \
  Livro2_Delphi_VCL_FMX/Modulo_*.md \
  -o Livro2_Delphi_Completo.pdf \
  --pdf-engine=xelatex \
  --toc \
  --toc-depth=3 \
  --number-sections \
  -V geometry:margin=2cm \
  -V fontsize=11pt \
  -V lang=pt-BR

echo "Livro 2 compilado com sucesso -> Livro2_Delphi_Completo.pdf"
echo "Processo finalizado com êxito!"
