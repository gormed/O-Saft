#!/usr/bin/perl
## PACKAGE {

# TODO: implement
#    require "o-saft-lib" "full";  # or "raw"
#	full: anything for o-saft.pl; raw partial for SSLhello.pm
# TODO: see comment at %cipher_names

package osaft;

use strict;
use warnings;

use constant {
    OSAFT_VERSION   => '16.05.10',  # offizial verion number of tis file
  # STR_VERSION => 'dd.mm.yy',      # must be defined in calling program
    STR_ERROR   => "**ERROR: ",
    STR_WARN    => "**WARNING: ",
    STR_HINT    => "!!Hint: ",
    STR_USAGE   => "**USAGE: ",
    STR_DBX     => "#dbx# ",
    STR_UNDEF   => "<<undef>>",
    STR_NOTXT   => "<<>>",
    OSAFT_SID   => '@(#) o-saft-lib.pm 1.28 16/05/15 17:15:00',

};

#_____________________________________________________________________________
#_____________________________________________________ public documentation __|

# more public documentation, see start of methods section, and at end of file.

## no critic qw(Documentation::RequirePodSections)
#  our POD below is fine, perlcritic (severity 2) is too pedantic here.

=pod

=encoding utf8

=head1 NAME

o-saft-lib -- common perl modul for O-Saft and related tools

=head1 SYNOPSIS

    o-saft-lib.pm           # on command line will print help

Thinking perlish, there are two variants to use this module and its constants
and variables:

=over 4

=item 1. Variant with BEGIN

    BEGIN {
        require "o-saft-lib.pm";    # file may have any name
        ...
    }
    ...
    use strict;
    print "a constant : " . osaft::STD_HINT;
    print "a variable : " . $osaft::var;

=item 2. Variant outside BEGIN

    BEGIN {
        ...
    }
    use strict;
    use osaft;                      # file must be named  osaft.pm
    ...
    print "a constant : " . STD_HINT
    print "a variable : " . $var;

=back

None of the constants, variables, or methods should be defined in the caller,
otherwise the calling script must handle warnings properly.

=head1 OPTIONS

=head1 DESCRIPTION

Utility package for O-Saft (o-saft.pl and related tools). This package declares
and defines common L</VARIABLES> and L</METHODS> to be used in the calling tool.
All variables and methods are defined in the  osaft::  namespace.

=head2 Used Functions

Following functions (methods) must be defined in the calling program:

=over 4

=item _trace( )

=item _trace1( )

=item _trace2( )

=item _trace3( )

=back

=head1 CONSTANTS

=over 4

=item STR_ERROR

=item STR_WARN

=item STR_HINT

=item STR_USAGE

=item STR_DBX

=item STR_UNDEF

=item STR_NOTXT

=back

=head1 VARIABLES

=over 4

=item %cfg

=item %dbx

=item %prot

=item %prot_txt

=item %tls_handshake_type

=item %tls_record_type

=item %tls_error_alerts

=item %tls_extensions

=item %tls_curve_types

=item %tls_curves

=item %data_oid

=item %ciphers

=item %ciphers_desc

=item %cipher_names

=item %cipher_alias

=item %cipher_results

=back

=head1 METHODS

=cut

## no critic qw(Modules::ProhibitAutomaticExportation, Variables::ProhibitPackageVars)
# FIXME: perlcritic complains to use @EXPORT_OK instead of @EXPORT, but that
#        is not possible as long as constants are exported;
#        should be changed when "use constant" is replaced by "use Readonly"
# FIXME: perlcritic complains to not declare (global) package variables, but
#        the purpose of this module is to do that. This may change in future.

# See NOTES below also.

use Exporter qw(import);
use base qw(Exporter);
#our @ISA        = qw(Exporter);
our $VERSION    = OSAFT_VERSION;
our @EXPORT     = qw(
                STR_ERROR
                STR_WARN
                STR_HINT
                STR_USAGE
                STR_DBX
                STR_UNDEF
                STR_NOTXT
                %prot
                %prot_txt
                %tls_handshake_type
                %tls_record_type
                %tls_error_alerts
                %tls_extensions
                %tls_curve_types
                %tls_curves
                %data_oid
                %dbx
                %cfg
                %ciphers_desc
                %ciphers
                %cipher_names
                %cipher_alias
                @cipher_results
                get_cipher_sec
                get_cipher_ssl
                get_cipher_enc
                get_cipher_bits
                get_cipher_mac
                get_cipher_auth
                get_cipher_keyx
                get_cipher_score
                get_cipher_tags
                get_cipher_desc
                get_cipher_hex
                get_cipher_name
                get_openssl_version
                get_dh_paramter
                osaft_sleep
                osaft_done
);
# insert above in vi with:
# :r !sed -ne 's/^sub \([a-zA-Z][^ (]*\).*/\t\t\1/p' %
# :r !sed -ne 's/^our \([\%$@][a-zA-Z0-9_][^ (]*\).*/\t\t\1/p' %
# :r !sed -ne 's/^ *\(STR_[A-Z][^ ]*\).*/\t\t\1/p' %

#_____________________________________________________________________________
#________________________________________________________________ variables __|

our %prot   = (     # collected data for protocols and ciphers
    # NOTE: ssl must be same string as in %cfg, %ciphers[ssl] and Net::SSLinfo %_SSLmap
    # ssl           protocol  name        hex version value openssl  option     val LOW ...
    #--------------+---------------------+-----------------+-------------------+---+---+---+---
    'SSLv2'     => {'txt' => "SSL 2.0 ",  'hex' => 0x0002,  'opt' => "-ssl2"    },
    'SSLv3'     => {'txt' => "SSL 3.0 ",  'hex' => 0x0300,  'opt' => "-ssl3"    },
    'TLSv1'     => {'txt' => "TLS 1.0 ",  'hex' => 0x0301,  'opt' => "-tls1"    },
    'TLSv11'    => {'txt' => "TLS 1.1 ",  'hex' => 0x0302,  'opt' => "-tls1_1"  },
    'TLSv12'    => {'txt' => "TLS 1.2 ",  'hex' => 0x0303,  'opt' => "-tls1_2"  },
    'TLSv13'    => {'txt' => "TLS 1.3 ",  'hex' => 0x0304,  'opt' => "-tls1_3"  },
    'DTLSv09'   => {'txt' => "DTLS 0.9",  'hex' => 0x0100,  'opt' => "-dtls"    },  # see Notes
    'DTLSv1'    => {'txt' => "DTLS 1.0",  'hex' => 0xFEFF,  'opt' => "-dtls1"   },  #  "
    'DTLSv11'   => {'txt' => "DTLS 1.1",  'hex' => 0xFEFE,  'opt' => "-dtls1_1" },  #  "
    'DTLSv12'   => {'txt' => "DTLS 1.2",  'hex' => 0xFEFD,  'opt' => "-dtls1_2" },  #  "
    'DTLSv13'   => {'txt' => "DTLS 1.3",  'hex' => 0xFEFC,  'opt' => "-dtls1_3" },  #  "
    'TLS1FF'    => {'txt' => "--dummy--", 'hex' => 0x03FF,  'opt' => undef      },  #  "
    'DTLSfamily'=> {'txt' => "--dummy--", 'hex' => 0xFE00,  'opt' => undef      },  #  "
   #'TLS_FALLBACK_SCSV'=>{'txt'=> "SCSV", 'hex' => 0x5600,  'opt' => undef      },
    #-----------------------+--------------+----------------+------------------+---+---+---+---
    # "protocol"=> {cnt, WEAK, LOW, MEDIUM, HIGH, pfs, default, protocol} see _prot_init_value()
    # Notes:
    #  TLS1FF   0x03FF  # last possible version of TLS1.x (not specified, used internal)
    #  DTLSv09: 0x0100  # DTLS, OpenSSL pre 0.9.8f, not finally standardized; some versions use 0xFEFF
    #  DTLSv09: -dtls   # never defined and used in openssl
    #  DTLSv1   0xFEFF  # DTLS1.0 (udp)
    #  DTLSv11  0xFEFE  # DTLS1.1: has never been used (udp)
    #  DTLSv12  0xFEFD  # DTLS1.2 (udp)
    #  DTLSv13  0xFEFC  # DTLS1.3, NOT YET specified (udp)
    #  DTLSfamily       # DTLS1.FF, no defined PROTOCOL, for internal use only
    # 'hex' value will be copied to $cfg{'openssl_version_map'} below
    # 'opt' value will be copied to $cfg{'openssl_option_map'}  below
    # TODO: hex value should be same as %_SSLmap in Net::SSLinfo
); # %prot

our %prot_txt = (
    'cnt'           => "Supported total ciphers for ",           # counter
    '-?-'           => "Supported ciphers with security unknown",# "
    'WEAK'          => "Supported ciphers with security WEAK",   #  "
    'LOW'           => "Supported ciphers with security LOW",    #  "
    'MEDIUM'        => "Supported ciphers with security MEDIUM", #  "
    'HIGH'          => "Supported ciphers with security HIGH",   #  "
    'pfs_ciphers'   => "PFS (all  ciphers)",            # list with PFS ciphers
    'pfs_cipher'    => "PFS (selected cipher)",         # cipher if offered as default
    'default'       => "Selected  cipher  by server",   # cipher offered as default
    'protocol'      => "Selected protocol by server",   # 1 if selected as default protocol
); # %prot_txt

our %tls_handshake_type = (
    'hello_request'         => 0,
    'client_hello'          => 1,
    'server_hello'          => 2,
    'hello_verify_request'  => 3,       # RFC4347 DTLS
    'certificate'           => 11,
    'server_key_exchange'   => 12,
    'certificate_request'   => 13,
    'server_hello_done'     => 14,
    'certificate_verify'    => 15,
    'client_key_exchange'   => 16,
    'finished'              => 20,
    'certificate_url'       => 21,      # RFC6066 10.2
    'certificate_status'    => 22,      # RFC6066 10.2
    '255'                   => 255,
    '<<undefined>>'         => -1,      # added for internal use
    '<<fragmented_message>>'=> -99      # added for internal use
); # tls_handshake_type

our %tls_record_type = (
    'change_cipher_spec'    => 20,
    'alert'                 => 21,
    'handshake'             => 22,
    'application_data'      => 23,
    'heartbeat'             => 24,
    '255'                   => 255,
    '<<undefined>>'         => -1       # added for internal use
); # %tls_record_type

our %tls_error_alerts = ( # mainly RFC6066
    #----+-------------------------------------+--+----+---------------
    # ID      name                             DTLD RFC OID
    #----+-------------------------------------+--+----+---------------
     0 => [qw(close_notify                      Y  6066 -)],
    10 => [qw(unexpected_message                Y  6066 -)],
    20 => [qw(bad_record_mac                    Y  6066 -)],
    21 => [qw(decryption_failed                 Y  6066 -)],
    22 => [qw(record_overflow                   Y  6066 -)],
    30 => [qw(decompression_failure             Y  6066 -)],
    40 => [qw(handshake_failure                 Y  6066 -)],
    41 => [qw(no_certificate_RESERVED           Y  5246 -)],
    42 => [qw(bad_certificate                   Y  6066 -)],
    43 => [qw(unsupported_certificate           Y  6066 -)],
    44 => [qw(certificate_revoked               Y  6066 -)],
    45 => [qw(certificate_expired               Y  6066 -)],
    46 => [qw(certificate_unknown               Y  6066 -)],
    47 => [qw(illegal_parameter                 Y  6066 -)],
    48 => [qw(unknown_ca                        Y  6066 -)],
    49 => [qw(access_denied                     Y  6066 -)],
    50 => [qw(decode_error                      Y  6066 -)],
    51 => [qw(decrypt_error                     Y  6066 -)],
    60 => [qw(export_restriction_RESERVED       Y  6066 -)],
    70 => [qw(protocol_version                  Y  6066 -)],
    71 => [qw(insufficient_security             Y  6066 -)],
    80 => [qw(internal_error                    Y  6066 -)],
    86 => [qw(inappropriate_fallback            Y  RFC5246_update-Draft-2014-05-31 -)], # added according 'https://datatracker.ietf.org/doc/draft-bmoeller-tls-downgrade-scsv/?include_text=1'
    90 => [qw(user_canceled                     Y  6066 -)],
   100 => [qw(no_renegotiation                  Y  6066 -)],
   110 => [qw(unsupported_extension             Y  6066 -)],
   111 => [qw(certificate_unobtainable          Y  6066 -)],
   112 => [qw(unrecognized_name                 Y  6066 -)],
   113 => [qw(bad_certificate_status_response   Y  6066 -)],
   114 => [qw(bad_certificate_hash_value        Y  6066 -)],
   115 => [qw(unknown_psk_identity              Y  4279 -)],
    #----+-------------------------------------+--+----+---------------
); # %tls_error_alerts

our %tls_extensions = ( # RFC 6066
    0 => [qw(server_name)               ],
    1 => [qw(max_fragment_length)       ],
    2 => [qw(client_certificate_url)    ],
    3 => [qw(trusted_ca_keys)           ],
    4 => [qw(truncated_hmac)            ],
    5 => [qw(status_request)            ],
    6 => [qw(user_mapping)              ],  # RFC????
    7 => [qw(reserved_7)                ],  # -"-
    8 => [qw(reserved_8)                ],  # -"-
    9 => [qw(cert_tape)                 ],  # RFC5081
   10 => [qw(ecliptic_curves)           ],  # RFC4492
   11 => [qw(ec_point_formats)          ],  # RFC4492
   12 => [qw(srp)                       ],  # RFC5054
   13 => [qw(signature_algorithms)      ],  # RFC5246; also supported_algorithms
#  14 => [qw(unassigned)                ],  # -"-
#  ...
#  34 => [qw(unassigned)                ],  # -"-
   35 => [qw(SessionTicket)             ],  # RFC4507
65535 => [qw(65535)  ],
); # %tls_extensions

my %tls_extensions__text = ( # TODO: this information needs to be added to %tls_extensions above
    'extension' => {            # TLS extensions
        '00000'     => "renegotiation info length",     # 0x0000 ??
        '00001'     => "renegotiation length",          # 0x0001 ??
        '00010'     => "elliptic curves",               # 0x000a length=4
        '00011'     => "EC point formats",              # 0x000b length=2
        '00015'     => "heartbeat",                     # 0x000f length=1
        '00035'     => "session ticket",                # 0x0023 length=0
        '13172'     => "next protocol",                 # 0x3374 length=NNN
        '65281'     => "renegotiation info",            # 0xff01 length=1
    },
); # %tls_extensions__text

# Torsten: %ECCURVE_TYPE
our %tls_curve_types = ( # RFC 4492 
    'explicit_prime'        => 1,
    'explicit_char2'        => 2,
    'named_curve'           => 3,
    'reserved_248'          => 248,
    'reserved_249'          => 249,
    'reserved_250'          => 250,
    'reserved_251'          => 251,
    'reserved_252'          => 252,
    'reserved_253'          => 253,
    'reserved_254'          => 254,
    'reserved_255'          => 255,
); # %tls_curve_types

