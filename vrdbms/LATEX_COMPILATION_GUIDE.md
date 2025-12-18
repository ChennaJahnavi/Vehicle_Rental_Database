# LaTeX Compilation Guide for PROJECT_REPORT.tex

## File Created

✅ **PROJECT_REPORT.tex** - IEEE conference format LaTeX document

---

## Prerequisites

### Required Software

1. **LaTeX Distribution:**
   - **macOS:** Install MacTeX from https://www.tug.org/mactex/
   - **Linux:** `sudo apt-get install texlive-full` (Ubuntu/Debian)
   - **Windows:** Install MiKTeX from https://miktex.org/

2. **IEEE Template:**
   - The document uses `IEEEtran` class which is included in most LaTeX distributions
   - If missing, download from: https://www.ieee.org/conferences/publishing/templates.html

---

## Compilation Steps

### Method 1: Using pdflatex (Recommended)

```bash
cd /Users/ceejayy/Documents/180B_Project1/vrdbms

# First compilation (generates .aux file)
pdflatex PROJECT_REPORT.tex

# Second compilation (resolves references)
pdflatex PROJECT_REPORT.tex

# Output: PROJECT_REPORT.pdf
```

### Method 2: Using Overleaf (Online - Easiest)

1. Go to https://www.overleaf.com/
2. Create a new project
3. Upload `PROJECT_REPORT.tex`
4. Click "Recompile"
5. Download the PDF

### Method 3: Using VS Code with LaTeX Workshop Extension

1. Install "LaTeX Workshop" extension in VS Code
2. Open `PROJECT_REPORT.tex`
3. Press `Ctrl+Alt+B` (or `Cmd+Option+B` on Mac) to build
4. PDF will open automatically

---

## Customization

### Update Author Information

Edit lines 48-54 in `PROJECT_REPORT.tex`:

```latex
\author{\IEEEauthorblockN{1\textsuperscript{st} Your Name}
\IEEEauthorblockA{\textit{Department of Computer Science} \\
\textit{Your University}\\
City, Country \\
your.email@university.edu}
}
```

### Add Multiple Authors

```latex
\author{\IEEEauthorblockN{1\textsuperscript{st} First Author}
\IEEEauthorblockA{\textit{dept. name} \\
\textit{organization}\\
City, Country \\
email1@university.edu}
\and
\IEEEauthorblockN{2\textsuperscript{nd} Second Author}
\IEEEauthorblockA{\textit{dept. name} \\
\textit{organization}\\
City, Country \\
email2@university.edu}
}
```

### Update Title (if needed)

Line 45:
```latex
\title{Vehicle Rental Database Management System: Performance Optimization and Concurrency Control}
```

---

## Troubleshooting

### Error: "IEEEtran.cls not found"

**Solution:**
```bash
# Download IEEEtran.cls
wget https://www.ieee.org/content/dam/ieee-org/ieee/web/org/pubs/IEEEtran.zip
unzip IEEEtran.zip
# Copy IEEEtran.cls to your LaTeX distribution's cls folder
```

### Error: "Missing packages"

**Solution:** Install missing packages:
```bash
# On Linux
sudo apt-get install texlive-latex-extra

# On macOS (with MacTeX)
tlmgr install <package-name>
```

### Error: "Bibliography not found"

**Solution:** The document uses manual bibliography. If you want to use BibTeX:
1. Create a `.bib` file
2. Replace `\begin{thebibliography}` section with `\bibliography{filename}`
3. Run: `pdflatex → bibtex → pdflatex → pdflatex`

### Code Listings Not Showing

**Solution:** Ensure `listings` package is installed:
```bash
tlmgr install listings
```

---

## Output

After successful compilation, you'll have:
- ✅ `PROJECT_REPORT.pdf` - Final PDF document
- `PROJECT_REPORT.aux` - Auxiliary file (can be deleted)
- `PROJECT_REPORT.log` - Compilation log (can be deleted)

---

## File Structure

```
vrdbms/
├── PROJECT_REPORT.tex          ← LaTeX source file
├── PROJECT_REPORT.pdf          ← Generated PDF (after compilation)
├── PROJECT_REPORT.md           ← Original markdown version
└── LATEX_COMPILATION_GUIDE.md  ← This file
```

---

## Quick Start (macOS)

```bash
# Install MacTeX (if not installed)
# Download from: https://www.tug.org/mactex/

# Navigate to project directory
cd /Users/ceejayy/Documents/180B_Project1/vrdbms

# Compile
pdflatex PROJECT_REPORT.tex
pdflatex PROJECT_REPORT.tex

# Open PDF
open PROJECT_REPORT.pdf
```

---

## Quick Start (Linux)

```bash
# Install LaTeX (if not installed)
sudo apt-get install texlive-full

# Navigate to project directory
cd /path/to/180B_Project1/vrdbms

# Compile
pdflatex PROJECT_REPORT.tex
pdflatex PROJECT_REPORT.tex

# Open PDF
xdg-open PROJECT_REPORT.pdf
```

---

## Quick Start (Windows)

1. Install MiKTeX: https://miktex.org/download
2. Open Command Prompt
3. Navigate to project directory
4. Run: `pdflatex PROJECT_REPORT.tex` (twice)
5. Open `PROJECT_REPORT.pdf`

---

## Features Included

✅ IEEE conference paper format  
✅ Proper sectioning and subsections  
✅ Tables formatted correctly  
✅ SQL code listings with syntax highlighting  
✅ Bibliography in IEEE format  
✅ Abstract and keywords  
✅ Author information block  

---

## Notes

- The document follows IEEE conference paper guidelines
- Page limit: Typically 6 pages for conference papers (adjust if needed)
- All content from the markdown report has been converted
- Code examples use `listings` package for syntax highlighting
- Tables use `booktabs` for professional formatting

---

## Need Help?

- LaTeX Documentation: https://www.latex-project.org/help/documentation/
- IEEE Author Center: https://journals.ieeeauthorcenter.ieee.org/
- Overleaf Documentation: https://www.overleaf.com/learn

---

**Your IEEE format paper is ready to compile! 🎓**



