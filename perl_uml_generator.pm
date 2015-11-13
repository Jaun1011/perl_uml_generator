#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;

##########################################################################
## Function:	main()
## Parameters:	-
## returnvalue:	reference of class
##########################################################################
sub main {
	my $content;
	my $path = "/home/jan/Projects/git/NNE/nne_uai/nne_sai/src/service/";
	my @files = readDirectory($path);
	my $filename = ".html";
	my $fullcontent = "";
	my $input  = "";
	
	foreach my $content (@files) {
		$content = readFile($path.$content);
		my @class = getClass($content);
		my @variables = getVariables($content);
		my @methodes = getMethodes($content);
		my @methodeVariables = getMethodeVariables($content ,@methodes);
		$input .= createTable(@class, @variables, @methodes, @methodeVariables);
		
	}
	my $html = generateHTML($input);
	writeFile($filename, $html);
}


sub readDirectory {
	my $directory = shift;
	my @files;
	opendir DIR, $directory or die $!;
	while( my $entry = readdir DIR ){
		push(@files,$entry);
	}
	closedir DIR;
	return @files;
}

##########################################################################
## Function:	readFile()
## Parameters:	-
## returnvalue:	reference of class
##########################################################################
sub readFile {
	my $filename = shift;
	my $content = "";

	open(my $fh, '<:encoding(UTF-8)', $filename)
		or die "Could not open file '$filename' $!";

	while (my $row = <$fh>) {
		$content .= $row;
	}
	return  $content;
}

sub writeFile {
	my $filename = shift;
	my $input = shift;
	open (FILE, ">$filename") or die $!;
   		print FILE $input;
	close (FILE);
}

##########################################################################
## Function:	getMethodes()
## Parameters:	-
## returnvalue:
##########################################################################
sub getClass {
	my $content = shift;
	my @class = $content =~ /package (.*?)[;]/;
	return [@class];
}

sub getVariables {
	my $content = shift;

	my @variables = $content =~ /use(.*?)sub/s;
	@variables = $variables[0] =~ /my\s(.*?);/g;
	return [@variables];
}

sub getMethodes {
	my $content = shift;
	my @methodes = $content =~ /sub\s(.*?)\s[{]/g;
	return [@methodes];
}

sub getMethodeVariables {
	my $content = shift;
	my @methodes = shift;
	my @meth_variables;
	my @dataobject;
	my $i = 0;

	foreach my $mod (@methodes) {
		foreach my $methode (@$mod) {
			my @meth_content = $content =~ /sub $methode {(.*?)}/sg;
			@meth_variables = $meth_content[0] =~ /my (.*?) = shift/g;
			$dataobject[$i] = {$methode => [@meth_variables]};
			$i++;
		}
	}
	return [@dataobject];
}


sub generateHTML {
	my $content = shift;
	my $html = qq(
		<html>
			<head>
				<link rel="stylesheet" type="text/css" href="formate.css">
			</head>
			<body>
				$content
			</body>
		</html>
	);
	return $html;
}

##########################################################################
## Function:	createTable()
## Parameters:	-
## returnvalue:
##########################################################################
sub createTable {
	my @classes = shift;
	my @variables = shift;
	my @methodes = shift;
	my @methodevariables = shift;

	my $table = qq(<div class="module">\n).
				createTableClass(@classes).
				createTableVariables(@variables).
				createTableMethodes(@methodes, @methodevariables).
				"</div>\n";
	return $table;
}

##########################################################################
## Function:	createTableClass()
## Parameters:	-
## returnvalue:
##########################################################################
sub createTableClass {
	my @classes = shift;
	my $table_methodes = qq(<div class="classname">\n);
	foreach my $class (@classes) {
		foreach my $mod (@$class) {

			$table_methodes .= "$mod <br>\n";

		}
	}
	$table_methodes .= "</div>\n";
	return $table_methodes;
}

##########################################################################
## Function:	createTableMethodes()
## Parameters:	-
## returnvalue:
##########################################################################
sub createTableVariables{
	my @methodes = shift;
	my $table_methodes = qq(<div class="var">\n);
	foreach my $methode (@methodes) {
		foreach my $mod (@$methode) {

			$table_methodes .= " $mod <br>\n";
		}
	}
	$table_methodes .= "</div>\n";
	return $table_methodes;
}

##########################################################################
## Function:	createTableMethodes()
## Parameters:	-
## returnvalue:
##########################################################################
sub createTableMethodes {
	my @methodes = shift;
	my @methodevariables = shift;
	my $table_methodes = qq(<div class="meth">\n);

	foreach my $methode (@methodes) {
		foreach my $mod (@$methode) {
			$table_methodes .= " +$mod(";

			my @methvar = prepareMethodeVariables($mod, @methodevariables);
			my $i = 0;

			foreach my $var (@methvar) {
				foreach my $v (@$var) {
					if ($v ne '$self') {
						if ($v ne '$class') {
							if ($i eq 0) {
								$table_methodes .= $v;
								$i++;
							}else{
								$table_methodes .= ", $v";
							}
						}
					}
				}
			}
			$table_methodes .= ") <br>\n";
		}
	}
	$table_methodes .= "</div>\n";
	return $table_methodes;
}

##########################################################################
## Function:	prepareMethodeVariables()
## Parameters:	-
## returnvalue:
##########################################################################
sub prepareMethodeVariables {
	my $methode = shift;
	my @methodevariables = shift;

	foreach my $mod (@methodevariables) {
		foreach my $vars (@$mod) {
			if (defined $vars->{$methode}){
				my @methvar = $vars->{$methode};
				return @methvar;

			}
		}
	}
}
main();
