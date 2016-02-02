ikiwiki-pandoc
==============

Pandoc plugin for ikiwiki.

Pandoc <http://johnmacfarlane.net/pandoc/> has a richer syntax and more flexible configuration than Markdown, and is also able to parse a variety of other syntaxes. This plugin can be configured to generate wiki pages from LaTeX, reST, mediawiki, textile, OPML or Emacs Org sources, as well as markdown. It can also be configured to convert inline TeX math using a variety of methods. Finally, if Pandoc was compiled with the `-fhighlighting` option, it will apply syntax highlighting to code blocks and `inline code spans`.

* <http://ikiwiki.info/plugins/contrib/pandoc/>


Install
-------

    # (1) Install the library.
    # Alternatively, can be installed in /usr/share/perl5 or similar.
    #
    mkdir -p ~/.ikiwiki/IkiWiki/Plugin
    cp pandoc.pm ~/.ikiwiki/IkiWiki/Plugin

    # (2) Install template (for math support).
    # $TEMPLATEDIR is often /usr/share/ikiwiki/templates by default.
    # Check the `templatedir` setting of your *.setup file.
    #
    mv $TEMPLATEDIR/page.tmpl $TEMPLATEDIR/page.tmpl.orig
    cp page.tmpl $TEMPLATEDIR

    # (3) Possibly install javascript (only for mathml).
    # $UNDERLAYDIR is often /usr/share/ikiwiki and depends on the
    # settings `underlaydir` and `add_underlays` in your *.setup file
    #
    cp *.js $UNDERLAYDIR/javascript/

    # (4) Activate module:
    #     add 'pandoc' to `add_plugins` list in your *.setup file

    # (5) Refresh your *.setup file and rebuild your wiki:
    # Between those two commands, you may want to tweak some options.
    #
    ikiwiki --changesetup *.setup
    ikiwiki --rebuild --setup *.setup

**Note:** If you want to put mathematics markup into your pages or blog entries, you are likely to run into problems with the `smiley` plugin, so you should probably disable it by adding it to the `disable_plugins` list in your `*.setup` file.

Options
-------

The following options are available in the `*.setup` file. Some of them are also available in the web settings.

### Program paths

* `pandoc_command` (string): Path to pandoc executable. If not set, looks for `pandoc` in your `$PATH`.

* `pandoc_citeproc` (string): Path to pandoc-citeproc executable (for references/bibliography handling). If not set, looks for it in `$PATH`.


### Input format support

* `pandoc_markdown_ext` (string): Markdown file extension(s) for pandoc handling. Multiple comma-separated extensions may be specified, e.g. `md,mdwn,markdown,pd`.

* `pandoc_rst` (boolean): If true, enables processing of ReST documents (fixed extension: `.rst`).

* `pandoc_latex` (boolean): If true, enables processing of LaTeX documents (fixed extension: `.tex`).

* `pandoc_textile` (boolean): If true, enables processing of textile documents (fixed extension: `.textile`).

* `pandoc_mediawiki` (boolean): If true, enables processing of MediaWiki documents (fixed extension: `.mediawiki`).

* `pandoc_org` (boolean): If true, enables processing of Emacs Org-mode documents (fixed extension: `.org`).

* `pandoc_opml` (boolean): If true, enables processing of OPML documents (fixed extension: `.opml`).


### Settings for mathematics display

Pandoc's variant of markdown supports TeX math delimited with `$...$` (inline math) and `$$ ... $$` (display math). There are several possibilities with regard to the way in which this appears in the HTML output. For a more detailed description, see later in this document.

These settings have no effect unless you have activated the `page.tmpl` file which comes with this module (or have inserted an appropriate math support block into your own template).

* `pandoc_math` (string): base setting for math support. Can be one of `mathjax`, `katex`, `mathml`, `asciimathml`, `jsmath`, `latexmathml`, `mimetex`, or `webtex`. For most people, `mathjax` is recommended.

* `pandoc_math_custom_js` (string): Optionally specify a javascript URL to load support for the math display option specified under `pandoc_math`. You would use this if you e.g. have a local version of MathJax or KaTeX. If you have picked `mathml`, it would probably be sensible to point to the `mathml.js` script which comes with this module. For `mimetex` and `webtex`, this setting should not point to a javascript file but to a server-side (CGI) URL which returns an image for insertion into the page at the appropriate point.

* `pandoc_math_custom_css`: Optional custom CSS URL to control the appearances of math.

### Settings for references and bibliography

* `pandoc_bibliography` (string): Full path to the (BibTeX-format) bibliography file to use by default. If this is empty, you must specify either `bibliography` (filename) or `references` (structured list of references) in a YAML meta-block in the page itself.

