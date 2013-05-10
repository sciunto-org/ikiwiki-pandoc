ikiwiki-pandoc
==============

Pandoc plugin for ikiwiki.

Pandoc <http://johnmacfarlane.net/pandoc/> has a richer syntax and more
flexible configuration than Markdown, and is also able to parse a variety of
other syntaxes. This plugin can be configured to generate wiki pages from LaTeX
and reST sources, as well as markdown. It can also be configured to convert
inline TeX using a variety of methods. And, if Pandoc was compiled with the
-fhighlighting, it can be configured to apply syntax highlighting to code
blocks and `inline code spans`.


License
=======

GPLv2

Authors
=======
* Jason Blevin (Original author) <http://jblevins.org/projects/ikiwiki/>
* Jim Pryor <http://www.jimpryor.net/>
* Beni Cherniavsky-Paskin <https://github.com/cben>
* Ryan Burgoyne <https://github.com/rburgoyne>
* Baldur Kristinsson <https://github.com/bk>
* François Boulogne

Install
=======

    # Install the library
    mkdir -p ~/.ikiwiki/IkiWiki/Plugin
    cp pandoc.pm ~/.ikiwiki/IkiWiki/Plugin
    # Alternatively, can be installed in /usr/share/perl5

    # Install templates
    cp *tmpl /usr/share/ikiwiki/templates
    cd /usr/share/ikiwiki/templates
    mv page.tmpl page.tmpl.ori
    ln -s mathjax.tmpl page.tmpl

    # Install javascript
    cp *js /usr/share/ikiwiki/javascript





## Options ##

### Available in Ikiwiki's web preferences ###

1. File extension for Markdown files (defaults to mdwn)

1. Use smart quotes, dashes, and ellipses

1. Generate ASCII instead of UTF8.

1. Number section headings in generated pages

1. Wrap sections in `<div>` tags (or `<section>` tags in HTML5), and
   attach identifiers to the `<div>` rather than th header itself. This
   allows the section to be styled or manipulated via javascript.

1. Obfuscate emails using HTML character references

1. Generate HTML5 (the Ikiwiki html5 setting should also be set)

1. Classes to use for all indented code blocks (these can also be 
   specified differently from block to block; see below)


### Have to be configured manually in your wiki's *.setup file ###

1. Path to pandoc executable (defaults to /usr/local/bin/pandoc)

1. Enable Pandoc processing of LaTeX documents

1. Enable Pandoc processing of reStructuredText documents

1. Method for handling inline TeX (see below)


## Details ##

### Syntax Coloring ###

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


### Tables ###

Pandoc has a native [table-handling syntax](http://johnmacfarlane.net/pandoc/README.html#tables). This overlaps 
somewhat with Ikiwiki's `table` directive. Here too, you'll have to decide which facility better suits your needs.


### Inline TeX processing ###

Pandoc recognizes inline TeX and can be configured to display it on the web using a variety of tools.

1. You can use MathJax <http://www.mathjax.org/>. This requires copying the `mathjax.tmpl` file that accompanies this 
plugin to a template directory seen by your wiki. Rename the file to `page.tmpl`. (Available since Pandoc 1.8.)

1. jsMath is the predecessor to MathJax. It doesn't give as nice results, and is harder to install, but it's also an 
option. Download jsMath and jsMath-fonts <http://www.math.union.edu/~dpvc/jsMath/> and install them so that they're 
served from the root of your server, that is, from `/jsMath/...` Also, copy the file `jsmath.tmpl` that accompanies 
this plugin to a template directory seen by your wiki. Rename the file to `page.tmpl`.

1. A different JavaScript solution is LatexMathML <http://math.etsu.edu/LaTeXMathML/>. Again, this gives less good 
results than MathJax, but it's easier to install than jsMath. Download the `LaTeXMathML.js` and 
`LaTeXMathML.standardarticle.css` files and install them so that they're served from the root of your server.  Also, 
copy the file `latexmathml.tmpl` that accompanies this plugin to a template directory seen by your wiki. Rename the 
file to `page.tmpl`.

1. Instead of using JavaScript, a different approach is to build and install a cgi on your server. MathTeX 
<http://www.forkosh.com/mathtex.html> gives good results, but needs LaTeX to be available on the server. This plugin 
assumes that if you're using MathTeX, it will be served from `/cgi-bin/mathtex.cgi`.

1. MimeTeX <http://www.forkosh.com/mimetex.html> is the predecessor to MathTeX. It doesn't give as nice results, but 
will work on less equipped servers. This plugin assumes that if you're using MimeTeX, it will be served from 
`/cgi-bin/mimetex.cgi`.

1. Or you could use a third-party cgi, such as Google Charts API <http://code.google.com/apis/chart/>. (Available since 
Pandoc 1.6.)

1. Another option is to directly render the TeX into MathML. Browser support for displaying MathML is coming slowly. 
Firefox supports it well, but WebKit/Chrome is only beginning to. To process inline TeX via this method, copy the file 
`mathml.tmpl` that accompanies this plugin to a template directory seen by your wiki. Rename the file to `page.tmpl`. 
You should also arrange for the file `mathml.js` to be served from the root of your server; this file helps provide a 
better fallbacks for browsers that can't display the MathML. This method also requires htmlscrubber to be disabled, at 
least for pages containing MathML. (Available since Pandoc 1.5.)

1. If none of the other options are enabled, Pandoc will attempt to render inline TeX using Unicode characters, in so 
far as that's possible.


If none of these options work for you, you could check out the [teximg plugin](http://ikiwiki.info/plugins/teximg/); 
this works something like MathTex, above. You could also look into using
`itex2MML`; Jason Blevins <http://jblevins.org/projects/ikiwiki/> has a plugin
for using that tool together with Markdown. (A newer version is mentioned at <http://ikiwiki.info/todo/mdwn_itex/>.)

See also <http://ikiwiki.info/todo/latex>, which describes a number of other works-in-progress for rendering LaTeX in 
Ikiwiki.)


### TeX macros ###

Another nice Pandoc feature is that it parses and uses `\newcommand` and `\renewcommand` macro definitions:

    \newcommand{\tuple}[1]{\langle #1 \rangle}
    ...
    $\tuple{a, b, c}$

