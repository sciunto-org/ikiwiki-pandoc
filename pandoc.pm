#!/usr/bin/env perl

package IkiWiki::Plugin::pandoc;

use warnings;
use strict;
use IkiWiki;
use FileHandle;
use IPC::Open2;
use JSON;
# use Data::Dumper;

sub import {
    my $markdown_ext = $config{pandoc_markdown_ext} || "mdwn";

    # May be both a string with a single value, a string containing commas or an arrayref
    if ($markdown_ext =~ /,/) {
        $markdown_ext = [split /\s*,\s*/, $markdown_ext];
    }

    hook(type => "getsetup", id => "pandoc", call => \&getsetup);
    hook(type => "pagetemplate", id => "pandoc", call => \&pagetemplate);

    if (ref $markdown_ext eq 'ARRAY') {
        foreach my $mde (@$markdown_ext) {
            hook(type => 'htmlize', id => $mde,
                 call => sub{ htmlize("markdown", @_) });
        }
    } else {
        hook(type => "htmlize", id => $markdown_ext,
             call => sub { htmlize("markdown", @_) });
    }
    if ($config{pandoc_latex}) {
        hook(type => "htmlize", id => "tex",
             call => sub { htmlize("latex", @_) });
    }
    if ($config{pandoc_rst}) {
        hook(type => "htmlize", id => "rst",
             call => sub { htmlize("rst", @_) });
    }
    if ($config{pandoc_textile}) {
        hook(type => "htmlize", id => "textile",
             call => sub { htmlize("textile", @_) });
    }
    if ($config{pandoc_mediawiki}) {
        hook(type => "htmlize", id => "mediawiki",
             call => sub { htmlize("mediawiki", @_) });
    }
    if ($config{pandoc_opml}) {
        hook(type => "htmlize", id => "opml",
             call => sub { htmlize("opml", @_) });
    }
    if ($config{pandoc_org}) {
        hook(type => "htmlize", id => "org",
             call => sub { htmlize("org", @_) });
    }
}


sub getsetup () {
    return
    plugin => {
        safe => 1,
        rebuild => 1,
    },
    pandoc_command => {
        type => "string",
        example => "/usr/local/bin/pandoc",
        description => "Path to pandoc executable",
        safe => 0,
        rebuild => 0,
    },
    pandoc_citeproc => {
        type => "string",
        example => "/usr/local/bin/pandoc-citeproc",
        description => "Path to pandoc-citeproc executable",
        safe => 0,
        rebuild => 0,
    },
    pandoc_markdown_ext => {
        type => "string",
        example => "mdwn,md,markdown",
        description => "File extension(s) for Markdown files handled by Pandoc",
        safe => 1,
        rebuild => 1,
    },
    pandoc_latex => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of LaTeX documents (extension=tex)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_rst => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of reStructuredText documents (extension=rst)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_textile => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of Textile documents (extension=textile)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_mediawiki => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of MediaWiki documents (extension=mediawiki)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_org => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of Emacs org-mode documents (extension=org)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_opml => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of OPML documents (extension=opml)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_smart => {
        type => "boolean",
        example => 1,
        description => "Use smart quotes, dashes, and ellipses",
        safe => 1,
        rebuild => 1,
    },
    pandoc_obfuscate => {
        type => "boolean",
        example => 1,
        description => "Obfuscate emails",
        safe => 1,
        rebuild => 1,
    },
    pandoc_html5 => {
        type => "boolean",
        example => 0,
        description => "Generate HTML5",
        safe => 1,
        rebuild => 1,
    },
    pandoc_ascii => {
        type => "boolean",
        example => 0,
        description => "Generate ASCII instead of UTF8",
        safe => 1,
        rebuild => 1,
    },
    pandoc_numsect => {
        type => "boolean",
        example => 0,
        description => "Number sections",
        safe => 1,
        rebuild => 1,
    },
    pandoc_sectdiv => {
        type => "boolean",
        example => 0,
        description => "Attach IDs to section DIVs instead of Headers",
        safe => 1,
        rebuild => 1,
    },
    pandoc_codeclasses => {
        type => "string",
        example => "",
        description => "Classes to use for indented code blocks",
        safe => 1,
        rebuild => 1,
    },
    pandoc_math => {
        type => "string",
        example => "mathjax",
        description => "How to process TeX math (mathjax, katex, mathml, mathjs, latexmathml, asciimathml, mimetex, webtex)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_math_custom_js => {
        type => "string",
        example => "",
        description => "Link to local/custom javascript for math (or to server-side script for mimetex and webtex)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_math_custom_css => {
        type => "string",
        example => "",
        description => "Link to local/custom CSS for math (requires appropriate pandoc_math setting)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_bibliography => {
        type => "string",
        example => "",
        description => "Path to default bibliography file",
        safe => 0,
        rebuild => 1,
    },
    pandoc_csl => {
        type => "string",
        example => "",
        description => "Path to CSL file (for references and bibliography)",
        safe => 0,
        rebuild => 1,
    },
    pandoc_filters => {
        type => "string",
        example => "",
        description => "A comma-separated list of custom pandoc filters",
        safe => 0,
        rebuild => 1,
    },
}


