// Generate minimal ECC cert
// Required OpenSSL version < 1.0.1i
// author: Adam Yi <i@adamyi.com>

#include <stdio.h>

#include <openssl/pem.h>
#include <openssl/x509.h>

EVP_PKEY * generate_key_ecc()
{
    BIO *outbio = NULL;

    int eccgrp = OBJ_txt2nid("secp256k1");
    EC_KEY *myecc = EC_KEY_new_by_curve_name(eccgrp);

    EC_KEY_set_asn1_flag(myecc, OPENSSL_EC_NAMED_CURVE);

    if (! (EC_KEY_generate_key(myecc)))
	BIO_printf(outbio, "Error generating the ECC key.");

    EVP_PKEY *pkey = EVP_PKEY_new();
    if (!EVP_PKEY_assign_EC_KEY(pkey, myecc))
	BIO_printf(outbio, "Error assigning ECC key to EVP_PKEY structure.");

    return pkey;
}

X509 * generate_x509(EVP_PKEY * pkey)
{
    X509 * x509 = X509_new();

    ASN1_INTEGER_set(X509_get_serialNumber(x509), 1);

    X509_gmtime_adj(X509_get_notBefore(x509), 0);
    X509_gmtime_adj(X509_get_notAfter(x509), 0);

    X509_set_pubkey(x509, pkey);

    // X509v1 cannot have empty issuer & subject DN
    X509_NAME * name = X509_get_subject_name(x509);

    X509_NAME_add_entry_by_txt(name, "0.0",  MBSTRING_ASC, (unsigned char *)"",        -1, -1, 0);

    X509_set_issuer_name(x509, name);

    return x509;
}

void write_to_disk(EVP_PKEY * pkey, X509 * x509)
{
    FILE * pkey_file = fopen("key.pem", "wb");

    PEM_write_PKCS8PrivateKey(pkey_file, pkey, NULL, NULL, 0, NULL, NULL);
    fclose(pkey_file);

    FILE * x509_file = fopen("cert.pem", "wb");

    PEM_write_X509(x509_file, x509);
    fclose(x509_file);

    return;
}

int main(int argc, char ** argv)
{
    printf("Generating ECC key...\n");

    EVP_PKEY * pkey = generate_key_ecc();
    if(!pkey)
	return 1;

    printf("Generating X509 cert...\n");

    X509 * x509 = generate_x509(pkey);
    if(!x509)
    {
	EVP_PKEY_free(pkey);
	return 1;
    }

    printf("Writting files....\n");

    write_to_disk(pkey, x509);
    EVP_PKEY_free(pkey);
    X509_free(x509);

    printf("Done!\n");
}
