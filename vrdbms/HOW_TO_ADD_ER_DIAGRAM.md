# How to Add ER Diagram Image to LaTeX Report

## Current Status
The ER diagram image is currently commented out because the image file doesn't exist yet.

## Steps to Add Your ER Diagram:

### Option 1: If you have the ER diagram image file

1. **Save your ER diagram as an image:**
   - Format: PNG, JPG, or PDF (PNG recommended)
   - Name: `ER_Diagram.png` (or any name you prefer)
   - Location: Save it in the same folder as `PROJECT_REPORT.tex`
     - Path: `/Users/ceejayy/Documents/180B_Project1/vrdbms/`

2. **Update the LaTeX file:**
   - Open `PROJECT_REPORT.tex`
   - Find line ~105 (around the `\includegraphics` command)
   - Uncomment the line:
     ```latex
     \includegraphics[width=0.9\textwidth]{ER_Diagram.png}
     ```
   - If your image has a different name, change `ER_Diagram.png` to your filename

3. **Recompile:**
   ```bash
   pdflatex PROJECT_REPORT.tex
   pdflatex PROJECT_REPORT.tex
   ```

### Option 2: If you need to create/export the ER diagram

**From Database Tools:**
- **pgAdmin:** Right-click database → "ERD For Database" → Export as PNG/PDF
- **MySQL Workbench:** Database → Reverse Engineer → Export as PNG
- **dbdiagram.io:** Export → PNG/PDF
- **Draw.io:** File → Export as → PNG/PDF

**From ER Diagram Tools:**
- **Lucidchart:** Export → PNG/PDF
- **dbdiagram.io:** Export → PNG/PDF
- **Draw.io:** File → Export as → PNG/PDF

### Option 3: Use a placeholder (for now)

If you don't have the image yet, the figure caption will still appear in the PDF, but without the image. You can add the image later.

## Image Requirements:

- **Format:** PNG, JPG, or PDF
- **Resolution:** At least 300 DPI for good quality
- **Size:** The image will be scaled to fit, but larger is better
- **Location:** Same directory as PROJECT_REPORT.tex

## Current LaTeX Code:

```latex
\begin{figure*}[htbp]
\centering
\includegraphics[width=0.9\textwidth]{ER_Diagram.png}
\caption{Entity-Relationship Diagram for Vehicle Rental Database Management System}
\label{fig:er_diagram}
\end{figure*}
```

## Troubleshooting:

**Image not showing?**
- Check the filename matches exactly (case-sensitive on some systems)
- Check the file is in the same directory as the .tex file
- Try using full path: `\includegraphics[width=0.9\textwidth]{/full/path/to/ER_Diagram.png}`

**Image too large/small?**
- Adjust width: `width=0.8\textwidth` (smaller) or `width=\textwidth` (larger)
- Use `height` instead: `height=0.5\textheight`

**Wrong format?**
- Convert to PNG using online tools or image editors
- Or use PDF: `ER_Diagram.pdf`

---

**Once you have the image file, uncomment line 105 in PROJECT_REPORT.tex and recompile!**