# Torsten: %ECC_NAMED_CURVE = 
# http://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml#tls-parameters-10
# Value =>   Description bits(added) DTLS-OK Reference
our %tls_curves = (
    # http://www.iana.org/assignments/tls-parameters/tls-parameters.xhtml#tls-parameters-8
    #----+-------------+-------+----+--+----+----------------------+-------------------------
    # ID   name         NIST   bits DTLD RFC OID                    other name
    #----+-------------+-------+----+--+----+----------------------+-------------------------
    0 => [qw(unassigned -          0  N IANA -                    )],
    1 => [qw(sect163k1  K-163    163  Y 4492 1.3.132.0.1          )],
    2 => [qw(sect163r1  -        163  Y 4492 1.3.132.0.2          )],
    3 => [qw(sect163r2  B-163    163  Y 4492 1.3.132.0.15         )],
    4 => [qw(sect193r1  -        193  Y 4492 1.3.132.0.24         )],
    5 => [qw(sect193r2  -        193  Y 4492 1.3.132.0.25         )],
    6 => [qw(sect233k1  K-233    233  Y 4492 1.3.132.0.26         )],
    7 => [qw(sect233r1  B-233    233  Y 4492 1.3.132.0.27         )],
    8 => [qw(sect239k1  -        239  Y 4492 1.3.132.0.3          )],
    9 => [qw(sect283k1  K-283    283  Y 4492 1.3.132.0.16         )],
   10 => [qw(sect283r1  B-283    283  Y 4492 1.3.132.0.17         )],
   11 => [qw(sect409k1  K-409    409  Y 4492 1.3.132.0.36         )],
   12 => [qw(sect409r1  B-409    409  Y 4492 1.3.132.0.37         )],
   13 => [qw(sect571k1  K-571    571  Y 4492 1.3.132.0.38         )],
   14 => [qw(sect571r1  B-571    571  Y 4492 1.3.132.0.39         )],
   15 => [qw(secp160k1  -        160  Y 4492 1.3.132.0.9          )],
   16 => [qw(secp160r1  -        160  Y 4492 1.3.132.0.8          )],
   17 => [qw(secp160r2  -        160  Y 4492 1.3.132.0.30         )],
   18 => [qw(secp192k1  -        192  Y 4492 1.3.132.0.31         )], # ANSI X9.62 prime192v1, NIST P-192, 
   19 => [qw(secp192r1  P-192    192  Y 4492 1.2.840.10045.3.1.1  )], # ANSI X9.62 prime192v1
   20 => [qw(secp224k1  -        224  Y 4492 1.3.132.0.32         )],
   21 => [qw(secp224r1  P-224    224  Y 4492 1.3.132.0.33         )],
   22 => [qw(secp256k1  P-256    256  Y 4492 1.3.132.0.10         )],
   23 => [qw(secp256r1  P-256    256  Y 4492 1.2.840.10045.3.1.7  )], # ANSI X9.62 prime256v1
   24 => [qw(secp384r1  P-384    384  Y 4492 1.3.132.0.34         )],
   25 => [qw(secp521r1  P-521    521  Y 4492 1.3.132.0.35         )],
   26 => [qw(brainpoolP256r1  -  256  Y 7027 1.3.36.3.3.2.8.1.1.7 )],
   27 => [qw(brainpoolP384r1  -  384  Y 7027 1.3.36.3.3.2.8.1.1.11)],
   28 => [qw(brainpoolP512r1  -  512  Y 7027 1.3.36.3.3.2.8.1.1.13)],
#  28 => [qw(brainpoolP521r1  -  521  Y 7027 1.3.36.3.3.2.8.1.1.13)], # ACHTUNG: in manchen Beschreibungen dieser falsche String
   29 => [qw(ecdh_x25519      -  255  Y 4492bis -                 )], # [draft-ietf-tls-tls][draft-ietf-tls-rfc4492bis])], #TEMPORARY-registered_2016-02-29,_expires 2017-03-01,
   30 => [qw(ecdh_x448        -  448  Y 4492bis -                 )], # -"-
#  31 => [qw(eddsa_ed25519    -  448  Y 4492bis 1.3.101.100       )], # Signature curves, see https://tools.ietf.org/html/draft-ietf-tls-tls13-11
#  32 => [qw(eddsa_ed448      -  448  Y 4492bis 1.3.101.101       )], # -"-

  256 => [qw(ffdhe2048        - 2048  Y ietf-tls-negotiated-ff-dhe-10)],
  257 => [qw(ffdhe3072        - 3072  Y ietf-tls-negotiated-ff-dhe-10)],
  258 => [qw(ffdhe4096        - 4096  Y ietf-tls-negotiated-ff-dhe-10)],
  259 => [qw(ffdhe6144        - 6144  Y ietf-tls-negotiated-ff-dhe-10)],
  260 => [qw(ffdhe8192        - 8192  Y ietf-tls-negotiated-ff-dhe-10)],
65281 => [qw(arbitrary_explicit_prime_curves - ?  Y 4492 -        )], # 0xFF01
65282 => [qw(arbitrary_explicit_char2_curves - ?  Y 4492 -        )], # 0xFF02
    #----+-------------+-------+----+--+----+----------------------+-------------------------
42001 => [qw(Curve3617        -   -1  n ? -                       )],
42002 => [qw(secp112r1        -   -1  n ? 1.3.132.0.6             )],
42003 => [qw(secp112r2        -   -1  n ? 1.3.132.0.7             )],
42004 => [qw(secp113r1        -   -1  n ? 1.3.132.0.4             )],
42005 => [qw(secp113r2        -   -1  n ? 1.3.132.0.5             )],
42006 => [qw(secp131r1        -   -1  n ? 1.3.132.0.22            )],
42007 => [qw(secp131r2        -   -1  n ? 1.3.132.0.23            )],
42008 => [qw(secp128r1        -   -1  n ? 1.3.132.0.28            )],
42009 => [qw(secp128r2        -   -1  n ? 1.3.132.0.29            )],
42011 => [qw(ed25519    Ed25519   -1  n 1.3.6.1.4.1.11591.15.1    )], # PGP
42012 => [qw(brainpoolp160r1  -   -1  n ? 1.3.36.3.3.2.8.1.1.1    )],
42013 => [qw(brainpoolp192r1  -   -1  n ? 1.3.36.3.3.2.8.1.1.3    )],
42014 => [qw(brainpoolp224r1  -   -1  n ? 1.3.36.3.3.2.8.1.1.5    )],
42015 => [qw(brainpoolp320r1  -   -1  n ? 1.3.36.3.3.2.8.1.1.9    )],
42016 => [qw(brainpoolp512r1  -   -1  n ? 1.3.36.3.3.2.8.1.1.13   )], # same as brainpoolP521r142001 => [qw(
42020 => [qw(GOST2001-test    -   -1  n ? 1.2.643.2.2.35.0        )],
42021 => [qw(GOST2001-CryptoPro-A - -1 n ? 1.2.643.2.2.35.1       )],
42022 => [qw(GOST2001-CryptoPro-B - -1 n ? 1.2.643.2.2.35.2       )],
42023 => [qw(GOST2001-CryptoPro-C - -1 n ? 1.2.643.2.2.35.3       )],
42024 => [qw(GOST2001-CryptoPro-A - -1 n ? - )], # GOST2001-CryptoPro-XchA
42025 => [qw(GOST2001-CryptoPro-C - -1 n ? - )], # GOST2001-CryptoPro-XchB
42026 => [qw(GOST2001-CryptoPro-A - -1 n ? 1.2.643.2.2.36.0       )],
42027 => [qw(GOST2001-CryptoPro-C - -1 n ? 1.2.643.2.2.36.1       )],
42031 => [qw(X9.62 prime192v2 -   -1  n ? 1.2.840.10045.3.1.2     )],
42032 => [qw(X9.62 prime192v3 -   -1  n ? 1.2.840.10045.3.1.3     )],
42033 => [qw(X9.62 prime239v1 -   -1  n ? 1.2.840.10045.3.1.4     )],
42034 => [qw(X9.62 prime239v2 -   -1  n ? 1.2.840.10045.3.1.5     )],
42035 => [qw(X9.62 prime239v3 -   -1  n ? 1.2.840.10045.3.1.6     )],
42041 => [qw(X9.62 c2tnb191v1 -   -1  n ? 1.2.840.10045.3.0.5     )],
42042 => [qw(X9.62 c2tnb191v2 -   -1  n ? 1.2.840.10045.3.0.6     )],
42043 => [qw(X9.62 c2tnb191v3 -   -1  n ? 1.2.840.10045.3.0.7     )],
42044 => [qw(X9.62 c2tnb239v1 -   -1  n ? 1.2.840.10045.3.0.11    )],
42045 => [qw(X9.62 c2tnb239v2 -   -1  n ? 1.2.840.10045.3.0.12    )],
42046 => [qw(X9.62 c2tnb239v3 -   -1  n ? 1.2.840.10045.3.0.13    )],
42047 => [qw(X9.62 c2tnb359v1 -   -1  n ? 1.2.840.10045.3.0.18    )],
42048 => [qw(X9.62 c2tnb431r1 -   -1  n ? 1.2.840.10045.3.0.20    )],
# fobidden curves
42061 => [qw(X9.62 c2pnb163v1 -   -1  n ? 1.2.840.10045.3.0.1     )],
42062 => [qw(X9.62 c2pnb163v2 -   -1  n ? 1.2.840.10045.3.0.2     )],
42063 => [qw(X9.62 c2pnb163v3 -   -1  n ? 1.2.840.10045.3.0.3     )],
42064 => [qw(X9.62 c2pnb176w1 -   -1  n ? 1.2.840.10045.3.0.4     )],
42065 => [qw(X9.62 c2pnb208w1 -   -1  n ? 1.2.840.10045.3.0.10    )],
42066 => [qw(X9.62 c2pnb272w1 -   -1  n ? 1.2.840.10045.3.0.16    )],
42067 => [qw(X9.62 c2pnb304w1 -   -1  n ? 1.2.840.10045.3.0.18    )],
42068 => [qw(X9.62 c2pnb368w1 -   -1  n ? 1.2.840.10045.3.0.19    )],
# unknown curves
42101 => [qw(prime192v1       -  192  n ? -                       )], # X9.62/SECG curve over a 192 bit prime field
42101 => [qw(prime192v2       -  192  n ? -                       )], # X9.62 curve over a 192 bit prime field
42101 => [qw(prime192v3       -  192  n ? -                       )], # X9.62 curve over a 192 bit prime field
42101 => [qw(prime239v1       -  239  n ? -                       )], # X9.62 curve over a 239 bit prime field
42101 => [qw(prime239v2       -  239  n ? -                       )], # X9.62 curve over a 239 bit prime field
42101 => [qw(prime239v3       -  239  n ? -                       )], # X9.62 curve over a 239 bit prime field
42101 => [qw(prime256v1       -  256  n ? -                       )], # X9.62/SECG curve over a 256 bit prime field
42101 => [qw(wap-wsg-idm-ecid-wtls1   -  113  n ? -               )], # WTLS curve over a 113 bit binary field
42101 => [qw(wap-wsg-idm-ecid-wtls3   -  163  n ? -               )], # NIST/SECG/WTLS curve over a 163 bit binary field
42101 => [qw(wap-wsg-idm-ecid-wtls4   -  113  n ? -               )], # SECG curve over a 113 bit binary field
42101 => [qw(wap-wsg-idm-ecid-wtls5   -  163  n ? -               )], # X9.62 curve over a 163 bit binary field
42101 => [qw(wap-wsg-idm-ecid-wtls6   -  112  n ? -               )], # SECG/WTLS curve over a 112 bit prime field
42101 => [qw(wap-wsg-idm-ecid-wtls7   -  160  n ? -               )], # SECG/WTLS curve over a 160 bit prime field
42101 => [qw(wap-wsg-idm-ecid-wtls8   -  112  n ? -               )], # WTLS curve over a 112 bit prime field
42101 => [qw(wap-wsg-idm-ecid-wtls9   -  160  n ? -               )], # WTLS curve over a 160 bit prime field
42101 => [qw(wap-wsg-idm-ecid-wtls10  -  233  n ? -               )], # NIST/SECG/WTLS curve over a 233 bit binary field
42101 => [qw(wap-wsg-idm-ecid-wtls11  -  233  n ? -               )], # NIST/SECG/WTLS curve over a 233 bit binary field
42101 => [qw(wap-wsg-idm-ecid-wtls12  -  224  n ? -               )], # WTLS curvs over a 224 bit prime field
42101 => [qw(Oakley-EC2N-3    -  155  n ? -                       )], # IPSec/IKE/Oakley curve #3 over a 155 bit binary field.
42101 => [qw(Oakley-EC2N-4    -  185  n ? -                       )], # IPSec/IKE/Oakley curve #4 over a 185 bit binary field
#----+--------+------------+---------------------+-------------------------
# numsp256d1
# numsp256t1
# Curve25519
#----+--------+------------+---------------------+-------------------------
); # %tls_curves

################
# FIPS-186-2 FIPS-186-3
#
# Aliases: P-256 -- NIST P-256 -- NIST-P256 -- NIST-256 -- secp256r1 -- prime256v1
#
# order_for_NIST_curves_by_ID = 23, 1, 3, 19, 21, 6, 7, 9, 10, 24, 11, 12, 25, 13, 14
################

our %data_oid = ( # TODO: nothing YET IMPLEMENTED except for EV
        # TODO: generate this table using Net::SSLeay functions like:
        #   Net::SSLeay::OBJ_nid2ln(),  Net::SSLeay::OBJ_ln2nid()
        #   Net::SSLeay::OBJ_nid2sn(),  Net::SSLeay::OBJ_sn2nid(),
        #   Net::SSLeay::OBJ_nid2obj(), Net::SSLeay::OBJ_obj2nid(),
        #   Net::SSLeay::OBJ_txt2obj(), Net::SSLeay::OBJ_txt2nid(),
        #   Net::SSLeay::OBJ_obj2txt(),
        # all constants and values are defined in openssl/crypto/objects/obj_dat.h
        #   print "nid ". Net::SSLeay::OBJ_txt2nid("CN"); # --> 13
        #   print "Nam ". Net::SSLeay::OBJ_obj2txt( Net::SSLeay::OBJ_txt2obj("1.3.6.1.5.5.7.3.3"), 0); # --> Code Signing
        #   print "nam ". Net::SSLeay::OBJ_obj2txt( Net::SSLeay::OBJ_txt2obj("CN"), 0); # --> commonName
        #   print "oid ". Net::SSLeay::OBJ_obj2txt( Net::SSLeay::OBJ_txt2obj("CN"), 1); # --> 2.5.4.3
        #   print "OID ". Net::SSLeay::OBJ_obj2txt( Net::SSLeay::OBJ_nid2obj( 13 ), 1); # --> 2.5.4.3
        # we should use NIDs to generate the hash, as all other strings are
        # case sensitive. get NIDs with:
        #   grep NID_ openssl/crypto/objects/objects.h | awk '{print $3}' | sort -n
        # so we can loop from 0..180 (or 300 if checks are possible)
        # see also: http://www.zytrax.com/books/ldap/apa/oid.html
        #
        # wir koennen dann einen Parser fuer OIDs bauen:
        #   loop ueber OID und dabei immer .N vom Ende wegnehmen und rest mit OBJ_obj2txt() ausgeben
        #   # 1.3.6.1.4 -->  "" . identified-organization . dot . iana . Private
        #   # 2.5.29.32 -->  "" . directory services (X.500) . id-ce . X509v3 Certificate Policies

#   '1.3.6.1'                   => {iso(1) org(3) dod(6) iana(1)}
    '1.3.6.1'                   => {'txt' => "Internet OID"},
    '1.3.6.1.5.5.7.1.1'         => {'txt' => "Authority Information Access"}, # authorityInfoAccess
    '1.3.6.1.5.5.7.1.12'        => {'txt' => STR_UNDEF},
    '1.3.6.1.5.5.7.1.14'        => {'txt' => "Proxy Certification Information"},
    '1.3.6.1.5.5.7.3.1'         => {'txt' => "Server Authentication"},
    '1.3.6.1.5.5.7.3.2'         => {'txt' => "Client Authentication"},
    '1.3.6.1.5.5.7.3.3'         => {'txt' => "Code Signing"},
    '1.3.6.1.5.5.7.3.4'         => {'txt' => "Email Protection"},
    '1.3.6.1.5.5.7.3.5'         => {'txt' => "IPSec end system"},
    '1.3.6.1.5.5.7.3.6'         => {'txt' => "IPSec tunnel"},
    '1.3.6.1.5.5.7.3.7'         => {'txt' => "IPSec user"},
    '1.3.6.1.5.5.7.3.8'         => {'txt' => "Timestamping"},
    '1.3.6.1.4.1.11129.2.5.1'   => {'txt' => STR_UNDEF},    # Certificate Policy?
    '1.3.6.1.4.1.14370.1.6'     => {'txt' => STR_UNDEF},    # Certificate Policy?
    '1.3.6.1.4.1.311.10.3.3'    => {'txt' => "Microsoft Server Gated Crypto"},
    '1.3.6.1.4.1.311.10.11'     => {'txt' => "Microsoft Server: EV additional Attributes"},
    '1.3.6.1.4.1.311.10.11.11'  => {'txt' => "Microsoft Server: EV ??friendly name??"},
    '1.3.6.1.4.1.311.10.11.83'  => {'txt' => "Microsoft Server: EV ??root program??"},
    '1.3.6.1.4.1.4146.1.10'     => {'txt' => STR_UNDEF},    # Certificate Policy?
    '2.16.840.1.113730.4.1'     => {'txt' => "Netscape SGC"},
    '1.2.840.113549.1.1.1'      => {'txt' => "SubjectPublicKeyInfo"}, # ???
    # EV: OIDs used in EV Certificates
    '2.5.4.10'                  => {'txt' => "EV Certificate: subject:organizationName"},
    '2.5.4.11'                  => {'txt' => "EV Certificate: subject:organizationalUnitName"},
    '2.5.4.15'                  => {'txt' => "EV Certificate: subject:businessCategory"},
    '2.5.4.3'                   => {'txt' => "EV Certificate: subject:commonName"}, # or SubjectAlternativeName:dNSName
    # EV: Jurisdiction of Incorporation or Registration
    '1.3.6.1.4.1.311.60.2.1.1'  => {'txt' => "EV Certificate: subject:jurisdictionOfIncorporationLocalityName"},
    '1.3.6.1.4.1.311.60.2.1.2'  => {'txt' => "EV Certificate: subject:jurisdictionOfIncorporationStateOrProvinceName"},
    '1.3.6.1.4.1.311.60.2.1.3'  => {'txt' => "EV Certificate: subject:jurisdictionOfIncorporationCountryName"},
    '2.5.4.5'                   => {'txt' => "EV Certificate: subject:serialNumber"},
    # EV: Physical Address of Place of Business
    '2.5.4.6'                   => {'txt' => "EV Certificate: subject:countryName"},
    '2.5.4.7'                   => {'txt' => "EV Certificate: subject:localityName"},
    '2.5.4.8'                   => {'txt' => "EV Certificate: subject:stateOrProvinceName"},
    '2.5.4.9'                   => {'txt' => "EV Certificate: subject:streetAddress"},
    '2.5.4.17'                  => {'txt' => "EV Certificate: subject:postalCode"},
    # EV: Compliance with European Union Qualified Certificates Standard In addition, RFC 3739
    '1.3.6.1.4.1.311.60.2.1'    => {'txt' => "EV Certificate: qcStatements:qcStatement:statementId"},
    # EV: others
    '1.3.6.1.4.1.311.60.1.1'    => {'txt' => "EV Certificate: ??fake root??"},
    '2.5.29.32.0'               => {'txt' => "EV Certificate: subject:anyPolicy"},
    '2.5.29.35'                 => {'txt' => "EV Certificate: subject:authorityKeyIdentifier"}, # Authority key id
    '2.5.29.37'                 => {'txt' => "EV Certificate: subject:extendedKeyUsage"}, # Extended key usage
    '0.9.2342.19200300.100.1.25'=> {'txt' => "EV Certificate: subject:domainComponent"},
    # others
    '2.5.4.4'                   => {'txt' => "subject:surname"},
    '2.5.4.12'                  => {'txt' => "subject:title"},
    '2.5.4.41'                  => {'txt' => "subject:name"},
    '2.5.4.42'                  => {'txt' => "subject:givenName"},
    '2.5.4.43'                  => {'txt' => "subject:intials"},
    '2.5.4.44'                  => {'txt' => "subject:generationQualifier"},
    '2.5.4.46'                  => {'txt' => "subject:dnQualifier"},
    '2.5.29.14'                 => {'txt' => "subject:subjectKeyIdentifier"}, # Subject key id
    '2.5.29.15'                 => {'txt' => "subject:keyUsage"},             # Key usage
    '2.5.29.17'                 => {'txt' => "subject:subjectAlternateName"}, # Subject alternative name
    '2.5.29.19'                 => {'txt' => "subject:basicConstraints"},     # Basic constraints
    '2.5.29.31'                 => {'txt' => "subject:crlDistributionPoints"},# CRL distribution points
    '2.5.29.32'                 => {'txt' => "subject:certificatePolicies"},  # Certificate Policies
    '2.16.840.1.113733.1.7.23.6'=> {'txt' => STR_UNDEF},    # Certificate Policy?
    '2.16.840.1.113733.1.7.48.1'=> {'txt' => STR_UNDEF},    #  ''
    '2.16.840.1.113733.1.7.54'  => {'txt' => STR_UNDEF},    #  ''
    '0.9.2342.19200300.100.1.3' => {'txt' => "subject:mail"},
); # %data_oid


