#!/usr/bin/perl -w

use strict;

use SOAP::Lite 
  uri => 'urn:Netscal/BankAccount/',
  proxy => 'http://localhost/cgi-bin/BankAccount',
  'debug';


use Test::More tests => 32;

while(<DATA>)
{
   chomp;

   my $soap = SOAP::Lite->new();

   my ( $desc,$sort_code, $acct_no, $pass) = split /\|/;

   my $res = $soap->check_acct($sort_code, $acct_no)->result() ? 'Y' : 'N' ;

   is($res,$pass,$desc);
}
__END__
Pass the modulus 10 check.|089999|66374958|Y
Pass the modulus 11 check.|107999|88837491|Y
Pass the modulus 11 and the double alternate checks.|202959|63748472|Y
Exception 10 & 11 in the validation table whereby the first check passes and the second check fails.|871427|46238510|Y
Exception 10 & 11 in the validation table whereby the first check fails and the second check passes.|872427|46238510|Y
Exception 10 in the validation table whereby the first two digits of the account number = 09 and the 7th = 9. The first check passes, the second check fails.|871427|09123496|Y
Exception 10 in the validation table whereby the first two digits of the account number = 99 and the 7th = 9. The first check passes, the second check fails.|871427|99123496|Y
Exception 3 in the validation table. As the third digit of the account number is a 6 the second check should be ignored. The sorting code is also the first in a range.|820000|73688637|Y
Exception 3 in the validation table. As the third digit of the account number is a 9 the second check should be ignored. The sorting code is also the last in a range. |827999|73988638|Y
Exception 3 in the validation table. As the third digit of the account number is not a 6 or a 9 and both checks pass.|827101|28748352|Y
Exception 4 in the validation table where the remainder is equal to the checkdigit.|134020|63849203|Y
Ensures that the value of 27 has been added to the accumulated total and passes the double alternate modulus check as in exception 1 of the validation table.|118765|64371389|Y
Exception 6 in the validation table whereby the account fails the Barclays check but is a foreign currency account.|200915|41011166|Y
Exception 5 in the validation table and passes.|938611|07806039|Y
Exception 5 in the validation table and passes with substitution.|938600|42368003|Y
Exception 5 in the validation table whereby both checks produce a remainder of 0 and pass.|938063|55065200|Y
Exception 7 in the validation table and passes but would fail the normal check.|772798|99345694|Y
Exception 8 in the validation table and passes.|086090|06774744|Y
Exception 2 & 9 in the validation table whereby the first check passes and the second check fails.|309070|02355688|Y
Exception 2 & 9 in the validation table whereby the first check fails and the second check passes with substitution.|309070|12345668|Y
Exception 2 & 9 in the validation table where a > 0 and g is not = 9 and passes.|309070|12345677|Y
Exception 2 & 9 in the validation table where a > 0 and g = 9 and passes.|309070|99345694|Y
Exception 5 in the validation table whereby the first check digit is correct and the second  incorrect.|938063|15764273|N
Exception 5 in the validation table whereby the first check digit is incorrect and the second correct.|938063|15764264|N
Exception 5 in the validation table whereby the first check digit is incorrect with a remainder of 1.|938063|15763217|N
Exception 1 in the validation table but fails the double alternate check.|118765|64371388|N
Pass the modulus 11 check and fails the double alternate check.|203099|66831036|N
Fail the modulus 11 check and pass the double alternate check.|203099|58716970|N
Fail the modulus 10 check|089999|66374959|N
Fail the modulus 11 check|107999|88837493|N
Exception 12 in the validation table and passes the modulus 11 check and fails the modulus 10 check|074456|12345112|Y
Exception 13 in the validation table and passes the modulus 11 and the modulus 10 checks|070116|34012583|Y
