#!/usr/bin/perl -w
#*****************************************************************************
#*                                                                           *
#*                            Netscalibur UK                                 *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      PROGRAM     :  Netscal::BankAccount                                  *
#*                                                                           *
#*      AUTHOR      :  JNS                                                   *
#*                                                                           *
#*      DESCRIPTION :  Check structural validity of a bank account           *
#*                                                                           *
#*                                                                           *
#*****************************************************************************
#*                                                                           *
#*      $Log: BankAccount.pm,v $
#*      Revision 1.2  2002/04/25 12:11:23  tdcjs
#*      Small changes after made live
#*
#*      Revision 1.1.1.1  2002/04/25 10:00:17  tdcjs
#*      Added a new module
#*
#*                                                                           *
#*                                                                           *
#*****************************************************************************

package Netscal::BankAccount;


BEGIN
{
   unless ( exists $INC{'FindBin.pm'} )
   {
       use FindBin;
   }
}

use lib $FindBin::Bin;

use vars qw(@ISA $VERSION @EXPORT);

@ISA = qw(Exporter);
require Exporter;

@EXPORT = qw( check_acct );

($VERSION) = q$Revision: 1.2 $ =~ /([\d.]+)/;

use strict;

use Netscal::BankAccount::Config;

my $valfile = $Netscal::BankAccount::Config::valfile;
my $subsfile = $Netscal::BankAccount::Config::subsfile;

my @weightings = qw(
                     weight_u
                     weight_v
                     weight_w
                     weight_x
                     weight_y
                     weight_z
                     weight_a
                     weight_b
                     weight_c
                     weight_d
                     weight_e
                     weight_f
                     weight_g
                     weight_h
                   );
my @fields = (
                'start_sort',
                'end_sort',
                'algorithm',
                 @weightings,
                'except',
               );

my @valtable;

my %methods = (
                 MOD10 => { sub => \&mod_check, base => 10 },
                 MOD11 => { sub => \&mod_check, base => 11 },
                 DBLAL => { sub => \&double_alt_mod_check, base => 0 }
              );
             
open(VAL,$valfile) || die "Couldn't open $valfile - $!\n";

while(<VAL>)
{
   chomp;

   my %record ;

   @record{@fields} = split ' '; 

   $record{except} ||= '';

   push @valtable, \%record;
}

close(VAL);

my %subs;

open(SUBS, $subsfile) || die "Couldn't open $subsfile - $!\n";

while(<SUBS>)
{
   chomp;

   my ( $old, $new ) = split ' ';

   $subs{$old} = $new;
}

close(SUBS);


 my %skip_excepts = (
                       2  => 1,
                       9  => 1,
                       10 => 1,
                       11 => 1,
                       12 => 1,
                       13 => 1
                     );
sub check_acct
{
   shift if $_[0] =~ /Netscal::BankAccount/;
   my ( $sort_code, $acct_code ) = @_;

   my $ret = 0;

   my $last_exc;

   $sort_code =~ s/[^\d]*//g;
   $acct_code =~ s/[^\d]*//g;

   if ( length $sort_code == 6 and length $acct_code == 8 )
   {
      foreach my $rule ( find_sort_code($sort_code) )
      {
         my $exc = $rule->{except};
         my $method = $methods{$rule->{algorithm}}->{sub};
         my $base = $methods{$rule->{algorithm}}->{base};

         if ( $exc and $exc == 6 and $acct_code =~ /^[45678]\d+(\d)\1$/ )
         {
               $ret++;
         }
         else
         { 
             if ( $exc and $exc == 5 )
             {
                if ( exists $subs{$sort_code} )
                {
                   $sort_code = $subs{$sort_code};
                }
             }
             my %rule_temp = %{$rule};

             my $weightings = [ @rule_temp{@weightings} ];


             if ( $method->($sort_code, $acct_code,$weightings, $exc,$base ) )
             {
                $ret++;
                if ( $exc && exists $skip_excepts{$exc} )
                {
                   last;
                }
             }
             else
             {
                if ( $exc and $exc == 2 )
                {
                   $ret = 0;
                 }
                 else
                 {
                   unless ( ($exc and ($exc >= 10 ) ) || (( $exc && $last_exc ) && ($last_exc == 2 && $exc == 9))) 
                   {
                      $ret-- ;
                   }
                 }
             }
         }
         $last_exc = $exc;
      }

   }

   return $ret > 0 ? 1 : 0 ;
}

