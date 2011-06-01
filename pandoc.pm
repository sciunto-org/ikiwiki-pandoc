#!/usr/bin/env perl

package IkiWiki::Plugin::pandoc;

use warnings;
use strict;
use IkiWiki;
use FileHandle;
use IPC::Open2;

sub import {
    my $markdown_ext = $config{pandoc_markdown_ext} || "mdwn";

    hook(type => "getsetup", id => "pandoc", call => \&getsetup);
    hook(type => "htmlize", id => $markdown_ext,
	 # longname => "Pandoc Markdown",
         call => sub { htmlize("markdown", @_) });
    if ($config{pandoc_latex}) {
        hook(type => "htmlize", id => "tex",
             call => sub { htmlize("latex", @_) });
    }
    if ($config{pandoc_rst}) {
        hook(type => "htmlize", id => "rst",
             call => sub { htmlize("rst", @_) });
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
    pandoc_markdown_ext => {
        type => "string",
        example => "mdwn",
        description => "File extension for Markdown files",
        safe => 1,
        rebuild => 1,
    },
    pandoc_latex => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of LaTeX documents",
        safe => 0,
        rebuild => 1,
    },
    pandoc_rst => {
        type => "boolean",
        example => 0,
        description => "Enable Pandoc processing of reStructuredText documents",
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
        example => "unicode",
        description => "Process TeX math using",
        safe => 0,
        rebuild => 1,
    },
}


sub htmlize ($@) {
    my $format = shift;
    my %params = @_;
    my $page = $params{page};

    local(*PANDOC_IN, *PANDOC_OUT);
    my @args;

    my $command = $config{pandoc_command} || "/usr/local/bin/pandoc";

    if ($config{pandoc_smart}) {
        push @args, '--smart';
    };

    if ($config{pandoc_obfuscate}) {
        push @args, '--email-obfuscation=references';
    } else {
        push @args, '--email-obfuscation=none';
    };

    if ($config{pandoc_html5}) {
        push @args, '--html5';
    };

    if ($config{pandoc_ascii}) {
        push @args, '--ascii';
    };

    if ($config{pandoc_numsect}) {
        push @args, '--number-sections';
    };

    if ($config{pandoc_sectdiv}) {
        push @args, '--section-divs';
    };

    if ($config{pandoc_codeclasses} && ($config{pandoc_codeclasses} ne "")) {
        push @args, '--indented-code-classes=' . $config{pandoc_codeclasses};
    };


    for ($config{pandoc_math}) {
        if (/^mathjax$/) { 
            push @args, '--mathjax=/dev/null';
        }
        elsif (/^jsmath$/) {
            push @args, '--jsmath';
        }
        elsif (/^latexmathml$/) {
            push @args, '--latexmathml';
        }
        elsif (/^mimetex$/) {
            push @args, '--mimetex';
        }
        elsif (/^mathtex$/) {
            push @args, '--mimetex=/cgi-bin/mathtex.cgi';
        }
        elsif (/^google$/) {
            push @args, '--webtex';
        }
        elsif (/^mathml$/) {
            push @args, '--mathml';
        }
        else { }
    }

    # $ENV{"LC_ALL"} = "en_US.UTF-8";
    my $pid = open2(*PANDOC_IN, *PANDOC_OUT, $command,
                    '-f', $format,
                    '-t', 'html',
                    @args);

    error("Unable to open $command") unless $pid;

    # Workaround for perl bug (#376329)
    require Encode;
    my $content = Encode::encode_utf8($params{content});

    print PANDOC_OUT $content;
    close PANDOC_OUT;

    my @html = <PANDOC_IN>;
    close PANDOC_IN;

    waitpid $pid, 0;

    $content = Encode::decode_utf8(join('', @html));
    return $content;
}

1