our %ciphers_desc = (   # description of following %ciphers table
    'head'          => [qw(  sec  ssl   enc  bits mac  auth  keyx   score  tags)],
                            # abbreviations used by openssl:
                            # SSLv2, SSLv3, TLSv1, TLSv1.1, TLSv1.2
                            # Kx=  key exchange (DH is diffie-hellman)
                            # Au=  authentication
                            # Enc= encryption with bit size
                            # Mac= mac encryption algorithm
    'text'          => [ # full description of each column in 'ciphers' below
        'Security',         # LOW, MEDIUM, HIGH as reported by openssl 0.9.8 .. 1.0.1h
                            # WEAK as reported by openssl 0.9.8 as EXPORT
                            # weak unqualified by openssl or know vulnerable
                            # NOTE: weak includes NONE (no security at all)
                            #
                            # all following informations as reported by openssl 0.9.8 .. 1.0.1h
        'SSL/TLS',          # Protocol Version:
                            # SSLv2, SSLv3, TLSv1, TLSv11, TLSv12, TLSv13, DTLS0.9, DTLS1.0, PCT
                            # NOTE: all SSLv3 are also TLSv1, TLSv11, TLSv12
                            # (cross-checked with sslaudit.ini)
        'Encryption Algorithm', # None, AES, AESCCM, AESGCM, CAMELLIA, DES, 3DES, FZA, IDEA, RC4, RC2, SEED
        'Key Size',         # in bits
        'MAC Algorithm',    # MD5, SHA1, SHA256, SHA384, AEAD
        'Authentication',   # None, DSS, RSA, ECDH, ECDSA, KRB5, PSK
        'Key Exchange',     # DH, ECDH, ECDH/ECDSA, RSA, KRB5, PSK, SRP
                            # last column is a : separated list (only export from openssl)
                            # different versions of openssl report  ECDH or ECDH/ECDSA
        'score',            # score value as defined in sslaudit.ini (0, 20, 80, 100)
                            # additionally following sores are used:
                            #  10: have been 100 in sslaudit.ini (HIGH  in openssl)
                            #   8: have been 80 in sslaudit.ini  (MDIUM in openssl)
                            #   3:                               (LOW   in openssl)
                            #   2: have been 20 in sslaudit.ini
                            #   1: assumed weak security
                            #  11: unknown, assumed weak security
                            #  81: unknown, assumed MEDIUM security
                            #  91: unknown, assumed HIGH security
                            #   0: all anon and NULL and <56 bit ciphers dispite above settings
        'tags',             # export  as reported by openssl 0.9.8 .. 1.0.1h
                            # OSX     on Mac OS X only
                            # :    (colon) is empty marker (need for other tools
        ],
); # %ciphers_desc


our %ciphers = (
        #-----------------------------+------+-----+----+----+----+-----+--------+----+--------,
        #'head'                 => [qw(  sec  ssl   enc  bits mac  auth  keyx    score tags)],
        #-----------------------------+------+-----+----+----+----+-----+--------+----+--------,
# ...
); # %ciphers


