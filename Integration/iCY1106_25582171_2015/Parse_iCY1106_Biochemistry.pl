#!/usr/bin/env perl
#use PlantSEED::Formulas;
use warnings;
use strict;
my @temp=();

my $Compounds = "iCY1106_Compound_Table.txt";
my $Reactions = "iCY1106_Reaction_Table.txt";

open(FH, "< $Compounds");
my $header=1;
my %Original_Compounds=();
while(<FH>){
    chomp;
    if($header){$header--;next}
    @temp=split(/\t/,$_);

    my $cpd_cpt = $temp[0];

    #Convert ASCII codes
    $temp[0] =~ s/_LPAREN_/(/;
    $temp[0] =~ s/_RPAREN_/)/;

    #Clean up identifier
    $temp[0] =~ s/^M_+//;

    #Remove Compartment
    my $cpd = $temp[0];
    $cpd =~ s/_(\w+)$//;
    my $cpt = $1;

    $Original_Compounds{$cpd_cpt}={'ID'=>$cpd,
				   'NAMES'=>$temp[1],
				   'COMPARTMENT'=>$cpt};
}
close(FH);

my $filestub = $Compounds;
$filestub =~ s/_Compound_Table\.txt$//;

open(OUT, "> ".$filestub."_Compounds.tbl");
my @Headers=("ID","NAMES","COMPARTMENT");
print OUT join("\t",@Headers),"\n";
foreach my $id (sort keys %Original_Compounds){
    foreach my $h (@Headers){
	print OUT $Original_Compounds{$id}{$h};
	print OUT "\t" unless $h eq $Headers[$#Headers];
    }
    print OUT "\n";
}
close(OUT);

open(FH, "< $Reactions");
$header=1;
my %Original_Reactions=();
while(<FH>){
    chomp;
    if($header){$header--;next}

    #Convert ascii codes
    $_ =~ s/_LPAREN_/(/g;
    $_ =~ s/_RPAREN_/)/g;
    $_ =~ s/_LSQBKT_/[/g;
    $_ =~ s/_RSQBKT_/]/g;
    $_ =~ s/_FSLASH_/\//g;
    @temp=split(/\t/,$_);

    my $rxn = $temp[0];

    #Clean up identifier
    $rxn =~ s/^R_+//;

    #Go through reactants
    my ($rev,$reactants,$products)=@temp[2..5];

    #Skipping all boundary exchange reactions
    next if !$products;

    my @reactants = split(/;/,$reactants);
    my @eqn=();
    my %cpts = (); #got to double-check
    my $cpt_count = 0;
    foreach my $rct (@reactants){
	$rct =~ /M_([\(\)\w]+)_(\w+)\[(\d+(\.[\de-]+)*)\]/;
	my ($cpd,$cpt,$coeff)=($1,$2,$3);

	if(defined($coeff) && $coeff != 1){
	    $coeff="(".$coeff.")";
	}else{
	    $coeff=undef($coeff);
	}

	if(!exists($cpts{$cpt})){
	    $cpts{$cpt}=$cpt_count;
	    $cpt_count++;
	}

	$cpt = "[".$cpts{$cpt}."]";
	
	my $rct_str = $cpd.$cpt;
	if(defined($coeff)){
	    $rct_str = $coeff." ".$rct_str;
	}

	push(@eqn,$rct_str);
    }

    my $reversibility = "<=>";
    if($rev ne "False"){
	$reversibility = "=>";
    }
    push(@eqn,$reversibility);

    my @products = split(/;/,$products);
    foreach my $pdt (@products){
	$pdt =~ /M_([\(\)\w]+)_(\w+)\[(\d+(\.[\de-]+)*)\]/;
	my ($cpd,$cpt,$coeff)=($1,$2,$3);


	if(defined($coeff) && $coeff != 1){
	    $coeff="(".$coeff.")";
	}else{
	    $coeff=undef($coeff);
	}

	if(!exists($cpts{$cpt})){
	    $cpts{$cpt}=$cpt_count;
	    $cpt_count++;
	}

	$cpt = "[".$cpts{$cpt}."]";

	my $pdt_str = $cpd.$cpt;
	if(defined($coeff)){
	    $pdt_str = $coeff." ".$pdt_str;
	}
	push(@eqn,$pdt_str);
    }
    my $eqn_str = join(" ",@eqn);

    $Original_Reactions{$rxn}={'ID'=>$rxn,
			       'NAMES'=>$temp[1],
			       'EQUATION'=>$eqn_str};
}
close(FH);

open(OUT, "> ".$filestub."_Reactions.tbl");
@Headers=("ID","NAMES","EQUATION");
print OUT join("\t",@Headers),"\n";
foreach my $id (sort keys %Original_Reactions){
    foreach my $h (@Headers){
	print OUT $Original_Reactions{$id}{$h};
	print OUT "\t" unless $h eq $Headers[$#Headers];
    }
    print OUT "\n";
}
close(OUT);