sub find_sort_code
{
    my ( $sort_code ) = @_;

    my @records = ();

    foreach my $record ( @valtable )
    {
       if ( $sort_code >= $record->{start_sort} and 
             $sort_code <= $record->{end_sort} )
       {
          push @records, $record;
       }
       elsif ( $record->{end_sort} > $sort_code )
       {
          last;
       }
    }

    return @records;
}

sub mod_check
{
   my ($sort_code,$acct_no, $weightings, $exc, $base ) = @_;

   my @digits = split //, $sort_code . $acct_no;

   my $sum = 0;

   my $remainder = 0;

   my $index;

   if ( $base == 11 )
   {
     if ( $exc )
     {
        if ( $exc == 2 )
        {
           if ( $acct_no !~ /^0/ )
           {
              if ( substr($acct_no, 6,1 ) == 9 )
              {
                  $weightings = [qw(0 0 0 0 0 0 0 0 8 7 10 9 3 1)];
              }
              else
              {
                  $weightings = [qw(0 0 1 2 5 3 6 4 8 7 10 9 3 1)];
              }
           }
        }
        elsif ( $exc == 4 )
        {
            $remainder = substr($acct_no,6,2);
        }
        elsif ( $exc == 7 )
        {
           if ( substr($acct_no, 6,1) == 9 )
           {
              my @t_weight = @{$weightings};

              @t_weight[0 .. 7] = qw(0 0 0 0 0 0 0 0);

              $weightings = \@t_weight;
           }
        }
        elsif ( $exc == 9 )
        {
           @digits[0 .. 5 ] = qw(3 0 9 6 3 4);
        }
        elsif ( $exc == 10 )
        {
           if ( substr($acct_no,0,2) == 9 or substr($acct_no,0,2) == 99 )
           {
              if ( substr($acct_no,6,1) == 9 )
              {
                 my @t_weight = @{$weightings};

                 @t_weight[0 .. 7] = qw(0 0 0 0 0 0 0 0 );

                 $weightings = \@t_weight;
              }
           }
        }
     }
   }
   elsif ( $base == 10 )
   {
      if ( $exc )
      {
        if ( $exc == 8 )
        {
            @digits[0 .. 5] = qw(0 9 0 1 2 6);
        }
      }
   }

   for $index ( 0 .. 13 )
   {
     $sum += $digits[$index] * $weightings->[$index];
   }

   my $res = ($sum % $base );

   my $return_value;

   if ( $base == 11 and $exc and $exc == 5 )
   {
      if ( $res <= 1 )
      {
         $return_value = ( $res == 0 and substr($acct_no, 6,1) == 0 );         
      }
      else
      {
         $return_value = ( substr($acct_no, 6,1) == ( 11 - $res ) );
      }
   }
   else
   {
      $return_value = ( $res == $remainder );
   }

   return $return_value;
}

sub double_alt_mod_check
{
   my ($sort_code,$acct_no, $weightings, $exc ) = @_;

   my $base = 10;

   my $return_code = 0;

   if ( $exc and $exc == 3 and substr($acct_no,2,1) =~ /[69]/ )
   {
      $return_code = 1;
   }
   elsif ( $exc and $exc == 2 )
   {
      if ( $acct_no !~ /^0/ )
      {
         if ( substr($acct_no, 6,1 ) == 9 )
         {
            #$weightings = [qw(0 0 1 2 5 3 6 4 8 6 10 9 3 1)];
            $weightings = [qw(0 0 0 0 0 0 0 0 8 7 10 9 3 1)];
         }
         else
         {
            $weightings = [qw(0 0 1 2 5 3 6 4 8 6 10 9 3 1)];
            #$weightings = [qw(0 0 0 0 0 0 0 0 8 7 10 9 3 1)];
         }
       }
   }
   else
   {
      my @digits = split //, $sort_code . $acct_no;

      my $sum = 0;

      my $index;

      for $index ( 0 .. 13 )
      {
        my $total = $digits[$index] * $weightings->[$index];

        if ( $total > 9 )
        {
          my ( $left, $right ) = split //, $total;
          $total = $left + $right;
        }

        $sum += $total;
      }

      if ( $exc and $exc == 1 )
      {
         $sum += 27;
      }

      my $res = $sum % $base;

      if ( $exc and $exc == 5 )
      {
         if ( $res == 0 and substr($acct_no, 7,1) == 0 )
         {
            $return_code = 1;
         }
         else
         {
            $return_code = ( substr($acct_no, 7,1) == ( 10 - $res ) );
         }
      }
      else
      {
         $return_code = ( $res == 0 );
      }
   }

   return $return_code;
}

1;
__END__