our %cipher_names = (
### Achtung: die hex-Wert sind intern, davon sind nur die letzten 4 oder 6
###          Stellen (je nach Protokoll) der eigentliche Wert.
    # ADH_DES_192_CBC_SHA      # alias: DH_anon_WITH_3DES_EDE_CBC_SHA
    # ADH_DES_40_CBC_SHA       # alias: DH_anon_EXPORT_WITH_DES40_CBC_SHA
    # ADH_DES_64_CBC_SHA       # alias: DH_anon_WITH_DES_CBC_SHA
    # ADH_RC4_40_MD5           # alias: DH_anon_EXPORT_WITH_RC4_40_MD5
    # DHE_RSA_WITH_AES_128_SHA # alias: DHE_RSA_WITH_AES_128_CBC_SHA
    # DHE_RSA_WITH_AES_256_SHA # alias: DHE_RSA_WITH_AES_256_CBC_SHA
    #
    #!#----------+-------------------------------------+--------------------------+
    #!# constant =>     cipher suite name              # cipher suite value
    #!#----------+-------------------------------------+--------------------------+
    '0x0300001B' => [qw(ADH-DES-CBC3-SHA                ADH_DES_192_CBC_SHA)],
    '0x03000019' => [qw(EXP-ADH-DES-CBC-SHA             ADH_DES_40_CBC_SHA)],
    '0x0300001A' => [qw(ADH-DES-CBC-SHA                 ADH_DES_64_CBC_SHA)],
    '0x03000018' => [qw(ADH-RC4-MD5                     ADH_RC4_128_MD5)],
    '0x03000017' => [qw(EXP-ADH-RC4-MD5                 ADH_RC4_40_MD5)],
    '0x030000A6' => [qw(ADH-AES128-GCM-SHA256           ADH_WITH_AES_128_GCM_SHA256)],
    '0x03000034' => [qw(ADH-AES128-SHA                  ADH_WITH_AES_128_SHA)],
    '0x0300006C' => [qw(ADH-AES128-SHA256               ADH_WITH_AES_128_SHA256)],
    '0x030000A7' => [qw(ADH-AES256-GCM-SHA384           ADH_WITH_AES_256_GCM_SHA384)],
    '0x0300003A' => [qw(ADH-AES256-SHA                  ADH_WITH_AES_256_SHA)],
    '0x0300006D' => [qw(ADH-AES256-SHA256               ADH_WITH_AES_256_SHA256)],
    '0x03000046' => [qw(ADH-CAMELLIA128-SHA             ADH_WITH_CAMELLIA_128_CBC_SHA)],
    '0x03000089' => [qw(ADH-CAMELLIA256-SHA             ADH_WITH_CAMELLIA_256_CBC_SHA)],
    '0x030000BF' => [qw(ADH-CAMELLIA128-SHA256          ADH_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x030000C5' => [qw(ADH-CAMELLIA256-SHA256          ADH_WITH_CAMELLIA_256_CBC_SHA256)],
    '0x0300009B' => [qw(ADH-SEED-SHA                    ADH_WITH_SEED_SHA)],
    '0x020700c0' => [qw(DES-CBC3-MD5                    DES_192_EDE3_CBC_WITH_MD5)],
    '0x020701c0' => [qw(DES-CBC3-SHA                    DES_192_EDE3_CBC_WITH_SHA)],
    '0x02060040' => [qw(DES-CBC-MD5                     DES_64_CBC_WITH_MD5)],
    '0x02060140' => [qw(DES-CBC-SHA                     DES_64_CBC_WITH_SHA)],
    '0x02ff0800' => [qw(DES-CFB-M1                      DES_64_CFB64_WITH_MD5_1)],
    '0x03000063' => [qw(EXP1024-DHE-DSS-DES-CBC-SHA     DHE_DSS_EXPORT1024_WITH_DES_CBC_SHA)],
    '0x03000065' => [qw(EXP1024-DHE-DSS-RC4-SHA         DHE_DSS_EXPORT1024_WITH_RC4_56_SHA)],
    '0x030000A2' => [qw(DHE-DSS-AES128-GCM-SHA256       DHE_DSS_WITH_AES_128_GCM_SHA256)],
    '0x03000032' => [qw(DHE-DSS-AES128-SHA              DHE_DSS_WITH_AES_128_SHA)],
    '0x03000040' => [qw(DHE-DSS-AES128-SHA256           DHE_DSS_WITH_AES_128_SHA256)],
    '0x030000A3' => [qw(DHE-DSS-AES256-GCM-SHA384       DHE_DSS_WITH_AES_256_GCM_SHA384)],
    '0x03000038' => [qw(DHE-DSS-AES256-SHA              DHE_DSS_WITH_AES_256_SHA)],
    '0x0300006A' => [qw(DHE-DSS-AES256-SHA256           DHE_DSS_WITH_AES_256_SHA256)],
    '0x03000044' => [qw(DHE-DSS-CAMELLIA128-SHA         DHE_DSS_WITH_CAMELLIA_128_CBC_SHA)],
    '0x03000087' => [qw(DHE-DSS-CAMELLIA256-SHA         DHE_DSS_WITH_CAMELLIA_256_CBC_SHA)],
    '0x030000BD' => [qw(DHE-DSS-CAMELLIA128-SHA256      DHE_DSS_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x030000C3' => [qw(DHE-DSS-CAMELLIA256-SHA256      DHE_DSS_WITH_CAMELLIA_256_CBC_SHA256)],
    '0x03000066' => [qw(DHE-DSS-RC4-SHA                 DHE_DSS_WITH_RC4_128_SHA)],
    '0x03000099' => [qw(DHE-DSS-SEED-SHA                DHE_DSS_WITH_SEED_SHA)],
    '0x0300009E' => [qw(DHE-RSA-AES128-GCM-SHA256       DHE_RSA_WITH_AES_128_GCM_SHA256)],
    '0x03000033' => [qw(DHE-RSA-AES128-SHA              DHE_RSA_WITH_AES_128_SHA)],
    '0x03000067' => [qw(DHE-RSA-AES128-SHA256           DHE_RSA_WITH_AES_128_SHA256)],
    '0x0300009F' => [qw(DHE-RSA-AES256-GCM-SHA384       DHE_RSA_WITH_AES_256_GCM_SHA384)],
    '0x03000039' => [qw(DHE-RSA-AES256-SHA              DHE_RSA_WITH_AES_256_SHA)],
    '0x0300006B' => [qw(DHE-RSA-AES256-SHA256           DHE_RSA_WITH_AES_256_SHA256)],
    '0x03000045' => [qw(DHE-RSA-CAMELLIA128-SHA         DHE_RSA_WITH_CAMELLIA_128_CBC_SHA)],
    '0x03000088' => [qw(DHE-RSA-CAMELLIA256-SHA         DHE_RSA_WITH_CAMELLIA_256_CBC_SHA)],
    '0x030000BE' => [qw(DHE-RSA-CAMELLIA128-SHA256      DHE_RSA_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x030000C4' => [qw(DHE-RSA-CAMELLIA256-SHA256      DHE_RSA_WITH_CAMELLIA_256_CBC_SHA256)],
    '0x0300CC15' => [qw(DHE-RSA-CHACHA20-POLY1305-SHA256   DHE_RSA_WITH_CHACHA20_POLY1305_SHA256)],
    '0x0300CCAA' => [qw(DHE-RSA-CHACHA20-POLY1305-SHA256   DHE_RSA_WITH_CHACHA20_POLY1305_SHA256)], # see Note(c)
    '0x0300CCAB' => [qw(PSK-CHACHA20-POLY1305-SHA256    PSK_WITH_CHACHA20_POLY1305_SHA256)],
    '0x0300CCAC' => [qw(ECDHE-PSK-CHACHA20-POLY1305-SHA256 ECDHE_PSK_WITH_CHACHA20_POLY1305_SHA256)],
    '0x0300CCAD' => [qw(DHE-PSK-CHACHA20-POLY1305-SHA256   DHE_PSK_WITH_CHACHA20_POLY1305_SHA256)],
    '0x0300CCAE' => [qw(PSK-RSA-CHACHA20-POLY1305       RSA_PSK_WITH_CHACHA20_POLY1305_SHA256)],
    '0x0300009A' => [qw(DHE-RSA-SEED-SHA                DHE_RSA_WITH_SEED_SHA)],
    '0x030000BB' => [qw(DH-DSS-CAMELLIA128-SHA256       DH_DSS_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x030000C1' => [qw(DH-DSS-CAMELLIA256-SHA256       DH_DSS_WITH_CAMELLIA_256_CBC_SHA256)],
    '0x0300000D' => [qw(DH-DSS-DES-CBC3-SHA             DH_DSS_DES_192_CBC3_SHA)],
    '0x0300000B' => [qw(EXP-DH-DSS-DES-CBC-SHA          DH_DSS_DES_40_CBC_SHA)],
    '0x0300000C' => [qw(DH-DSS-DES-CBC-SHA              DH_DSS_DES_64_CBC_SHA)],
    '0x030000A4' => [qw(DH-DSS-AES128-GCM-SHA256        DH_DSS_WITH_AES_128_GCM_SHA256)],
    '0x03000030' => [qw(DH-DSS-AES128-SHA               DH_DSS_WITH_AES_128_SHA)],
    '0x0300003E' => [qw(DH-DSS-AES128-SHA256            DH_DSS_WITH_AES_128_SHA256)],
    '0x030000A5' => [qw(DH-DSS-AES256-GCM-SHA384        DH_DSS_WITH_AES_256_GCM_SHA384)],
    '0x03000036' => [qw(DH-DSS-AES256-SHA               DH_DSS_WITH_AES_256_SHA)],
    '0x03000068' => [qw(DH-DSS-AES256-SHA256            DH_DSS_WITH_AES_256_SHA256)],
    '0x03000042' => [qw(DH-DSS-CAMELLIA128-SHA          DH_DSS_WITH_CAMELLIA_128_CBC_SHA)],
    '0x03000085' => [qw(DH-DSS-CAMELLIA256-SHA          DH_DSS_WITH_CAMELLIA_256_CBC_SHA)],
    '0x03000097' => [qw(DH-DSS-SEED-SHA                 DH_DSS_WITH_SEED_SHA)],
    '0x03000010' => [qw(DH-RSA-DES-CBC3-SHA             DH_RSA_DES_192_CBC3_SHA)],
    '0x0300000E' => [qw(EXP-DH-RSA-DES-CBC-SHA          DH_RSA_DES_40_CBC_SHA)],
    '0x0300000F' => [qw(DH-RSA-DES-CBC-SHA              DH_RSA_DES_64_CBC_SHA)],
    '0x030000A0' => [qw(DH-RSA-AES128-GCM-SHA256        DH_RSA_WITH_AES_128_GCM_SHA256)],
    '0x03000031' => [qw(DH-RSA-AES128-SHA               DH_RSA_WITH_AES_128_SHA)],
    '0x0300003F' => [qw(DH-RSA-AES128-SHA256            DH_RSA_WITH_AES_128_SHA256)],
    '0x030000A1' => [qw(DH-RSA-AES256-GCM-SHA384        DH_RSA_WITH_AES_256_GCM_SHA384)],
    '0x03000037' => [qw(DH-RSA-AES256-SHA               DH_RSA_WITH_AES_256_SHA)],
    '0x03000069' => [qw(DH-RSA-AES256-SHA256            DH_RSA_WITH_AES_256_SHA256)],
    '0x03000043' => [qw(DH-RSA-CAMELLIA128-SHA          DH_RSA_WITH_CAMELLIA_128_CBC_SHA)],
    '0x03000086' => [qw(DH-RSA-CAMELLIA256-SHA          DH_RSA_WITH_CAMELLIA_256_CBC_SHA)],
    '0x030000BC' => [qw(DH-RSA-CAMELLIA128-SHA256       DH_RSA_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x030000C2' => [qw(DH-RSA-CAMELLIA256-SHA256       DH_RSA_WITH_CAMELLIA_256_CBC_SHA256)],
    '0x03000098' => [qw(DH-RSA-SEED-SHA                 DH_RSA_WITH_SEED_SHA)],
    '0x0300C009' => [qw(ECDHE-ECDSA-AES128-SHA          ECDHE_ECDSA_WITH_AES_128_CBC_SHA)],
    '0x0300C02B' => [qw(ECDHE-ECDSA-AES128-GCM-SHA256   ECDHE_ECDSA_WITH_AES_128_GCM_SHA256)],
    '0x0300C023' => [qw(ECDHE-ECDSA-AES128-SHA256       ECDHE_ECDSA_WITH_AES_128_SHA256)],
    '0x0300C00A' => [qw(ECDHE-ECDSA-AES256-SHA          ECDHE_ECDSA_WITH_AES_256_CBC_SHA)],
    '0x0300C02C' => [qw(ECDHE-ECDSA-AES256-GCM-SHA384   ECDHE_ECDSA_WITH_AES_256_GCM_SHA384)],
    '0x0300C024' => [qw(ECDHE-ECDSA-AES256-SHA384       ECDHE_ECDSA_WITH_AES_256_SHA384)],
    '0x03000072' => [qw(ECDHE-ECDSA-CAMELLIA128-SHA256  ECDHE_ECDSA_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x03000073' => [qw(ECDHE-ECDSA-CAMELLIA256-SHA384  ECDHE_ECDSA_WITH_CAMELLIA_256_CBC_SHA384)],
    '0x0300CC14' => [qw(ECDHE-ECDSA-CHACHA20-POLY1305-SHA256 ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256)],
    '0x0300CCA9' => [qw(ECDHE-ECDSA-CHACHA20-POLY1305-SHA256 ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256)], # see Note(c)
    '0x0300C008' => [qw(ECDHE-ECDSA-DES-CBC3-SHA        ECDHE_ECDSA_WITH_DES_192_CBC3_SHA)],
    '0x0300C006' => [qw(ECDHE-ECDSA-NULL-SHA            ECDHE_ECDSA_WITH_NULL_SHA)],
    '0x0300C007' => [qw(ECDHE-ECDSA-RC4-SHA             ECDHE_ECDSA_WITH_RC4_128_SHA)],
    '0x0300C013' => [qw(ECDHE-RSA-AES128-SHA            ECDHE_RSA_WITH_AES_128_CBC_SHA)],
    '0x0300C02F' => [qw(ECDHE-RSA-AES128-GCM-SHA256     ECDHE_RSA_WITH_AES_128_GCM_SHA256)],
    '0x0300C027' => [qw(ECDHE-RSA-AES128-SHA256         ECDHE_RSA_WITH_AES_128_SHA256)],
    '0x0300C014' => [qw(ECDHE-RSA-AES256-SHA            ECDHE_RSA_WITH_AES_256_CBC_SHA)],
    '0x0300C030' => [qw(ECDHE-RSA-AES256-GCM-SHA384     ECDHE_RSA_WITH_AES_256_GCM_SHA384)],
    '0x0300C028' => [qw(ECDHE-RSA-AES256-SHA384         ECDHE_RSA_WITH_AES_256_SHA384)],
    '0x03000076' => [qw(ECDHE-RSA-CAMELLIA128-SHA256    ECDHE_RSA_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x03000077' => [qw(ECDHE-RSA-CAMELLIA256-SHA384    ECDHE_RSA_WITH_CAMELLIA_256_CBC_SHA384)],
    '0x0300CC13' => [qw(ECDHE-RSA-CHACHA20-POLY1305-SHA256  ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256)],
    '0x0300CCA8' => [qw(ECDHE-RSA-CHACHA20-POLY1305-SHA256  ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256)], # see Note(c)
    '0x0300C012' => [qw(ECDHE-RSA-DES-CBC3-SHA          ECDHE_RSA_WITH_DES_192_CBC3_SHA)],
    '0x0300C010' => [qw(ECDHE-RSA-NULL-SHA              ECDHE_RSA_WITH_NULL_SHA)],
    '0x0300C011' => [qw(ECDHE-RSA-RC4-SHA               ECDHE_RSA_WITH_RC4_128_SHA)],
    '0x0300C004' => [qw(ECDH-ECDSA-AES128-SHA           ECDH_ECDSA_WITH_AES_128_CBC_SHA)],
    '0x0300C02D' => [qw(ECDH-ECDSA-AES128-GCM-SHA256    ECDH_ECDSA_WITH_AES_128_GCM_SHA256)],
    '0x0300C025' => [qw(ECDH-ECDSA-AES128-SHA256        ECDH_ECDSA_WITH_AES_128_SHA256)],
    '0x0300C005' => [qw(ECDH-ECDSA-AES256-SHA           ECDH_ECDSA_WITH_AES_256_CBC_SHA)],
    '0x0300C02E' => [qw(ECDH-ECDSA-AES256-GCM-SHA384    ECDH_ECDSA_WITH_AES_256_GCM_SHA384)],
    '0x0300C026' => [qw(ECDH-ECDSA-AES256-SHA384        ECDH_ECDSA_WITH_AES_256_SHA384)],
    '0x03000074' => [qw(ECDH-ECDSA-CAMELLIA128-SHA256   ECDH_ECDSA_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x03000075' => [qw(ECDH-ECDSA-CAMELLIA256-SHA384   ECDH_ECDSA_WITH_CAMELLIA_256_CBC_SHA384)],
    '0x0300C003' => [qw(ECDH-ECDSA-DES-CBC3-SHA         ECDH_ECDSA_WITH_DES_192_CBC3_SHA)],
    '0x0300C001' => [qw(ECDH-ECDSA-NULL-SHA             ECDH_ECDSA_WITH_NULL_SHA)],
    '0x0300C002' => [qw(ECDH-ECDSA-RC4-SHA              ECDH_ECDSA_WITH_RC4_128_SHA)],
    '0x0300C00E' => [qw(ECDH-RSA-AES128-SHA             ECDH_RSA_WITH_AES_128_CBC_SHA)],
    '0x0300C031' => [qw(ECDH-RSA-AES128-GCM-SHA256      ECDH_RSA_WITH_AES_128_GCM_SHA256)],
    '0x0300C029' => [qw(ECDH-RSA-AES128-SHA256          ECDH_RSA_WITH_AES_128_SHA256)],
    '0x0300C00F' => [qw(ECDH-RSA-AES256-SHA             ECDH_RSA_WITH_AES_256_CBC_SHA)],
    '0x0300C032' => [qw(ECDH-RSA-AES256-GCM-SHA384      ECDH_RSA_WITH_AES_256_GCM_SHA384)],
    '0x0300C02A' => [qw(ECDH-RSA-AES256-SHA384          ECDH_RSA_WITH_AES_256_SHA384)],
    '0x03000078' => [qw(ECDH-RSA-CAMELLIA128-SHA256     ECDH_RSA_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x03000079' => [qw(ECDH-RSA-CAMELLIA256-SHA384     ECDH_RSA_WITH_CAMELLIA_256_CBC_SHA384)],
    '0x0300C00D' => [qw(ECDH-RSA-DES-CBC3-SHA           ECDH_RSA_WITH_DES_192_CBC3_SHA)],
    '0x0300C00B' => [qw(ECDH-RSA-NULL-SHA               ECDH_RSA_WITH_NULL_SHA)],
    '0x0300C00C' => [qw(ECDH-RSA-RC4-SHA                ECDH_RSA_WITH_RC4_128_SHA)],
    '0x0300C018' => [qw(AECDH-AES128-SHA                ECDH_anon_WITH_AES_128_CBC_SHA)],
    '0x0300C019' => [qw(AECDH-AES256-SHA                ECDH_anon_WITH_AES_256_CBC_SHA)],
    '0x0300C017' => [qw(AECDH-DES-CBC3-SHA              ECDH_anon_WITH_DES_192_CBC3_SHA)],
    '0x0300C015' => [qw(AECDH-NULL-SHA                  ECDH_anon_WITH_NULL_SHA)],
    '0x0300C016' => [qw(AECDH-RC4-SHA                   ECDH_anon_WITH_RC4_128_SHA)],
    '0x03000013' => [qw(EDH-DSS-DES-CBC3-SHA            EDH_DSS_DES_192_CBC3_SHA)],
    '0x03000011' => [qw(EXP-EDH-DSS-DES-CBC-SHA         EDH_DSS_DES_40_CBC_SHA)],
    '0x03000012' => [qw(EDH-DSS-DES-CBC-SHA             EDH_DSS_DES_64_CBC_SHA)],
    '0x03000016' => [qw(EDH-RSA-DES-CBC3-SHA            EDH_RSA_DES_192_CBC3_SHA)],
    '0x03000014' => [qw(EXP-EDH-RSA-DES-CBC-SHA         EDH_RSA_DES_40_CBC_SHA)],
    '0x03000015' => [qw(EDH-RSA-DES-CBC-SHA             EDH_RSA_DES_64_CBC_SHA)],
    '0x0300001D' => [qw(FZA-FZA-SHA                     FZA_DMS_FZA_SHA)],     # FORTEZZA_KEA_WITH_FORTEZZA_CBC_SHA
    '0x0300001C' => [qw(FZA-NULL-SHA                    FZA_DMS_NULL_SHA)],    # FORTEZZA_KEA_WITH_NULL_SHA
    '0x0300001e' => [qw(FZA-RC4-SHA                     FZA_DMS_RC4_SHA)],     # <== 1e so that it is its own hash entry in crontrast to 1E (duplicate constant definition in openssl)
    '0x02050080' => [qw(IDEA-CBC-MD5                    IDEA_128_CBC_WITH_MD5)],
    '0x03000023' => [qw(KRB5-DES-CBC3-MD5               KRB5_DES_192_CBC3_MD5)],
    '0x0300001F' => [qw(KRB5-DES-CBC3-SHA               KRB5_DES_192_CBC3_SHA)],
    '0x03000029' => [qw(EXP-KRB5-DES-CBC-MD5            KRB5_DES_40_CBC_MD5)],
    '0x03000026' => [qw(EXP-KRB5-DES-CBC-SHA            KRB5_DES_40_CBC_SHA)],
    '0x03000022' => [qw(KRB5-DES-CBC-MD5                KRB5_DES_64_CBC_MD5)],
    '0x0300001E' => [qw(KRB5-DES-CBC-SHA                KRB5_DES_64_CBC_SHA)],
    '0x03000025' => [qw(KRB5-IDEA-CBC-MD5               KRB5_IDEA_128_CBC_MD5)],
    '0x03000021' => [qw(KRB5-IDEA-CBC-SHA               KRB5_IDEA_128_CBC_SHA)],
    '0x0300002A' => [qw(EXP-KRB5-RC2-CBC-MD5            KRB5_RC2_40_CBC_MD5)],
    '0x03000027' => [qw(EXP-KRB5-RC2-CBC-SHA            KRB5_RC2_40_CBC_SHA)],
    '0x03000024' => [qw(KRB5-RC4-MD5                    KRB5_RC4_128_MD5)],
    '0x03000020' => [qw(KRB5-RC4-SHA                    KRB5_RC4_128_SHA)],
    '0x0300002B' => [qw(EXP-KRB5-RC4-MD5                KRB5_RC4_40_MD5)],
    '0x03000028' => [qw(EXP-KRB5-RC4-SHA                KRB5_RC4_40_SHA)],
    '0x02ff0810' => [qw(NULL                            NULL)],
    '0x02000000' => [qw(NULL-MD5                        NULL_WITH_MD5)],
    '0x03000000' => [qw(NULL-MD5                        NULL_WITH_NULL_NULL)],
    '0x0300008A' => [qw(PSK-RC4-SHA                     PSK_WITH_RC4_128_SHA)],
    '0x0300008B' => [qw(PSK-3DES-EDE-CBC-SHA            PSK_WITH_3DES_EDE_CBC_SHA)],
    '0x0300008C' => [qw(PSK-AES128-CBC-SHA              PSK_WITH_AES_128_CBC_SHA)],
    '0x0300008D' => [qw(PSK-AES256-CBC-SHA              PSK_WITH_AES_256_CBC_SHA)],
    '0x02010080' => [qw(RC4-MD5                         RC4_128_WITH_MD5)],
    '0x02020080' => [qw(EXP-RC4-MD5                     RC4_128_EXPORT40_WITH_MD5)],
    '0x02030080' => [qw(RC2-CBC-MD5                     RC2_128_CBC_WITH_MD5)],
    '0x02040080' => [qw(EXP-RC2-CBC-MD5                 RC2_128_CBC_EXPORT40_WITH_MD5)],
    '0x02080080' => [qw(RC4-64-MD5                      RC4_64_WITH_MD5)],
    '0x0300000A' => [qw(DES-CBC3-SHA                    RSA_DES_192_CBC3_SHA)],
    '0x03000008' => [qw(EXP-DES-CBC-SHA                 RSA_DES_40_CBC_SHA)],
    '0x03000009' => [qw(DES-CBC-SHA                     RSA_DES_64_CBC_SHA)],
    '0x03000062' => [qw(EXP1024-DES-CBC-SHA             RSA_EXPORT1024_WITH_DES_CBC_SHA)],
    '0x03000061' => [qw(EXP1024-RC2-CBC-MD5             RSA_EXPORT1024_WITH_RC2_CBC_56_MD5)],
    '0x03000060' => [qw(EXP1024-RC4-MD5                 RSA_EXPORT1024_WITH_RC4_56_MD5)],
    '0x03000064' => [qw(EXP1024-RC4-SHA                 RSA_EXPORT1024_WITH_RC4_56_SHA)],
    '0x03000007' => [qw(IDEA-CBC-SHA                    RSA_IDEA_128_SHA)],
    '0x03000001' => [qw(NULL-MD5                        RSA_NULL_MD5)],
    '0x03000002' => [qw(NULL-SHA                        RSA_NULL_SHA)],
    '0x03000006' => [qw(EXP-RC2-CBC-MD5                 RSA_RC2_40_MD5)],
    '0x03000004' => [qw(RC4-MD5                         RSA_RC4_128_MD5)],
    '0x03000005' => [qw(RC4-SHA                         RSA_RC4_128_SHA)],
    '0x03000003' => [qw(EXP-RC4-MD5                     RSA_RC4_40_MD5)],
    '0x0300009C' => [qw(AES128-GCM-SHA256               RSA_WITH_AES_128_GCM_SHA256)],
    '0x0300002F' => [qw(AES128-SHA                      RSA_WITH_AES_128_SHA)],
    '0x0300003C' => [qw(AES128-SHA256                   RSA_WITH_AES_128_SHA256)],
    '0x0300009D' => [qw(AES256-GCM-SHA384               RSA_WITH_AES_256_GCM_SHA384)],
    '0x03000035' => [qw(AES256-SHA                      RSA_WITH_AES_256_SHA)],
    '0x0300003D' => [qw(AES256-SHA256                   RSA_WITH_AES_256_SHA256)],
    '0x03000041' => [qw(CAMELLIA128-SHA                 RSA_WITH_CAMELLIA_128_CBC_SHA)],
    '0x03000084' => [qw(CAMELLIA256-SHA                 RSA_WITH_CAMELLIA_256_CBC_SHA)],
    '0x030000BA' => [qw(CAMELLIA128-SHA256              RSA_WITH_CAMELLIA_128_CBC_SHA256)],
    '0x030000C0' => [qw(CAMELLIA256-SHA256              RSA_WITH_CAMELLIA_256_CBC_SHA256)],
    '0x0300003B' => [qw(NULL-SHA256                     RSA_WITH_NULL_SHA256)],
    '0x03000096' => [qw(SEED-SHA                        RSA_WITH_SEED_SHA)],
#
    '0x0300002C' => [qw(PSK-SHA                         PSK_WITH_NULL_SHA)],
    '0x0300002D' => [qw(DHE-PSK-SHA                     DHE_PSK_WITH_NULL_SHA)],
    '0x0300002E' => [qw(RSA-PSK-SHA                     RSA_PSK_WITH_NULL_SHA)],
    '0x0300008E' => [qw(DHE-PSK-RC4-SHA                 DHE_PSK_WITH_RC4_128_SHA)],
    '0x0300008F' => [qw(DHE-PSK-3DES-SHA                DHE_PSK_WITH_3DES_EDE_CBC_SHA)],
    '0x03000090' => [qw(DHE-PSK-AES128-SHA              DHE_PSK_WITH_AES_128_CBC_SHA)],
    '0x03000091' => [qw(DHE-PSK-AES256-SHA              DHE_PSK_WITH_AES_256_CBC_SHA)],
    '0x03000092' => [qw(RSA-PSK-RC4-SHA                 RSA_PSK_WITH_RC4_128_SHA)],
#   '0x03000093' => [qw(RSA-PSK-3DES-SHA                RSA_PSK_WITH_3DES_EDE_CBC_SHA)],
    '0x03000093' => [qw(RSA-PSK-3DES-EDE-CBC-SHA        RSA_PSK_WITH_3DES_EDE_CBC_SHA)],
    '0x03000094' => [qw(RSA-PSK-AES128-SHA              RSA_PSK_WITH_AES_128_CBC_SHA)],
#   '0x03000094' => [qw(RSA-PSK-AES128-CBC-SHA          RSA_PSK_WITH_AES_128_CBC_SHA)],     # openssl 1.0.2
    '0x03000095' => [qw(RSA-PSK-AES256-SHA              RSA_PSK_WITH_AES_256_CBC_SHA)],
#   '0x03000095' => [qw(RSA-PSK-AES128-CBC-SHA          RSA_PSK_WITH_AES_256_CBC_SHA)],     # openssl 1.0.2
    '0x030000AA' => [qw(DHE-PSK-AES128-GCM-SHA256       DHE_PSK_WITH_AES_128_GCM_SHA256)],
    '0x030000AB' => [qw(DHE-PSK-AES256-GCM-SHA384       DHE_PSK_WITH_AES_256_GCM_SHA384)],
    '0x030000AC' => [qw(RSA-PSK-AES128-GCM-SHA256       RSA_PSK_WITH_AES_128_GCM_SHA256)],
    '0x030000AD' => [qw(RSA-PSK-AES256-GCM-SHA384       RSA_PSK_WITH_AES_256_GCM_SHA384)],
    '0x030000AE' => [qw(PSK-AES128-SHA256               PSK_WITH_AES_128_CBC_SHA256)],
    '0x030000AF' => [qw(PSK-AES256-SHA384               PSK_WITH_AES_256_CBC_SHA384)],
    '0x030000B0' => [qw(PSK-SHA256                      PSK_WITH_NULL_SHA256)],
    '0x030000B1' => [qw(PSK-SHA384                      PSK_WITH_NULL_SHA384)],
    '0x030000B2' => [qw(DHE-PSK-AES128-SHA256           DHE_PSK_WITH_AES_256_CBC_SHA256)],
    '0x030000B3' => [qw(DHE-PSK-AES256-SHA384           DHE_PSK_WITH_AES_256_CBC_SHA384)],
    '0x030000B4' => [qw(DHE-PSK-SHA256                  DHE_PSK_WITH_NULL_SHA256)],
    '0x030000B5' => [qw(DHE-PSK-SHA384                  DHE_PSK_WITH_NULL_SHA384)],
    '0x030000B6' => [qw(RSA-PSK-AES128-SHA256           RSA_PSK_WITH_AES_256_CBC_SHA256)],
    '0x030000B7' => [qw(RSA-PSK-AES256-SHA384           RSA_PSK_WITH_AES_256_CBC_SHA384)],
    '0x030000B8' => [qw(RSA-PSK-SHA256                  RSA_PSK_WITH_NULL_SHA256)],
    '0x030000B9' => [qw(RSA-PSK-SHA384                  RSA_PSK_WITH_NULL_SHA384)],
#
    '0x0300C09C' => [qw(RSA-AES128-CCM                  RSA_WITH_AES_128_CCM)],
    '0x0300C09D' => [qw(RSA-AES256-CCM                  RSA_WITH_AES_256_CCM)],
    '0x0300C09E' => [qw(DHE-RSA-AES128-CCM              DHE_RSA_WITH_AES_128_CCM)],
    '0x0300C09F' => [qw(DHE-RSA-AES256-CCM              DHE_RSA_WITH_AES_256_CCM)],
    '0x0300C0A4' => [qw(PSK-RSA-AES128-CCM              PSK_WITH_AES_128_CCM)],
    '0x0300C0A5' => [qw(PSK-RSA-AES256-CCM              PSK_WITH_AES_256_CCM)],
    '0x0300C0AC' => [qw(ECDHE-RSA-AES128-CCM            ECDHE_ECDSA_WITH_AES_128_CCM)],
    '0x0300C0AD' => [qw(ECDHE-RSA-AES256-CCM            ECDHE_ECDSA_WITH_AES_256_CCM)],
    '0x0300C0A0' => [qw(RSA-AES128-CCM-8                RSA_WITH_AES_128_CCM_8)],
    '0x0300C0A1' => [qw(RSA-AES256-CCM-8                RSA_WITH_AES_256_CCM_8)],
    '0x0300C0A2' => [qw(DHE-RSA-AES128-CCM-8            DHE_RSA_WITH_AES_128_CCM_8)],
    '0x0300C0A3' => [qw(DHE-RSA-AES256-CCM-8            DHE_RSA_WITH_AES_256_CCM_8)],
    '0x0300C0A8' => [qw(PSK-RSA-AES128-CCM-8            PSK_WITH_AES_128_CCM_8)],
    '0x0300C0A9' => [qw(PSK-RSA-AES256-CCM-8            PSK_WITH_AES_256_CCM_8)],
    '0x0300C0AE' => [qw(ECDHE-RSA-AES128-CCM-8          ECDHE_ECDSA_WITH_AES_128_CCM_8)],
    '0x0300C0AF' => [qw(ECDHE-RSA-AES256-CCM-8          ECDHE_ECDSA_WITH_AES_256_CCM_8)],
    '0x03005600' => [qw(SCSV                            TLS_FALLBACK_SCSV)], # FIXME: according http://tools.ietf.org/html/7507.html
    '0x030000FF' => [qw(INFO_SCSV                       EMPTY_RENEGOTIATION_INFO_SCSV)],
    '0x0300C01C' => [qw(SRP-DSS-3DES-EDE-CBC-SHA        SRP_SHA_DSS_WITH_3DES_EDE_CBC_SHA)],
    '0x0300C01F' => [qw(SRP-DSS-AES-128-CBC-SHA         SRP_SHA_DSS_WITH_AES_128_CBC_SHA)],
    '0x0300C022' => [qw(SRP-DSS-AES-256-CBC-SHA         SRP_SHA_DSS_WITH_AES_256_CBC_SHA)],
    '0x0300C01B' => [qw(SRP-RSA-3DES-EDE-CBC-SHA        SRP_SHA_RSA_WITH_3DES_EDE_CBC_SHA)],
    '0x0300C01E' => [qw(SRP-RSA-AES-128-CBC-SHA         SRP_SHA_RSA_WITH_AES_128_CBC_SHA)],
    '0x0300C021' => [qw(SRP-RSA-AES-256-CBC-SHA         SRP_SHA_RSA_WITH_AES_256_CBC_SHA)],
    '0x0300C01A' => [qw(SRP-3DES-EDE-CBC-SHA            SRP_SHA_WITH_3DES_EDE_CBC_SHA)],
    '0x0300C01D' => [qw(SRP-AES-128-CBC-SHA             SRP_SHA_WITH_AES_128_CBC_SHA)],
    '0x0300C020' => [qw(SRP-AES-256-CBC-SHA             SRP_SHA_WITH_AES_256_CBC_SHA)],
    '0x0300FEE0' => [qw(RSA-FIPS-3DES-EDE-SHA           RSA_FIPS_WITH_3DES_EDE_CBC_SHA)],
    '0x0300FEE1' => [qw(RSA-FIPS-DES-CBC-SHA            RSA_FIPS_WITH_DES_CBC_SHA)],
    '0x0300FEFE' => [qw(RSA-FIPS-DES-CBC-SHA            RSA_FIPS_WITH_DES_CBC_SHA)],
    '0x0300FEFF' => [qw(RSA-FIPS-3DES-EDE-SHA           RSA_FIPS_WITH_3DES_EDE_CBC_SHA)],
    '0x03000080' => [qw(GOST94-GOST89-GOST89            GOSTR341094_WITH_28147_CNT_IMIT)],
    '0x03000081' => [qw(GOST2001-GOST89-GOST89          GOSTR341001_WITH_28147_CNT_IMIT)],
    '0x0300FF00' => [qw(GOST-MD5             -?-)],  # ??
    '0x0300FF01' => [qw(GOST-GOST94          -?-)],  # ??
    '0x0300FF00' => [qw(GOST94-NULL-GOST94   -?-)],  # ??
    '0x0300FF01' => [qw(GOST2001-NULL-GOST94 -?-)],  # ??
# TODO:  following PCT...
    '0x00800001' => [qw(PCT_SSL_CERT_TYPE               PCT1_CERT_X509)],
    '0x00800003' => [qw(PCT_SSL_CERT_TYPE               PCT1_CERT_X509_CHAIN)],
    '0x00810001' => [qw(PCT_SSL_HASH_TYPE               PCT1_HASH_MD5)],
    '0x00810003' => [qw(PCT_SSL_HASH_TYPE               PCT1_HASH_SHA)],
    '0x00820003' => [qw(PCT_SSL_EXCH_TYPE               PCT1_EXCH_RSA_PKCS1)],
    '0x00823004' => [qw(PCT_SSL_CIPHER_TYPE_1ST_HALF    PCT1_CIPHER_RC4)],
    '0x00842840' => [qw(PCT_SSL_CIPHER_TYPE_2ND_HALF    PCT1_ENC_BITS_40|PCT1_MAC_BITS_128)],
    '0x00848040' => [qw(PCT_SSL_CIPHER_TYPE_2ND_HALF    PCT1_ENC_BITS_128|PCT1_MAC_BITS_128)],
    '0x008f8001' => [qw(PCT_SSL_COMPAT                  PCT_VERSION_1)],
    #!#----------+-------------------------------------+--------------------------+
#
    # Note(c)
    #   according https://tools.ietf.org/html/draft-ietf-tls-chacha20-poly1305-04
    #   some hex keys for ciphers changed
); # %cipher_names

our %cipher_alias = ( # TODO: list not yet used
    #!#----------+-------------------------------------+--------------------------+
    #!# constant =>     cipher suite name alias        # comment (where found)
    #!#----------+-------------------------------------+--------------------------+
    '0x02030080' => [qw(RC2-MD5)],                     #
    '0x02040080' => [qw(EXP-RC2-MD5)],                 # from sslaudit.ini
    '0x03000012' => [qw(EDH-DSS-CBC-SHA)],             # from sslaudit.ini and mozilla
    '0x0300001D' => [qw(FZA-FZA-CBC-SHA)],
    '0x03000032' => [qw(EDH-DSS-AES128-SHA)],          # from RSA BSAFE SSL-C
    '0x03000033' => [qw(EDH-RSA-AES128-SHA)],          # from RSA BSAFE SSL-C
    '0x03000038' => [qw(EDH-DSS-AES256-SHA)],          # from RSA BSAFE SSL-C
    '0x03000039' => [qw(EDH-RSA-AES256-SHA)],          # from RSA BSAFE SSL-C
    '0x03000062' => [qw(EXP-DES-56-SHA)],              # from RSA BSAFE SSL-C
    '0x03000063' => [qw(EXP-EDH-DSS-DES-56-SHA)],      # from RSA BSAFE SSL-C
    '0x03000064' => [qw(EXP-RC4-56-SHA)],              # from RSA BSAFE SSL-C
    '0x03000065' => [qw(EXP-EDH-DSS-RC4-56-SHA)],
    '0x03000066' => [qw(EDH-DSS-RC4-SHA)],             # from RSA BSAFE SSL-C
    '0x0300009B' => [qw(DHanon-SEED-SHA)],
    #!#----------+-------------------------------------+--------------------------+
); # %cipher_alias


our @cipher_results = [
# currently (12/2015)
#   [ sslv3, rc4-md5, yes ]
#   [ sslv3, NULL,    no ]

# in future (01/2016)
#   [ ssl, cipher, pos+cipher, pos+cipherraw, dh-bits, dh-param, "comment"]
#
#   # ssl      : SSLv2, SSLv3, TLS10, ...
#   # cipher   : hex-Wert (als String)
#   # pos+*    : -1 = undef (noch nicht berechnet), 0 = keine Reihenfolge
#                       beim Server, 1 .. n wie vom Server ausgewaehlt
#   # dh-bits  : DH Bits
#   # dh-param : ECDH Kurve

# dann können verschieden Algorithmen implementiert werden
### 1. o-saft wie jetzt
### 2. o-saft mit cipherraw wie jetzt
### 3. cipherraw mit unterschiedlicher Anzahl Ciphers, z.B.:
###      1, 8,9,15,16,17,32,64,48,49,127,128,129
### 4. von cipherraw den selected Cipher geben lassen

]; # @cipher_results

my $me =  $0;
   $me =~ s#.*[/\\]##;

our %cfg = (
    'me'            => $me,
    'mename'        => "O-Saft ", # my name pretty printed
    'ARG0'          => $0,
    'ARGV'          => [@ARGV], # arguments passed on command line
    'RC-ARGV'       => [],      # arguments read from RC-FILE (set in caller)
    'RC-FILE'       => "./.$me",# our RC-FILE, search in pwd only!

   # config. key        default   description
   #------------------+---------+----------------------------------------------
    'try'           => 0,       # 1: do not execute openssl, just show
    'exec'          => 0,       # 1: if +exec command used
    'trace'         => 0,       # 1: trace yeast, 2=trace Net::SSLeay and Net::SSLinfo also
    'traceME'       => 0,       # 1: trace yeast only, but no modules
                                # -1: trace modules only, but not yeast
    'traceARG'      => 0,       # 1: trace yeast's argument processing
    'traceCMD'      => 0,       # 1: trace command processing
    'traceKEY'      => 0,       # 1: (trace) print yeast's internal variable names
    'traceTIME'     => 0,       # 1: (trace) print additiona time for benchmarking
    'linux_debug'   => 0,       # passed to Net::SSLeay::linux_debug
    'verbose'       => 0,       # used for --v
    'warning'       => 1,       # 1: print warnings; 0: don't print warnings
    'proxyhost'     => "",      # FQDN or IP of proxy to be used
    'proxyport'     => 0,       # port for proxy
    'proxyauth'     => "",      # authentication string used for proxy
    'proxyuser'     => "",      # username for proxy authentication (Basic or Digest Auth)
    'proxypass'     => "",      # password for proxy authentication (Basic or Digest Auth)
    'starttls'      => "",      # use STARTTLS if not empty
                                # protocol to be used with STARTTLS; default: SMTP
                                # valid protocols: SMTP, IMAP, IMAP2, POP3, FTPS, LDAP, RDP, XMPP
    'slowServerDelay'   => 0,   # time to wait in seconds after a connection via proxy or before starting STARTTLS sequence
    'starttlsDelay' => 0,       # STARTTLS: time to wait in seconds (to slow down the requests)
    'starttls_phase'=> [],      # STARTTLS: Array for customized STARTTLS sequences
    'starttls_error'=> [],      # STARTTLS: Array for customized STARTTLS sequences error handling
    'enabled'       => 0,       # 1: only print enabled ciphers
    'disabled'      => 0,       # 1: only print disabled ciphers
    'nolocal'       => 0,
    'experimental'  => 0,       # 1: use experimental functionality
    'ignore_no_conn'=> 0,       # 1: ignore warnings if connection fails, check target anyway
    'uselwp'        => 0,       # 1: use perls LWP module for HTTP checks # TODO: NOT YET IMPLEMENTED
    'forcesni'      => 0,       # 1: do not check if SNI seems to be supported by Net::SSLeay
    'usesni'        => 1,       # 0: do not make connection in SNI mode;
                                # 3: test with and without SNI mode (used with +cipherraw only)
    'usedns'        => 1,       # 1: make DNS reverse lookup
    'usemx'         => 0,       # 1: make MX-Record DNS lookup
    'usehttp'       => 1,       # 1: make HTTP request
    'use_md5cipher' => 1,       # 0: do not use *-MD5 ciphers except for SSLv2 with +cipher
    'use_reconnect' => 1,       # 0: do not use -reconnect option for openssl
    'use_nextprot'  => 1,       # 0: do not use -nextprotoneg option for openssl
    'use_extdebug'  => 1,       # 0: do not use -tlsextdebug option for openssl
    'slowly'        => 0,       # passed to Net::SSLeay::slowly
    'sni_name'      => "1",     # name to be used for SNI mode connection; hostname if empty
                                # NOTE: default=1 as this is behaviour for Net::SSLinfo < 1.85
    'sclient_opt'   => "",      # argument or option passed to openssl s_client command
    'no_cert'       => 0,       # 0: get data from certificate; 1, 2, do not get data
    'no_cert_txt'   => "",      # change default text if no data from cert retrieved
    'ca_depth'      => undef,   # depth of peer certificate verification verification
    'ca_crl'        => undef,   # URL where to find CRL file
    'ca_file'       => undef,   # PEM format file with CAs
    'ca_path'       => undef,   # path to directory with PEM files for CAs
                                # see Net::SSLinfo why undef as default
    'ca_paths'      => [qw(/etc/ssl/certs /usr/lib/certs /System/Library/OpenSSL)],
                                # common paths to PEM files for CAs
    'ca_files'      => [qw(ca-certificates.crt certificates.crt certs.pem)],
                                # common PEM filenames for CAs
    'openssl_env'   => undef,   # environment variable OPENSSL if defined
    'openssl_cnf'   => undef,   # full path with openssl's openssl.cnf
    'openssl_cnfs'  => [qw(/usr/lib/ssl/openssl.cnf /etc/ssl/openssl.cnf /System//Library/OpenSSL/openssl.cnf /usr/ssl/openssl.cnf)], # NOT YET USED
    'openssl_fips'  => undef,   # NOT YET USED
    'openssl_msg'   => "",      # '-msg': option needed for openssl versions older than 1.0.2 to get the dh_parameter
    'ignorecase'    => 1,       # 1: compare some strings case insensitive
    'shorttxt'      => 0,       # 1: use short label texts
    'version'       => [],      # contains the versions to be checked
    'versions'      =>          # all supported versions
                       # [reverse sort keys %prot], # do not use generic list 'cause the want special order
                       [qw(SSLv2 SSLv3 TLSv1 TLSv11 TLSv12 TLSv13 DTLSv09 DTLSv1 DTLSv11 DTLSv12 DTLSv13)],
    'DTLS_versions' => [qw(DTLSv09 DTLSv1 DTLSv11 DTLSv12 DTLSv13)],
                                # temporary list 'cause DTLS not supported by openssl (6/2015)
    'ssl_lazy'      => 0,       # 1: lazy check for available SSL protocol functionality
    'SSLv2'         => 1,       # 1: check this SSL version
    'SSLv3'         => 1,       # 1:   "
    'TLSv1'         => 1,       # 1:   "
    'TLSv11'        => 1,       # 1:   "
    'TLSv12'        => 1,       # 1:   "
    'TLSv13'        => 1,       # 1:   "
                                # NOTE: DTLS currently (6/2015) disabled by default 'cause not supported by openssl
    'DTLSv09'       => 0,       # 1:   "
    'DTLSv1'        => 0,       # 1:   "
    'DTLSv11'       => 0,       # 1:   "
    'DTLSv12'       => 0,       # 1:   "
    'DTLSv13'       => 0,       # 1:   "
    'TLS1FF'        => 0,       # dummy for future use
    'DTLSfamily'    => 0,       # dummy for future use
    'nullssl2'      => 0,       # 1: complain if SSLv2 enabled but no ciphers accepted
    'cipher'        => [],      # ciphers we got with --cipher=
    'cipherpattern' => "ALL:NULL:eNULL:aNULL:LOW:EXP", # openssl pattern for all ciphers
                                # TODO: must be same as in Net::SSLinfo or used from there
    'ciphers'       => [],      # contains all ciphers to be tested
    'cipherrange'   => 'rfc',   # the range to be used from 'cipherranges'
    'cipherranges'  => {        # constants for ciphers (NOTE: written as hex)
                    # Technical (perl) note for definition of these ranges:
                    # Each range is defined as a string like  key=>"2..5, c..f"
                    # instead of an array like  key=>[2..5, c..f]  which would
                    # result in  key=>[2 3 4 5 c d e f] .
                    # This expansion of the range is done at compile time  and 
                    # so will consume a huge amount of memory at runtime.
                    # Using a string instead of the expanded array reduces the
                    # memory footprint,  but requires use of  eval()  when the
                    # range is needed:  eval($cfg{cipherranges}->{rfc})
                    # Each string must be syntax for perl's range definition.
        'yeast'     => "",      # internal list, computed later ...
                                # push(@all, @{$_}[0]) foreach (values %cipher_names);
        'rfc'       =>          # constants for ciphers defined in various RFCs
                       "0x03000000 .. 0x030000FF, 0x0300C000 .. 0x0300C0FF,
                        0x0300CC00 .. 0x0300CCFF, 0x0300FE00 .. 0x0300FFFF,
                       ",
        'shifted'   =>          # constants for ciphers defined in various RFCs shifted with an offset of 64 (=0x40) Bytes
                       "0x03000100 .. 0x0300013F,
                        0x03000000 .. 0x030000FF, 0x0300C000 .. 0x0300C0FF,
                        0x0300CC00 .. 0x0300CCFF, 0x0300FE00 .. 0x0300FFFF,
                       ",
        'long'      =>          # more lazy list of constants for cipher
                       "0x03000000 .. 0x030000FF, 0x0300C000 .. 0x0300FFFF,
                       ",
        'huge'      =>          # huge range of constants for cipher
                       "0x03000000 .. 0x0300FFFF,
                       ",
        'safe'      =>          # safe full range of constants for cipher
                                # because some network stack (NIC) will crash for 0x033xxxxx
                       "0x03000000 .. 0x032FFFFF,
                       ",
        'full'      =>          # full range of constants for cipher
                       "0x03000000 .. 0x03FFFFFF,
                       ",
# TODO:                 0x03000000,   0x03FFFFFF,   # used as return by microsoft testserver and also by SSL-honeypot (US)
        'SSLv2'     =>          # constants for ciphers according RFC for SSLv2
                       "0x02000000,   0x02010080, 0x02020080, 0x02030080, 0x02040080,
                        0x02050080,   0x02060040, 0x02060140, 0x020700C0, 0x020701C0,
                        0x02FF0810,   0x02FF0800, 0x02FFFFFF,   # obsolete SSLv2 ciphers
                        0x03000000 .. 0x03000002, 0x03000007 .. 0x0300002C, 0x030000FF,
                        0x0300FEE0,   0x0300FEE1, 0x0300FEFE, 0x0300FEFF, # obsolete FIPS ciphers
# TODO:                 0x02000000,   0x02FFFFFF,   # increment even only
# TODO:                 0x03000000,   0x03FFFFFF,   # increment  odd only
                       ",
        'SSLv2_long'=>          # more lazy list of constants for ciphers for SSLv2
                       "0x02000000,   0x02010080, 0x02020080, 0x02030080, 0x02040080,
                        0x02050080,   0x02060040, 0x02060140, 0x020700C0, 0x020701C0,
                        0x02FF0810,   0x02FF0800, 0x02FFFFFF,
                        0x03000000 .. 0x0300002F, 0x030000FF,   # old SSLv3 ciphers
                        0x0300FEE0,   0x0300FEE1, 0x0300FEFE, 0x0300FEFF,
                       ",
    }, # cipherranges
    'ciphers-v'     => 0,       # as: openssl ciphers -v
    'ciphers-V'     => 0,       # as: openssl ciphers -V
    'do'            => [],      # the commands to be performed, any of commands
    'commands'      => [],      # contains all commands, constructed below
    'ignore-out'    => [],      # commands (output) to be ignored, see --no-cmd
                    # Results of these commands are not printed in output.
                    # Purpose is to avoid output of noicy commands  (like some
                    # +bsi*).  All data collections and checks are still done,
                    # just output of results is omitted.
                    # Technically these commands are not removed from cfg{do},
                    # but just skipped in printdata() and printchecks(), which
                    # makes implementation much easier.
    'cmd-intern'    => [        # add internal commands
                    # these have no key in %data or %checks
                        qw(
                         check cipher dump check_sni exec help info info--v http
                         quick list libversion sizes s_client version quit
                         sigkey bsi ev cipherraw cipher-dh
                        ),
                    # internal (debugging) commands
                      # qw(options cert_type),  # will be seen with +info--v only
                    # keys not used as command
                        qw(cn_nosni valid-years valid-months valid-days)
                       ],
    'cmd-experiment'=> [        # experimental commands
                        qw(sloth),
                       ],
    'cmd-NL'        => [        # commands which need NL when printed
                                # they should be available with +info --v only 
                        qw(certificate extensions pem pubkey sigdump text chain chain_verify)
                       ],
    'cmd-NOT_YET'   => [        # commands and checks NOT YET IMPLEMENTED
                        qw(zlib lzo open_pgp fallback closure order sgc scsv time),
                       ],
    'cmd-HINT'      => [        # checks which are NOT YET fully implemented
                                # these are mainly all commands for compliance
                                # see also: cmd-bsi
                        qw(rfc7525
                           tr-02102            bsi-tr-02102+ bsi-tr-02102-
                           tr-03116+ tr-03116- bsi-tr-03116+ bsi-tr-03116-
                       )],
    'cmd-beast'     => [qw(beast)],                 # commands for +beast
    'cmd-crime'     => [qw(crime)],                 # commands for +crime
    'cmd-drown'     => [qw(drown)],                 # commands for +drown
    'cmd-freak'     => [qw(freak)],                 # commands for +freak
    'cmd-lucky13'   => [qw(lucky13)],               # commands for +lucky13
    'cmd-http'      => [],      # commands for +http, computed below
    'cmd-hsts'      => [],      # commands for +hsts, computed below
    'cmd-info'      => [],      # commands for +info, simply anything from %data
    'cmd-info--v'   => [],      # commands for +info --v
    'cmd-check'     => [],      # commands for +check, simply anything from %checks
    'cmd-sizes'     => [],      # commands for +sizes
    'cmd-quick'     => [        # commands for +quick
                        qw(
                         selected cipher fingerprint_hash fp_not_md5 
                         sha2signature pub_encryption pub_enc_known email
                         serial subject dates verify expansion compression hostname
                         beast crime drown freak export rc4_cipher rc4 pfs_cipher crl
                         hassslv2 hassslv3 poodle sloth
                         resumption renegotiation tr-02102 bsi-tr-02102+ bsi-tr-02102- rfc7525 hsts_sts
                       )],
    'cmd-ev'        => [qw(cn subject altname dv ev ev- ev+ ev-chars)], # commands for +ev
    'cmd-bsi'       => [                            # commands for +bsi
                                                    # see also: cmd-HINT
                        qw(after dates crl rc4_cipher renegotiation
                           tr-02102            bsi-tr-02102+ bsi-tr-02102-
                           tr-03116+ tr-03116- bsi-tr-03116+ bsi-tr-03116-
                       )],
    'cmd-pfs'       => [qw(pfs_cipher pfs_cipherall session_random)],   # commands for +pfs
    'cmd-sni'       => [qw(sni hostname)],          # commands for +sni
    'cmd-sni--v'    => [qw(sni cn altname verify_altname verify_hostname hostname wildhost wildcard)],
    'cmd-vulns'     => [                            # commands for checking known vulnerabilities
                        qw(beast breach crime drown freak heartbleed logjam lucky13 poodle rc4 sloth time hassslv2 hassslv3 pfs_cipher session_random)
                       #qw(resumption renegotiation) # die auch?
                       ],
    'cmd-prots'     => [                            # commands for checking protocols
                        qw(hassslv2 hassslv3 hastls10 hastls11 hastls12 hastls13 hasalpn alpn npn session_protocol protocols https_protocols http_protocols https_svc http_svc)
                       ],
                    # need_* lists used to improve performance
    'need_cipher'   => [        # commands which need +cipher
                        qw(check beast crime time breach drown freak pfs_cipher pfs_cipherall rc4_cipher rc4 selected poodle logjam sloth cipher cipher-dh),
                        qw(tr-02102 bsi-tr-02102+ bsi-tr-02102- tr-03116+ tr-03116- bsi-tr-03116+ bsi-tr-03116- rfc7525),
                        qw(hassslv2 hassslv3 hastls10 hastls11 hastls12 hastls13), # TODO: need simple check for protocols
                       ],
    'need_default'  => [        # commands which need selected cipher
                        qw(check cipher pfs_cipher selected),
                        qw(sslv3  tlsv1   tlsv10  tlsv11 tlsv12),
                                # following checks may cause errors because
                                # missing functionality (i.e in openssl) # 10/2015
                        qw(sslv2  tlsv13  dtlsv09 dtlvs1 dtlsv11 dtlsv12 dtlsv13)
                       ],
    'need_checkssl' => [        # commands which need checkssl() # TODO: needs to be verified
                        qw(check beast crime time breach freak pfs_cipher pfs_cipherall rc4_cipher rc4 selected ev+ ev-),
                        qw(tr-02102 bsi-tr-02102+ bsi-tr-02102- tr-03116+ tr-03116- bsi-tr-03116+ bsi-tr-03116- rfc7525 rfc6125_names),
                       ],
    'need_checkchr' => [        # commands which always need checking various characters
                        qw(cn subject issuer altname ext_crl ocsp_uri),
                       ],
    'data_hex'      => [        # data values which are in hex values
                                # used in conjunction with --format=hex
                                # not usefull in this list: serial extension
                        qw(
                         fingerprint fingerprint_hash fingerprint_sha1 fingerprint_md5
                         sigkey_value pubkey_value modulus
                         master_key session_id session_ticket
                       )],      # fingerprint is special, see _ishexdata()
    'opt-v'         => 0,       # 1 when option -v was given
    'opt-V'         => 0,       # 1 when option -V was given
    'format'        => "",      # empty means some slightly adapted values (no \s\n)
    'formats'       => [qw(csv html json ssv tab xml fullxml raw hex 0x esc)],
    'out_header'    => 0,       # print header lines in output
    'out_score'     => 0,       # print scoring; default for +check
    'tmplib'        => "/tmp/yeast-openssl/",   # temp. directory for openssl and its libraries
    'pass_options'  => "",      # options to be passeed thru to other programs
    'mx_domains'    => [],      # list of mx-domain:port to be processed
    'hosts'         => [],      # list of host:port to be processed
    'host'          => "",      # currently scanned host
    'ip'            => "",      # currently scanned host's IP (machine readable format)
    'IP'            => "",      # currently scanned host's IP (human readable, doted octed)
    'rhost'         => "",      # currently scanned host's reverse resolved name
    'DNS'           => "",      # currently scanned host's other IPs and names (DNS aliases)
    'port'          => 443,     # port for currently used connections
    'timeout'       => 2,       # default timeout in seconds for connections
                                # NOTE that some servers do not connect SSL within this time
                                #      this may result in ciphers marked as  "not supported"
                                #      it's recommended to set timeout to 3 or higher, which
                                #      results in a performance bottleneck, obviously
    'sslhello' => {    # configurations for TCP SSL protocol (mainly used in Net::SSLhello)
        'timeout'   => 2,       # timeout to receive ssl-answer
        'retry'     => 2,       # number of retry when timeout
        'maxciphers'=> 32,      # number of ciphers sent in SSL3/TLS Client-Hello
        'useecc'    => 1,       # 1: use supported elliptic curves
        'useecpoint'=> 1,       # 1: use ec_point_formats extension
        'usereneg'  => 0,       # 1: secure renegotiation
        'double_reneg'  => 0,   # 0: do not send reneg_info extension if the cipher_spec already includes SCSV
                                #    "TLS_EMPTY_RENEGOTIATION_INFO_SCSV" {0x00, 0xFF}
        'nodatanocipher'=> 1,   # 1: do not abort testing next cipher for some TLS intolerant Servers 'NoData or Timeout Equals to No Cipher'
    },
    'legacy'        => "simple",
    'legacys'       => [qw(cnark sslaudit sslcipher ssldiagnos sslscan ssltest
                        ssltest-g sslyze testsslserver thcsslcheck openssl
                        simple full compact quick key)],
                       # SSLAudit, THCSSLCheck, TestSSLServer are converted using lc()
    'showhost'      => 0,       # 1: prefix printed line with hostname
    'usr-args'      => [],      # list of all arguments --usr* (to be used in o-saft-usr.pm)
   #------------------+---------+----------------------------------------------
   #------------------+--------------------------------------------------------
    'regex' => {
        # First some basic RegEx used later on, either in following RegEx or
        # as $cfg{'regex'}->{...}  itself.
        '_or-'      => '[\+_-]',
                       # tools use _ or - as separator character; + used in openssl
        'ADHorDHA'  => '(?:A(?:NON[_-])?DH|DH(?:A|[_-]ANON))[_-]',
                       # Anonymous DH has various acronyms:
                       #     ADH, ANON_DH, DHA, DH-ANON, DH_Anon, ...
        'RC4orARC4' => '(?:ARC(?:4|FOUR)|RC4)',
                       # RC4 has other names due to copyright problems:
                       #     ARC4, ARCFOUR, RC4
        '3DESorCBC3'=> '(?:3DES(?:[_-]EDE)[_-]CBC|DES[_-]CBC3)',
                       # Tripple DES is used as 3DES-CBC, 3DES-EDE-CBC, or DES-CBC3
        'DESor3DES' => '(?:[_-]3DES|DES[_-]_192)',
                       # Tripple DES is used as 3DES or DES_192
        'DHEorEDH'  => '(?:DHE|EDH)[_-]',
                       # DHE and EDH are 2 acronyms for the same thing
        'EC-DSA'    => 'EC(?:DHE|EDH)[_-]ECDSA',
        'EC-RSA'    => 'EC(?:DHE|EDH)[_-]RSA',
                       # ECDHE-RSA or ECDHE-ECDSA
        'EC'        => 'EC(?:DHE|EDH)[_-]',
        'EXPORT'    => 'EXP(?:ORT)?(?:40|56|1024)?[_-]',
                       # EXP, EXPORT, EXPORT40, EXP1024, EXPORT1024, ...
        'FRZorFZA'  => '(?:FORTEZZA|FRZ|FZA)[_-]',
                       # FORTEZZA has abbreviations FZA and FRZ
                       # unsure about FORTEZZA_KEA
        'SHA2'      => 'sha(2|224|256|384|512)',
                       # any SHA2, just sha2 is too lazy
        'SSLorTLS'  => '^(?:SSL[23]?|TLS[12]?|PCT1?)[_-]',
                       # Numerous protocol prefixes are in use:
                       #     PTC, PCT1, SSL, SSL2, SSL3, TLS, TLS1, TLS2,
        'aliases'   => '(?:(?:DHE|DH[_-]ANON|DSS|RAS|STANDARD)[_-]|EXPORT_NONE?[_-]?XPORT|STRONG|UNENCRYPTED)',
                       # various variants for aliases to select cipher groups
        'compression'   =>'(?:DEFLATE|LZO)',    # if compression available
        'nocompression' =>'(?:NONE|NULL|^\s*$)',# if no compression available
        'encryption'    =>'(?:encryption|ecPublicKey)', # anything containing this string
        'encryption_ok' =>'(?:(?:(?:(?:md[245]|ripemd160|sha(?:1|224|256|384|512))with)?[rd]saencryption)|id-ecPublicKey)',
                       # well known strings to identify signature and public key encryption
                       # rsaencryption, dsaencryption, md[245]withrsaencryption, 
                       # ripemd160withrsa shaXXXwithrsaencryption
                       # id-ecPublicKey
        'encryption_no' =>'(?:rsa(?:ssapss)?|sha1withrsa|dsawithsha1?|dsa_with_sha256)',
                       # rsa, rsassapss, sha1withrsa, dsawithsha*, dsa_with_sha256
        'isIP'          => '(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)',
        'isDNS'         => '(?:[a-z0-9.-]+)',
        'isIDN'         => '(?:xn--)',
        'leftwild'      => '^\*(?:[a-z0-9.-]+)',
        'doublewild'    => '(?:[a-z0-9.-]+\*[a-z0-9-]+\*)', # x*x or x*.x*
        'invalidwild'   => '(?:\.\*\.)',            # no .*.
        'invalidIDN'    => '(?:xn--[a-z0-9-]*\*)',  # no * right of xn--

        # RegEx containing pattern to identify vulnerable ciphers
            #
            # In a perfect (perl) world we can use negative lokups like
            #     (ABC)(?!XYZ)
            # which means: contains `ABC' but not `XYZ' where `XYZ' could be
            # to the right or left of `ABC'.
            # But in real world some perl implementations fail to match such
            # pattern correctly. Hence we use two pattern:  one for positive
            # match and second for the negative (not) match. Both patterns
            # must be used programatically.
            # Key 'TYPE' must match and key 'notTYPE' must not match.
        # The following RegEx define what is "vulnerable":
        'BEAST'     => '^(?:SSL[23]?|TLS[12]|PCT1?[_-])?(?:ARC(?:4|FOUR)|RC4)',
#       'BREACH'    => '^(?:SSL[23]?|TLS[12]|PCT1?[_-])?',
        'FREAK'     => '^(?:SSL[23]?)?(?:EXP(?:ORT)?(?:40|56|1024)?[_-])',
                       # EXP? is same as regex{EXPORT} above
        'notCRIME'  => '(?:NONE|NULL|^\s*$)',   # same as nocompression (see above)
#       'TIME'      => '^(?:SSL[23]?|TLS[12]|PCT1?[_-])?',
        'Lucky13'   => '^(?:SSL[23]?|TLS[12]|PCT1?[_-])?.*?[_-]CBC',
        'Logjam'    => 'EXP(?:ORT)?(?:40|56|1024)?[_-]',    # match against cipher
                       # Logjam is same as regex{EXPORT} above
        'SLOTH'     => '(?:(EXP(?:ORT)?|NULL).*MD5$|EC(?:DHE|EDH)[_-]ECDSA[_-].*(?:MD5|SHA)$)',
        # The following RegEx define what is "not vulnerable":
        'PFS'       => '^(?:(?:SSLv?3|TLSv?1(?:[12])?|PCT1?)[_-])?((?:EC)?DHE|EDH)[_-]',

        'TR-02102'  => '(?:DHE|EDH)[_-](?:PSK|(?:EC)?(?:[DR]S[AS]))[_-]',
                       # ECDHE_ECDSA | ECDHE_RSA | DHE_DSS | DHE_RSA
                       # ECDHE_ECRSA, ECDHE_ECDSS or DHE_DSA does not exist, hence lazy regex above
        'notTR-02102'     => '[_-]SHA$',
                       # ciphers with SHA1 hash are not allowed
        'TR-02102-noPFS'  => '(?:EC)?DH)[_-](?:EC)?(?:[DR]S[AS])[_-]',
                       # if PFS not possible, see TR-02102-2 3.2.1
        'TR-03116+' => 'EC(?:DHE|EDH)[_-](?:PSK|(?:EC)?(?:[DR]S[AS]))[_-]AES128[_-](?:GCM[_-])?SHA256',
        'TR-03116-' => 'EC(?:DHE|EDH)[_-](?:PSK|(?:EC)?(?:[DR]S[AS]))[_-]AES(?:128|256)[_-](?:GCM[_-])?SHA(?:256|384)',
                       # in strict mode only:
                       #  ECDHE-ECDSA-AES128.*SHA256 ECDHE-RSA-AES128.*SHA256 RSA-PSK-AES128-SHA256 ECDHE-PSK-AES128-SHA256
                       # in lazy mode (for curiosity) we also allow:
                       #  ECDHE-ECDSA-AES256.*SHA256 ECDHE-RSA-AES256.*SHA256
                       #  ECDHE-ECDSA-AES256.*SHA384 ECDHE-RSA-AES256.*SHA384
        'notTR-03116'     => '(?:PSK[_-]AES256|[_-]SHA$)',
                       # NOTE: for curiosity again, notTR-03116 is for strict mode only
        'RFC7525'   => 'EC(?:DHE|EDH)[_-](?:PSK|(?:EC)?(?:[DR]S[AS]))[_-]AES128[_-](?:GCM[_-])?SHA256',
        '1.3.6.1.5.5.7.1.1'  =>  '(?:1\.3\.6\.1\.5\.5\.7\.1\.1|authorityInfoAccess)',
        'NSA-B'     =>'(?:ECD(?:H|SA).*?AES.*?GCM.*?SHA(?:256|384|512))',

        # Regex containing pattern for compliance checks
        # The following RegEx define what is "not compliant":
        'notISM'    => '(?:NULL|A(?:NON[_-])?DH|DH(?:A|[_-]ANON)[_-]|(?:^DES|[_-]DES)[_-]CBC[_-]|MD5|RC)',
        'notPCI'    => '(?:NULL|(?:A(?:NON[_-])?DH|DH(?:A|[_-]ANON)|(?:^DES|[_-]DES)[_-]CBC|EXP(?:ORT)?(?:40|56|1024)?)[_-])',
        'notFIPS-140'=>'(?:(?:ARC(?:4|FOUR)|RC4)|MD5|IDEA)',
        'FIPS-140'  => '(?:(?:3DES(?:[_-]EDE)[_-]CBC|DES[_-]CBC3)|AES)', # these are compiant

        # Regex for checking invalid characers (used in compliance and EV checks)
        'nonprint'  => '/[\x00-\x1f\x7f-\xff]+/',          # not printable;  m/[:^print:]/
        'crnlnull'  => '/[\r\n\t\v\0]+/',                  # CR, NL, TABS and NULL

        # Regex for checking EV-SSL
        # they should matching:   /key=value/other-key=other-value
        '2.5.4.10'  => '(?:2\.5\.4\.10|organizationName|O)',
        '2.5.4.11'  => '(?:2\.5\.4\.1?|organizationalUnitName|OU)',
        '2.5.4.15'  => '(?:2\.5\.4\.15|businessCategory)',
        '2.5.4.3'   => '(?:2\.5\.4\.3|commonName|CN)',
        '2.5.4.5'   => '(?:2\.5\.4\.5|serialNumber)',
        '2.5.4.6'   => '(?:2\.5\.4\.6|countryName|C)',
        '2.5.4.7'   => '(?:2\.5\.4\.7|localityName|L)',
        '2.5.4.8'   => '(?:2\.5\.4\.8|stateOrProvinceName|SP|ST)', # TODO: is ST a bug?
        '2.5.4.9'   => '(?:2\.5\.4\.9|street(?:Address)?)', # '/street=' is very lazy
        '2.5.4.17'  => '(?:2\.5\.4\.17|postalCode)',
#       '?.?.?.?'   => '(?:?\.?\.?\.?|domainComponent|DC)',
#       '?.?.?.?'   => '(?:?\.?\.?\.?|surname|SN)',
#       '?.?.?.?'   => '(?:?\.?\.?\.?|givenName|GN)',
#       '?.?.?.?'   => '(?:?\.?\.?\.?|pseudonym)',
#       '?.?.?.?'   => '(?:?\.?\.?\.?|initiala)',
#       '?.?.?.?'   => '(?:?\.?\.?\.?|title)',
        '1.3.6.1.4.1.311.60.2.1.1' => '(?:1\.3\.6\.1\.4\.1\.311\.60\.2\.1\.1|jurisdictionOfIncorporationLocalityName)',
        '1.3.6.1.4.1.311.60.2.1.2' => '(?:1\.3\.6\.1\.4\.1\.311\.60\.2\.1\.2|jurisdictionOfIncorporationStateOrProvinceName)',
        '1.3.6.1.4.1.311.60.2.1.3' => '(?:1\.3\.6\.1\.4\.1\.311\.60\.2\.1\.3|jurisdictionOfIncorporationCountryName)',

        'EV-chars'  => '[a-zA-Z0-9,./:= @?+\'()-]',         # valid characters in EV definitions
        'notEV-chars'=>'[^a-zA-Z0-9,./:= @?+\'()-]',        # not valid characters in EV definitions
        'EV-empty'  => '^(?:n\/a|(?:in|not )valid)\s*$',    # empty string, or "invalid" or "not valid"

        # Regex for matching commands
        'cmd-http'  => '^h?(?:ttps?|sts)_',     # match keys for HTTP
        'cmd-hsts'  => '^h?sts',                # match keys for (H)STS
        'cmd-sizes' => '^(?:cnt|len)_',         # match keys for length, sizes etc.
        'cmd-intern'=> '^(?:cn_nosni|valid-(?:year|month|day)s)', # internal data only, no command

        # Regex for matching SSL protocol keys in %data and %checks
        'SSLprot'   => '^(SSL|D?TLS)v[0-9]',    # match keys SSLv2, TLSv1, ...

    }, # regex
   #------------------+--------------------------------------------------------
    'ourstr' => {
        # regex to match strings of our own output, see OUTPUT in o-saft-man.pm
        # first all that match a line at beginning:
        'error'     => qr(^\*\*ERR),            # see STR_ERROR
        'warning'   => qr(^\*\*WARN),           # see STR_WARN
        'hint'      => qr(^\!\!Hint),           # see STR_HINT
        'dbx'       => qr(^#dbx#),              # see STR_DBX
        'headline'  => qr(^={1,3} ),            # headlines
        'keyline'   => qr(^#\[),                # dataline prefixed with key
        'verbose'   => qr(^#[^[]),              # verbose output
        # matches somewhere in the line:
        'undef'     => qr(\<\<undef),           # see STR_UNDEF
        'yeast'     => qr(\<\<.*?\>\>),         # additional informations
        'na'        => qr(N\/A),                # N/A
        'yes'       => qr(:\s*yes),             # good check result; # TODO: : needs to be $text{separator}
        'no'        => qr(:\s*no ),             # bad check result
    }, # ourstr
   #------------------+--------------------------------------------------------
    'compliance' => {           # description of RegEx above for compliance checks
        'TR-02102'  => "no RC4, only eclipic curve, only SHA256 or SHA384, need CRL and AIA, no wildcards, and verifications ...",
        'TR-03116'  => "TLSv1.2, only ECDSA, RSA or PSK ciphers, only eclipic curve, only SHA224 or SHA256, need OCSP-Stapling CRL and AIA, no wildcards, and verifications ...",
        'ISM'       => "no NULL cipher, no Anonymous Auth, no single DES, no MD5, no RC ciphers",
        'PCI'       => "no NULL cipher, no Anonymous Auth, no single DES, no Export encryption, DH > 1023",
        'FIPS-140'  => "must be TLSv1 or 3DES or AES, no IDEA, no RC4, no MD5",
        'FIPS-140-2'=> "-- NOT YET IMPLEMENTED --",      # TODO:
        'RFC7525'   => "TLS 1.2; AES with GCM; ECDHE and SHA256 or SHA384; HSTS",
        #
        # NIST SP800-52 recommendations for clients (best first):
        #   TLS_DHE_DSS_WITH_AES_256_CBC_SHA
        #   TLS_DHE_RSA_WITH_AES_256_CBC_SHA
        #   TLS_RSA_WITH_AES_256_CBC_SHA
        #   TLS_DH_DSS_WITH_AES_256_CBC_SHA
        #   TLS_DH_RSA_WITH_AES_256_CBC_SHA
        #   TLS_DHE_DSS_WITH_AES_128_CBC_SHA
        #   TLS_DHE_RSA_WITH_AES_128_CBC_SHA
        #   TLS_RSA_WITH_AES_128_CBC_SHA
        #   TLS_DH_DSS_WITH_AES_128_CBC_SHA
        #   TLS_DH_RSA_WITH_AES_128_CBC_SHA
        #   TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA
        #   TLS_DHE_RSA_WITH_3DES_EDE_CBC_SHA
        #   TLS_RSA_WITH_3DES_EDE_CBC_SHA
        #   TLS_DH_DSS_WITH_3DES_EDE_CBC_SHA
        #   TLS_DH_RSA_WITH_3DES_EDE_CBC
        #   TLS_RSA_WITH_RC4_128_SHA2
        #
        # NIST SP800-52 recommendations for server (best first):
        #    same as above except TLS_RSA_WITH_RC4_128_SHA2
        #
        # Supported by (most) browsers (see SSL_comp_report2011.pdf):
        #    TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384_P384  (IE8 only)
        #    TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA*
        #    TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA*
        #    TLS_DHE_RSA_WITH_AES_256_CBC_SHA
        #    TLS_DHE_RSA_WITH_AES_128_CBC_SHA
        #    TLS_RSA_WITH_RC4_128_SHA
        #    TLS_DHE_DSS_WITH_3DES_EDE_CBC_SHA
        #
        # NIST SP800-57 recommendations for key management (part 1):
        'NSA-B'     => "must be AES with CTR or GCM; ECDSA or ECDH and SHA256 or SHA512",
    },
    'sig_algorithms' => [       # signature algorithms; (2016) not yet used
        qw(
           dsaEncryption dsaEncryption-old dsaWithSHA dsaWithSHA1 dsa_With_SHA256
           ecdsa-with-SHA256
           md2WithRSAEncryption    md4WithRSAEncryption  md5WithRSAEncryption
           None   ripemd160WithRSA rsa  rsaEncryption    rsassapss
           shaWithRSAEncryption    sha1WithRSAEncryption sha1WithRSA
           sha224WithRSAEncryption sha256WithRSAEncryption
           sha384WithRSAEncryption sha512WithRSAEncryption
        ),
           "rsassapss (invalid pss parameters)"
    ],
    'sig_algorithm_common' => [ # most common signature algorithms; (2016) not yet used
        qw(None ecdsa-with-SHA256
           sha1WithRSAEncryption   sha256WithRSAEncryption
           sha384WithRSAEncryption sha512WithRSAEncryption
        )
    ],
    'openssl_option_map' => {   # map our internal option to openssl option; used our Net:SSL*
        # will be initialized from %prot
     },
    'openssl_version_map' => {  # map our internal option to openssl version (hex value); used our Net:SSL*
        # will be initialized from %prot
     },
    'done'      => {},          # defined in caller
   #------------------+---------+----------------------------------------------
); # %cfg

our %dbx = (    # save hardcoded settings (command lists, texts), and debugging data
                # used in o-saft-dbx.pm only
    'argv'      => undef,       # normal options and arguments
    'cfg'       => undef,       # config options and arguments
    'exe'       => undef,       # executable, library, environment
    'file'      => undef,       # read files
    'cmd-check' => undef,
    'cmd-http'  => undef,
    'cmd-info'  => undef,
    'cmd-quick' => undef,
); # %dbx


#_____________________________________________________________________________
#__________________________________________________________________ methods __|

# TODO: interanl wrappers for main's methods
sub _trace(@)   { ::_trace(@_); return; }   ## no critic qw(Subroutines::RequireArgUnpacking)
sub _trace0(@)  { ::_trace(@_); return; }   ## no critic qw(Subroutines::RequireArgUnpacking)
sub _trace1(@)  { ::_trace(@_); return; }   ## no critic qw(Subroutines::RequireArgUnpacking)
sub _trace2(@)  { ::_trace(@_); return; }   ## no critic qw(Subroutines::RequireArgUnpacking)
sub _trace3(@)  { ::_trace(@_); return; }   ## no critic qw(Subroutines::RequireArgUnpacking)

=pod

=head2 get_cipher_sec($cipher)

=head2 get_cipher_ssl($cipher)

=head2 get_cipher_enc($cipher)

=head2 get_cipher_bits($cipher)

=head2 get_cipher_mac($cipher)

=head2 get_cipher_auth($cipher)

=head2 get_cipher_keyx($cipher)

=head2 get_cipher_score($cipher)

=head2 get_cipher_tags($cipher)

=head2 get_cipher_desc($cipher)

Get information from internal C<%cipher> data structure.

=cut

# some people prefer to use a getter function to get data from objects
# each function returns a spcific value (column) from the %cipher table
# see %ciphers_desc about description of the columns
sub get_cipher_sec($)  { my $c=shift; return $ciphers{$c}[0] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_ssl($)  { my $c=shift; return $ciphers{$c}[1] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_enc($)  { my $c=shift; return $ciphers{$c}[2] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_bits($) { my $c=shift; return $ciphers{$c}[3] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_mac($)  { my $c=shift; return $ciphers{$c}[4] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_auth($) { my $c=shift; return $ciphers{$c}[5] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_keyx($) { my $c=shift; return $ciphers{$c}[6] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_score($){ my $c=shift; return $ciphers{$c}[7] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_tags($) { my $c=shift; return $ciphers{$c}[8] || "" if ((grep{/^$c/} %ciphers)>0); return ""; }
sub get_cipher_desc($) { my $c=shift;
    # get description for specified cipher from %ciphers
    if (! defined $ciphers{$c}) {
#       _warn("undefined cipher description for '$c'"); # TODO: correct %ciphers
#       return STR_UNDEF;
    }
    my @c = @{$ciphers{$c}};
    shift @c;
    return @c if ((grep{/^$c/} %ciphers)>0);
    return "";
}

=pod

=head2 get_cipher_hex($cipher)

Get cipher's hex key from C<%cipher_names> or C<%cipher_alias> data structure.

=head2 get_cipher_name($cipher)

Check if given C<%cipher> name is a known cipher.

=cut

sub get_cipher_hex($)  {
    # find hex key for cipher in %cipher_names or %cipher_alias
    my $c = shift;
    foreach my $k (keys %cipher_names) { # database up to VERSION 14.07.14
        return $k if (($cipher_names{$k}[0] eq $c) or ($cipher_names{$k}[1] eq $c));
    }
    foreach my $k (keys %cipher_alias) { # not yet found, check for alias
        return $k if ($cipher_alias{$k}[0] eq $c);
    }
    return "";
} # get_cipher_hex

sub get_cipher_name($) {
    # check if given cipher name is a known cipher
    # checks in %cipher_names if nof found in %ciphers
    my $cipher  = shift;
    return $cipher if ((grep{/^$cipher/} %ciphers)>0);
    _trace("get_cipher_name: search $cipher");
    foreach my $k (keys %cipher_names) {
        return $cipher_names{$k}[0] if ($cipher =~ m/$cipher_names{$k}[0]/);
        return $cipher_names{$k}[0] if ($cipher_names{$k}[1] =~ /$cipher/);
    }
    # nothing found yet, try more lazy match
    foreach my $k (keys %cipher_names) {
        if ($cipher_names{$k}[0] =~ m/$cipher/) {
            _warn("partial match for cipher name found '$cipher'");
            return $cipher_names{$k}[0];
        }
    }
    return "";
} # get_cipher_name


=pod

=head2 get_openssl_version($cmd)

Call external $cmd (which is a full path for L<openssl|openssl>, usually) executable
to retrive its version. Returns version string.
=cut

sub get_openssl_version($) {
    # we do a simple call, no checks, should work on all platforms
    # get something like: OpenSSL 1.0.1k 8 Jan 2015
    my $cmd  = shift;
    my $data = qx($cmd version);
    chomp $data;
    _trace("get_openssl_version: $data");
    $data =~ s#^.*?(\d+(?:\.\d+)*).*$#$1#; # get version number without letters
    _trace("get_openssl_version()\t= $data");
    return $data;
} # get_openssl_version


=pod

=head2 get_dh_paramter($cipher, $data)

Parse output of `openssl -msg' (given in $data) and returns DH parameters.
Returns empty string if none found.
=cut

sub get_dh_paramter($$) {
    my ($cipher, $data) = @_;
    if ($data =~ m#Server Temp Key:#) {
        $data =~ s/.*?Server Temp Key:\s*([^\n]*)\n.*/$1/si;
        _trace("get_dh_paramter(){ Server Temp Key\t= $data }");
        return $data;
    }
    # else continue extracting DH parameters from ServerKeyExchange-Message
    my $dh = "";
    # we may get a ServerKeyExchange-Message with the -msg option
    # <<< TLS 1.2 Handshake [length 040f], ServerKeyExchange
    #     0c 00 04 0b 01 00 c1 41 38 da 2e b3 7e 68 71 31
    #     86 da 01 e5 95 fa 7e 83 9b a2 28 1b a5 fb d2 72
    #     ...
    # >>> TLS 1.2 ChangeCipherSpec [length 0001]
    return "" if ($data !~ m#ServerKeyExchange#);

    # this is a long regex and cannot be chunked
    ## no critic qw(RegularExpressions::ProhibitComplexRegexes)
    $data =~ s{
            .*?Handshake
            \s*?\[length\s*([0-9a-fA-F]{2,4})\]\,?
            \s*?ServerKeyExchange
            \s*[\n\r]+(.*?)
            [\n\r][<>]+.*
        }
        {$1_$2}xsi;
    ## use critic
    _trace("get_dh_paramter: #{ DHE RAW data:\n$data\n#}\n");
    $data =~ s/\s+/ /gi;          # squeeze multible spaces
    $data =~ s/[^0-9a-f_]//gi;    # remove all none hex characters and non seperator
    my ($lenStr, $len) = 0;
    ($lenStr, $data) = split(/_/, $data);   # 2 strings with Hex Octetts!
    _trace3("get_dh_paramter: #{ DHE RAW data): len: $lenStr\n$data\n#}\n");
    $len = hex($lenStr);
    my $message = pack("H*", $data);

    # parse message header
    my $msgData = "";
    my ($msgType, $msgFirstByte, $msgLen) = 0;
       ($msgType,       # C
        $msgFirstByte,  # C
        $msgLen,        # n
        $msgData)   = unpack("C C n a*", $message);

    if ($msgType == 0x0C) { # is ServerKeyExchange
        # get info about the session cipher and prepare parameter $keyExchange
        # for parseServerKeyExchange()
        my $keyExchange = $cipher;
        _trace1("get_dh_paramter: cipher: $keyExchange");
        $keyExchange =~ s/^((?:EC)?DHE?)_anon.*/A$1/;   # DHE_anon -> EDH, ECDHE_anon -> AECDH, DHE_anon -> ADHE
        $keyExchange =~ s/^((?:EC)?DH)E.*/E$1/;         # DHE -> EDH, ECDHE -> EECDH
        $keyExchange =~ s/^(?:E|A|EA)((?:EC)?DH).*/$1/; # EDH -> DH, ADH -> DH, EECDH -> ECDH
        _trace1(" get_dh_paramter: keyExchange (DH or ECDH) = $keyExchange");
        # get length of 'dh_parameter' manually from '-msg' data if the
        # 'session cipher' uses a keyExchange with DHE and DH_anon
        # (according RFC2246/RFC5246: sections 7.4.3)
        $dh = Net::SSLhello::parseServerKeyExchange($keyExchange, $msgLen, $msgData);
    }

    chomp $dh;
    _trace("get_dh_paramter(){ ServerKeyExchange\t= $dh }");
    return $dh;
}; # get_dh_paramter

# internal methods

sub _prot_init_value() {
    #? initialize default values in %prot
    foreach my $ssl (keys %prot) {
        $prot{$ssl}->{'cnt'}        = 0;
        $prot{$ssl}->{'-?-'}        = 0;
        $prot{$ssl}->{'WEAK'}       = 0;
        $prot{$ssl}->{'LOW'}        = 0;
        $prot{$ssl}->{'MEDIUM'}     = 0;
        $prot{$ssl}->{'HIGH'}       = 0;
        $prot{$ssl}->{'protocol'}   = 0;
        $prot{$ssl}->{'default'}    = STR_UNDEF;
        $prot{$ssl}->{'pfs_cipher'} = STR_UNDEF;
        $prot{$ssl}->{'pfs_ciphers'}= [];
    }
    return;
} # _prot_init_value

sub _cfg_init() {
    #? initialize dynamic settings in %cfg, copy data from %prot
    $cfg{'openssl_option_map'}->{$_}  = $prot{$_}->{'opt'} foreach (keys %prot);
    $cfg{'openssl_version_map'}->{$_} = $prot{$_}->{'hex'} foreach (keys %prot);
    # incorporate some environment variables
    $cfg{'openssl_env'} = $ENV{'OPENSSL'}      if (defined $ENV{'OPENSSL'});
    $cfg{'openssl_cnf'} = $ENV{'OPENSSL_CONF'} if (defined $ENV{'OPENSSL_CONF'});
    $cfg{'openssl_fips'}= $ENV{'OPENSSL_FIPS'} if (defined $ENV{'OPENSSL_FIPS'});

    return;
} # _cfg_init

sub _dbx_init() {
    #? initialize settings for debugging
    $dbx{'cmd-check'} = $cfg{'cmd-check'};
    $dbx{'cmd-http'}  = $cfg{'cmd-http'};
    $dbx{'cmd-info'}  = $cfg{'cmd-info'};
    $dbx{'cmd-quick'} = $cfg{'cmd-quick'};
    push(@{$dbx{file}}, "osaft.pm");    # set myself
    return;
} # _dbx_init


=pod

=head2 osaft_hint($cmd)

Print hint for specified command.
=cut

sub osaft_hint($) {
    #? Print hint for specified command.
    my $cmd = shift;
    print STR_HINT, $cmd;
    return;
} # osaft_hint

sub osaft_sleep($) {
    #? wrapper for IO::select
    my $wait = shift;
    select( undef, undef, undef, $wait);
    return;
} # osaft_sleep

sub _osaft_init() {
    #? additional generic initializations for data structures
    _prot_init_value(); # initallize WEAK, LOW, MEDIUM, HIGH, default, pfs, protocol
    _cfg_init();        # initallize dynamic data in %cfg
    _dbx_init();        # initallize debugging data in %dbx
    foreach my $k (keys %data_oid) {
        $data_oid{$k}->{val} = "<<check error>>"; # set a default value
    }

    # complete initialization of %cfg data
   #foreach my $k (keys %prot); # copy to %cfg
   #    $cfg{'openssl_option_map'}->{$k}  = $prot{$k}->{'opt'}; # copy to %cfg
   #    $cfg{'openssl_version_map'}->{$k} = $prot{$k}->{'hex'}; # copy to %cfg
   #}

    return;
}; # _osaft_init

sub osaft_done() {};            # dummy to check successful include

# complete initializations
_osaft_init();

#_____________________________________________________________________________
#_____________________________________________________ public documentation __|

=pod

=head1 NOTES

It's often recommended not to export constants and variables from modules, see
for example  http://perldoc.perl.org/Exporter.html#Good-Practices . The main
purpose of this module is defining variables. Hence we export them.

=head1 SEE ALSO

# ...

=head1 AUTHOR

28-dec-15 Achim Hoffmann

=cut

## PACKAGE }


#_____________________________________________________________________________
#_____________________________________________________________________ self __|

unless (defined caller) {       # print myself or open connection
    printf("# %s %s\n", __PACKAGE__, $VERSION);
    if (eval {require POD::Perldoc;}) {
        # pod2usage( -verbose => 1 );
        exit( Pod::Perldoc->run(args=>[$0]) );
    }
    if (qx(perldoc -V)) {
        # may return:  You need to install the perl-doc package to use this program.
        #exec "perldoc $0"; # scary ...
        printf("# no POD::Perldoc installed, please try:\n  perldoc $0\n");
        exit 0;
    }
}

1;

