site_name: SLOTH 
repo_url: https://github.com/Collab4Sloth/
use_directory_urls: false
copyright: Copyright &copy; 2024 C. Introïni, R. Prat [(CEA.IRESNE.DEC)
generate: true
markdown_extensions:  
  - toc:
      permalink: true
  - attr_list
  - pymdownx.emoji:
      emoji_index: !!python/name:material.extensions.emoji.twemoji
      emoji_generator: !!python/name:material.extensions.emoji.to_svg
  - md_in_html
  - pymdownx.superfences
  - pymdownx.tabbed:
      alternate_style: true
  - admonition
  - pymdownx.details
  - pymdownx.highlight:
      anchor_linenums: true
      line_spans: __span
      pygments_lang_class: true
  - pymdownx.inlinehilite
  - pymdownx.snippets:
      base_path: $relative
  - pymdownx.superfences
  - def_list
  - pymdownx.tasklist:
      custom_checkbox: true
  - pymdownx.arithmatex:
      generic: true
  - footnotes
extra_javascript:
  - javascripts/mathjax.js
  - https://polyfill.io/v3/polyfill.min.js?features=es6
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js


# extra_javascript:
#   - javascripts/katex.js
#   - https://unpkg.com/katex@0/dist/katex.min.js
#   - https://unpkg.com/katex@0/dist/contrib/auto-render.min.js

# extra_css:
#   - https://unpkg.com/katex@0/dist/katex.min.css

edit_uri: edit/main/docs/
plugins:
  # - offline
  - search
  - bibtex:
      bib_file: "docs/References/biblio.bib"

theme: 
# name: readthedocs
  name: material
  logo: img/sloth_bl.png
  icon:
    repo: fontawesome/brands/github
    previous: fontawesome/solid/angle-left
    next: fontawesome/solid/angle-right
    edit: material/pencil 
    view: material/eye

  features:
    - content.code.copy
    - content.code.select
    - navigation.indexes 
    - navigation.tabs
    - navigation.top
    - navigation.instant
    - navigation.instant.progress
    - navigation.tracking

    
  palette:
    primary: black
    accent: 'red'
########################################
########################################
docs_dir: '@DOCS_DIR@'
########################################
########################################
nav:
  - Home: index.md
  - Getting Started:
    - Started/index.md
    - Installation guide:
      - Started/Installation/index.md
      - Started/Installation/linux.md
      - Started/Installation/mac.md
      - Started/Installation/cluster.md
    - Examples:
      - Started/Examples/index.md
      @EXAMPLE_LIST@
    - Code quality: Started/Quality/quality.md
    - Building a SLOTH application: 
      - Started/HowTo/index.md

  - User Manual: 
    - Documentation/User/index.md
  - Modelling Description: 
    - Documentation/Physical/index.md
  - Code Documentation: 
    - Documentation/Code/index.md
  - Applications:
    - Applications/index.md
  - References: 
    - References/index.md
  - About: 
    - About/index.md