sub htmlize ($@) {
    my $format = shift;
    my %params = @_;
    my $page = $params{page};
    my $htmlformat = 'html';

    local(*PANDOC_IN, *JSON_IN, *JSON_OUT, *PANDOC_OUT);
    my @args = ();

    # The default assumes pandoc is in PATH
    my $command = $config{pandoc_command} || "pandoc";

    if ($config{pandoc_smart}) {
        push @args, '--smart';
    }

    if ($config{pandoc_obfuscate}) {
        push @args, '--email-obfuscation=references';
    } else {
        push @args, '--email-obfuscation=none';
    }

    if ($config{pandoc_html5}) {
        $htmlformat = 'html5';
    }

    if ($config{pandoc_ascii}) {
        push @args, '--ascii';
    }

    if ($config{pandoc_numsect}) {
        push @args, '--number-sections';
    }

    if ($config{pandoc_sectdiv}) {
        push @args, '--section-divs';
    }

    if ($config{pandoc_codeclasses} && ($config{pandoc_codeclasses} ne "")) {
        push @args, '--indented-code-classes=' . $config{pandoc_codeclasses};
    }

    # How to process math. Normally either mathjax or katex.
    my %mathconf = map {($_=>"--$_")} qw(
        jsmath mathjax latexmathml asciimathml mathml katex mimetex webtex
    );
    my %with_urls = qw/mimetex 1 webtex 1/;
    my $mathopt = $1 if $config{pandoc_math} =~ /(\w+)/;
    my $custom_js = $config{pandoc_math_custom_js} || '';
    if ($mathopt && $mathconf{$mathopt}) {
        if ($with_urls{$mathopt} && $custom_js) {
            # In these cases, the 'custom js' is a misnomer: actually a server-side script
            push @args, $mathconf{$mathopt} ."=". $custom_js;
        } else {
            push @args, $mathconf{$mathopt};
        }
        $pagestate{$page}{meta}{"pandoc_math"} = $mathopt;
        $pagestate{$page}{meta}{"pandoc_math_$mathopt"} = 1;
        $pagestate{$page}{meta}{"pandoc_math_custom_js"} = $custom_js if $custom_js;
    }
    # Convert to intermediate JSON format so that the title block
    # can be parsed out
    # We must omit the 'bibliography' parameter here, otherwise the list of
    # references will be doubled.
    my $to_json_pid = open2(*JSON_OUT, *PANDOC_OUT, $command,
                    '-f', $format,
                    '-t', 'json',
                    @args);
    error("Unable to open $command") unless $to_json_pid;

    # Workaround for perl bug (#376329)
    require Encode;
    my $content = Encode::encode_utf8($params{content});

    print PANDOC_OUT $content;
    close PANDOC_OUT;

    my $json_content = <JSON_OUT>;
    close JSON_OUT;

    waitpid $to_json_pid, 0;

    # Parse the title block out of the JSON and set the meta values
    my @json_content = @{decode_json($json_content)};
    my $meta = {};
    if (ref $json_content[0] eq 'HASH') {
        $meta = $json_content[0]->{'unMeta'};
    }
    else {
        warn "WARNING: Unexpected format for meta block. Incompatible version of Pandoc?\n";
    }

    # Get some selected meta attributes, more specifically:
    # (title date bibliography csl subtitle abstract summary description
    #  version references author [+ num_authors primary_author])

    sub compile_string {
        # Partially represents an item from the data structure in meta as a string.
        my @uncompiled = @_;
        @uncompiled = @{$uncompiled[0]} if @uncompiled==1 && ref $uncompiled[0] eq 'ARRAY';
        my $compiled_string = '';
        foreach my $word_or_space (@uncompiled) {
            next unless ref $word_or_space eq 'HASH';
            my $type = $word_or_space->{'t'};
            $compiled_string .= compile_string(@{ $word_or_space->{c} }) if $type eq 'MetaInlines';
            next unless $type eq 'Str' || $type eq 'Space' || $type eq 'MetaString';
            $compiled_string .= $type eq 'Space' ? ' ' : $word_or_space->{c};
        }
        return $compiled_string;
    }

    my %scalar_meta = map { ($_=>undef) } qw(
        title date bibliography csl subtitle abstract summary description version);
    my %list_meta = map { ($_=>[]) } qw/author references/;
    my $have_bibl = 0;
    foreach my $k (keys %scalar_meta) {
        next unless $meta->{$k};
        $scalar_meta{$k} = compile_string($meta->{$k}->{c});
        $pagestate{$page}{meta}{$k} = $scalar_meta{$k};
        $pagestate{$page}{meta}{"pandoc_$k"} = $pagestate{$page}{meta}{$k};

    }
    foreach my $k (keys %list_meta) {
        next unless $meta->{$k};
        $list_meta{$k} = $meta->{$k}->{'c'};
        $list_meta{$k} = [ map { compile_string($_) } @{$list_meta{$k}} ] if $k eq 'author';
        $have_bibl = 1 if $k eq 'references';
        $pagestate{$page}{meta}{"pandoc_$k"} = $pagestate{$page}{meta}{$k};
    }
    my $num_authors = scalar @{ $list_meta{author} };
    $scalar_meta{num_authors} = $num_authors;
    $pagestate{$page}{meta}{num_authors} = $num_authors;
    if ($num_authors) {
        $scalar_meta{primary_author} = $list_meta{author}->[0];
        $pagestate{$page}{meta}{author} = join(', ', @{$list_meta{author}});
        $pagestate{$page}{meta}{pandoc_primary_author} = $scalar_meta{primary_author}
    }

    # The bibliography may be set in a Meta block in the page or in the .setup file.
    # If both are present, the Meta block has precedence.
    for my $bibl ($scalar_meta{bibliography}, $config{pandoc_bibliography}) {
        if ($bibl) {
            $have_bibl = 1;
            $pagestate{$page}{meta}{pandoc_bibliography} = $bibl;
            push @args, '--bibliography='.$bibl;
            last;
        }
    }
    # Similarly for the CSL file...
    for my $cslfile ($scalar_meta{csl}, $config{pandoc_csl}) {
        if ($cslfile) {
            $pagestate{$page}{meta}{pandoc_csl} = $cslfile;
            push @args, '--csl='.$cslfile;
            last;
        }
    }

    # Turn on the pandoc-citeproc filter if either global bibliography,
    # local bibliography or a 'references' key in Meta is present.
    if ($have_bibl) {
        my $citeproc = $config{pandoc_citeproc} || 'pandoc-citeproc';
        push @args, "--filter=$citeproc";
    }

    # Other pandoc filters. Note that currently there is no way to
    # configure a filter to run before pandoc-citeproc has done its work.
    if ($config{pandoc_filters}) {
        my @filters = split /\s*,\s*/, $config{pandoc_filters};
        s/^["']//g for @filters; # get rid of enclosing quotes
        foreach my $filter (@filters) {
            push @args, "--filter=$filter";
        }
    }

    my $to_html_pid = open2(*PANDOC_IN, *JSON_IN, $command,
                    '-f', 'json',
                    '-t', $htmlformat,
                    @args);
    error("Unable to open $command") unless $to_html_pid;

    print JSON_IN $json_content;
    close JSON_IN;

    my @html = <PANDOC_IN>;
    close PANDOC_IN;

    waitpid $to_html_pid, 0;

    $content = Encode::decode_utf8(join('', @html));
    return $content;
}


sub pagetemplate (@) {
    my %params = @_;
    my $page = $params{page};
    my $template = $params{template};
    foreach my $k (keys %{$pagestate{$page}{meta}}) {
        next unless $k =~ /^pandoc_/;
        $template->param($k => $pagestate{$page}{meta}{$k});
    }
}

1;