* `pandoc_csl` (string): CSL file to use by default to format in-line references and the list of references. If this is empty, the default Chicago author-year format will be used, unless you specify a CSL file using `csl` in a YAML meta-block in the page itself.

* `pandoc_csl_default_lang` (string): Language code to use by default during citations processing, unless something different is specified in the YAML meta block (using either of the keys `lang` or `locale`). Language codes follow [RFC 1766](https://www.ietf.org/rfc/rfc1766.txt) and are typically either two letters (e.g. `en` for English) or two letters followed by a hyphen and a refinement code (e.g. `en-GB` for British English). If no language code is configured here, pandoc-citeproc uses the default language of the preferred CSL file, or US English (`en-US`) if it specifies no default language. Underscore may be used instead of a hyphen in language codes, so `en-GB` and `en_GB` are equivalent. Pandoc-citeproc [supports](https://github.com/jgm/pandoc-citeproc/tree/master/locales) almost 50 major European and Asian languages.

### Output tweaking

* `pandoc_smart` (boolean): Whether smart quotes and other typographic niceties are enabled.

* `pandoc_obfuscate` (boolean): Whether to detect and obfuscate email adresses automatically.

* `pandoc_html5` (boolean): Whether Pandoc should produce HTML5.

* `pandoc_ascii` (boolean): Produce ASCII output rather than UTF-8.

* `pandoc_numsect` (boolean): Whether to number sections.

* `pandoc_sectdiv` (boolean): Attach IDs to section DIVs instead of to headers.

* `pandoc_codeclasses` (string): CSS classes to add to indented code blocks. One may also specify CSS classes individually for each block.

### Extra output formats

It is sometimes useful to use pandoc to export the content of a wiki page to non-html formats, e.g. pdf or docx. This can be triggered by setting certain attributes in the YAML meta block of the page. The currently supported formats are `pdf`, `docx`, `odt`, `latex`, `beamer`, and `epub`. The corresponding meta attributes are the boolean values `generate_pdf`, `generate_docx`, `generate_odt`, `generate_latex`, `generate_beamer`, and `generate_epub`. As a shortcut, `generate_all_formats` will turn on all the generation of all six formats. For instance,

```yaml
generate_all_formats: true
generate_beamer: false
```

will export files of all formats except Beamer.

When such extra formats have been generated for a page, links to the exported files will be appended to the action links (e.g. "Edit"). These are at the top of the page in the default theme.

There are several configuration options related to the export functionality:

* `pandoc_latex_template`: Path to pandoc template for LaTeX and PDF output. Since PDF files are created by way of LaTeX, there is no separate PDF template. (Obviously, PDF generation requires a working LaTeX installation).

* `pandoc_latex_extra_options`: List of extra pandoc options of LaTeX and PDF generation. (Note that this, like other `*_extra_options`, is a *list*, not simply a string).

* `pandoc_beamer_template`: Path to pandoc template for Beamer PDF output. (Beamer is a presentations package for LaTeX).

* `pandoc_beamer_extra_options`: List of extra pandoc options for Beamer PDF generation.

* `pandoc_docx_template`: Path to pandoc template for MS Word (`docx`) output.

* `pandoc_docx_extra_options`: List of extra pandoc options for `docx` generation.

* `pandoc_odt_template`: Path to pandoc template for OpenDocument (`odt`) output for LibreOffice, OpenOffice, etc..

* `pandoc_odt_extra_options`: List of extra pandoc options for `odt` generation.

* `pandoc_epub_template`: Path to pandoc template for epub output. (Note that the this will actually generate EPUB3 files rather than the more familiar EPUB2. The reason is that EPUB3 has better native math support).

* `pandoc_epub_extra_options`: List of extra pandoc options for epub generation.

Notable **limitations** with regard to the export suppport:

* There is currently no way of overriding template or option settings for a specific format on a per-page basis.

* There is currently no option for turning some list of export formats on by default for all pandoc-processed pages. The reason is that some plugins which insert content into the page, notably the [template plugin](https://ikiwiki.info/plugins/template/), call pandoc in such a way that the pandoc plugin apparently has no certain way of distinguishing between these calls and the processing of an entire page. A global option might thus lead to much wasted work and conceivably even to the overwriting of export files by incorrect content.

Details
-------

### Syntax Coloring

Pandoc can be configured to apply classes globally to all its inline code blocks (for example, `numberLines` or 
`perl`). Alternatively, code blocks can be written in this style:

    ~~~
    if (a > 3) {
       moveShip(5 + gravity, DOWN);
    }
    ~~~

The line of `~~~` can be longer than 3 characters, if you like. This manner of writing indented code blocks also 
permits us to specify the block's specific syntax, which might be different from other blocks:


    ~~~{.haskell .numberLines}
    if (a > 3) {
       moveShip(5 + gravity, DOWN);
    }
    ~~~

If Pandoc wasn't compiled with syntax highlighting support, such a code block will be processed like this:

    <pre class="haskell">
        <code>
        ...
        </code>
    </pre>


You can also specify the syntax for inline code spans: `` `some code`{.haskell} ``.

For syntax highlighting, you may add this in your css style sheet:

    /*From pandoc for code highlighting*/
    table.sourceCode, tr.sourceCode, td.lineNumbers, td.sourceCode {
          margin: 0; padding: 0; vertical-align: baseline; border: none; }
          table.sourceCode { width: 100%; line-height: 100%; }
          td.lineNumbers { text-align: right; padding-right: 4px; padding-left: 4px; color: #aaaaaa; border-right: 1px solid #aaaaaa; }
          td.sourceCode { padding-left: 5px; }
          code > span.kw { color: #007020; font-weight: bold; }
          code > span.dt { color: #902000; }
          code > span.dv { color: #40a070; }
          code > span.bn { color: #40a070; }
          code > span.fl { color: #40a070; }
          code > span.ch { color: #4070a0; }
          code > span.st { color: #4070a0; }
          code > span.co { color: #60a0b0; font-style: italic; }
          code > span.ot { color: #007020; }
          code > span.al { color: #ff0000; font-weight: bold; }
          code > span.fu { color: #06287e; }
          code > span.er { color: #ff0000; font-weight: bold; }



Note: This functionality overlaps somewhat with Ikiwiki's `highlight` plugin and `format` directive:

    [[!format  perl """
    print "hello, world\n";
    """]]


### Tables

Pandoc has a native [table-handling syntax](http://johnmacfarlane.net/pandoc/README.html#tables). This overlaps 
somewhat with Ikiwiki's `table` directive. Here too, you'll have to decide which facility better suits your needs.


### Inline TeX processing for math

Pandoc recognizes inline TeX and can be configured to display it on the web using a variety of tools.

1. MathJax <http://www.mathjax.org/> is the option recommended for most people, since it combines extensive support for TeX commands with good browser support.

2. KaTeX (<https://khan.github.io/KaTeX/>) is faster and more lightweight than MathJax but does not support as many TeX commands. It also does not behave as nicely if there is an error in your TeX markup.

3. jsMath is the predecessor to MathJax. It doesn't give as nice results, and is harder to install. Download jsMath and jsMath-fonts <http://www.math.union.edu/~dpvc/jsMath/> and install them to your server. Set `pandoc_math_custom_js` appropriately.

4. A different JavaScript solution is LatexMathML <http://math.etsu.edu/LaTeXMathML/>.

5. Asciimathml <http://asciimath.org/> is an alternative, non-TeX syntax for math markup, which is supported by Pandoc if you have the correct setting in `pandoc_math`.

6. The `mimetex` setting for `pandoc_math` is used for CGI-based image solutions and requires you to set `pandoc_math_custom_js` to the URL of an appropriate server-side script. Two of these are  MathTeX <http://www.forkosh.com/mathtex.html> (which requires LaTeX to be installed) and MimeTeX <http://www.forkosh.com/mimetex.html> (which doesn't).

7. The `webtex` setting is similar to `mimetex` and uses the Google Charts API <http://code.google.com/apis/chart/> by default.

9. Native MathML support (the `mathml` setting for `pandoc_math`) is only present in Mozilla-based browsers, i.e. Firefox. There are Javascript solutions to emulate this support in other browsers, e.g. through MathJax. The `mathml.js` file which comes with this module is one such possibility. If you opt for using MathML you should enable this through the `pandoc_math_custom_js` setting. Note that if you pick `mathml`, you must disable the `htmlscrubber` plugin.

10. If none of the other options are enabled, Pandoc will attempt to render inline TeX using Unicode characters, in so far as that's possible.


If none of these options work for you, you could check out the [teximg plugin](http://ikiwiki.info/plugins/teximg/); this works something like MathTex, above. You could also look into using `itex2MML`; Jason Blevins <http://jblevins.org/projects/ikiwiki/> has a plugin for using that tool together with Markdown. (A newer version is mentioned at <http://ikiwiki.info/todo/mdwn_itex/>.)

See also <http://ikiwiki.info/todo/latex>, which describes a number of other  works-in-progress for rendering LaTeX in Ikiwiki.)


### FAQ

See this article if you encounter issues with https: <http://www.mathjax.org/resources/faqs/#problem-https> and change URLs in templates.


### TeX macros

Another nice Pandoc feature is that it parses and uses `\newcommand` and `\renewcommand` macro definitions:

    \newcommand{\tuple}[1]{\langle #1 \rangle}
    ...
    $\tuple{a, b, c}$


License
=======

GPLv2. See `LICENSE` for more details.
